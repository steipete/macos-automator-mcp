// Attribute.swift - Defines a typed wrapper for Accessibility Attribute keys.

import Foundation
import ApplicationServices // Re-add for AXUIElement type
// import ApplicationServices // For kAX... constants - We will now use AccessibilityConstants.swift primarily
import CoreGraphics // For CGRect, CGPoint, CGSize, CFRange

// A struct to provide a type-safe way to refer to accessibility attributes.
// The generic type T represents the expected Swift type of the attribute's value.
// Note: For attributes returning AXValue (like CGPoint, CGRect), T might be the AXValue itself
// or the final unwrapped Swift type. For now, let's aim for the final Swift type where possible.
public struct Attribute<T> {
    public let rawValue: String

    // Internal initializer to allow creation within the module, e.g., for dynamic attribute strings.
    internal init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - General Element Attributes
    public static var role: Attribute<String> { Attribute<String>(kAXRoleAttribute) }
    public static var subrole: Attribute<String> { Attribute<String>(kAXSubroleAttribute) }
    public static var roleDescription: Attribute<String> { Attribute<String>(kAXRoleDescriptionAttribute) }
    public static var title: Attribute<String> { Attribute<String>(kAXTitleAttribute) }
    public static var description: Attribute<String> { Attribute<String>(kAXDescriptionAttribute) }
    public static var help: Attribute<String> { Attribute<String>(kAXHelpAttribute) }
    public static var identifier: Attribute<String> { Attribute<String>(kAXIdentifierAttribute) }

    // MARK: - Value Attributes
    // kAXValueAttribute can be many types. For a generic getter, Any might be appropriate,
    // or specific versions if the context knows the type.
    public static var value: Attribute<Any> { Attribute<Any>(kAXValueAttribute) }
    // Example of a more specific value if known:
    // static var stringValue: Attribute<String> { Attribute(kAXValueAttribute) }

    // MARK: - State Attributes
    public static var enabled: Attribute<Bool> { Attribute<Bool>(kAXEnabledAttribute) }
    public static var focused: Attribute<Bool> { Attribute<Bool>(kAXFocusedAttribute) }
    public static var busy: Attribute<Bool> { Attribute<Bool>(kAXElementBusyAttribute) }
    public static var hidden: Attribute<Bool> { Attribute<Bool>(kAXHiddenAttribute) }

    // MARK: - Hierarchy Attributes
    public static var parent: Attribute<AXUIElement> { Attribute<AXUIElement>(kAXParentAttribute) }
    // For children, the direct attribute often returns [AXUIElement].
    // Element.children getter then wraps these.
    public static var children: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXChildrenAttribute) }
    public static var selectedChildren: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXSelectedChildrenAttribute) }
    public static var visibleChildren: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXVisibleChildrenAttribute) }
    public static var windows: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXWindowsAttribute) }
    public static var mainWindow: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXMainWindowAttribute) } // Can be nil
    public static var focusedWindow: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXFocusedWindowAttribute) } // Can be nil
    public static var focusedElement: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXFocusedUIElementAttribute) } // Can be nil
    
    // MARK: - Application Specific Attributes
    // public static var enhancedUserInterface: Attribute<Bool> { Attribute<Bool>(kAXEnhancedUserInterfaceAttribute) } // Constant not found, commenting out
    public static var frontmost: Attribute<Bool> { Attribute<Bool>(kAXFrontmostAttribute) }
    public static var mainMenu: Attribute<AXUIElement> { Attribute<AXUIElement>(kAXMenuBarAttribute) }
    // public static var hiddenApplication: Attribute<Bool> { Attribute(kAXHiddenAttribute) } // Same as element hidden, but for app. Covered by .hidden

    // MARK: - Window Specific Attributes
    public static var minimized: Attribute<Bool> { Attribute<Bool>(kAXMinimizedAttribute) }
    public static var modal: Attribute<Bool> { Attribute<Bool>(kAXModalAttribute) }
    public static var defaultButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXDefaultButtonAttribute) }
    public static var cancelButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXCancelButtonAttribute) }
    public static var closeButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXCloseButtonAttribute) }
    public static var zoomButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXZoomButtonAttribute) }
    public static var minimizeButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXMinimizeButtonAttribute) }
    public static var toolbarButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXToolbarButtonAttribute) }
    public static var fullScreenButton: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXFullScreenButtonAttribute) }
    public static var proxy: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXProxyAttribute) }
    public static var growArea: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXGrowAreaAttribute) }

    // MARK: - Table/List/Outline Attributes
    public static var rows: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXRowsAttribute) }
    public static var columns: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXColumnsAttribute) }
    public static var selectedRows: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXSelectedRowsAttribute) }
    public static var selectedColumns: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXSelectedColumnsAttribute) }
    public static var selectedCells: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXSelectedCellsAttribute) }
    public static var visibleRows: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXVisibleRowsAttribute) }
    public static var visibleColumns: Attribute<[AXUIElement]> { Attribute<[AXUIElement]>(kAXVisibleColumnsAttribute) }
    public static var header: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXHeaderAttribute) }
    public static var orientation: Attribute<String> { Attribute<String>(kAXOrientationAttribute) } // e.g., kAXVerticalOrientationValue

    // MARK: - Text Attributes
    public static var selectedText: Attribute<String> { Attribute<String>(kAXSelectedTextAttribute) }
    public static var selectedTextRange: Attribute<CFRange> { Attribute<CFRange>(kAXSelectedTextRangeAttribute) }
    public static var numberOfCharacters: Attribute<Int> { Attribute<Int>(kAXNumberOfCharactersAttribute) }
    public static var visibleCharacterRange: Attribute<CFRange> { Attribute<CFRange>(kAXVisibleCharacterRangeAttribute) }
    // Parameterized attributes are handled differently, often via functions.
    // static var attributedStringForRange: Attribute<NSAttributedString> { Attribute(kAXAttributedStringForRangeParameterizedAttribute) }
    // static var stringForRange: Attribute<String> { Attribute(kAXStringForRangeParameterizedAttribute) }

    // MARK: - Scroll Area Attributes
    public static var horizontalScrollBar: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXHorizontalScrollBarAttribute) }
    public static var verticalScrollBar: Attribute<AXUIElement?> { Attribute<AXUIElement?>(kAXVerticalScrollBarAttribute) }

    // MARK: - Action Related
    // Action names are typically an array of strings.
    public static var actionNames: Attribute<[String]> { Attribute<[String]>(kAXActionNamesAttribute) }
    // Action description is parameterized by the action name, so a simple Attribute<String> isn't quite right.
    // It would be kAXActionDescriptionAttribute, and you pass a parameter.
    // For now, we will represent it as taking a string, and the usage site will need to handle parameterization.
    public static var actionDescription: Attribute<String> { Attribute<String>(kAXActionDescriptionAttribute) }

    // MARK: - AXValue holding attributes (expect these to return AXValueRef)
    // These will typically be unwrapped by a helper function (like ValueParser or similar) into their Swift types.
    public static var position: Attribute<CGPoint> { Attribute<CGPoint>(kAXPositionAttribute) }
    public static var size: Attribute<CGSize> { Attribute<CGSize>(kAXSizeAttribute) }
    // Note: CGRect for kAXBoundsAttribute is also common if available.
    // For now, relying on position and size.

    // Add more attributes as needed from ApplicationServices/HIServices Accessibility Attributes...
}