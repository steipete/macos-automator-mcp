// AXSearch.swift - Contains search and element collection logic

import Foundation
import ApplicationServices

// Variable DEBUG_LOGGING_ENABLED is expected to be globally available from AXLogging.swift

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

@MainActor 
public func search(element: AXUIElement,
            locator: Locator,
            requireAction: String?,
            depth: Int = 0,
            maxDepth: Int = DEFAULT_MAX_DEPTH_SEARCH,
            isDebugLoggingEnabled: Bool) -> AXUIElement? {

    let currentElementRoleForLog: String? = axValue(of: element, attr: kAXRoleAttribute)
    let currentElementTitle: String? = axValue(of: element, attr: kAXTitleAttribute)
    
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
        if attributesMatch(element: element, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
            if isDebugLoggingEnabled {
                let roleStr = currentElementRoleForLog ?? "nil"
                let message = "search [D\(depth)]: Element Role & All Attributes MATCHED criteria. Role: \(roleStr)."
                debug(message)
            }
            if let requiredActionStr = requireAction, !requiredActionStr.isEmpty {
                if elementSupportsAction(element, action: requiredActionStr) {
                    if isDebugLoggingEnabled {
                        let message = "search [D\(depth)]: Required action '\(requiredActionStr)' IS present. Element is a full match."
                        debug(message)
                    }
                    return element
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
                return element 
            }
        }
    }

    var childrenToSearch: [AXUIElement] = []
    var uniqueChildrenSet = Set<AXUIElementHashableWrapper>()

    if let directChildren: [AXUIElement] = axValue(of: element, attr: kAXChildrenAttribute) {
        for child in directChildren {
            let wrapper = AXUIElementHashableWrapper(element: child)
            if !uniqueChildrenSet.contains(wrapper) {
                childrenToSearch.append(child); uniqueChildrenSet.insert(wrapper)
            }
        }
    }

    let webContainerRoles: [String] = [kAXWebAreaRole, "AXWebView", "BrowserAccessibilityCocoa", kAXScrollAreaRole, kAXGroupRole, kAXWindowRole, "AXSplitGroup", "AXLayoutArea"]
    if let currentRole = currentElementRoleForLog, webContainerRoles.contains(currentRole) {
        let webAttributesList: [String] = [
            kAXVisibleChildrenAttribute, kAXTabsAttribute, "AXWebAreaChildren", "AXHTMLContent", 
            "AXARIADOMChildren", "AXDOMChildren", "AXApplicationNavigation", 
            "AXApplicationElements", "AXContents", "AXBodyArea", "AXDocumentContent", 
            "AXWebPageContent", "AXAttributedString", "AXSplitGroupContents",
            "AXLayoutAreaChildren", "AXGroupChildren", kAXSelectedChildrenAttribute, 
            kAXRowsAttribute, kAXColumnsAttribute 
        ]
        for attrName in webAttributesList {
            if let webChildren: [AXUIElement] = axValue(of: element, attr: attrName) {
                for child in webChildren {
                    let wrapper = AXUIElementHashableWrapper(element: child)
                    if !uniqueChildrenSet.contains(wrapper) {
                        childrenToSearch.append(child); uniqueChildrenSet.insert(wrapper)
                    }
                }
            }
        }
    }
    
    if currentElementRoleForLog == kAXApplicationRole { 
        if let windowChildren: [AXUIElement] = axValue(of: element, attr: kAXWindowsAttribute) {
            for child in windowChildren {
                let wrapper = AXUIElementHashableWrapper(element: child)
                if !uniqueChildrenSet.contains(wrapper) {
                    childrenToSearch.append(child); uniqueChildrenSet.insert(wrapper)
                }
            }
        }
    }

    if !childrenToSearch.isEmpty {
      for child in childrenToSearch {
          if let found = search(element: child, locator: locator, requireAction: requireAction, depth: depth + 1, maxDepth: maxDepth, isDebugLoggingEnabled: isDebugLoggingEnabled) {
              return found
          }
      }
    }
    return nil
}

@MainActor
public func collectAll(
    appElement: AXUIElement, 
    locator: Locator,
    currentElement: AXUIElement, 
    depth: Int,
    maxDepth: Int,
    maxElements: Int,
    currentPath: [AXUIElementHashableWrapper],
    elementsBeingProcessed: inout Set<AXUIElementHashableWrapper>,
    foundElements: inout [AXUIElement],
    isDebugLoggingEnabled: Bool
) {
    let elementWrapper = AXUIElementHashableWrapper(element: currentElement)
    if elementsBeingProcessed.contains(elementWrapper) || currentPath.contains(elementWrapper) {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Cycle detected or element already processed for \(currentElement)."
            debug(message)
        }
        return
    }
    elementsBeingProcessed.insert(elementWrapper)

    if foundElements.count >= maxElements {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Max elements limit of \(maxElements) reached."
            debug(message)
        }
        elementsBeingProcessed.remove(elementWrapper)
        return
    }
    if depth > maxDepth {
        if isDebugLoggingEnabled {
            let message = "collectAll [D\(depth)]: Max depth \(maxDepth) reached."
            debug(message)
        }
        elementsBeingProcessed.remove(elementWrapper)
        return
    }

    let elementRoleForLog: String? = axValue(of: currentElement, attr: kAXRoleAttribute)
    
    let wantedRoleFromCriteria = locator.criteria[kAXRoleAttribute as String] ?? locator.criteria["AXRole"]
    var roleMatchesCriteria = false
    if let currentRole = elementRoleForLog, let roleToMatch = wantedRoleFromCriteria, !roleToMatch.isEmpty, roleToMatch != "*" {
        roleMatchesCriteria = (currentRole == roleToMatch)
    } else {
        roleMatchesCriteria = true
    }
    
    if roleMatchesCriteria {
        var finalMatch = attributesMatch(element: currentElement, matchDetails: locator.criteria, depth: depth, isDebugLoggingEnabled: isDebugLoggingEnabled)
        
        if finalMatch, let requiredAction = locator.requireAction, !requiredAction.isEmpty {
            if !elementSupportsAction(currentElement, action: requiredAction) {
                 if isDebugLoggingEnabled {
                    let roleStr = elementRoleForLog ?? "nil"
                    let message = "collectAll [D\(depth)]: Action '\(requiredAction)' not supported by element with role '\(roleStr)'."
                    debug(message)
                 }
                 finalMatch = false
            }
        }
        
        if finalMatch {
            if !foundElements.contains(where: { $0 === currentElement }) { 
                 foundElements.append(currentElement)
                 if isDebugLoggingEnabled {
                     let pathHintStr: String = axValue(of: currentElement, attr: "AXPathHint") ?? "nil"
                     let titleStr: String = axValue(of: currentElement, attr: kAXTitleAttribute) ?? "nil"
                     let idStr: String = axValue(of: currentElement, attr: kAXIdentifierAttribute) ?? "nil"
                     let roleStr = elementRoleForLog ?? "nil"
                     let message = "collectAll [CD1 D\(depth)]: Added. Role:'\(roleStr)', Title:'\(titleStr)', ID:'\(idStr)', Path:'\(pathHintStr)'. Hits:\(foundElements.count)"
                     debug(message)
                 }
            }
        }
    }

    if depth < maxDepth && foundElements.count < maxElements {
        var childrenToSearch: [AXUIElement] = []
        var uniqueChildrenForThisLevel = Set<AXUIElementHashableWrapper>()

        if let directChildren: [AXUIElement] = axValue(of: currentElement, attr: kAXChildrenAttribute) {
            for child in directChildren {
                let wrapper = AXUIElementHashableWrapper(element: child)
                if !uniqueChildrenForThisLevel.contains(wrapper) {
                    childrenToSearch.append(child); uniqueChildrenForThisLevel.insert(wrapper)
                }
            }
        }

        let webContainerRolesCF: [String] = [kAXWebAreaRole, "AXWebView", "BrowserAccessibilityCocoa", kAXScrollAreaRole, kAXGroupRole, kAXWindowRole, "AXSplitGroup", "AXLayoutArea"]
        if let currentRoleCF = elementRoleForLog, webContainerRolesCF.contains(currentRoleCF) {
            let webAttributesList: [String] = [
                kAXVisibleChildrenAttribute, kAXTabsAttribute, "AXWebAreaChildren", "AXHTMLContent", 
                "AXARIADOMChildren", "AXDOMChildren", "AXApplicationNavigation", 
                "AXApplicationElements", "AXContents", "AXBodyArea", "AXDocumentContent", 
                "AXWebPageContent", "AXAttributedString", "AXSplitGroupContents",
                "AXLayoutAreaChildren", "AXGroupChildren", kAXSelectedChildrenAttribute, 
                kAXRowsAttribute, kAXColumnsAttribute
            ]
            for attrName in webAttributesList {
                if let webChildren: [AXUIElement] = axValue(of: currentElement, attr: attrName) {
                    for child in webChildren {
                        let wrapper = AXUIElementHashableWrapper(element: child)
                        if !uniqueChildrenForThisLevel.contains(wrapper) {
                            childrenToSearch.append(child); uniqueChildrenForThisLevel.insert(wrapper)
                        }
                    }
                }
            }
        }
        
        if elementRoleForLog == kAXApplicationRole { 
            if let windowChildren: [AXUIElement] = axValue(of: currentElement, attr: kAXWindowsAttribute) {
                for child in windowChildren {
                    let wrapper = AXUIElementHashableWrapper(element: child)
                    if !uniqueChildrenForThisLevel.contains(wrapper) {
                        childrenToSearch.append(child); uniqueChildrenForThisLevel.insert(wrapper)
                    }
                }
            }
        }
        
        let newPath = currentPath + [elementWrapper]

        if !childrenToSearch.isEmpty {
            for child in childrenToSearch {
                if foundElements.count >= maxElements { break } 
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
    }
    elementsBeingProcessed.remove(elementWrapper)
}

// End of AXSearch.swift for now 