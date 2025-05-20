import Foundation
import ApplicationServices

// MARK: - Element Common Attribute Getters & Status Properties

extension Element {
    // Common Attribute Getters
    @MainActor public var role: String? { attribute(Attribute<String>.role) }
    @MainActor public var subrole: String? { attribute(Attribute<String>.subrole) }
    @MainActor public var title: String? { attribute(Attribute<String>.title) }
    @MainActor public var description: String? { attribute(Attribute<String>.description) }
    @MainActor public var isEnabled: Bool? { attribute(Attribute<Bool>.enabled) }
    @MainActor public var value: Any? { attribute(Attribute<Any>.value) } // Keep public if external modules might need it
    @MainActor public var roleDescription: String? { attribute(Attribute<String>.roleDescription) }
    @MainActor public var help: String? { attribute(Attribute<String>.help) }
    @MainActor public var identifier: String? { attribute(Attribute<String>.identifier) }

    // Status Properties
    @MainActor public var isFocused: Bool? { attribute(Attribute<Bool>.focused) }
    @MainActor public var isHidden: Bool? { attribute(Attribute<Bool>.hidden) }
    @MainActor public var isElementBusy: Bool? { attribute(Attribute<Bool>.busy) }

    @MainActor public var isIgnored: Bool {
        // Basic check: if explicitly hidden, it's ignored.
        // More complex checks could be added (e.g. disabled and non-interactive, purely decorative group etc.)
        if attribute(Attribute<Bool>.hidden) == true {
            return true
        }
        // Add other conditions for being ignored if necessary, e.g., based on role and lack of children/value
        // For now, only explicit kAXHiddenAttribute implies ignored for this helper.
        return false
    }

    @MainActor public var pid: pid_t? {
        var processID: pid_t = 0
        let error = AXUIElementGetPid(self.underlyingElement, &processID)
        if error == .success {
            return processID
        }
        return nil
    }

    // Hierarchy and Relationship Getters (Simpler Ones)
    @MainActor public var parent: Element? {
        guard let parentElementUI: AXUIElement = attribute(Attribute<AXUIElement>.parent) else { return nil }
        return Element(parentElementUI)
    }

    @MainActor public var windows: [Element]? {
        guard let windowElementsUI: [AXUIElement] = attribute(Attribute<[AXUIElement]>.windows) else { return nil }
        return windowElementsUI.map { Element($0) }
    }

    @MainActor public var mainWindow: Element? {
        guard let windowElementUI: AXUIElement = attribute(Attribute<AXUIElement?>.mainWindow) ?? nil else { return nil }
        return Element(windowElementUI)
    }

    @MainActor public var focusedWindow: Element? {
        guard let windowElementUI: AXUIElement = attribute(Attribute<AXUIElement?>.focusedWindow) ?? nil else { return nil }
        return Element(windowElementUI)
    }

    @MainActor public var focusedElement: Element? {
        guard let elementUI: AXUIElement = attribute(Attribute<AXUIElement?>.focusedElement) ?? nil else { return nil }
        return Element(elementUI)
    }
    
    // Action-related (moved here as it's a simple getter)
    @MainActor
    public var supportedActions: [String]? {
        return attribute(Attribute<[String]>.actionNames)
    }
}