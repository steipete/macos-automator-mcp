// AXSearch.swift - Contains search and element collection logic

import Foundation
import ApplicationServices

@MainActor // Or remove if not needed and called from non-main actor contexts safely
public func decodeExpectedArray(fromString: String) -> [String]? {
    let trimmedString = fromString.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedString.hasPrefix("[") && trimmedString.hasSuffix("]") {
        let innerString = String(trimmedString.dropFirst().dropLast())
        if innerString.isEmpty { return [] }
        return innerString.split(separator: ",").map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r\"'"))
        }
    } else {
        return trimmedString.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
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

// search function with advanced attribute matching and retry logic
@MainActor 
public func search(element: AXUIElement,
            locator: Locator,
            requireAction: String?,
            depth: Int = 0,
            maxDepth: Int = 20) -> AXUIElement? {

    let currentElementRoleForLog: String? = axValue(of: element, attr: kAXRoleAttribute)
    let currentElementTitle: String? = axValue(of: element, attr: kAXTitleAttribute)

    debug("search [D\(depth)]: Visiting. Role: \(currentElementRoleForLog ?? "nil"), Title: \(currentElementTitle ?? "N/A"). Locator: Role='\(locator.role ?? "any")', Match=\(locator.match ?? [:])")

    if depth > maxDepth {
        debug("search [D\(depth)]: Max depth \(maxDepth) reached for element \(currentElementRoleForLog ?? "nil").")
        return nil
    }

    var roleMatches = false
    if let currentRole = currentElementRoleForLog, let wantedRole = locator.role, !wantedRole.isEmpty, wantedRole != "*" {
        roleMatches = (currentRole == wantedRole)
    } else {
        roleMatches = true // Wildcard role "*", empty role, or nil role in locator means role check passes
        debug("search [D\(depth)]: Wildcard/empty/nil role ('\(locator.role ?? "any")') considered a match for element role \(currentElementRoleForLog ?? "nil").")
    }
    
    if roleMatches {
        // Role matches (or is wildcard/not specified), now check attributes using the new function.
        if attributesMatch(element: element, locator: locator, depth: depth) {
            debug("search [D\(depth)]: Element Role & All Attributes MATCHED. Role: \(currentElementRoleForLog ?? "nil").")
            if let requiredActionStr = requireAction, !requiredActionStr.isEmpty {
                if elementSupportsAction(element, action: requiredActionStr) {
                    debug("search [D\(depth)]: Required action '\(requiredActionStr)' IS present. Element is a full match.")
                    return element
                } else {
                    debug("search [D\(depth)]: Element matched role/attrs, but required action '\(requiredActionStr)' is MISSING. Continuing child search.")
                    // Don't return; continue search in children as this specific element is not a full match if action is required but missing.
                }
            } else {
                debug("search [D\(depth)]: No requireAction specified. Element is a match based on role/attributes.")
                return element // No requireAction, and role/attributes matched.
            }
        }
    } // End of if roleMatches

    // If role didn't match, or if role matched but attributes/action didn't, search children.
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

    let webContainerRoles = ["AXWebArea", "AXWebView", "BrowserAccessibilityCocoa", "AXScrollArea", "AXGroup", "AXWindow", "AXSplitGroup", "AXLayoutArea"]
    if let currentRole = currentElementRoleForLog, currentRole != "nil", webContainerRoles.contains(currentRole) {
        let webAttributesList = [
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
    
    if (currentElementRoleForLog ?? "nil") == "AXApplication" { 
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
      // debug("search [D\(depth)]: Total \(childrenToSearch.count) unique children to recurse into for \(currentElementRoleForLog ?? "nil").")
      for child in childrenToSearch {
          if let found = search(element: child, locator: locator, requireAction: requireAction, depth: depth + 1, maxDepth: maxDepth) {
              return found
          }
      }
    }
    return nil
}

// Original simple collectAll function from main.swift
@MainActor
public func collectAll(element: AXUIElement,
                locator: Locator,
                requireAction: String?,
                hits: inout [AXUIElement],
                depth: Int = 0,
                maxDepth: Int = 200) {

    if hits.count > MAX_COLLECT_ALL_HITS {
        debug("collectAll [D\(depth)]: Safety limit of \(MAX_COLLECT_ALL_HITS) reached.")
        return
    }
    if depth > maxDepth { 
        debug("collectAll [D\(depth)]: Max depth \(maxDepth) reached.")
        return 
    }

    // Safely unwrap locator.role for isEmpty check, default to true if nil (empty string behavior)
    let roleIsEmpty = locator.role?.isEmpty ?? true
    let wildcardRole = locator.role == "*" || roleIsEmpty
    let elementRole: String? = axValue(of: element, attr: kAXRoleAttribute)
    let roleMatches = wildcardRole || elementRole == locator.role
    
    if roleMatches {
        // Use the attributesMatch helper function - corrected call
        let currentAttributesMatch = attributesMatch(element: element, locator: locator, depth: depth)
        var 최종결정Ok = currentAttributesMatch // Renamed 'ok' to avoid conflict
        
        if 최종결정Ok, let required = requireAction, !required.isEmpty {
            if !elementSupportsAction(element, action: required) { 
                 debug("collectAll [D\(depth)]: Action '\(required)' not supported by element with role '\(elementRole ?? "nil")'.")
                 최종결정Ok = false
            }
        }
        
        if 최종결정Ok { 
            if !hits.contains(where: { $0 === element }) { 
                 hits.append(element) 
                 debug("collectAll [D\(depth)]: Element added. Role: '\(elementRole ?? "nil")'. Total hits: \(hits.count)")
            }
        }
    }

    // Child traversal logic (can be kept similar to the search function's child traversal)
    if depth < maxDepth {
        var childrenToSearch: [AXUIElement] = []
        var uniqueChildrenSet = Set<AXUIElementHashableWrapper>() // Use AXUIElementHashableWrapper for deduplication

        if let directChildren: [AXUIElement] = axValue(of: element, attr: kAXChildrenAttribute) {
            for child in directChildren {
                let wrapper = AXUIElementHashableWrapper(element: child)
                if !uniqueChildrenSet.contains(wrapper) {
                    childrenToSearch.append(child); uniqueChildrenSet.insert(wrapper)
                }
            }
        }

        let webContainerRoles = ["AXWebArea", "AXWebView", "BrowserAccessibilityCocoa", "AXScrollArea", "AXGroup", "AXWindow", "AXSplitGroup", "AXLayoutArea"]
        if let currentRoleString = elementRole, webContainerRoles.contains(currentRoleString) {
            let webAttributesList = [
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
        
        if elementRole == "AXApplication" { 
            if let windowChildren: [AXUIElement] = axValue(of: element, attr: kAXWindowsAttribute) {
                for child in windowChildren {
                    let wrapper = AXUIElementHashableWrapper(element: child)
                    if !uniqueChildrenSet.contains(wrapper) {
                        childrenToSearch.append(child); uniqueChildrenSet.insert(wrapper)
                    }
                }
            }
        }
        
        for child in childrenToSearch {
            if hits.count > MAX_COLLECT_ALL_HITS { break }
            collectAll(element: child, locator: locator, requireAction: requireAction,
                       hits: &hits, depth: depth + 1, maxDepth: maxDepth)
        }
    }
}

// Advanced attributesMatch function (from earlier discussions, adapted)
@MainActor
public func attributesMatch(element: AXUIElement, locator: Locator, depth: Int) -> Bool {
    // Extracted and adapted from the search function's attribute matching logic
    // Safely unwrap locator.match, default to empty dictionary if nil
    guard let matchDict = locator.match, !matchDict.isEmpty else {
        debug("attributesMatch [D\(depth)]: No attributes in locator.match to check or locator.match is nil. Defaulting to true.")
        return true // No attributes to match means it's a match by this criteria
    }

    for (attrKey, wantValueStr) in matchDict { // Iterate over the unwrapped matchDict
        var currentSpecificAttributeMatch = false
        
        // 1. Boolean Matching
        if wantValueStr.lowercased() == "true" || wantValueStr.lowercased() == "false" {
            let wantBool = wantValueStr.lowercased() == "true"
            if let gotBool: Bool = axValue(of: element, attr: attrKey) {
                currentSpecificAttributeMatch = (gotBool == wantBool)
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Bool). Want: \(wantBool), Got: \(gotBool). Match: \(currentSpecificAttributeMatch)")
            } else {
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Bool). Want: \(wantBool), Got: nil/non-bool.")
                currentSpecificAttributeMatch = false
            }
        }
        // 2. Array Matching (with Retry)
        else if let expectedArr = decodeExpectedArray(fromString: wantValueStr) {
            var actualArr: [String]? = nil
            let maxRetries = 3
            let retryDelayUseconds: UInt32 = 50000 // 50ms

            for attempt in 0..<maxRetries {
                actualArr = axValue(of: element, attr: attrKey)
                if let currentActualArr = actualArr {
                    if attrKey == kAXDOMClassListAttribute && currentActualArr.isEmpty {
                        if attempt < maxRetries - 1 {
                            debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (AXDOMClassList) empty attempt \(attempt + 1). Retrying...")
                            usleep(retryDelayUseconds)
                            continue 
                        } else {
                            debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (AXDOMClassList) remained empty after \(maxRetries) attempts.")
                            break 
                        }
                    }
                    break // Found non-nil (and for AXDOMClassList, non-empty or last attempt)
                } else { // actualArr is nil
                    if attempt < maxRetries - 1 {
                        debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' nil attempt \(attempt + 1). Retrying...")
                        usleep(retryDelayUseconds)
                    } else {
                        debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' remained nil after \(maxRetries) attempts.")
                        break 
                    }
                }
            }
            
            if let finalActualArr = actualArr { 
                if attrKey == kAXDOMClassListAttribute { // Special handling for AXDOMClassList (subset match)
                    currentSpecificAttributeMatch = Set(expectedArr).isSubset(of: Set(finalActualArr))
                    debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Array Subset). Want: \(expectedArr), Got: \(finalActualArr). Match: \(currentSpecificAttributeMatch)")
                } else { // Exact match for other arrays
                    currentSpecificAttributeMatch = (Set(expectedArr) == Set(finalActualArr) && expectedArr.count == finalActualArr.count)
                    debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Array Exact). Want: \(expectedArr), Got: \(finalActualArr). Match: \(currentSpecificAttributeMatch)")
                }
            } else {
                currentSpecificAttributeMatch = false
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Array). Wanted: \(expectedArr), Got: nil/empty after retries.")
            }
        }
        // 3. Numeric Matching
        else if let wantInt = Int(wantValueStr) {
            if let gotInt: Int = axValue(of: element, attr: attrKey) {
                currentSpecificAttributeMatch = (gotInt == wantInt)
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Numeric). Want: \(wantInt), Got: \(gotInt). Match: \(currentSpecificAttributeMatch)")
            } else {
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (Numeric). Wanted: \(wantInt), Got: nil/non-integer.")
                currentSpecificAttributeMatch = false
            }
        }
        // 4. String Matching (Fallback)
        else {
            if let gotString: String = axValue(of: element, attr: attrKey) {
                currentSpecificAttributeMatch = (gotString == wantValueStr)
                debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (String). Wanted: \(wantValueStr), Got: \(gotString). Match: \(currentSpecificAttributeMatch)")
            } else {
                // If wantValueStr is empty and gotString is nil, consider it a match for empty string criteria.
                if wantValueStr.isEmpty && axValue(of: element, attr: attrKey) == (nil as String?) {
                    currentSpecificAttributeMatch = true
                    debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (String). Wanted empty string, Got nil. Match: true (special case)")
                } else {
                    debug("attributesMatch [D\(depth)]: Attr '\(attrKey)' (String). Wanted: \(wantValueStr), Got: nil/non-string.")
                    currentSpecificAttributeMatch = false
                }
            }
        }
        
        if !currentSpecificAttributeMatch {
            debug("attributesMatch [D\(depth)]: Attribute '\(attrKey)' MISMATCH. Halting attribute checks for this element.")
            return false // A single mismatch means the element doesn't match the locator's attributes
        }
    } // End of attribute matching loop
    
    debug("attributesMatch [D\(depth)]: All attributes in locator.match successfully matched.")
    return true // All attributes in locator.match were checked and matched
}

// End of AXSearch.swift for now 