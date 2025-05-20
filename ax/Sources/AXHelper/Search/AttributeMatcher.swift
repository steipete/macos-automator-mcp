import Foundation
import ApplicationServices // For AXUIElement, CFTypeRef etc.

// debug() is assumed to be globally available from Logging.swift
// DEBUG_LOGGING_ENABLED is a global public var from Logging.swift

@MainActor
internal func attributesMatch(element: Element, matchDetails: [String: String], depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    if isDebugLoggingEnabled {
        let criteriaDesc = matchDetails.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let roleForLog = element.role ?? "nil"
        let titleForLog = element.title ?? "nil"
        debug("attributesMatch [D\(depth)]: Check. Role=\(roleForLog), Title=\(titleForLog). Criteria: [\(criteriaDesc)]")
    }

    // Check computed name criteria first
    let computedNameEquals = matchDetails["computed_name_equals"]
    let computedNameContains = matchDetails["computed_name_contains"]
    if !matchComputedNameAttributes(element: element, computedNameEquals: computedNameEquals, computedNameContains: computedNameContains, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
        return false // Computed name check failed
    }

    // Existing criteria matching logic
    for (key, expectedValue) in matchDetails {
        // Skip computed_name keys here as they are handled above
        if key == "computed_name_equals" || key == "computed_name_contains" { continue }

        // Skip AXRole as it's handled by the caller (search/collectAll) before calling attributesMatch.
        if key == kAXRoleAttribute || key == "AXRole" { continue }

        // Handle boolean attributes explicitly
        if key == kAXEnabledAttribute || key == kAXFocusedAttribute || key == kAXHiddenAttribute || key == kAXElementBusyAttribute || key == "IsIgnored" || key == kAXMainAttribute {
            if !matchBooleanAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
                return false // No match
            }
            continue // Move to next criteria item
        }
        
        // For array attributes, decode the expected string value into an array
        if key == kAXActionNamesAttribute || key == kAXAllowedValuesAttribute || key == kAXChildrenAttribute /* add others if needed */ {
            if !matchArrayAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
                return false // No match
            }
            continue
        }

        // Fallback to generic string attribute comparison
        if !matchStringAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
            return false // No match
        }
    }

    if isDebugLoggingEnabled {
        debug("attributesMatch [D\(depth)]: All attributes MATCHED criteria.")
    }
    return true
}

@MainActor
internal func matchStringAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    if let currentValue = element.attribute(Attribute<String>(key)) { // Attribute<String> implies string conversion
        if currentValue != expectedValueString {
            if isDebugLoggingEnabled {
                debug("attributesMatch [D\(depth)]: Attribute '\(key)' expected '\(expectedValueString)', but found '\(currentValue)'. No match.")
            }
            return false
        }
        return true // Match for this string attribute
    } else {
        // If axValue returns nil, it means the attribute doesn't exist, or couldn't be converted to String.
        // Check if expected value was also indicating absence or a specific "not available" string
        if expectedValueString.lowercased() == "nil" || expectedValueString == kAXNotAvailableString || expectedValueString.isEmpty {
             if isDebugLoggingEnabled {
                debug("attributesMatch [D\(depth)]: Attribute '\(key)' not found, but expected value ('\(expectedValueString)') suggests absence is OK. Match for this key.")
            }
            return true // Absence was expected
        } else {
            if isDebugLoggingEnabled {
                debug("attributesMatch [D\(depth)]: Attribute '\(key)' (expected '\(expectedValueString)') not found or not convertible to String. No match.")
            }
            return false
        }
    }
}

@MainActor
internal func matchArrayAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    guard let expectedArray = decodeExpectedArray(fromString: expectedValueString) else {
        if isDebugLoggingEnabled {
            debug("matchArrayAttribute [D\(depth)]: Could not decode expected array string '\(expectedValueString)' for attribute '\(key)'. No match.")
        }
        return false
    }
    
    var actualArray: [String]? = nil
    if key == kAXActionNamesAttribute {
        actualArray = element.supportedActions
    } else if key == kAXAllowedValuesAttribute {
        actualArray = element.attribute(Attribute<[String]>(key))
    } else if key == kAXChildrenAttribute {
        actualArray = element.children?.map { $0.role ?? "UnknownRole" } 
    } else {
        if isDebugLoggingEnabled {
            debug("matchArrayAttribute [D\(depth)]: Unknown array key '\(key)'. This function needs to be extended for this key.")
        }
        return false
    }

    if let actual = actualArray {
        if Set(actual) != Set(expectedArray) {
            if isDebugLoggingEnabled {
                debug("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' expected '\(expectedArray)', but found '\(actual)'. Sets differ. No match.")
            }
            return false
        }
        return true
    } else {
        // If expectedArray is empty and actualArray is nil (attribute not present), consider it a match for "empty list matches not present"
        if expectedArray.isEmpty {
            if isDebugLoggingEnabled {
                 debug("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' not found, but expected array was empty. Match for this key.")
            }
            return true
        }
        if isDebugLoggingEnabled {
            debug("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' (expected '\(expectedValueString)') not found in element. No match.")
        }
        return false
    }
}

@MainActor
internal func matchBooleanAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    var currentBoolValue: Bool?
    switch key {
    case kAXEnabledAttribute: currentBoolValue = element.isEnabled
    case kAXFocusedAttribute: currentBoolValue = element.isFocused
    case kAXHiddenAttribute: currentBoolValue = element.isHidden
    case kAXElementBusyAttribute: currentBoolValue = element.isElementBusy
    case "IsIgnored": currentBoolValue = element.isIgnored // This is already a Bool
    case kAXMainAttribute: currentBoolValue = element.attribute(Attribute<Bool>(key)) // Fetch as Bool
    default: 
        if isDebugLoggingEnabled {
            debug("matchBooleanAttribute [D\(depth)]: Unknown boolean key '\(key)'. This should not happen.")
        }
        return false // Should not be called with other keys
    }

    if let actualBool = currentBoolValue {
        let expectedBool = expectedValueString.lowercased() == "true"
        if actualBool != expectedBool {
            if isDebugLoggingEnabled {
                debug("attributesMatch [D\(depth)]: Boolean Attribute '\(key)' expected '\(expectedBool)', but found '\(actualBool)'. No match.")
            }
            return false
        }
        return true // Match for this boolean attribute
    } else { // Attribute not present or not a boolean (should not happen for defined keys if element implements them)
        if isDebugLoggingEnabled {
            debug("attributesMatch [D\(depth)]: Boolean Attribute '\(key)' (expected '\(expectedValueString)') not found in element. No match.")
        }
        return false
    }
}

@MainActor
internal func matchComputedNameAttributes(element: Element, computedNameEquals: String?, computedNameContains: String?, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    if computedNameEquals == nil && computedNameContains == nil {
        return true // No computed name criteria to check
    }

    let computedAttrs = getComputedAttributes(for: element)
    if let currentComputedNameAny = computedAttrs["ComputedName"]?.value,
       let currentComputedName = currentComputedNameAny as? String {
        if let equals = computedNameEquals {
            if currentComputedName != equals {
                if isDebugLoggingEnabled {
                    debug("matchComputedNameAttributes [D\(depth)]: ComputedName '\(currentComputedName)' != '\(equals)'. No match.")
                }
                return false
            }
        }
        if let contains = computedNameContains {
            if !currentComputedName.localizedCaseInsensitiveContains(contains) {
                if isDebugLoggingEnabled {
                    debug("matchComputedNameAttributes [D\(depth)]: ComputedName '\(currentComputedName)' does not contain '\(contains)'. No match.")
                }
                return false
            }
        }
        return true // Matched computed name criteria or no relevant criteria provided for it
    } else { // No ComputedName available from the element
        // If locator requires computed name but element has none, it's not a match
        if isDebugLoggingEnabled {
            debug("matchComputedNameAttributes [D\(depth)]: Locator requires ComputedName (equals: \(computedNameEquals ?? "nil"), contains: \(computedNameContains ?? "nil")), but element has none. No match.")
        }
        return false
    }
}

