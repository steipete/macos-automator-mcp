// TextExtraction.swift - Utilities for extracting textual content from Elements.

import Foundation
import ApplicationServices // For Element and kAX...Attribute constants

// Assumes Element is defined and has an `attribute(String) -> String?` method.
// Constants like kAXValueAttribute are expected to be available (e.g., from AccessibilityConstants.swift)
// axValue<T>() is assumed to be globally available from ValueHelpers.swift

@MainActor
public func extractTextContent(element: Element, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> String {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    dLog("Extracting text content for element: \(element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")
    var texts: [String] = []
    let textualAttributes = [
        kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute,
        kAXPlaceholderValueAttribute, kAXLabelValueAttribute, kAXRoleDescriptionAttribute,
        // Consider adding kAXStringForRangeParameterizedAttribute if dealing with large text views for performance
        // kAXSelectedTextAttribute could also be relevant depending on use case
    ]
    for attrName in textualAttributes {
        var tempLogs: [String] = [] // For the axValue call
        // Pass the received logging parameters to axValue
        if let strValue: String = axValue(of: element.underlyingElement, attr: attrName, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs), !strValue.isEmpty, strValue.lowercased() != kAXNotAvailableString.lowercased() {
            texts.append(strValue)
            currentDebugLogs.append(contentsOf: tempLogs) // Collect logs from axValue
        } else {
            currentDebugLogs.append(contentsOf: tempLogs) // Still collect logs if value was nil/empty
        }
    }
    
    // Deduplicate while preserving order
    var uniqueTexts: [String] = []
    var seenTexts = Set<String>()
    for text in texts {
        if !seenTexts.contains(text) {
            uniqueTexts.append(text)
            seenTexts.insert(text)
        }
    }
    return uniqueTexts.joined(separator: "\n")
}