---
title: JXA UI Click Element
category: 03_jxa_core
id: jxa_ui_click
description: >-
  Click on UI elements in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - click
  - button
  - interaction
---

# JXA UI Click Element

This script provides functionality to click on UI elements in macOS applications using JavaScript for Automation (JXA).

## Usage

The function can be used to click on buttons, checkboxes, menu items, and other interactive UI elements.

```javascript
// Click on a UI element
function clickElement(appName, target, wait) {
    try {
        // Activate the application
        const app = Application(appName);
        app.activate();
        delay(wait);
        
        // Get System Events process for UI interaction
        const systemEvents = Application("System Events");
        const process = systemEvents.processes[appName];
        
        if (!process.exists()) {
            return {
                success: false,
                error: `Process ${appName} not found`
            };
        }
        
        // Find the target element based on provided criteria
        const element = findUIElement(process, target);
        
        if (!element) {
            return {
                success: false,
                error: "Target element not found"
            };
        }
        
        // Perform the click action
        element.click();
        
        return {
            success: true,
            message: `Clicked element in ${appName}`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error clicking element: ${error.message}`
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "click"
- `appName`: The name of the application to target
- `target`: Object specifying the element to click (see Target Specification in the Base documentation)
- `wait`: Seconds to wait after activating the application (default: 1)

## Example Usage

Here's an example of how to use the `clickElement` function to click a button in System Settings:

```json
{
  "action": "click",
  "appName": "System Settings",
  "target": {
    "uiType": "buttons",
    "property": "name",
    "value": "General"
  }
}
```

You can also click on elements by name, role, position, or other identifying attributes:

```json
{
  "action": "click",
  "appName": "Safari",
  "target": {
    "role": "AXButton",
    "description": "Back"
  }
}
```

This script requires the findUIElement helper function to locate the target element.