import Foundation
import ApplicationServices     // AXUIElement*
import AppKit                 // NSRunningApplication, NSWorkspace
// CoreGraphics may be used by other files but not directly needed in this lean main.swift

fputs("AX_SWIFT_TOP_SCOPE_FPUTS_STDERR\n", stderr) // For initial stderr check by caller

// Low-level type ID functions are now in AXUtils.swift
// func AXUIElementGetTypeID() -> CFTypeID {
//     return AXUIElementGetTypeID_Impl()
// }
// @_silgen_name("AXUIElementGetTypeID")
// func AXUIElementGetTypeID_Impl() -> CFTypeID

@MainActor
func checkAccessibilityPermissions() {
    debug("Checking accessibility permissions...")
    if !AXIsProcessTrusted() {
        fputs("ERROR: Accessibility permissions are not granted.\n", stderr)
        fputs("Please enable in System Settings > Privacy & Security > Accessibility.\n", stderr)
        if let parentName = getParentProcessName() {
            fputs("Hint: Grant accessibility permissions to '\(parentName)'.\n", stderr)
        }
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        _ = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        exit(1)
    } else {
        debug("Accessibility permissions are granted.")
    }
}

@MainActor
func getParentProcessName() -> String? {
    let parentPid = getppid()
    if let parentApp = NSRunningApplication(processIdentifier: parentPid) {
        return parentApp.localizedName ?? parentApp.bundleIdentifier
    }
    return nil
}

@MainActor 
func getApplicationElement(bundleIdOrName: String) -> AXUIElement? {
    guard let processID = pid(forAppIdentifier: bundleIdOrName) else { // pid is in AXUtils.swift
        debug("Failed to find PID for app: \(bundleIdOrName)")
        return nil
    }
    debug("Creating application element for PID: \(processID) for app '\(bundleIdOrName)'.")
    return AXUIElementCreateApplication(processID)
}

// MARK: - Core Verbs

@MainActor
func handleQuery(cmd: CommandEnvelope) throws -> Codable {
    debug("Handling query for app '\(cmd.locator.app)', role '\(cmd.locator.role ?? "any")', multi: \(cmd.multi ?? false)")

    guard let appElement = getApplicationElement(bundleIdOrName: cmd.locator.app) else {
        return ErrorResponse(error: "Application not found: \(cmd.locator.app)", debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
    }

    var startElement = appElement
    if let pathHint = cmd.locator.pathHint, !pathHint.isEmpty {
        guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) else { // navigateToElement from AXUtils.swift
            return ErrorResponse(error: "Element not found via path hint: \(pathHint)", debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
        }
        startElement = navigatedElement
    }

    let reqAttrs = cmd.attributes ?? []
    let outputFormat = cmd.output_format ?? "smart"

    if outputFormat == "text_content" {
        var allTexts: [String] = []
        if cmd.multi == true {
            var hits: [AXUIElement] = []
            // collectAll from AXSearch.swift
            collectAll(element: startElement, locator: cmd.locator, requireAction: cmd.locator.requireAction, hits: &hits)
            let elementsToProcess = Array(hits.prefix(cmd.max_elements ?? 200))
            for el in elementsToProcess {
                allTexts.append(extractTextContent(element: el)) // extractTextContent from AXUtils.swift
            }
        } else {
            guard let found = search(element: startElement, locator: cmd.locator, requireAction: cmd.locator.requireAction) else { // search from AXSearch.swift
                return ErrorResponse(error: "No element matched for text_content single query", debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
            }
            allTexts.append(extractTextContent(element: found))
        }
        return TextContentResponse(text_content: allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n"), debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
    }

    if cmd.multi == true {
        var hits: [AXUIElement] = []
        collectAll(element: startElement, locator: cmd.locator, requireAction: cmd.locator.requireAction, hits: &hits)
        if hits.isEmpty {
             return ErrorResponse(error: "No elements matched multi-query criteria", debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
        }
        var elementsToProcess = hits
        if let max = cmd.max_elements, elementsToProcess.count > max {
            elementsToProcess = Array(elementsToProcess.prefix(max))
            debug("Capped multi-query results from \(hits.count) to \(max)")
        }
        let resultArray = elementsToProcess.map {
            getElementAttributes($0, requestedAttributes: reqAttrs, forMultiDefault: (reqAttrs.isEmpty), targetRole: cmd.locator.role, outputFormat: outputFormat)
        }
        return MultiQueryResponse(elements: resultArray, debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
    } else {
        guard let foundElement = search(element: startElement, locator: cmd.locator, requireAction: cmd.locator.requireAction) else {
            return ErrorResponse(error: "No element matches single query criteria", debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
        }
        let attributes = getElementAttributes(foundElement, requestedAttributes: reqAttrs, forMultiDefault: false, targetRole: cmd.locator.role, outputFormat: outputFormat)
        return QueryResponse(attributes: attributes, debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
    }
}

@MainActor
func handlePerform(cmd: CommandEnvelope) throws -> PerformResponse {
    debug("Handling perform for app '\(cmd.locator.app)', role '\(cmd.locator.role ?? "any")', action: \(cmd.action ?? "nil")")
    guard let appElement = getApplicationElement(bundleIdOrName: cmd.locator.app),
          let actionToPerform = cmd.action else {
        throw AXErrorString.elementNotFound
    }
    var startElement = appElement
    if let pathHint = cmd.locator.pathHint, !pathHint.isEmpty {
        guard let navigatedElement = navigateToElement(from: appElement, pathHint: pathHint) else {
            throw AXErrorString.elementNotFound
        }
        startElement = navigatedElement
    }
    guard let targetElement = search(element: startElement, locator: cmd.locator, requireAction: actionToPerform) else {
        throw AXErrorString.elementNotFound
    }
    let err = AXUIElementPerformAction(targetElement, actionToPerform as CFString)
    guard err == .success else {
        throw AXErrorString.actionFailed(err)
    }
    return PerformResponse(status: "ok", message: nil, debug_logs: commandSpecificDebugLoggingEnabled ? collectedDebugLogs : nil)
}

// MARK: - Main Loop

let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = [.withoutEscapingSlashes]

if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    let helpText = """
    ax Accessibility Helper v\(AX_BINARY_VERSION)
    Communicates via JSON on stdin/stdout.
    Input JSON: See CommandEnvelope in AXModels.swift
    Output JSON: See response structs (QueryResponse, etc.) in AXModels.swift
    """
    print(helpText)
    exit(0)
}

checkAccessibilityPermissions()
debug("ax binary version: \(AX_BINARY_VERSION) starting main loop.")

while let line = readLine(strippingNewline: true) {
    collectedDebugLogs = [] 
    commandSpecificDebugLoggingEnabled = false

    fputs("AX_SWIFT_INSIDE_WHILE_LOOP_FPUTS_STDERR\n", stderr)

    do {
        let data = Data(line.utf8)
        let cmdEnvelope = try decoder.decode(CommandEnvelope.self, from: data)

        if cmdEnvelope.debug_logging == true {
            commandSpecificDebugLoggingEnabled = true
            debug("Command-specific debug logging explicitly enabled for this request.")
        }

        var response: Codable
        switch cmdEnvelope.cmd {
        case .query:
            response = try handleQuery(cmd: cmdEnvelope)
        case .perform:
            response = try handlePerform(cmd: cmdEnvelope)
        }
        
        let reply = try encoder.encode(response)
        FileHandle.standardOutput.write(reply)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)

    } catch let error as AXErrorString {
        let errorResponse = ErrorResponse(error: error.description, debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        if let errorData = try? encoder.encode(errorResponse) {
            FileHandle.standardError.write(errorData)
            FileHandle.standardError.write("\n".data(using: .utf8)!)
        } else {
            fputs("{\"error\":\"Failed to encode AXErrorString: \(error.description)\"}\n", stderr)
        }
    } catch {
        let errorResponse = ErrorResponse(error: "Unknown error: \(error.localizedDescription)", debug_logs: collectedDebugLogs.isEmpty ? nil : collectedDebugLogs)
        if let errorData = try? encoder.encode(errorResponse) {
            FileHandle.standardError.write(errorData)
            FileHandle.standardError.write("\n".data(using: .utf8)!)
        } else {
            fputs("{\"error\":\"Unknown error and failed to encode: \(error.localizedDescription)\"}\n", stderr)
        }
    }
}

