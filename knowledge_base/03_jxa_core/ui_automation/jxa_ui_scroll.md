---
title: JXA UI Scroll Element
category: 03_jxa_core
id: jxa_ui_scroll
description: >-
  Scroll UI elements in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - scroll
  - scrolling
  - navigation
  - scrollarea
---

# JXA UI Scroll Element

This script provides functionality to scroll UI elements in macOS applications using JavaScript for Automation (JXA). It allows you to programmatically scroll in any direction with a specified amount.

## Usage

The function can be used to scroll content in scroll areas, text views, web views, and other scrollable containers.

```javascript
// Scroll an element
function scrollElement(appName, target, direction, amount) {
    try {
        if (!direction || (direction !== "up" && direction !== "down" && 
                          direction !== "left" && direction !== "right")) {
            return {
                success: false,
                error: "Direction must be 'up', 'down', 'left', or 'right'"
            };
        }
        
        const scrollAmount = amount || 1; // Default to 1 if not specified
        
        // Activate the application
        const app = Application(appName);
        app.activate();
        delay(0.5);
        
        // Get System Events process for UI interaction
        const systemEvents = Application("System Events");
        const process = systemEvents.processes[appName];
        
        if (!process.exists()) {
            return {
                success: false,
                error: `Process ${appName} not found`
            };
        }
        
        // Find the target element
        const element = findUIElement(process, target);
        
        if (!element) {
            return {
                success: false,
                error: "Target element not found"
            };
        }
        
        // Check if the element is a scroll area or contained in one
        let scrollArea = null;
        
        if (element.role && element.role() === "AXScrollArea") {
            scrollArea = element;
        } else {
            // Try to find a parent scroll area
            try {
                scrollArea = findUIElement(process, {
                    role: "AXScrollArea",
                    containingElement: element
                });
            } catch (e) {
                // If we can't find a specific scroll area, we'll scroll the element directly
                scrollArea = element;
            }
        }
        
        if (!scrollArea) {
            return {
                success: false,
                error: "No scrollable area found"
            };
        }
        
        // Scroll the element
        try {
            // Click the scroll area to make sure it has focus
            scrollArea.click();
            delay(0.2);
            
            // Use keyboard shortcuts to scroll
            if (direction === "up") {
                for (let i = 0; i < scrollAmount; i++) {
                    systemEvents.keyCode(126); // Up arrow
                    delay(0.1);
                }
            } else if (direction === "down") {
                for (let i = 0; i < scrollAmount; i++) {
                    systemEvents.keyCode(125); // Down arrow
                    delay(0.1);
                }
            } else if (direction === "left") {
                for (let i = 0; i < scrollAmount; i++) {
                    systemEvents.keyCode(123); // Left arrow
                    delay(0.1);
                }
            } else if (direction === "right") {
                for (let i = 0; i < scrollAmount; i++) {
                    systemEvents.keyCode(124); // Right arrow
                    delay(0.1);
                }
            }
            
            return {
                success: true,
                message: `Scrolled ${direction} ${scrollAmount} times`
            };
        } catch (e) {
            return {
                success: false,
                error: `Error scrolling: ${e.message}`
            };
        }
    } catch (error) {
        return {
            success: false,
            error: `Error scrolling element: ${error.message}`
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "scrollElement"
- `appName`: The name of the application to target
- `target`: Object specifying the element to scroll (see Target Specification in the Base documentation)
- `direction`: The direction to scroll ("up", "down", "left", or "right")
- `amount`: The number of scroll actions to perform (default: 1)

## Example Usage

Here's an example of how to use the `scrollElement` function to scroll down in a Finder list view:

```json
{
  "action": "scrollElement",
  "appName": "Finder",
  "target": {
    "role": "AXScrollArea"
  },
  "direction": "down",
  "amount": 3
}
```

You can scroll in any direction and specify the amount of scrolling:

```json
{
  "action": "scrollElement",
  "appName": "Safari",
  "target": {
    "role": "AXWebArea"
  },
  "direction": "up",
  "amount": 5
}
```

This function is particularly useful for navigating through long content areas, lists, or web pages in your automation workflows.