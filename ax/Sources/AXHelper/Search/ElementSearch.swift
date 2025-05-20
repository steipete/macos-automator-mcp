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