---
title: JXA UI Wait For Element
category: 03_jxa_core
id: jxa_ui_wait_element
description: >-
  Wait for UI elements to appear in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - wait
  - polling
  - timeout
  - element
  - appearance
---

# JXA UI Wait For Element

This script provides functionality to wait for UI elements to appear in macOS applications using JavaScript for Automation (JXA). This is useful for automating workflows where elements may take time to load or become available.

## Usage

The function polls for a UI element to appear within a specified timeout period.

```javascript
// Wait for a UI element to appear
function waitForElement(appName, target, timeout) {
    try {
        // Activate the application
        const app = Application(appName);
        app.activate();
        
        // Get System Events process for UI interaction
        const systemEvents = Application("System Events");
        const process = systemEvents.processes[appName];
        
        if (!process.exists()) {
            return {
                success: false,
                error: `Process ${appName} not found`
            };
        }
        
        // Convert timeout to seconds
        const timeoutSeconds = typeof timeout === 'number' ? timeout : 10;
        const startTime = new Date().getTime();
        const endTime = startTime + (timeoutSeconds * 1000);
        
        // Poll for the element until it appears or timeout
        let element = null;
        while (new Date().getTime() < endTime) {
            element = findUIElement(process, target);
            
            if (element) {
                // Element found
                return {
                    success: true,
                    message: `Element found after ${((new Date().getTime() - startTime) / 1000).toFixed(1)} seconds`
                };
            }
            
            // Wait before checking again
            delay(0.5);
        }
        
        return {
            success: false,
            error: `Element not found within ${timeoutSeconds} seconds`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error waiting for element: ${error.message}`
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "waitForElement"
- `appName`: The name of the application to target
- `target`: Object specifying the element to wait for (see Target Specification in the Base documentation)
- `timeout`: Maximum time to wait in seconds (default: 10)

## Example Usage

Here's an example of how to use the `waitForElement` function to wait for a "New Message" window to appear in Mail:

```json
{
  "action": "waitForElement",
  "appName": "Mail",
  "target": {
    "name": "New Message"
  },
  "timeout": 5
}
```

You can wait for any type of UI element by providing appropriate target specifications:

```json
{
  "action": "waitForElement",
  "appName": "Safari",
  "target": {
    "role": "AXTextField",
    "description": "Address and Search"
  },
  "timeout": 8
}
```

This function is particularly useful in automation scripts where you need to wait for UI elements to load before proceeding with interaction.