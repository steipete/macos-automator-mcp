// AXAttribute.swift - Defines a typed wrapper for Accessibility Attribute keys.

import Foundation
import ApplicationServices // Re-add for AXUIElement type
// import ApplicationServices // For kAX... constants - We will now use AXConstants.swift primarily
import CoreGraphics // For CGRect, CGPoint, CGSize, CFRange

// A struct to provide a type-safe way to refer to accessibility attributes.
// The generic type T represents the expected Swift type of the attribute's value.
// Note: For attributes returning AXValue (like CGPoint, CGRect), T might be the AXValue itself
// or the final unwrapped Swift type. For now, let's aim for the final Swift type where possible.
public struct AXAttribute<T> {
    public let rawValue: String

    // Internal initializer to allow creation within the module, e.g., for dynamic attribute strings.
    internal init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - General Element Attributes
    public static var role: AXAttribute<String> { AXAttribute<String>(kAXRoleAttribute) }
    public static var subrole: AXAttribute<String> { AXAttribute<String>(kAXSubroleAttribute) }
    public static var roleDescription: AXAttribute<String> { AXAttribute<String>(kAXRoleDescriptionAttribute) }
    public static var title: AXAttribute<String> { AXAttribute<String>(kAXTitleAttribute) }
    public static var description: AXAttribute<String> { AXAttribute<String>(kAXDescriptionAttribute) }
    public static var help: AXAttribute<String> { AXAttribute<String>(kAXHelpAttribute) }
    public static var identifier: AXAttribute<String> { AXAttribute<String>(kAXIdentifierAttribute) }

    // MARK: - Value Attributes
    // kAXValueAttribute can be many types. For a generic getter, Any might be appropriate,
    // or specific versions if the context knows the type.
    public static var value: AXAttribute<Any> { AXAttribute<Any>(kAXValueAttribute) }
    // Example of a more specific value if known:
    // static var stringValue: AXAttribute<String> { AXAttribute(kAXValueAttribute) }

    // MARK: - State Attributes
    public static var enabled: AXAttribute<Bool> { AXAttribute<Bool>(kAXEnabledAttribute) }
    public static var focused: AXAttribute<Bool> { AXAttribute<Bool>(kAXFocusedAttribute) }
    public static var busy: AXAttribute<Bool> { AXAttribute<Bool>(kAXElementBusyAttribute) }
    public static var hidden: AXAttribute<Bool> { AXAttribute<Bool>(kAXHiddenAttribute) }

    // MARK: - Hierarchy Attributes
    public static var parent: AXAttribute<AXUIElement> { AXAttribute<AXUIElement>(kAXParentAttribute) }
    // For children, the direct attribute often returns [AXUIElement].
    // AXElement.children getter then wraps these.
    public static var children: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXChildrenAttribute) }
    public static var selectedChildren: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXSelectedChildrenAttribute) }
    public static var visibleChildren: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXVisibleChildrenAttribute) }
    public static var windows: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXWindowsAttribute) }
    public static var mainWindow: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXMainWindowAttribute) } // Can be nil
    public static var focusedWindow: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXFocusedWindowAttribute) } // Can be nil
    public static var focusedElement: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXFocusedUIElementAttribute) } // Can be nil
    
    // MARK: - Application Specific Attributes
    // public static var enhancedUserInterface: AXAttribute<Bool> { AXAttribute<Bool>(kAXEnhancedUserInterfaceAttribute) } // Constant not found, commenting out
    public static var frontmost: AXAttribute<Bool> { AXAttribute<Bool>(kAXFrontmostAttribute) }
    public static var mainMenu: AXAttribute<AXUIElement> { AXAttribute<AXUIElement>(kAXMenuBarAttribute) }
    // public static var hiddenApplication: AXAttribute<Bool> { AXAttribute(kAXHiddenAttribute) } // Same as element hidden, but for app. Covered by .hidden

    // MARK: - Window Specific Attributes
    public static var minimized: AXAttribute<Bool> { AXAttribute<Bool>(kAXMinimizedAttribute) }
    public static var modal: AXAttribute<Bool> { AXAttribute<Bool>(kAXModalAttribute) }
    public static var defaultButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXDefaultButtonAttribute) }
    public static var cancelButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXCancelButtonAttribute) }
    public static var closeButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXCloseButtonAttribute) }
    public static var zoomButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXZoomButtonAttribute) }
    public static var minimizeButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXMinimizeButtonAttribute) }
    public static var toolbarButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXToolbarButtonAttribute) }
    public static var fullScreenButton: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXFullScreenButtonAttribute) }
    public static var proxy: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXProxyAttribute) }
    public static var growArea: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXGrowAreaAttribute) }

    // MARK: - Table/List/Outline Attributes
    public static var rows: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXRowsAttribute) }
    public static var columns: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXColumnsAttribute) }
    public static var selectedRows: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXSelectedRowsAttribute) }
    public static var selectedColumns: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXSelectedColumnsAttribute) }
    public static var selectedCells: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXSelectedCellsAttribute) }
    public static var visibleRows: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXVisibleRowsAttribute) }
    public static var visibleColumns: AXAttribute<[AXUIElement]> { AXAttribute<[AXUIElement]>(kAXVisibleColumnsAttribute) }
    public static var header: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXHeaderAttribute) }
    public static var orientation: AXAttribute<String> { AXAttribute<String>(kAXOrientationAttribute) } // e.g., kAXVerticalOrientationValue

    // MARK: - Text Attributes
    public static var selectedText: AXAttribute<String> { AXAttribute<String>(kAXSelectedTextAttribute) }
    public static var selectedTextRange: AXAttribute<CFRange> { AXAttribute<CFRange>(kAXSelectedTextRangeAttribute) }
    public static var numberOfCharacters: AXAttribute<Int> { AXAttribute<Int>(kAXNumberOfCharactersAttribute) }
    public static var visibleCharacterRange: AXAttribute<CFRange> { AXAttribute<CFRange>(kAXVisibleCharacterRangeAttribute) }
    // Parameterized attributes are handled differently, often via functions.
    // static var attributedStringForRange: AXAttribute<NSAttributedString> { AXAttribute(kAXAttributedStringForRangeParameterizedAttribute) }
    // static var stringForRange: AXAttribute<String> { AXAttribute(kAXStringForRangeParameterizedAttribute) }

    // MARK: - Scroll Area Attributes
    public static var horizontalScrollBar: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXHorizontalScrollBarAttribute) }
    public static var verticalScrollBar: AXAttribute<AXUIElement?> { AXAttribute<AXUIElement?>(kAXVerticalScrollBarAttribute) }

    // MARK: - Action Related
    // Action names are typically an array of strings.
    public static var actionNames: AXAttribute<[String]> { AXAttribute<[String]>(kAXActionNamesAttribute) }
    // Action description is parameterized by the action name, so a simple AXAttribute<String> isn't quite right.
    // It would be kAXActionDescriptionAttribute, and you pass a parameter.
    // For now, we will represent it as taking a string, and the usage site will need to handle parameterization.
    public static var actionDescription: AXAttribute<String> { AXAttribute<String>(kAXActionDescriptionAttribute) }

    // MARK: - AXValue holding attributes (expect these to return AXValueRef)
    // These will typically be unwrapped by a helper function (like AXValueParser or similar) into their Swift types.
    public static var position: AXAttribute<CGPoint> { AXAttribute<CGPoint>(kAXPositionAttribute) }
    public static var size: AXAttribute<CGSize> { AXAttribute<CGSize>(kAXSizeAttribute) }
    // Note: CGRect for kAXBoundsAttribute is also common if available.
    // For now, relying on position and size.

    // Add more attributes as needed from ApplicationServices/HIServices Accessibility Attributes...
} 
