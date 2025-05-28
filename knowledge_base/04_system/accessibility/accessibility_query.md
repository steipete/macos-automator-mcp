---
title: 'macOS: Query UI Elements with Accessibility API'
category: 04_system
id: macos_accessibility_query
description: >-
  Guide to using the accessibility_query tool to inspect and interact with UI elements
  across any application using the macOS Accessibility API.
keywords:
  - accessibility
  - AX
  - UI automation
  - screen reader
  - interface inspection
  - user interface
  - Safari
  - buttons
  - elements
  - inspection
  - UI testing
  - macOS
  - AXStaticText
language: javascript
isComplex: true
---

# Using the accessibility_query Tool

The `accessibility_query` tool provides a way to inspect and interact with UI elements of any application on macOS by leveraging the native Accessibility API. This is particularly useful when you need to:

1. Identify UI elements that aren't easily accessible through AppleScript or JXA
2. Extract text or other information from application UIs
3. Perform actions like clicking buttons or interacting with controls
4. Inspect the structure of application interfaces

## How It Works

The tool interfaces with the macOS Accessibility API framework, which is the same system that powers VoiceOver and other assistive technologies. It allows you to:

- Query elements by their accessibility role and attributes
- Navigate through the UI hierarchy
- Retrieve detailed information about UI elements
- Perform actions on elements (like clicking)

## Basic Usage

The tool accepts JSON queries through the `accessibility_query` MCP tool. There are two main command types:

1. `query` - Retrieve information about UI elements
2. `perform` - Execute an action on a UI element

### Query Examples

#### 1. Find all text in the frontmost Safari window:

```json
{
  "cmd": "query",
  "multi": true,
  "locator": {
    "app": "Safari",
    "role": "AXStaticText",
    "match": {},
    "pathHint": [
      "window[1]"
    ]
  },
  "attributes": [
    "AXRole",
    "AXTitle",
    "AXIdentifier",
    "AXActions",
    "AXPosition",
    "AXSize",
    "AXRoleDescription",
    "AXLabel",
    "AXTitleUIElement",
    "AXHelp"
  ]
}
```

#### 2. Find all clickable buttons in System Settings:

```json
{
  "cmd": "query",
  "multi": true,
  "locator": {
    "app": "System Settings",
    "role": "AXButton",
    "match": {},
    "pathHint": [
      "window[1]"
    ]
  },
  "requireAction": "AXPress"
}
```

#### 3. Find a specific button by title:

```json
{
  "cmd": "query",
  "locator": {
    "app": "System Settings",
    "role": "AXButton",
    "match": {
      "AXTitle": "General"
    }
  }
}
```

### Perform Examples

#### 1. Click a button:

```json
{
  "cmd": "perform",
  "locator": {
    "app": "System Settings",
    "role": "AXButton",
    "match": {
      "AXTitle": "General"
    }
  },
  "action": "AXPress"
}
```

#### 2. Enter text in a text field:

```json
{
  "cmd": "perform",
  "locator": {
    "app": "TextEdit",
    "role": "AXTextField",
    "match": {
      "AXFocused": "true"
    }
  },
  "action": "AXSetValue",
  "value": "Hello, world!"
}
```

## Advanced Usage

### Finding Elements with `pathHint`

The `pathHint` parameter helps navigate to a specific part of the UI hierarchy. Each entry has the format `"elementType[index]"` where index is 1-based:

```json
"pathHint": ["window[1]", "toolbar[1]", "group[3]"]
```

This navigates to the first window, then its toolbar, then the third group within that toolbar.

### Filtering with `requireAction`

Use `requireAction` to only find elements that support a specific action:

```json
"requireAction": "AXPress"
```

This will only return elements that can be clicked/pressed.

### Common Accessibility Roles

Here are some common accessibility roles you can use in queries:

- `AXButton` - Buttons
- `AXStaticText` - Text labels
- `AXTextField` - Editable text fields
- `AXCheckBox` - Checkboxes
- `AXRadioButton` - Radio buttons
- `AXPopUpButton` - Dropdown buttons
- `AXMenu` - Menus
- `AXMenuItem` - Menu items
- `AXWindow` - Windows
- `AXScrollArea` - Scrollable areas
- `AXList` - Lists
- `AXTable` - Tables
- `AXLink` - Links (in web content)
- `AXImage` - Images

### Common Accessibility Actions

- `AXPress` - Click/press an element
- `AXShowMenu` - Show a contextual menu
- `AXDecrement` - Decrease a value (e.g., in a stepper)
- `AXIncrement` - Increase a value
- `AXPickerCancel` - Cancel a picker
- `AXCancel` - Cancel an operation
- `AXConfirm` - Confirm an operation

## Troubleshooting

### No Elements Found

If you're not finding elements:

1. Verify the application is running
2. Try using more general queries first, then narrow down
3. Make sure you're using the correct accessibility role
4. Try listing all windows with `"role": "AXWindow"` to see what's available

### Permission Issues

Ensure that the application running this tool has Accessibility permissions in System Settings > Privacy & Security > Accessibility.

## Technical Notes

- The accessibility interface runs in the background, so it doesn't interrupt your normal application usage
- For web content in browsers, web-specific accessibility attributes are available
- Some applications may have non-standard accessibility implementations
- The tool uses the Swift AXUIElement framework to interact with the accessibility API

## Example: Extracting Text from a PDF in Preview

```json
{
  "cmd": "query",
  "multi": true,
  "locator": {
    "app": "Preview",
    "role": "AXStaticText",
    "match": {},
    "pathHint": [
      "window[1]",
      "AXScrollArea[1]"
    ]
  },
  "attributes": [
    "AXValue",
    "AXRole",
    "AXPosition",
    "AXSize"
  ]
}
```

This query extracts all text elements from a PDF document open in Preview, along with their positions and sizes on the page. 