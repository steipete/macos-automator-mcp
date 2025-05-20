// ElementSearch.swift - Contains search and element collection logic

import Foundation
import ApplicationServices

// Variable DEBUG_LOGGING_ENABLED is expected to be globally available from Logging.swift
// Element is now the primary type for UI elements.

// decodeExpectedArray MOVED to Utils/GeneralParsingUtils.swift

enum ElementMatchStatus {
    case fullMatch          // Role, attributes, and (if specified) action all match
    case partialMatch_actionMissing // Role and attributes match, but a required action is missing
    case noMatch            // Role or attributes do not match
}

@MainActor
private func evaluateElementAgainstCriteria(element: Element, locator: Locator, actionToVerify: String?, depth: Int, isDebugLoggingEnabled: Bool) -> ElementMatchStatus {
    let currentElementRoleForLog: String? = element.role
    let wantedRoleFromCriteria = locator.criteria[kAXRoleAttribute as String] ?? locator.criteria["AXRole"]
    var roleMatchesCriteria = false

    if let currentRole = currentElementRoleForLog, let roleToMatch = wantedRoleFromCriteria, !roleToMatch.isEmpty, roleToMatch != "*" {
        roleMatchesCriteria = (currentRole == roleToMatch)
    } else {
        roleMatchesCriteria = true // Wildcard/empty/nil role in criteria is a match
        if isDebugLoggingEnabled {
            let wantedRoleStr = wantedRoleFromCriteria ?? "any"
            let currentRoleStr = currentElementRoleForLog ?? "nil"
            debug("evaluateElementAgainstCriteria [D\(depth)]: Wildcard/empty/nil role in criteria ('\(wantedRoleStr)') considered a match for element role \(currentRoleStr).")
        }
    }

    if !roleMatchesCriteria {
        if isDebugLoggingEnabled {
            debug("evaluateElementAgainstCriteria [D\(depth)]: Role mismatch. Element role: \(currentElementRoleForLog ?? "nil"), Expected: \(wantedRoleFromCriteria ?? "any"). No match.")
        }
        return .noMatch
    }

    // Role matches, now check other attributes
    if !attributesMatch(element: element, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
        // attributesMatch itself will log the specific mismatch reason
        if isDebugLoggingEnabled {
            debug("evaluateElementAgainstCriteria [D\(depth)]: attributesMatch returned false. No match.")
        }
        return .noMatch
    }

    // Role and attributes match. Now check for required action.
    if let requiredAction = actionToVerify, !requiredAction.isEmpty {
        if !element.isActionSupported(requiredAction) {
            if isDebugLoggingEnabled {
                debug("evaluateElementAgainstCriteria [D\(depth)]: Role & Attributes matched, but required action '\(requiredAction)' is MISSING.")
            }
            return .partialMatch_actionMissing
        }
        if isDebugLoggingEnabled {
            debug("evaluateElementAgainstCriteria [D\(depth)]: Role, Attributes, and Required Action '\(requiredAction)' all MATCH.")
        }
    } else {
        if isDebugLoggingEnabled {
            debug("evaluateElementAgainstCriteria [D\(depth)]: Role & Attributes matched. No action to verify or action already included in locator.criteria for attributesMatch.")
        }
    }
    
    return .fullMatch
}

@MainActor
public func search(element: Element,
            locator: Locator,
            requireAction: String?,
            depth: Int = 0,
            maxDepth: Int = DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: Bool) -> Element? {

    if isDebugLoggingEnabled {
        let criteriaDesc = locator.criteria.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let roleStr = element.role ?? "nil"
        let titleStr = element.title ?? "N/A"
        debug("search [D\(depth)]: Visiting. Role: \(roleStr), Title: \(titleStr). Locator Criteria: [\(criteriaDesc)], Action: \(requireAction ?? "none")")
    }

    if depth > maxDepth {
        if isDebugLoggingEnabled {
            debug("search [D\(depth)]: Max depth \(maxDepth) reached for element \(element.briefDescription()).")
        }
        return nil
    }

    let matchStatus = evaluateElementAgainstCriteria(element: element, 
                                                 locator: locator, 
                                                 actionToVerify: requireAction, 
                                                 depth: depth, 
                                                 isDebugLoggingEnabled: isDebugLoggingEnabled)

    if matchStatus == .fullMatch {
        if isDebugLoggingEnabled {
            debug("search [D\(depth)]: evaluateElementAgainstCriteria returned .fullMatch for \(element.briefDescription()). Returning element.")
        }
        return element
    }
    
    // If .noMatch or .partialMatch_actionMissing, we continue to search children.
    // evaluateElementAgainstCriteria already logs the reasons for these statuses if isDebugLoggingEnabled.
    if isDebugLoggingEnabled && matchStatus == .partialMatch_actionMissing {
        debug("search [D\(depth)]: Element \(element.briefDescription()) matched criteria but missed action '\(requireAction ?? "")'. Continuing child search.")
    }
    if isDebugLoggingEnabled && matchStatus == .noMatch {
        debug("search [D\(depth)]: Element \(element.briefDescription()) did not match criteria. Continuing child search.")
    }

    // Get children using the now comprehensive Element.children property
    let childrenToSearch: [Element] = element.children ?? []

    if !childrenToSearch.isEmpty {
      for childElement in childrenToSearch {
          if let found = search(element: childElement, locator: locator, requireAction: requireAction, depth: depth + 1, maxDepth: maxDepth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
              return found
          }
      }
    }
    return nil
}

@MainActor
public func collectAll(
    appElement: Element,
    locator: Locator,
    currentElement: Element,
    depth: Int,
    maxDepth: Int,
    maxElements: Int,
    currentPath: [Element],
    elementsBeingProcessed: inout Set<Element>,
    foundElements: inout [Element],
    isDebugLoggingEnabled: Bool
) {
    if elementsBeingProcessed.contains(currentElement) || currentPath.contains(currentElement) {
        if isDebugLoggingEnabled {
            debug("collectAll [D\(depth)]: Cycle detected or element \(currentElement.briefDescription()) already processed/in path.")
        }
        return
    }
    elementsBeingProcessed.insert(currentElement)

    if foundElements.count >= maxElements {
        if isDebugLoggingEnabled {
            debug("collectAll [D\(depth)]: Max elements limit of \(maxElements) reached before processing \(currentElement.briefDescription()).")
        }
        elementsBeingProcessed.remove(currentElement) // Important to remove before returning
        return
    }
    if depth > maxDepth {
        if isDebugLoggingEnabled {
            debug("collectAll [D\(depth)]: Max depth \(maxDepth) reached for \(currentElement.briefDescription()).")
        }
        elementsBeingProcessed.remove(currentElement) // Important to remove before returning
        return
    }

    if isDebugLoggingEnabled {
        let criteriaDesc = locator.criteria.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        debug("collectAll [D\(depth)]: Visiting \(currentElement.briefDescription()). Criteria: [\(criteriaDesc)], Action: \(locator.requireAction ?? "none")")
    }

    // Use locator.requireAction for actionToVerify in collectAll context
    let matchStatus = evaluateElementAgainstCriteria(element: currentElement, 
                                                 locator: locator, 
                                                 actionToVerify: locator.requireAction, 
                                                 depth: depth, 
                                                 isDebugLoggingEnabled: isDebugLoggingEnabled)

    if matchStatus == .fullMatch {
        if foundElements.count < maxElements {
            if !foundElements.contains(currentElement) { 
                 foundElements.append(currentElement)
                 if isDebugLoggingEnabled {
                     debug("collectAll [D\(depth)]: Added \(currentElement.briefDescription()). Hits: \(foundElements.count)/\(maxElements)")
                 }
            } else if isDebugLoggingEnabled {
                debug("collectAll [D\(depth)]: Element \(currentElement.briefDescription()) was a full match but already in foundElements.")
            }
        } else if isDebugLoggingEnabled {
            // This case is covered by the check at the beginning of the function, 
            // but as a safeguard if logic changes:
            debug("collectAll [D\(depth)]: Element \(currentElement.briefDescription()) was a full match but maxElements (\(maxElements)) already reached.")
        }
    }
    // evaluateElementAgainstCriteria handles logging for .noMatch or .partialMatch_actionMissing
    // We always try to explore children unless maxElements is hit.

    let childrenToExplore: [Element] = currentElement.children ?? []
    elementsBeingProcessed.remove(currentElement) // Remove before recursing on children

    let newPath = currentPath + [currentElement]
    for child in childrenToExplore {
        if foundElements.count >= maxElements { 
            if isDebugLoggingEnabled {
                debug("collectAll [D\(depth)]: Max elements (\(maxElements)) reached during child traversal of \(currentElement.briefDescription()). Stopping further exploration for this branch.")
            }
            break 
        }
        collectAll(
            appElement: appElement, 
            locator: locator,
            currentElement: child, 
            depth: depth + 1, 
            maxDepth: maxDepth, 
            maxElements: maxElements,
            currentPath: newPath, 
            elementsBeingProcessed: &elementsBeingProcessed, 
            foundElements: &foundElements,
            isDebugLoggingEnabled: isDebugLoggingEnabled
        )
    }
}

@MainActor
private func attributesMatch(element: Element, matchDetails: [String: String], depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
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
        if key == kAXEnabledAttribute || key == kAXFocusedAttribute || key == kAXHiddenAttribute || key == kAXElementBusyAttribute || key == "IsIgnored" {
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
private func matchStringAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
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
private func matchArrayAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
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
private func matchBooleanAttribute(element: Element, key: String, expectedValueString: String, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
    var currentBoolValue: Bool?
    switch key {
    case kAXEnabledAttribute: currentBoolValue = element.isEnabled
    case kAXFocusedAttribute: currentBoolValue = element.isFocused
    case kAXHiddenAttribute: currentBoolValue = element.isHidden
    case kAXElementBusyAttribute: currentBoolValue = element.isElementBusy
    case "IsIgnored": currentBoolValue = element.isIgnored // This is already a Bool
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
private func matchComputedNameAttributes(element: Element, computedNameEquals: String?, computedNameContains: String?, depth: Int, isDebugLoggingEnabled: Bool) -> Bool {
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