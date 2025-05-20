import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from ElementSearch),
// extractTextContent (from Utils/TextExtraction.swift), DEFAULT_MAX_DEPTH_COLLECT_ALL, MAX_COLLECT_ALL_HITS,
// collectedDebugLogs, CommandEnvelope, TextContentResponse, Locator, Element.

@MainActor
func handleExtractText(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> TextContentResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling extract_text for app: \(appIdentifier)")
    guard let appElement = applicationElement(for: appIdentifier) else {
        return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveElement = appElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("ExtractText: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedElement = navigateToElement(from: effectiveElement, pathHint: pathHint) {
            effectiveElement = navigatedElement
        } else {
            return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Element for text extraction (path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }

    var elementsToExtractFrom: [Element] = []

    if let locator = cmd.locator {
        var foundCollectedElements: [Element] = []
        var processingSet = Set<Element>()
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
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
        elementsToExtractFrom = foundCollectedElements
    } else {
        elementsToExtractFrom = [effectiveElement]
    }
    
    if elementsToExtractFrom.isEmpty && cmd.locator != nil {
         return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "No elements found by locator for text extraction.", debug_logs: collectedDebugLogs)
    }

    var allTexts: [String] = []
    for element in elementsToExtractFrom {
        allTexts.append(extractTextContent(element: element))
    }
    
    let combinedText = allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n---\n\n")
    return TextContentResponse(command_id: cmd.command_id, text_content: combinedText.isEmpty ? nil : combinedText, error: nil, debug_logs: collectedDebugLogs)
}