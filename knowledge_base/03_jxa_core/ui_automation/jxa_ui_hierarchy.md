---
title: JXA UI Element Hierarchy
category: 03_jxa_core
id: jxa_ui_hierarchy
description: >-
  Explore the UI element hierarchy of macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - hierarchy
  - structure
  - elements
  - exploration
---

# JXA UI Element Hierarchy

This script provides functionality to explore the UI element hierarchy of macOS applications using JavaScript for Automation (JXA). This is valuable for understanding an application's structure for automation purposes.

## Usage

The functions can be used to get a hierarchical view of UI elements starting from a specific element or window.

```javascript
// Get a hierarchical view of UI elements
function getUIElementHierarchy(appName, startingPoint) {
    try {
        // Get System Events process for UI interaction
        const systemEvents = Application("System Events");
        const process = systemEvents.processes[appName];
        
        if (!process.exists()) {
            return {
                success: false,
                error: `Process ${appName} not found`
            };
        }
        
        // Determine the starting element for hierarchy exploration
        let startElement;
        
        if (Object.keys(startingPoint).length === 0) {
            // If no starting point specified, use the front window
            if (process.windows.length > 0) {
                startElement = process.windows[0];
            } else {
                return {
                    success: false,
                    error: "No windows found in application"
                };
            }
        } else {
            // Find the specific starting element
            startElement = findUIElement(process, startingPoint);
            
            if (!startElement) {
                return {
                    success: false,
                    error: "Starting element not found"
                };
            }
        }
        
        // Get the UI hierarchy starting from the element
        const hierarchy = exploreUIHierarchy(startElement, 0, 3); // Limit depth to 3 levels
        
        return {
            success: true,
            hierarchy: hierarchy,
            message: `Retrieved UI hierarchy for ${appName}`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error getting UI hierarchy: ${error.message}`
        };
    }
}

// Helper function to explore UI hierarchy recursively
function exploreUIHierarchy(element, currentDepth, maxDepth) {
    if (currentDepth > maxDepth) {
        return { 
            description: "...(further elements omitted for brevity)..." 
        };
    }
    
    try {
        const result = {};
        
        // Get basic element properties
        if (element.role) result.role = element.role();
        if (element.name) result.name = element.name();
        if (element.title) result.title = element.title();
        if (element.description) result.description = element.description();
        if (element.value !== undefined) {
            try {
                result.value = element.value();
            } catch (e) {
                // Some elements throw errors when accessing value
            }
        }
        
        // Get element position and size
        if (element.position) result.position = element.position();
        if (element.size) result.size = element.size();
        
        // Get accessibility attributes
        const attributes = {};
        try {
            if (element.attributes) {
                const attrNames = element.attributeNames();
                for (let i = 0; i < attrNames.length; i++) {
                    const attrName = attrNames[i];
                    try {
                        const attr = element.attributes[attrName];
                        if (attr && attr.value) {
                            attributes[attrName] = attr.value();
                        }
                    } catch (e) {
                        // Some attributes throw errors when accessing
                    }
                }
            }
        } catch (e) {
            // Ignore errors in attribute collection
        }
        
        if (Object.keys(attributes).length > 0) {
            result.attributes = attributes;
        }
        
        // Explore children recursively
        const children = [];
        try {
            // Different types of UI elements have different child element types
            const childTypes = [
                "buttons", "checkboxes", "comboBoxes", "groups", "images",
                "menus", "menuButtons", "menuItems", "popUpButtons", 
                "radioButtons", "radioGroups", "scrollAreas", "sliders",
                "splitters", "staticTexts", "tabGroups", "tables", "textAreas",
                "textFields", "toolbars", "UI elements"
            ];
            
            for (const type of childTypes) {
                try {
                    const elements = element[type];
                    if (elements && elements.length > 0) {
                        for (let i = 0; i < Math.min(elements.length, 5); i++) { // Limit to 5 children per type
                            const childElement = elements[i];
                            const childInfo = exploreUIHierarchy(childElement, currentDepth + 1, maxDepth);
                            if (Object.keys(childInfo).length > 0) {
                                children.push(childInfo);
                            }
                        }
                        
                        if (elements.length > 5) {
                            children.push({
                                description: `...${elements.length - 5} more ${type}...`
                            });
                        }
                    }
                } catch (e) {
                    // Skip if this type causes an error
                }
            }
        } catch (e) {
            // Ignore errors in child exploration
        }
        
        if (children.length > 0) {
            result.children = children;
        }
        
        return result;
    } catch (e) {
        return { 
            error: `Error exploring element: ${e.message}` 
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "getUIHierarchy"
- `appName`: The name of the application to explore
- `target`: (Optional) Object specifying the starting element for hierarchy exploration (see Target Specification in the Base documentation)

## Example Usage

Here's an example of how to use the `getUIElementHierarchy` function to explore the hierarchy of the frontmost Safari window:

```json
{
  "action": "getUIHierarchy",
  "appName": "Safari"
}
```

To explore the hierarchy starting from a specific UI element:

```json
{
  "action": "getUIHierarchy",
  "appName": "Safari",
  "target": {
    "role": "AXButton",
    "name": "Back"
  }
}
```

The function returns a hierarchical structure of UI elements, their properties, and their children, helping you understand the application's UI structure for automation purposes.