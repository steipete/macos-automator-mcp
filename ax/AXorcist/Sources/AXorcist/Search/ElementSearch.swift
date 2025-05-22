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
internal func evaluateElementAgainstCriteria(element: Element, locator: Locator, actionToVerify: String?, depth: Int, isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> ElementMatchStatus {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    
    var tempLogs: [String] = [] // For calls to Element methods that need their own log scope temporarily

    let currentElementRoleForLog: String? = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    let wantedRoleFromCriteria = locator.criteria[kAXRoleAttribute]
    var roleMatchesCriteria = false

    if let currentRole = currentElementRoleForLog, let roleToMatch = wantedRoleFromCriteria, !roleToMatch.isEmpty, roleToMatch != "*" {
        roleMatchesCriteria = (currentRole == roleToMatch)
    } else {
        roleMatchesCriteria = true // Wildcard/empty/nil role in criteria is a match
        let wantedRoleStr = wantedRoleFromCriteria ?? "any"
        let currentRoleStr = currentElementRoleForLog ?? "nil"
        dLog("evaluateElementAgainstCriteria [D\(depth)]: Wildcard/empty/nil role in criteria ('\(wantedRoleStr)') considered a match for element role \(currentRoleStr).")
    }

    if !roleMatchesCriteria {
        dLog("evaluateElementAgainstCriteria [D\(depth)]: Role mismatch. Element role: \(currentElementRoleForLog ?? "nil"), Expected: \(wantedRoleFromCriteria ?? "any"). No match.")
        return .noMatch
    }

    // Role matches, now check other attributes
    // attributesMatch will also need isDebugLoggingEnabled, currentDebugLogs
    if !attributesMatch(element: element, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
        // attributesMatch itself will log the specific mismatch reason
        dLog("evaluateElementAgainstCriteria [D\(depth)]: attributesMatch returned false. No match.")
        return .noMatch
    }

    // Role and attributes match. Now check for required action.
    if let requiredAction = actionToVerify, !requiredAction.isEmpty {
        if !element.isActionSupported(requiredAction, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
            dLog("evaluateElementAgainstCriteria [D\(depth)]: Role & Attributes matched, but required action '\(requiredAction)' is MISSING.")
            return .partialMatch_actionMissing
        }
        dLog("evaluateElementAgainstCriteria [D\(depth)]: Role, Attributes, and Required Action '\(requiredAction)' all MATCH.")
    } else {
        dLog("evaluateElementAgainstCriteria [D\(depth)]: Role & Attributes matched. No action to verify or action already included in locator.criteria for attributesMatch.")
    }
    
    return .fullMatch
}

@MainActor
public func search(element: Element,
            locator: Locator,
            requireAction: String?,
            depth: Int = 0,
            maxDepth: Int = DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: Bool,
            currentDebugLogs: inout [String]) -> Element? {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For calls to Element methods

    let criteriaDesc = locator.criteria.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    let roleStr = element.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "nil"
    let titleStr = element.title(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? "N/A"
    dLog("search [D\(depth)]: Visiting. Role: \(roleStr), Title: \(titleStr). Locator Criteria: [\(criteriaDesc)], Action: \(requireAction ?? "none")")

    if depth > maxDepth {
        let briefDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        dLog("search [D\(depth)]: Max depth \(maxDepth) reached for element \(briefDesc).")
        return nil
    }

    let matchStatus = evaluateElementAgainstCriteria(element: element, 
                                                 locator: locator, 
                                                 actionToVerify: requireAction, 
                                                 depth: depth, 
                                                 isDebugLoggingEnabled: isDebugLoggingEnabled, 
                                                 currentDebugLogs: &currentDebugLogs) // Pass through logs

    if matchStatus == .fullMatch {
        let briefDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        dLog("search [D\(depth)]: evaluateElementAgainstCriteria returned .fullMatch for \(briefDesc). Returning element.")
        return element
    }
    
    let briefDesc = element.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
    if matchStatus == .partialMatch_actionMissing {
        dLog("search [D\(depth)]: Element \(briefDesc) matched criteria but missed action '\(requireAction ?? "")'. Continuing child search.")
    }
    if matchStatus == .noMatch {
        dLog("search [D\(depth)]: Element \(briefDesc) did not match criteria. Continuing child search.")
    }

    let childrenToSearch: [Element] = element.children(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? []

    if !childrenToSearch.isEmpty {
      for childElement in childrenToSearch {
          if let found = search(element: childElement, locator: locator, requireAction: requireAction, depth: depth + 1, maxDepth: maxDepth, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs) {
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
    isDebugLoggingEnabled: Bool,
    currentDebugLogs: inout [String] // Added logging parameter
) {
    func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
    var tempLogs: [String] = [] // For calls to Element methods

    let briefDescCurrent = currentElement.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)

    if elementsBeingProcessed.contains(currentElement) || currentPath.contains(currentElement) {
        dLog("collectAll [D\(depth)]: Cycle detected or element \(briefDescCurrent) already processed/in path.")
        return
    }
    elementsBeingProcessed.insert(currentElement)

    if foundElements.count >= maxElements {
        dLog("collectAll [D\(depth)]: Max elements limit of \(maxElements) reached before processing \(briefDescCurrent).")
        elementsBeingProcessed.remove(currentElement)
        return
    }
    if depth > maxDepth {
        dLog("collectAll [D\(depth)]: Max depth \(maxDepth) reached for \(briefDescCurrent).")
        elementsBeingProcessed.remove(currentElement)
        return
    }

    let criteriaDesc = locator.criteria.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    dLog("collectAll [D\(depth)]: Visiting \(briefDescCurrent). Criteria: [\(criteriaDesc)], Action: \(locator.requireAction ?? "none")")

    let matchStatus = evaluateElementAgainstCriteria(element: currentElement, 
                                                 locator: locator, 
                                                 actionToVerify: locator.requireAction, 
                                                 depth: depth, 
                                                 isDebugLoggingEnabled: isDebugLoggingEnabled, 
                                                 currentDebugLogs: &currentDebugLogs) // Pass through logs

    if matchStatus == .fullMatch {
        if foundElements.count < maxElements {
            if !foundElements.contains(currentElement) { 
                 foundElements.append(currentElement)
                 dLog("collectAll [D\(depth)]: Added \(briefDescCurrent). Hits: \(foundElements.count)/\(maxElements)")
            } else {
                dLog("collectAll [D\(depth)]: Element \(briefDescCurrent) was a full match but already in foundElements.")
            }
        } else {
            dLog("collectAll [D\(depth)]: Element \(briefDescCurrent) was a full match but maxElements (\(maxElements)) already reached.")
        }
    }

    let childrenToExplore: [Element] = currentElement.children(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) ?? []
    elementsBeingProcessed.remove(currentElement)

    let newPath = currentPath + [currentElement]
    for child in childrenToExplore {
        if foundElements.count >= maxElements { 
            dLog("collectAll [D\(depth)]: Max elements (\(maxElements)) reached during child traversal of \(briefDescCurrent). Stopping further exploration for this branch.")
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
            isDebugLoggingEnabled: isDebugLoggingEnabled,
            currentDebugLogs: &currentDebugLogs // Pass through logs
        )
    }
}