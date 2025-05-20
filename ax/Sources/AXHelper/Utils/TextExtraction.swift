// TextExtraction.swift - Utilities for extracting textual content from Elements.

import Foundation
import ApplicationServices // For Element and kAX...Attribute constants

// Assumes Element is defined and has an `attribute(String) -> String?` method.
// Constants like kAXValueAttribute are expected to be available (e.g., from AccessibilityConstants.swift)
// axValue<T>() is assumed to be globally available from ValueHelpers.swift

@MainActor
public func extractTextContent(element: Element) -> String {
    var texts: [String] = []
    let textualAttributes = [
        kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute,
        kAXPlaceholderValueAttribute, kAXLabelValueAttribute, kAXRoleDescriptionAttribute,
        // Consider adding kAXStringForRangeParameterizedAttribute if dealing with large text views for performance
        // kAXSelectedTextAttribute could also be relevant depending on use case
    ]
    for attrName in textualAttributes {
        // Ensure element.attribute returns an optional String or can be cast to it.
        // The original code directly cast to String, assuming non-nil, which can be risky.
        // A safer approach is to conditionally unwrap or use nil coalescing.
        if let strValue: String = axValue(of: element.underlyingElement, attr: attrName), !strValue.isEmpty, strValue.lowercased() != "not available" {
            texts.append(strValue)
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