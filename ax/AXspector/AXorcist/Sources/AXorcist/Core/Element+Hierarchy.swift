import Foundation
import ApplicationServices

// MARK: - Element Hierarchy Logic

extension Element {
    @MainActor 
    public func children(isDebugLoggingEnabled: Bool, currentDebugLogs: inout [String]) -> [Element]? {
        func dLog(_ message: String) { if isDebugLoggingEnabled { currentDebugLogs.append(message) } }
        var collectedChildren: [Element] = []
        var uniqueChildrenSet = Set<Element>()
        var tempLogs: [String] = [] // For inner calls

        dLog("Getting children for element: \(self.briefDescription(option: .default, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &currentDebugLogs))")

        // Primary children attribute
        tempLogs.removeAll()
        if let directChildrenUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>.children, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
            currentDebugLogs.append(contentsOf: tempLogs)
            for childUI in directChildrenUI {
                let childAX = Element(childUI)
                if !uniqueChildrenSet.contains(childAX) {
                    collectedChildren.append(childAX)
                    uniqueChildrenSet.insert(childAX)
                }
            }
        } else {
            currentDebugLogs.append(contentsOf: tempLogs) // Append logs even if nil
        }

        // Alternative children attributes
        let alternativeAttributes: [String] = [
            kAXVisibleChildrenAttribute, kAXWebAreaChildrenAttribute, kAXHTMLContentAttribute,
            kAXARIADOMChildrenAttribute, kAXDOMChildrenAttribute, kAXApplicationNavigationAttribute,
            kAXApplicationElementsAttribute, kAXContentsAttribute, kAXBodyAreaAttribute, kAXDocumentContentAttribute,
            kAXWebPageContentAttribute, kAXSplitGroupContentsAttribute, kAXLayoutAreaChildrenAttribute,
            kAXGroupChildrenAttribute, kAXSelectedChildrenAttribute, kAXRowsAttribute, kAXColumnsAttribute,
            kAXTabsAttribute
        ]

        for attrName in alternativeAttributes {
            tempLogs.removeAll()
            if let altChildrenUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>(attrName), isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
                currentDebugLogs.append(contentsOf: tempLogs)
                for childUI in altChildrenUI {
                    let childAX = Element(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            } else {
                currentDebugLogs.append(contentsOf: tempLogs)
            }
        }
        
        tempLogs.removeAll()
        let currentRole = self.role(isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs)
        currentDebugLogs.append(contentsOf: tempLogs)

        if currentRole == kAXApplicationRole as String {
            tempLogs.removeAll()
            if let windowElementsUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>.windows, isDebugLoggingEnabled: isDebugLoggingEnabled, currentDebugLogs: &tempLogs) {
                 currentDebugLogs.append(contentsOf: tempLogs)
                 for childUI in windowElementsUI {
                    let childAX = Element(childUI)
                    if !uniqueChildrenSet.contains(childAX) {
                        collectedChildren.append(childAX)
                        uniqueChildrenSet.insert(childAX)
                    }
                }
            } else {
                currentDebugLogs.append(contentsOf: tempLogs)
            }
        }

        if collectedChildren.isEmpty {
            dLog("No children found for element.")
            return nil
        } else {
            dLog("Found \(collectedChildren.count) children.")
            return collectedChildren
        }
    }

    // generatePathString() is now fully implemented in Element.swift
}