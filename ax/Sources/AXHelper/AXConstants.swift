// AXConstants.swift - Defines global constants used throughout AXHelper

import Foundation

// Configuration Constants
public let MAX_COLLECT_ALL_HITS = 200 // Default max elements for collect_all if not specified in command
public let DEFAULT_MAX_DEPTH_SEARCH = 20 // Default max recursion depth for search
public let DEFAULT_MAX_DEPTH_COLLECT_ALL = 15 // Default max recursion depth for collect_all
public let AX_BINARY_VERSION = "1.1.5" // Updated version

// Standard Accessibility Attributes
public let kAXRoleAttribute = "AXRole"
public let kAXSubroleAttribute = "AXSubrole"
public let kAXRoleDescriptionAttribute = "AXRoleDescription"
public let kAXTitleAttribute = "AXTitle"
public let kAXValueAttribute = "AXValue"
public let kAXDescriptionAttribute = "AXDescription"
public let kAXHelpAttribute = "AXHelp"
public let kAXIdentifierAttribute = "AXIdentifier"
public let kAXPlaceholderValueAttribute = "AXPlaceholderValue"
public let kAXLabelUIElementAttribute = "AXLabelUIElement"
public let kAXTitleUIElementAttribute = "AXTitleUIElement"
public let kAXLabelValueAttribute = "AXLabelValue"

public let kAXChildrenAttribute = "AXChildren"
public let kAXParentAttribute = "AXParent"
public let kAXWindowsAttribute = "AXWindows"
public let kAXMainWindowAttribute = "AXMainWindow"
public let kAXFocusedWindowAttribute = "AXFocusedWindow"
public let kAXFocusedUIElementAttribute = "AXFocusedUIElement"

public let kAXEnabledAttribute = "AXEnabled"
public let kAXFocusedAttribute = "AXFocused"
public let kAXMainAttribute = "AXMain"

public let kAXPositionAttribute = "AXPosition"
public let kAXSizeAttribute = "AXSize"

// Actions
public let kAXActionsAttribute = "AXActions"
public let kAXActionNamesAttribute = "AXActionNames"
public let kAXPressAction = "AXPress"
public let kAXShowMenuAction = "AXShowMenu"

// Standard Accessibility Roles (examples, add more as needed)
public let kAXApplicationRole = "AXApplication"
public let kAXWindowRole = "AXWindow"
public let kAXButtonRole = "AXButton"
public let kAXCheckBoxRole = "AXCheckBox"
public let kAXStaticTextRole = "AXStaticText"
public let kAXTextFieldRole = "AXTextField"
public let kAXTextAreaRole = "AXTextArea"
public let kAXScrollAreaRole = "AXScrollArea"
public let kAXGroupRole = "AXGroup"
public let kAXWebAreaRole = "AXWebArea"
public let kAXToolbarRole = "AXToolbar"

// Attributes for web content and tables/lists
public let kAXVisibleChildrenAttribute = "AXVisibleChildren"
public let kAXTabsAttribute = "AXTabs"
public let kAXSelectedChildrenAttribute = "AXSelectedChildren"
public let kAXRowsAttribute = "AXRows"
public let kAXColumnsAttribute = "AXColumns"

// DOM specific attributes (often strings or arrays of strings)
public let kAXDOMIdentifierAttribute = "AXDOMIdentifier" // Example, might not be standard AX
public let kAXDOMClassListAttribute = "AXDOMClassList" // Example, might not be standard AX
public let kAXARIADOMResourceAttribute = "AXARIADOMResource" // Example
public let kAXARIADOMFunctionAttribute = "AXARIADOM-función" // Corrected identifier, kept original string value.
