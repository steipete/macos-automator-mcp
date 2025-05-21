// AccessibilityConstants.swift - Defines global constants used throughout the accessibility helper

import Foundation
import ApplicationServices // Added for AXError type
import AppKit // Added for NSAccessibility

// Configuration Constants
public let MAX_COLLECT_ALL_HITS = 200 // Default max elements for collect_all if not specified in command
public let DEFAULT_MAX_DEPTH_SEARCH = 20 // Default max recursion depth for search
public let DEFAULT_MAX_DEPTH_COLLECT_ALL = 15 // Default max recursion depth for collect_all
public let AX_BINARY_VERSION = "1.1.7" // Updated version
public let BINARY_VERSION = "1.1.7" // Updated version without AX prefix

// Standard Accessibility Attributes - Values should match CFSTR defined in AXAttributeConstants.h
public let kAXRoleAttribute = "AXRole" // Reverted to String literal
public let kAXSubroleAttribute = "AXSubrole"
public let kAXRoleDescriptionAttribute = "AXRoleDescription"
public let kAXTitleAttribute = "AXTitle"
public let kAXValueAttribute = "AXValue"
public let kAXValueDescriptionAttribute = "AXValueDescription" // New
public let kAXDescriptionAttribute = "AXDescription"
public let kAXHelpAttribute = "AXHelp"
public let kAXIdentifierAttribute = "AXIdentifier"
public let kAXPlaceholderValueAttribute = "AXPlaceholderValue"
public let kAXLabelUIElementAttribute = "AXLabelUIElement"
public let kAXTitleUIElementAttribute = "AXTitleUIElement"
public let kAXLabelValueAttribute = "AXLabelValue"
public let kAXElementBusyAttribute = "AXElementBusy" // New
public let kAXAlternateUIVisibleAttribute = "AXAlternateUIVisible" // New

public let kAXChildrenAttribute = "AXChildren"
public let kAXParentAttribute = "AXParent"
public let kAXWindowsAttribute = "AXWindows"
public let kAXMainWindowAttribute = "AXMainWindow"
public let kAXFocusedWindowAttribute = "AXFocusedWindow"
public let kAXFocusedUIElementAttribute = "AXFocusedUIElement"

public let kAXEnabledAttribute = "AXEnabled"
public let kAXFocusedAttribute = "AXFocused"
public let kAXMainAttribute = "AXMain" // Window-specific
public let kAXMinimizedAttribute = "AXMinimized" // New, Window-specific
public let kAXCloseButtonAttribute = "AXCloseButton" // New, Window-specific
public let kAXZoomButtonAttribute = "AXZoomButton" // New, Window-specific
public let kAXMinimizeButtonAttribute = "AXMinimizeButton" // New, Window-specific
public let kAXFullScreenButtonAttribute = "AXFullScreenButton" // New, Window-specific
public let kAXDefaultButtonAttribute = "AXDefaultButton" // New, Window-specific
public let kAXCancelButtonAttribute = "AXCancelButton" // New, Window-specific
public let kAXGrowAreaAttribute = "AXGrowArea" // New, Window-specific
public let kAXModalAttribute = "AXModal" // New, Window-specific

public let kAXMenuBarAttribute = "AXMenuBar" // New, App-specific
public let kAXFrontmostAttribute = "AXFrontmost" // New, App-specific
public let kAXHiddenAttribute = "AXHidden" // New, App-specific

public let kAXPositionAttribute = "AXPosition"
public let kAXSizeAttribute = "AXSize"

// Value attributes
public let kAXMinValueAttribute = "AXMinValue" // New
public let kAXMaxValueAttribute = "AXMaxValue" // New
public let kAXValueIncrementAttribute = "AXValueIncrement" // New
public let kAXAllowedValuesAttribute = "AXAllowedValues" // New

// Text-specific attributes
public let kAXSelectedTextAttribute = "AXSelectedText" // New
public let kAXSelectedTextRangeAttribute = "AXSelectedTextRange" // New
public let kAXNumberOfCharactersAttribute = "AXNumberOfCharacters" // New
public let kAXVisibleCharacterRangeAttribute = "AXVisibleCharacterRange" // New
public let kAXInsertionPointLineNumberAttribute = "AXInsertionPointLineNumber" // New

// Actions - Values should match CFSTR defined in AXActionConstants.h
public let kAXActionsAttribute = "AXActions" // This is actually kAXActionNamesAttribute typically
public let kAXActionNamesAttribute = "AXActionNames" // Correct name for listing actions
public let kAXActionDescriptionAttribute = "AXActionDescription" // To get desc of an action (not in AXActionConstants.h but AXUIElement.h)

public let kAXIncrementAction = "AXIncrement" // New
public let kAXDecrementAction = "AXDecrement" // New
public let kAXConfirmAction = "AXConfirm" // New
public let kAXCancelAction = "AXCancel" // New
public let kAXShowMenuAction = "AXShowMenu"
public let kAXPickAction = "AXPick" // New (Obsolete in headers, but sometimes seen)
public let kAXPressAction = "AXPress" // New

// Specific action name for setting a value, used internally by performActionOnElement
public let kAXSetValueAction = "AXSetValue"

// Standard Accessibility Roles - Values should match CFSTR defined in AXRoleConstants.h (examples, add more as needed)
public let kAXApplicationRole = "AXApplication"
public let kAXSystemWideRole = "AXSystemWide" // New
public let kAXWindowRole = "AXWindow"
public let kAXSheetRole = "AXSheet" // New
public let kAXDrawerRole = "AXDrawer" // New
public let kAXGroupRole = "AXGroup"
public let kAXButtonRole = "AXButton"
public let kAXRadioButtonRole = "AXRadioButton" // New
public let kAXCheckBoxRole = "AXCheckBox"
public let kAXPopUpButtonRole = "AXPopUpButton" // New
public let kAXMenuButtonRole = "AXMenuButton" // New
public let kAXStaticTextRole = "AXStaticText"
public let kAXTextFieldRole = "AXTextField"
public let kAXTextAreaRole = "AXTextArea"
public let kAXScrollAreaRole = "AXScrollArea"
public let kAXScrollBarRole = "AXScrollBar" // New
public let kAXWebAreaRole = "AXWebArea"
public let kAXImageRole = "AXImage" // New
public let kAXListRole = "AXList" // New
public let kAXTableRole = "AXTable" // New
public let kAXOutlineRole = "AXOutline" // New
public let kAXColumnRole = "AXColumn" // New
public let kAXRowRole = "AXRow" // New
public let kAXToolbarRole = "AXToolbar"
public let kAXBusyIndicatorRole = "AXBusyIndicator" // New
public let kAXProgressIndicatorRole = "AXProgressIndicator" // New
public let kAXSliderRole = "AXSlider" // New
public let kAXIncrementorRole = "AXIncrementor" // New
public let kAXDisclosureTriangleRole = "AXDisclosureTriangle" // New
public let kAXMenuRole = "AXMenu" // New
public let kAXMenuItemRole = "AXMenuItem" // New
public let kAXSplitGroupRole = "AXSplitGroup" // New
public let kAXSplitterRole = "AXSplitter" // New
public let kAXColorWellRole = "AXColorWell" // New
public let kAXUnknownRole = "AXUnknown" // New

// Attributes for web content and tables/lists
public let kAXVisibleChildrenAttribute = "AXVisibleChildren"
public let kAXSelectedChildrenAttribute = "AXSelectedChildren"
public let kAXTabsAttribute = "AXTabs" // Often a kAXRadioGroup or kAXTabGroup role
public let kAXRowsAttribute = "AXRows"
public let kAXColumnsAttribute = "AXColumns"
public let kAXSelectedRowsAttribute = "AXSelectedRows" // New
public let kAXSelectedColumnsAttribute = "AXSelectedColumns" // New
public let kAXIndexAttribute = "AXIndex" // New (for rows/columns)
public let kAXDisclosingAttribute = "AXDisclosing" // New (for outlines)

// Custom or less standard attributes (verify usage and standard names)
public let kAXPathHintAttribute = "AXPathHint" // Our custom attribute for pathing

// String constant for "not available"
public let kAXNotAvailableString = "n/a"

// DOM specific attributes (these seem custom or web-specific, not standard Apple AX)
// Verify if these are actual attribute names exposed by web views or custom implementations.
public let kAXDOMIdentifierAttribute = "AXDOMIdentifier" // Example, might not be standard AX
public let kAXDOMClassListAttribute = "AXDOMClassList" // Example, might not be standard AX
public let kAXARIADOMResourceAttribute = "AXARIADOMResource" // Example
public let kAXARIADOMFunctionAttribute = "AXARIADOM-función" // Corrected identifier, kept original string value.
public let kAXARIADOMChildrenAttribute = "AXARIADOMChildren" // New
public let kAXDOMChildrenAttribute = "AXDOMChildren" // New

// New constants for missing attributes
public let kAXToolbarButtonAttribute = "AXToolbarButton"
public let kAXProxyAttribute = "AXProxy"
public let kAXSelectedCellsAttribute = "AXSelectedCells"
public let kAXHeaderAttribute = "AXHeader"
public let kAXHorizontalScrollBarAttribute = "AXHorizontalScrollBar"
public let kAXVerticalScrollBarAttribute = "AXVerticalScrollBar"

// Attributes used in child heuristic collection (often non-standard or specific)
public let kAXWebAreaChildrenAttribute = "AXWebAreaChildren"
public let kAXHTMLContentAttribute = "AXHTMLContent"
public let kAXApplicationNavigationAttribute = "AXApplicationNavigation"
public let kAXApplicationElementsAttribute = "AXApplicationElements"
public let kAXContentsAttribute = "AXContents"
public let kAXBodyAreaAttribute = "AXBodyArea"
public let kAXDocumentContentAttribute = "AXDocumentContent"
public let kAXWebPageContentAttribute = "AXWebPageContent"
public let kAXSplitGroupContentsAttribute = "AXSplitGroupContents"
public let kAXLayoutAreaChildrenAttribute = "AXLayoutAreaChildren"
public let kAXGroupChildrenAttribute = "AXGroupChildren"

// Helper function to convert AXError to a string
public func axErrorToString(_ error: AXError) -> String {
    switch error {
    case .success: return "success"
    case .failure: return "failure"
    case .apiDisabled: return "apiDisabled"
    case .invalidUIElement: return "invalidUIElement"
    case .invalidUIElementObserver: return "invalidUIElementObserver"
    case .cannotComplete: return "cannotComplete"
    case .attributeUnsupported: return "attributeUnsupported"
    case .actionUnsupported: return "actionUnsupported"
    case .notificationUnsupported: return "notificationUnsupported"
    case .notImplemented: return "notImplemented"
    case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
    case .notificationNotRegistered: return "notificationNotRegistered"
    case .noValue: return "noValue"
    case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
    case .notEnoughPrecision: return "notEnoughPrecision"
    case .illegalArgument: return "illegalArgument"
    @unknown default:
        return "unknown AXError (code: \(error.rawValue))"
    }
}

// MARK: - Custom Application/Computed Keys

public let focusedApplicationKey = "focused"
public let computedNameAttributeKey = "ComputedName"
public let isClickableAttributeKey = "IsClickable"
public let isIgnoredAttributeKey = "IsIgnored" // Used in AttributeMatcher
public let computedPathAttributeKey = "ComputedPath"