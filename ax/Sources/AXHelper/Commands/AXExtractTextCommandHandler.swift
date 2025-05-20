import Foundation
import ApplicationServices
import AppKit

// Note: Relies on applicationElement, navigateToElement, collectAll (from AXSearch),
// extractTextContent (from Utils/AXTextExtraction.swift), DEFAULT_MAX_DEPTH_COLLECT_ALL, MAX_COLLECT_ALL_HITS,
// collectedDebugLogs, CommandEnvelope, TextContentResponse, Locator, AXElement.

@MainActor
func handleExtractText(cmd: CommandEnvelope, isDebugLoggingEnabled: Bool) throws -> TextContentResponse {
    let appIdentifier = cmd.application ?? "focused"
    debug("Handling extract_text for app: \(appIdentifier)")
    guard let appAXElement = applicationElement(for: appIdentifier) else {
        return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Application not found: \(appIdentifier)", debug_logs: collectedDebugLogs)
    }

    var effectiveAXElement = appAXElement
    if let pathHint = cmd.path_hint, !pathHint.isEmpty {
        debug("ExtractText: Navigating with path_hint: \(pathHint.joined(separator: " -> "))")
        if let navigatedAXElement = navigateToElement(from: effectiveAXElement, pathHint: pathHint) {
            effectiveAXElement = navigatedAXElement
        } else {
            return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "Element for text extraction (path_hint) not found: \(pathHint.joined(separator: " -> "))", debug_logs: collectedDebugLogs)
        }
    }

    var elementsToExtractFromAX: [AXElement] = []

    if let locator = cmd.locator {
        var foundCollectedAXElements: [AXElement] = []
        var processingSet = Set<AXElement>()
        collectAll(
            appAXElement: appAXElement,
            locator: locator, 
            currentAXElement: effectiveAXElement,
            depth: 0, 
            maxDepth: cmd.max_elements ?? DEFAULT_MAX_DEPTH_COLLECT_ALL, 
            maxElements: cmd.max_elements ?? MAX_COLLECT_ALL_HITS,
            currentPath: [], 
            elementsBeingProcessed: &processingSet, 
            foundElements: &foundCollectedAXElements,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
        elementsToExtractFromAX = foundCollectedAXElements
    } else {
        elementsToExtractFromAX = [effectiveAXElement]
    }
    
    if elementsToExtractFromAX.isEmpty && cmd.locator != nil {
         return TextContentResponse(command_id: cmd.command_id, text_content: nil, error: "No elements found by locator for text extraction.", debug_logs: collectedDebugLogs)
    }

    var allTexts: [String] = []
    for axEl in elementsToExtractFromAX {
        allTexts.append(extractTextContent(axElement: axEl))
    }
    
    let combinedText = allTexts.filter { !$0.isEmpty }.joined(separator: "\n\n---\n\n")
    return TextContentResponse(command_id: cmd.command_id, text_content: combinedText.isEmpty ? nil : combinedText, error: nil, debug_logs: collectedDebugLogs)
} 