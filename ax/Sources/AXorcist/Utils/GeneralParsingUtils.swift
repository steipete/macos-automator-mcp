// GeneralParsingUtils.swift - General parsing utilities

import Foundation

// TODO: Consider if this should be public or internal depending on usage across modules if this were a larger project.
// For AXHelper, internal or public within the module is fine.

/// Decodes a string representation of an array into an array of strings.
/// The input string can be JSON-style (e.g., "["item1", "item2"]")
/// or a simple comma-separated list (e.g., "item1, item2", with or without brackets).
public func decodeExpectedArray(fromString: String, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> [String]? {
    // This function itself does not log, but takes the parameters as it's called by functions that do.
    // func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }

    let trimmedString = fromString.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Try JSON deserialization first for robustness with escaped characters, etc.
    if trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]") {
        if let jsonData = trimmedString.data(using: .utf8) {
            do {
                // Attempt to decode as [String]
                if let array = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String] {
                    return array
                } 
                // Fallback: if it decodes as [Any], convert elements to String
                else if let anyArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any] {
                    return anyArray.compactMap { item -> String? in
                        if let strItem = item as? String {
                            return strItem
                        } else {
                            // For non-string items, convert to string representation
                            // This handles numbers, booleans if they were in the JSON array
                            return String(describing: item)
                        }
                    }
                }
            } catch {
                // dLog("JSON decoding failed for string: \(trimmedString). Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Fallback to comma-separated parsing if JSON fails or string isn't JSON-like
    // Remove brackets first if they exist for comma parsing
    var stringToSplit = trimmedString
    if stringToSplit.hasPrefix("[") && stringToSplit.hasSuffix("]") {
        stringToSplit = String(stringToSplit.dropFirst().dropLast())
    }

    // If the string (after removing brackets) is empty, it represents an empty array.
    if stringToSplit.isEmpty && trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]") {
        return []
    }
    // If the original string was just "[]" or "", and after stripping it's empty, it's an empty array.
    // If it was empty to begin with, or just spaces, it's not a valid array string by this func's def.
    if stringToSplit.isEmpty && !trimmedString.isEmpty && !(trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]")) {
        // e.g. input was " " which became "", not a valid array representation
        // or input was "item" which is not an array string
        // However, if original was "[]", stringToSplit is empty, should return []
        // If original was "", stringToSplit is empty, should return nil (or based on stricter needs)
        // This function is lenient: if after stripping brackets it's empty, it's an empty array.
        // If the original was non-empty but not bracketed, and became empty after trimming, it's not an array.
    }

    // Handle case where stringToSplit might be empty, meaning an empty array if brackets were present.
    if stringToSplit.isEmpty {
        // If original string was "[]", then stringToSplit is empty, return []
        // If original was "", then stringToSplit is empty, return nil (not an array format)
        return (trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]")) ? [] : nil
    }

    return stringToSplit.components(separatedBy: ",")
                           .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                           // Do not filter out empty strings if they are explicitly part of the list e.g. "a,,b"
                           // The original did .filter { !$0.isEmpty }, which might be too aggressive.
                           // For now, let's keep all components and let caller decide if empty strings are valid.
                           // Re-evaluating: if a component is empty after trimming, it usually means an empty element.
                           // Example: "[a, ,b]" -> ["a", "", "b"]. Example "a," -> ["a", ""].
                           // The original .filter { !$0.isEmpty } would turn "a,," into ["a"]
                           // Let's retain the original filtering of completely empty strings after trim, 
                           // as "[a,,b]" usually implies "[a,b]" in lenient contexts.
                           // If explicit empty strings like `["a", "", "b"]` are needed, JSON is better.
                           .filter { !$0.isEmpty } 
}