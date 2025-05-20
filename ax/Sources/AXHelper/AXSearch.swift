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
            requireAction: String?, // Added requireAction back, was in original plan
            depth: Int = 0,
            maxDepth: Int = 20) -> AXUIElement? { // Default maxDepth to 20 as per more recent versions

    let currentElementRoleForLog: String? = axValue(of: element, attr: kAXRoleAttribute)
    let currentElementTitle: String? = axValue(of: element, attr: kAXTitleAttribute)

    debug("search [D\(depth)]: Visiting. Role: \(currentElementRoleForLog ?? "nil"), Title: \(currentElementTitle ?? "N/A"). Locator: Role='\(locator.role)', Match=\(locator.match)")

    if depth > maxDepth {
        debug("search [D\(depth)]: Max depth \(maxDepth) reached for element \(currentElementRoleForLog ?? "nil").")
        return nil
    }

    var roleMatches = false
    if let currentRole = currentElementRoleForLog, currentRole == locator.role {
        roleMatches = true
    } else if locator.role == "*" || locator.role.isEmpty {
        roleMatches = true
        debug("search [D\(depth)]: Wildcard role ('\(locator.role)') considered a match for element role \(currentElementRoleForLog ?? "nil").")
    }
    
    if !roleMatches {
        // If role itself doesn't match (and not wildcard), then this element isn't a candidate.
        // Still need to search children.
        // debug("search [D\(depth)]: Role MISMATCH. Wanted: '\(locator.role)', Got: '\(currentElementRoleForLog ?? "nil")'.")
    } else {
        // Role matches (or is wildcard), now check attributes.
        var allLocatorAttributesMatch = true // Assume true, set to false on first mismatch
        if !locator.match.isEmpty {
            for (attrKey, wantValueStr) in locator.match {
                var currentSpecificAttributeMatch = false
                
                // 1. Boolean Matching
                if wantValueStr.lowercased() == "true" || wantValueStr.lowercased() == "false" {
                    let wantBool = wantValueStr.lowercased() == "true"
                    if let gotBool: Bool = axValue(of: element, attr: attrKey) {
                        currentSpecificAttributeMatch = (gotBool == wantBool)
                        debug("search [D\(depth)]: Attr '\(attrKey)' (Bool). Want: \(wantBool), Got: \(gotBool). Match: \(currentSpecificAttributeMatch)")
                    } else {
                        debug("search [D\(depth)]: Attr '\(attrKey)' (Bool). Want: \(wantBool), Got: nil/non-bool.")
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
                            if attrKey == "AXDOMClassList" && currentActualArr.isEmpty {
                                if attempt < maxRetries - 1 {
                                    debug("search [D\(depth)]: Attr '\(attrKey)' (AXDOMClassList) empty attempt \(attempt + 1). Retrying...")
                                    usleep(retryDelayUseconds)
                                    continue 
                                } else {
                                    debug("search [D\(depth)]: Attr '\(attrKey)' (AXDOMClassList) remained empty after \(maxRetries) attempts.")
                                    break 
                                }
                            }
                            break // Found non-nil (and for AXDOMClassList, non-empty or last attempt)
                        } else { // actualArr is nil
                            if attempt < maxRetries - 1 {
                                debug("search [D\(depth)]: Attr '\(attrKey)' nil attempt \(attempt + 1). Retrying...")
                                usleep(retryDelayUseconds)
                            } else {
                                debug("search [D\(depth)]: Attr '\(attrKey)' remained nil after \(maxRetries) attempts.")
                                break 
                            }
                        }
                    }
                    
                    if let finalActualArr = actualArr { 
                        if attrKey == "AXDOMClassList" { 
                            currentSpecificAttributeMatch = Set(expectedArr).isSubset(of: Set(finalActualArr))
                            debug("search [D\(depth)]: Attr '\(attrKey)' (Array Subset). Want: \(expectedArr), Got: \(finalActualArr). Match: \(currentSpecificAttributeMatch)")
                        } else {
                            currentSpecificAttributeMatch = (Set(expectedArr) == Set(finalActualArr) && expectedArr.count == finalActualArr.count)
                            debug("search [D\(depth)]: Attr '\(attrKey)' (Array Exact). Want: \(expectedArr), Got: \(finalActualArr). Match: \(currentSpecificAttributeMatch)")
                        }
                    } else {
                        currentSpecificAttributeMatch = false
                        debug("search [D\(depth)]: Attr '\(attrKey)' (Array). Wanted: \(expectedArr), Got: nil/empty after retries.")
                    }
                }
                // 3. Numeric Matching
                else if let wantInt = Int(wantValueStr) {
                    if let gotInt: Int = axValue(of: element, attr: attrKey) {
                        currentSpecificAttributeMatch = (gotInt == wantInt)
                        debug("search [D\(depth)]: Attr '\(attrKey)' (Numeric). Want: \(wantInt), Got: \(gotInt). Match: \(currentSpecificAttributeMatch)")
                    } else {
                        debug("search [D\(depth)]: Attr '\(attrKey)' (Numeric). Wanted: \(wantInt), Got: nil/non-integer.")
                        currentSpecificAttributeMatch = false
                    }
                }
                // 4. String Matching (Fallback)
                else {
                    if let gotString: String = axValue(of: element, attr: attrKey) {
                        currentSpecificAttributeMatch = (gotString == wantValueStr)
                        debug("search [D\(depth)]: Attr '\(attrKey)' (String). Wanted: \(wantValueStr), Got: \(gotString). Match: \(currentSpecificAttributeMatch)")
                    } else {
                        debug("search [D\(depth)]: Attr '\(attrKey)' (String). Wanted: \(wantValueStr), Got: nil/non-string.")
                        currentSpecificAttributeMatch = false
                    }
                }
                
                if !currentSpecificAttributeMatch {
                    debug("search [D\(depth)]: Attribute '\(attrKey)' MISMATCH. Halting attribute checks for this element.")
                    allLocatorAttributesMatch = false
                    break 
                }
            } // End of attribute matching loop
        } // else, if locator.match is empty, allLocatorAttributesMatch remains true by default.

        // If role and all attributes match, then check action and potentially return
        if allLocatorAttributesMatch { // This implies roleMatches was also true to get here
            debug("search [D\(depth)]: Element Role & Attributes MATCHED. Role: \(currentElementRoleForLog ?? "nil").")
            if let requiredActionStr = requireAction, !requiredActionStr.isEmpty {
                if elementSupportsAction(element, action: requiredActionStr) {
                    debug("search [D\(depth)]: Required action '\(requiredActionStr)' IS present.")
                    return element
                } else {
                    debug("search [D\(depth)]: Element matched role/attrs, but required action '\(requiredActionStr)' is MISSING. Continuing child search.")
                    // Don't return; continue search in children as this specific element is not a full match.
                }
            } else {
                debug("search [D\(depth)]: No requireAction. Element is a match.")
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

    let wildcardRole = locator.role == "*" || locator.role.isEmpty
    let elementRole: String? = axValue(of: element, attr: kAXRoleAttribute)
    let roleMatches = wildcardRole || elementRole == locator.role
    
    if roleMatches {
        // Use the attributesMatch helper function
        let currentAttributesMatch = attributesMatch(element: element, matchDetails: locator.match, depth: depth)
        var 최종결정Ok = currentAttributesMatch // Renamed 'ok' to avoid conflict if 'ok' is used inside attributesMatch's scope for its own logic.
        
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
public func attributesMatch(element: AXUIElement, matchDetails: [String:String], depth: Int) -> Bool {
    for (attrKey, wantValueStr) in matchDetails {
        var currentAttributeMatches = false

        // 1. Boolean Matching
        if wantValueStr.lowercased() == "true" || wantValueStr.lowercased() == "false" {
            let wantBool = wantValueStr.lowercased() == "true"
            if let gotBool: Bool = axValue(of: element, attr: attrKey) {
                currentAttributeMatches = (gotBool == wantBool)
                debug("attributesMatch [D\(depth)]: Boolean '\(attrKey)'. Wanted: \(wantBool), Got: \(gotBool), Match: \(currentAttributeMatches)")
            } else {
                debug("attributesMatch [D\(depth)]: Boolean '\(attrKey)'. Wanted: \(wantBool), Got: nil or non-boolean.")
                currentAttributeMatches = false
            }
        }
        // 2. Array Matching (NO RETRY IN THIS HELPER - RETRY IS IN SEARCH/COLLECTALL CALLING AXVALUE)
        else if let expectedArr = decodeExpectedArray(fromString: wantValueStr) {
            if let actualArr: [String] = axValue(of: element, attr: attrKey) { // Direct call to axValue
                if attrKey == "AXDOMClassList" { // Constant kAXDOMClassListAttribute would be better
                    currentAttributeMatches = Set(expectedArr).isSubset(of: Set(actualArr))
                    debug("attributesMatch [D\(depth)]: Array (Subset) '\(attrKey)'. Wanted: \(expectedArr), Got: \(actualArr), Match: \(currentAttributeMatches)")
                } else {
                    currentAttributeMatches = (Set(expectedArr) == Set(actualArr) && expectedArr.count == actualArr.count)
                    debug("attributesMatch [D\(depth)]: Array (Exact) '\(attrKey)'. Wanted: \(expectedArr), Got: \(actualArr), Match: \(currentAttributeMatches)")
                }
            } else {
                currentAttributeMatches = false // axValue didn't return a [String]
                debug("attributesMatch [D\(depth)]: Array '\(attrKey)'. Wanted: \(expectedArr), Got: nil or non-[String].")
            }
        }
        // 3. Numeric Matching
        else if let wantInt = Int(wantValueStr) {
            if let gotInt: Int = axValue(of: element, attr: attrKey) {
                currentAttributeMatches = (gotInt == wantInt)
                debug("attributesMatch [D\(depth)]: Numeric '\(attrKey)'. Wanted: \(wantInt), Got: \(gotInt), Match: \(currentAttributeMatches)")
            } else {
                debug("attributesMatch [D\(depth)]: Numeric '\(attrKey)'. Wanted: \(wantInt), Got: nil or non-integer.")
                currentAttributeMatches = false
            }
        }
        // 4. String Matching (Fallback)
        else {
            if let gotString: String = axValue(of: element, attr: attrKey) {
                currentAttributeMatches = (gotString == wantValueStr)
                debug("attributesMatch [D\(depth)]: String '\(attrKey)'. Wanted: \(wantValueStr), Got: \(gotString), Match: \(currentAttributeMatches)")
            } else {
                debug("attributesMatch [D\(depth)]: String '\(attrKey)'. Wanted: \(wantValueStr), Got: nil or non-string.")
                currentAttributeMatches = false
            }
        }
        
        if !currentAttributeMatches {
            // debug("attributesMatch [D\(depth)]: Attribute '\(attrKey)' overall MISMATCH for element.")
            return false // Mismatch for this key, so the whole match fails
        }
    } // End of loop through matchDetails
    return true // All attributes in matchDetails matched
}

// End of AXSearch.swift for now 