---
title: JXA UI Get & Set Element Values
category: 03_jxa_core
id: jxa_ui_element_values
description: >-
  Get and set values of UI elements in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - input
  - form
  - text
  - value
  - read
  - write
---

# JXA UI Get & Set Element Values

This script provides functionality to get and set values of UI elements in macOS applications using JavaScript for Automation (JXA).

## Usage

The functions can be used to read from and write to form fields, checkboxes, sliders, and other UI elements that have values.

```javascript
// Get the value of a UI element
function getElementValue(appName, target, wait) {
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
        
        // Get the value of the element
        let value = null;
        
        // Different element types store their values differently
        if (element.value !== undefined) {
            value = element.value();
        } else if (element.staticText && element.staticText.length > 0) {
            value = element.staticText[0].value();
        } else if (element.name !== undefined) {
            value = element.name();
        } else if (element.title !== undefined) {
            value = element.title();
        }
        
        return {
            success: true,
            value: value,
            message: `Retrieved value from element in ${appName}`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error getting element value: ${error.message}`
        };
    }
}

// Set the value of a UI element
function setElementValue(appName, target, value, wait) {
    try {
        if (value === undefined) {
            return {
                success: false,
                error: "Value parameter is required"
            };
        }
        
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
        
        // Set the value of the element
        if (element.value !== undefined) {
            element.value.set(value);
        } else {
            // Try to set the element's value by selecting all text and typing
            element.click();
            delay(0.2);
            
            // Select all existing text (Cmd+A)
            systemEvents.keystroke("a", {using: "command down"});
            delay(0.2);
            
            // Type the new value
            systemEvents.keystroke(value);
        }
        
        return {
            success: true,
            message: `Set value of element in ${appName}`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error setting element value: ${error.message}`
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

### For getValue action:
- `action`: Must be "getValue"
- `appName`: The name of the application to target
- `target`: Object specifying the element to get the value from (see Target Specification in the Base documentation)
- `wait`: Seconds to wait after activating the application (default: 1)

### For setValue action:
- `action`: Must be "setValue"
- `appName`: The name of the application to target
- `target`: Object specifying the element to set the value for
- `value`: The value to set (required)
- `wait`: Seconds to wait after activating the application (default: 1)

## Example Usage

Here's an example of how to get the value of a text field:

```json
{
  "action": "getValue",
  "appName": "Notes",
  "target": {
    "elementType": "textAreas",
    "index": 0
  }
}
```

And here's how to set text in a search field:

```json
{
  "action": "setValue",
  "appName": "Finder",
  "target": {
    "role": "AXSearchField"
  },
  "value": "document"
}
```

These functions handle different types of UI elements and their values appropriately.