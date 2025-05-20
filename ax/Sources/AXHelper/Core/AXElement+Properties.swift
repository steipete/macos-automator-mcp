import Foundation
import ApplicationServices

// MARK: - AXElement Common Attribute Getters & Status Properties

extension AXElement {
    // Common Attribute Getters
    @MainActor public var role: String? { attribute(AXAttribute<String>.role) }
    @MainActor public var subrole: String? { attribute(AXAttribute<String>.subrole) }
    @MainActor public var title: String? { attribute(AXAttribute<String>.title) }
    @MainActor public var axDescription: String? { attribute(AXAttribute<String>.description) }
    @MainActor public var isEnabled: Bool? { attribute(AXAttribute<Bool>.enabled) }
    @MainActor public var value: Any? { attribute(AXAttribute<Any>.value) } // Keep public if external modules might need it
    @MainActor public var roleDescription: String? { attribute(AXAttribute<String>.roleDescription) }
    @MainActor public var help: String? { attribute(AXAttribute<String>.help) }
    @MainActor public var identifier: String? { attribute(AXAttribute<String>.identifier) }

    // Status Properties
    @MainActor public var isFocused: Bool? { attribute(AXAttribute<Bool>.focused) }
    @MainActor public var isHidden: Bool? { attribute(AXAttribute<Bool>.hidden) }
    @MainActor public var isElementBusy: Bool? { attribute(AXAttribute<Bool>.busy) }

    @MainActor public var isIgnored: Bool {
        // Basic check: if explicitly hidden, it's ignored.
        // More complex checks could be added (e.g. disabled and non-interactive, purely decorative group etc.)
        if attribute(AXAttribute<Bool>.hidden) == true {
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
    @MainActor public var parent: AXElement? {
        guard let parentElementUI: AXUIElement = attribute(AXAttribute<AXUIElement>.parent) else { return nil }
        return AXElement(parentElementUI)
    }

    @MainActor public var windows: [AXElement]? {
        guard let windowElementsUI: [AXUIElement] = attribute(AXAttribute<[AXUIElement]>.windows) else { return nil }
        return windowElementsUI.map { AXElement($0) }
    }

    @MainActor public var mainWindow: AXElement? {
        guard let windowElementUI: AXUIElement = attribute(AXAttribute<AXUIElement?>.mainWindow) ?? nil else { return nil }
        return AXElement(windowElementUI)
    }

    @MainActor public var focusedWindow: AXElement? {
        guard let windowElementUI: AXUIElement = attribute(AXAttribute<AXUIElement?>.focusedWindow) ?? nil else { return nil }
        return AXElement(windowElementUI)
    }

    @MainActor public var focusedElement: AXElement? {
        guard let elementUI: AXUIElement = attribute(AXAttribute<AXUIElement?>.focusedElement) ?? nil else { return nil }
        return AXElement(elementUI)
    }
    
    // Action-related (moved here as it's a simple getter)
    @MainActor
    public var supportedActions: [String]? {
        return attribute(AXAttribute<[String]>.actionNames)
    }
} 