// AXSearch.swift - Contains search and element collection logic

import Foundation
import ApplicationServices

// Variable DEBUG_LOGGING_ENABLED is expected to be globally available from AXLogging.swift
// AXElement is now the primary type for UI elements.

@MainActor
public func decodeExpectedArray(fromString: String) -> [String]? {
    let trimmedString = fromString.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]") {
        if let jsonData = trimmedString.data(using: .utf8) {
            do {
                if let array = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String] {
                    return array
                } else if let anyArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [Any] {
                    return anyArray.compactMap { String(describing: $0) }
                }
            } catch {
                debug("JSON decoding failed for string: \(trimmedString). Error: \(error.localizedDescription)")
            }
        }
    }
    let strippedBrackets = trimmedString.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    if strippedBrackets.isEmpty { return [] }
    return strippedBrackets.components(separatedBy: ",")
                           .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                           .filter { !$0.isEmpty }
}

// AXUIElementHashableWrapper is no longer needed.
/*
public struct AXUIElementHashableWrapper: Hashable {
    public let element: AXUIElement
    private let identifier: ObjectIdentifier
    public init(element: AXUIElement) {
        self.element = element
        self.identifier = ObjectIdentifier(element)
    }
    public static func == (lhs: AXUIElementHashableWrapper, rhs: AXUIElementHashableWrapper) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
*/

@MainActor 
public func search(axElement: AXElement,
            locator: Locator,
            requireAction: String?,
            depth: Int = 0,
            maxDepth: Int = DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: Bool) -> AXElement? {

    let currentElementRoleForLog: String? = axElement.role
    let currentElementTitle: String? = axElement.title
    
    if isDebugLoggingEnabled {
        let criteriaDesc = locator.criteria.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        let roleStr = currentElementRoleForLog ?? "nil"
        let titleStr = currentElementTitle ?? "N/A"
        let message = "search [D\(depth)]: Visiting. Role: \(roleStr), Title: \(titleStr). Locator Criteria: [\(criteriaDesc)]"
        debug(message)
    }

    if depth > maxDepth {
        if isDebugLoggingEnabled {
            let roleStr = currentElementRoleForLog ?? "nil"
            let message = "search [D\(depth)]: Max depth \(maxDepth) reached for element \(roleStr)."
            debug(message)
        }
        return nil
    }

    let wantedRoleFromCriteria = locator.criteria[kAXRoleAttribute as String] ?? locator.criteria["AXRole"]
    var roleMatchesCriteria = false
    if let currentRole = currentElementRoleForLog, let roleToMatch = wantedRoleFromCriteria, !roleToMatch.isEmpty, roleToMatch != "*" {
        roleMatchesCriteria = (currentRole == roleToMatch)
    } else {
        roleMatchesCriteria = true
        if isDebugLoggingEnabled {
            let wantedRoleStr = wantedRoleFromCriteria ?? "any"
            let currentRoleStr = currentElementRoleForLog ?? "nil"
            let message = "search [D\(depth)]: Wildcard/empty/nil role in criteria ('\(wantedRoleStr)') considered a match for element role \(currentRoleStr)."
            debug(message)
        }
    }
    
    if roleMatchesCriteria {
        if attributesMatch(axElement: axElement, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
            if isDebugLoggingEnabled {
                let roleStr = currentElementRoleForLog ?? "nil"
                let message = "search [D\(depth)]: Element Role & All Attributes MATCHED criteria. Role: \(roleStr)."
                debug(message)
            }
            if let requiredActionStr = requireAction, !requiredActionStr.isEmpty {
                if axElement.isActionSupported(requiredActionStr) {
                    if isDebugLoggingEnabled {
                        let message = "search [D\(depth)]: Required action '\(requiredActionStr)' IS present. Element is a full match."
                        debug(message)
                    }
                    return axElement
                } else {
                    if isDebugLoggingEnabled {
                        let message = "search [D\(depth)]: Element matched criteria, but required action '\(requiredActionStr)' is MISSING. Continuing child search."
                        debug(message)
                    }
                }
            } else {
                if isDebugLoggingEnabled {
                    let message = "search [D\(depth)]: No requireAction specified. Element is a match based on criteria."
                    debug(message)
                }
                return axElement 
            }
        }
    }

    // Get children using the now comprehensive AXElement.children property
    var childrenToSearch: [AXElement] = axElement.children ?? []
    // No need for uniqueChildrenSet here if axElement.children already handles deduplication,
    // but if axElement.children can return duplicates from different sources, keep it.
    // AXElement.children as implemented now *does* deduplicate.

    // The extensive alternative children logic and application role/windows check 
    // has been moved into AXElement.children getter.

    if !childrenToSearch.isEmpty {
      for childAXElement in childrenToSearch {
          if let found = search(axElement: childAXElement, locator: locator, requireAction: requireAction, depth: depth + 1, maxDepth: maxDepth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
              return found
          }
      }
    }
    return nil
}

@MainActor
public func collectAll(
    appAXElement: AXElement,
    locator: Locator,
    currentAXElement: AXElement,
    depth: Int,
    maxDepth: Int,
    maxElements: Int,
    currentPath: [AXElement],
    elementsBeingProcessed: inout Set<AXElement>,
    foundElements: inout [AXElement],
    isDebugLoggingEnabled: Bool
) {
    if elementsBeingProcessed.contains(currentAXElement) || currentPath.contains(currentAXElement) {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Cycle detected or element already processed for \(currentAXElement.underlyingElement)." 
            debug(message)
        }
        return
    }
    elementsBeingProcessed.insert(currentAXElement)

    if foundElements.count >= maxElements {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Max elements limit of \(maxElements) reached."
            debug(message)
        }
        elementsBeingProcessed.remove(currentAXElement)
        return
    }
    if depth > maxDepth {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Max depth \(maxDepth) reached."
            debug(message)
        }
        elementsBeingProcessed.remove(currentAXElement)
        return
    }

    let elementRoleForLog: String? = currentAXElement.role
    
    let wantedRoleFromCriteria = locator.criteria[kAXRoleAttribute as String] ?? locator.criteria["AXRole"]
    var roleMatchesCriteria = false
    if let currentRole = elementRoleForLog, let roleToMatch = wantedRoleFromCriteria, !roleToMatch.isEmpty, roleToMatch != "*" {
        roleMatchesCriteria = (currentRole == roleToMatch)
    } else {
        roleMatchesCriteria = true
    }
    
    if roleMatchesCriteria {
        var finalMatch = attributesMatch(axElement: currentAXElement, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled)
        
        if finalMatch, let requiredAction = locator.requireAction, !requiredAction.isEmpty {
            if !currentAXElement.isActionSupported(requiredAction) {
                 if isDebugLoggingEnabled {
                    let roleStr = elementRoleForLog ?? "nil"
                    let message = "collectAll [D\(depth)]: Action '\(requiredAction)' not supported by element with role '\(roleStr)'."
                    debug(message)
                 }
                 finalMatch = false
            }
        }
        
        if finalMatch {
            if !foundElements.contains(currentAXElement) { 
                 foundElements.append(currentAXElement)
                 if isDebugLoggingEnabled {
                     let pathHintStr: String = currentAXElement.attribute(kAXPathHintAttribute) ?? "nil"
                     let titleStr: String = currentAXElement.title ?? "nil"
                     let idStr: String = currentAXElement.attribute(kAXIdentifierAttribute) ?? "nil"
                     let roleStr = elementRoleForLog ?? "nil"
                     let message = "collectAll [CD1 D\(depth)]: Added. Role:'\(roleStr)', Title:'\(titleStr)', ID:'\(idStr)', Path:'\(pathHintStr)'. Hits:\(foundElements.count)"
                     debug(message)
                 }
            }
        }
    }

    // Get children using the now comprehensive AXElement.children property
    var childrenToExplore: [AXElement] = currentAXElement.children ?? []
    // AXElement.children as implemented now *does* deduplicate.

    // The extensive alternative children logic and application role/windows check
    // has been moved into AXElement.children getter.

    elementsBeingProcessed.remove(currentAXElement)

    let newPath = currentPath + [currentAXElement]
    for child in childrenToExplore {
        if foundElements.count >= maxElements { break }
        collectAll(
            appAXElement: appAXElement, 
            locator: locator,
            currentAXElement: child, 
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

// End of AXSearch.swift for now 