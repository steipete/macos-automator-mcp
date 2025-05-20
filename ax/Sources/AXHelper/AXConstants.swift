// AXConstants.swift - Defines global constants used throughout AXHelper

import Foundation

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

// Configuration Constants
public let MAX_COLLECT_ALL_HITS = 100000
public let AX_BINARY_VERSION = "1.1.3" // Updated version