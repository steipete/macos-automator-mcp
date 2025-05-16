---
title: JXA UI Automation Base
category: 03_jxa_core
id: jxa_ui_base
description: >-
  Core functionality for UI automation using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - systemevents
---

# JXA UI Automation Base

This script provides the core functionality for UI automation using JavaScript for Automation (JXA). It includes the main run function, parameter processing, and demonstration code.

## Usage

This base script is designed to be used with various UI automation actions.

```javascript
// JXA UI Automation Base
// Core functionality for UI automation

function run(argv) {
    // When run directly with no arguments, show a basic example
    if (argv.length === 0) {
        return demonstrateUIAutomation();
    }
    
    return "Please use with MCP parameters";
}

// Handler for MCP input parameters
function processMCPParameters(params) {
    try {
        // Extract parameters
        const action = params.action || "";
        const appName = params.appName || "";
        const target = params.target || {};
        const wait = params.wait !== undefined ? params.wait : 1;
        
        // Validate required parameters
        if (!action) {
            return {
                success: false,
                error: "Action parameter is required"
            };
        }
        
        if (!appName) {
            return {
                success: false,
                error: "Application name is required"
            };
        }
        
        // Perform the requested action
        switch (action) {
            case "click":
                return clickElement(appName, target, wait);
            case "getValue":
                return getElementValue(appName, target, wait);
            case "setValue":
                return setElementValue(appName, target, params.value, wait);
            case "getWindowInfo":
                return getWindowInformation(appName);
            case "getUIHierarchy":
                return getUIElementHierarchy(appName, target);
            case "performMenuAction":
                return performMenuAction(appName, params.menuItems);
            case "waitForElement":
                return waitForElement(appName, target, params.timeout || 10);
            case "scrollElement":
                return scrollElement(appName, target, params.direction, params.amount);
            case "dragAndDrop":
                return dragAndDrop(appName, target, params.destination);
            default:
                return {
                    success: false,
                    error: `Unknown action: ${action}`
                };
        }
    } catch (error) {
        return {
            success: false,
            error: `Error processing parameters: ${error.message}`
        };
    }
}

// Basic UI automation demonstration
function demonstrateUIAutomation() {
    try {
        const app = Application.currentApplication();
        app.includeStandardAdditions = true;
        
        // Show example dialog
        const exampleApps = ["Finder", "Safari", "Mail", "System Settings", "Calendar"];
        const selectedApp = app.chooseFromList(exampleApps, {
            withPrompt: "Select an application to demonstrate UI automation:",
            defaultItems: ["Finder"]
        });
        
        if (!selectedApp) return "Demonstration cancelled";
        const appName = selectedApp[0];
        
        // Activate the selected application
        Application(appName).activate();
        delay(0.5);
        
        // Get window information for the app
        const windowInfo = getWindowInformation(appName);
        
        // Show some UI hierarchy for the application
        const hierarchyInfo = getUIElementHierarchy(appName, {});
        
        return {
            success: true,
            message: `Demonstrated UI automation with ${appName}`,
            windowInfo: windowInfo,
            hierarchySample: hierarchyInfo.slice(0, 3) // Just show first few items to avoid overwhelming
        };
    } catch (error) {
        return {
            success: false,
            error: `Error in demonstration: ${error.message}`
        };
    }
}

// Utility function to create a delay
function delay(seconds) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.delay(seconds);
}
```

## Common Parameters for All Actions

These parameters are used by all UI automation actions:

- `action`: The action to perform (required)
- `appName`: The name of the application to target (required)
- `wait`: Seconds to wait after activating the application (default: 1)

## Target Specification

The `target` parameter is an object that can contain various properties to identify UI elements:

- `windowIndex`: Index of the window to target
- `windowName`: Name of the window to target
- `uiType`: Type of UI element (e.g., "buttons", "textFields")
- `property`: Property name to match
- `value`: Value to match against the property
- `name`: Name of the element
- `role`: Accessibility role of the element
- `description`: Description of the element
- `title`: Title of the element
- `text`: Text content of the element
- `elementType`: Type of element to select by index
- `index`: Index of the element within its type
- `position`: [x, y] coordinates of the element
- `positionTolerance`: Tolerance for position matching

This base script provides the foundation for all other UI automation scripts.