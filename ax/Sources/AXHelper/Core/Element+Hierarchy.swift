import Foundation
import ApplicationServices

// MARK: - Element Hierarchy Logic

extension Element {
    @MainActor public var children: [Element]? {
        var collectedChildren: [Element] = []
        var uniqueChildrenSet = Set<Element>()

        // Primary children attribute
        if let directChildrenUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>.children) {
            for childUI in directChildrenUI {
                let childAX = Element(childUI)
                if !uniqueChildrenSet.contains(childAX) {
                    collectedChildren.append(childAX)
                    uniqueChildrenSet.insert(childAX)
                }
            }
        }

        // Alternative children attributes
        let alternativeAttributes: [String] = [
            kAXVisibleChildrenAttribute, "AXWebAreaChildren", "AXHTMLContent",
            "AXARIADOMChildren", "AXDOMChildren", "AXApplicationNavigation",
            "AXApplicationElements", "AXContents", "AXBodyArea", "AXDocumentContent",
            "AXWebPageContent", "AXSplitGroupContents", "AXLayoutAreaChildren",
            "AXGroupChildren", kAXSelectedChildrenAttribute, kAXRowsAttribute, kAXColumnsAttribute,
            kAXTabsAttribute
        ]

        for attrName in alternativeAttributes {
            if let altChildrenUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>(attrName)) {
                for childUI in altChildrenUI {
                    let childAX = Element(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            }
        }
        
        // For application elements, kAXWindowsAttribute is also very important
        // Use self.role (which calls attribute()) to get the role.
        if let role = self.role, role == kAXApplicationRole as String {
            if let windowElementsUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>.windows) {
                 for childUI in windowElementsUI {
                    let childAX = Element(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            }
        }

        return collectedChildren.isEmpty ? nil : collectedChildren
    }

    @MainActor
    public func generatePathString() -> String {
        var path: [String] = []
        var currentElement: Element? = self

        var safetyCounter = 0 // To prevent infinite loops from bad hierarchy
        let maxPathDepth = 20

        while let element = currentElement, safetyCounter < maxPathDepth {
            let role = element.role ?? "UnknownRole"
            var identifier = ""
            if let title = element.title, !title.isEmpty {
                identifier = "'\(title.prefix(30))'" // Truncate long titles
            } else if let idAttr = element.identifier, !idAttr.isEmpty {
                identifier = "#\(idAttr)"
            } else if let desc = element.description, !desc.isEmpty {
                identifier = "(\(desc.prefix(30)))"
            } else if let val = element.value as? String, !val.isEmpty {
                identifier = "[val:'(val.prefix(20))']"
            }

            let pathComponent = "\(role)\(identifier.isEmpty ? "" : ":\(identifier)")"
            path.insert(pathComponent, at: 0)
            
            // Break if we reach the application element itself or if parent is nil
            if role == kAXApplicationRole as String { break }
            currentElement = element.parent
            if currentElement == nil { break }
            
            // Extra check to prevent cycle if parent is somehow self (shouldn't happen with CFEqual based Element equality)
            if currentElement == element { 
                path.insert("...CYCLE_DETECTED...", at: 0)
                break 
            }
            safetyCounter += 1
        }
        if safetyCounter >= maxPathDepth {
            path.insert("...PATH_TOO_DEEP...", at: 0)
        }
        return path.joined(separator: " / ")
    }
}