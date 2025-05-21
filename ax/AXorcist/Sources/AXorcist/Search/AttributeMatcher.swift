import Foundation
import ApplicationServices // For AXUIElement, CFTypeRef etc.

// debug() is assumed to be globally available from Logging.swift
// DEBUG_LOGGING_ENABLED is a global public var from Logging.swift

@MainActor
internal func attributesMatch(element: Element, matchDetails: [String: String], depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls

    let criteriaDesc = matchDetails.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    let roleForLog = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "nil"
    let titleForLog = element.title(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "nil"
    dLog("attributesMatch [D\(depth)]: Check. Role=\(roleForLog), Title=\(titleForLog). Criteria: [\(criteriaDesc)]")

    if !matchComputedNameAttributes(element: element, computedNameEquals: matchDetails[computedNameAttributeKey + "_equals"], computedNameContains: matchDetails[computedNameAttributeKey + "_contains"], depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
        return false
    }

    for (key, expectedValue) in matchDetails {
        if key == computedNameAttributeKey + "_equals" || key == computedNameAttributeKey + "_contains" { continue }
        if key == kAXRoleAttribute { continue } // Already handled by ElementSearch's role check or not a primary filter here

        if key == kAXEnabledAttribute || key == kAXFocusedAttribute || key == kAXHiddenAttribute || key == kAXElementBusyAttribute || key == isIgnoredAttributeKey || key == kAXMainAttribute {
            if !matchBooleanAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                return false
            }
            continue
        }
        
        if key == kAXActionNamesAttribute || key == kAXAllowedValuesAttribute || key == kAXChildrenAttribute {
            if !matchArrayAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
                return false
            }
            continue
        }

        if !matchStringAttribute(element: element, key: key, expectedValueString: expectedValue, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
            return false
        }
    }

    dLog("attributesMatch [D\(depth)]: All attributes MATCHED criteria.")
    return true
}

@MainActor
internal func matchStringAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls

    if let currentValue = element.attribute(Attribute<String>(key), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
        if currentValue != expectedValueString {
            dLog("attributesMatch [D\(depth)]: Attribute '\(key)' expected '\(expectedValueString)', but found '\(currentValue)'. No match.")
            return false
        }
        return true
    } else {
        if expectedValueString.lowercased() == "nil" || expectedValueString == kAXNotAvailableString || expectedValueString.isEmpty {
            dLog("attributesMatch [D\(depth)]: Attribute '\(key)' not found, but expected value ('\(expectedValueString)') suggests absence is OK. Match for this key.")
            return true
        } else {
            dLog("attributesMatch [D\(depth)]: Attribute '\(key)' (expected '\(expectedValueString)') not found or not convertible to String. No match.")
            return false
        }
    }
}

@MainActor
internal func matchArrayAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls

    guard let expectedArray = decodeExpectedArray(fromString: expectedValueString, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) else {
        dLog("matchArrayAttribute [D\(depth)]: Could not decode expected array string '\(expectedValueString)' for attribute '\(key)'. No match.")
        return false
    }
    
    var actualArray: [String]? = nil
    if key == kAXActionNamesAttribute {
        actualArray = element.supportedActions(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    } else if key == kAXAllowedValuesAttribute {
        actualArray = element.attribute(Attribute<[String]>(key), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    } else if key == kAXChildrenAttribute {
        actualArray = element.children(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)?.map { childElement -> String in 
            var childLogs: [String] = []
            return childElement.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &childLogs) ?? "UnknownRole" 
        }
    } else {
        dLog("matchArrayAttribute [D\(depth)]: Unknown array key '\(key)'. This function needs to be extended for this key.")
        return false
    }

    if let actual = actualArray {
        if Set(actual) != Set(expectedArray) {
            dLog("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' expected '\(expectedArray)', but found '\(actual)'. Sets differ. No match.")
            return false
        }
        return true
    } else {
        if expectedArray.isEmpty {
            dLog("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' not found, but expected array was empty. Match for this key.")
            return true
        }
        dLog("matchArrayAttribute [D\(depth)]: Array Attribute '\(key)' (expected '\(expectedValueString)') not found in element. No match.")
        return false
    }
}

@MainActor
internal func matchBooleanAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls
    var currentBoolValue: Bool?

    switch key {
    case kAXEnabledAttribute: currentBoolValue = element.isEnabled(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXFocusedAttribute: currentBoolValue = element.isFocused(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXHiddenAttribute: currentBoolValue = element.isHidden(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXElementBusyAttribute: currentBoolValue = element.isElementBusy(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case isIgnoredAttributeKey: currentBoolValue = element.isIgnored(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    case kAXMainAttribute: currentBoolValue = element.attribute(Attribute<Bool>(key), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    default: 
        dLog("matchBooleanAttribute [D\(depth)]: Unknown boolean key '\(key)'. This should not happen.")
        return false
    }

    if let actualBool = currentBoolValue {
        let expectedBool = expectedValueString.lowercased() == "true"
        if actualBool != expectedBool {
            dLog("attributesMatch [D\(depth)]: Boolean Attribute '\(key)' expected '\(expectedBool)', but found '\(actualBool)'. No match.")
            return false
        }
        return true
    } else { 
        dLog("attributesMatch [D\(depth)]: Boolean Attribute '\(key)' (expected '\(expectedValueString)') not found in element. No match.")
        return false
    }
}

@MainActor
internal func matchComputedNameAttributes(element: Element, computedNameEquals: String?, computedNameContains: String?, depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> Bool {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For Element method calls

    if computedNameEquals == nil && computedNameContains == nil {
        return true
    }

    // getComputedAttributes will need logging parameters
    let computedAttrs = getComputedAttributes(for: element, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    if let currentComputedNameAny = computedAttrs[computedNameAttributeKey]?.value, // Assuming .value is how you get it from the AttributeData struct
       let currentComputedName = currentComputedNameAny as? String {
        if let equals = computedNameEquals {
            if currentComputedName != equals {
                dLog("matchComputedNameAttributes [D\(depth)]: ComputedName '\(currentComputedName)' != '\(equals)'. No match.")
                return false
            }
        }
        if let contains = computedNameContains {
            if !currentComputedName.localizedCaseInsensitiveContains(contains) {
                dLog("matchComputedNameAttributes [D\(depth)]: ComputedName '\(currentComputedName)' does not contain '\(contains)'. No match.")
                return false
            }
        }
        return true
    } else { 
        dLog("matchComputedNameAttributes [D\(depth)]: Locator requires ComputedName (equals: \(computedNameEquals ?? "nil"), contains: \(computedNameContains ?? "nil")), but element has none. No match.")
        return false
    }
}

