import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from ElementSearch),
// extractTextContent (from Utils/TextExtraction.swift), DEFAULT_MAX_DEPTH_COLLECT_ALL, MAX_COLLECT_ALL_HITS,
// collectedDebugLogs, CommandEnvelope, TextContentResponse, Locator, Element.

@MainActor
public func handleExtractText(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> TextContentResponse {
    var handlerLogs: [String] = [] // Local logs for this handler
    func dLog(_ message: String) { if isDebugLoggingEnabled { handlerLogs.append(message) } }
    let appIdentifier = cmd.application ?? focusedApplicationKey
    dLog("Handling extract_text for app: \(appIdentifier)")
    
    // Pass logging parameters to applicationElement
    guard let appElement = applicationElement(for: appIdentifier, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &handlerLogs) else {
        return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Application not found: \(appIdentifier)", debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        dLog("ExtractText: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        // Pass logging parameters to navigateToElement
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &handlerLogs) {
            effectiveElement = navigatedElement
        } else {
            return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Element for text extraction (path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
        }
    }

    var elementsToExtractFrom: [Element] = []

    if let locator = cmd.locator {
        var foundCollectedElements: [Element] = []
        var processingSet = Set<Element>()
        // Pass logging parameters to collectAll
        collectAll(
            appElement: appElement,
            locator: locator, 
            currentElement: effectiveElement,
            depth: 0, 
            maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_COLLECT_ALL, 
            maxElements: cmd.max_elements ?? MAX_COLLECT_ALL_HITS,
            currentPath: [], 
            elementsBeingProcessed: &processingSet, 
            foundElements: &foundCollectedElements,
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &handlerLogs
        )
        elementsToExtractFrom = foundCollectedElements
    } else {
        elementsToExtractFrom = [effectiveElement]
    }
    
    if elementsToExtractFrom.isEmpty && cmd.locator != nil {
         return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "No elements found by locator for text extraction.", debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
    }

    var allTexts: [String] = []
    for element in elementsToExtractFrom {
        // Pass logging parameters to extractTextContent
        allTexts.append(extractTextContent(element: element, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &handlerLogs))
    }
    
    let combinedText = allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n---\n\n")
    return TextContentResponse(command_id: cmd.command_id, text_content: combinedText.isEmpty ? nil : combinedText, error: nil, debug_logs: isDebugLoggingEnabled ? handlerLogs : nil)
}