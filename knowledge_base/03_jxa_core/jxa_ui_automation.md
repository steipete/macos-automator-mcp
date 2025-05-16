---
title: JXA UI Automation
category: 10_jxa_basics
id: jxa_ui_automation
description: Comprehensive UI automation using JavaScript for Automation (JXA) to interact with macOS applications, control UI elements, and perform accessibility-based interactions.
language: javascript
keywords: [jxa, javascript, automation, ui, accessibility, systemevents, click, button, interaction, form]
---

# JXA UI Automation

This script provides comprehensive UI automation capabilities using JavaScript for Automation (JXA). It leverages the macOS Accessibility framework to interact with UI elements across applications, offering more powerful control than traditional AppleScript.

## Usage

The script can be used to perform various UI automation tasks across macOS applications.

```javascript
// JXA UI Automation
// Advanced UI automation using JavaScript for Automation and Accessibility APIs

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

// Get information about application windows
function getWindowInformation(appName) {
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
        
        // Get information about all windows
        const windowInfo = [];
        const windows = process.windows;
        
        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            windowInfo.push({
                index: i,
                name: window.name ? window.name() : null,
                title: window.title ? window.title() : null,
                position: window.position ? window.position() : null,
                size: window.size ? window.size() : null,
                isMainWindow: window.attributes["AXMain"] ? window.attributes["AXMain"].value() : false
            });
        }
        
        return {
            success: true,
            windows: windowInfo,
            message: `Retrieved window information for ${appName}`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error getting window information: ${error.message}`
        };
    }
}

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

// Perform a menu action
function performMenuAction(appName, menuItems) {
    try {
        if (!Array.isArray(menuItems) || menuItems.length === 0) {
            return {
                success: false,
                error: "Menu items must be provided as a non-empty array"
            };
        }
        
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
        
        // Build the menu path
        let menuPath = "menu bar 1";
        for (let i = 0; i < menuItems.length; i++) {
            const menuItem = menuItems[i];
            menuPath += `->menu "${menuItem}"`;
            if (i < menuItems.length - 1) {
                menuPath += "->menu item";
            } else {
                menuPath += "->menu item";
            }
        }
        
        // Try to click the menu item
        try {
            const itemRef = process[menuPath];
            if (itemRef.exists()) {
                itemRef.click();
                return {
                    success: true,
                    message: `Performed menu action: ${menuItems.join(' -> ')}`
                };
            } else {
                return {
                    success: false,
                    error: "Menu item not found"
                };
            }
        } catch (e) {
            // If the specific path fails, try plan B: manually navigating menus
            try {
                // Click on the top-level menu
                const topMenu = process.menuBars[0].menuBarItems[menuItems[0]];
                topMenu.click();
                delay(0.3);
                
                // Navigate through submenus
                let currentMenu = topMenu.menus[0];
                for (let i = 1; i < menuItems.length; i++) {
                    const menuItemName = menuItems[i];
                    const menuItemRef = currentMenu.menuItems[menuItemName];
                    
                    if (i === menuItems.length - 1) {
                        // Click the final menu item
                        menuItemRef.click();
                    } else {
                        // Navigate to the next submenu
                        menuItemRef.click();
                        delay(0.3);
                        currentMenu = menuItemRef.menus[0];
                    }
                }
                
                return {
                    success: true,
                    message: `Performed menu action: ${menuItems.join(' -> ')}`
                };
            } catch (e2) {
                return {
                    success: false,
                    error: `Menu action failed: ${e2.message}`
                };
            }
        }
    } catch (error) {
        return {
            success: false,
            error: `Error performing menu action: ${error.message}`
        };
    }
}

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

// Drag and drop operation
function dragAndDrop(appName, source, destination) {
    try {
        if (!source || !destination) {
            return {
                success: false,
                error: "Source and destination targets are required"
            };
        }
        
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
        
        // Find the source and destination elements
        const sourceElement = findUIElement(process, source);
        if (!sourceElement) {
            return {
                success: false,
                error: "Source element not found"
            };
        }
        
        const destElement = findUIElement(process, destination);
        if (!destElement) {
            return {
                success: false,
                error: "Destination element not found"
            };
        }
        
        // Get the positions of the elements
        const sourcePosition = sourceElement.position();
        const destPosition = destElement.position();
        
        // Get the size of the elements
        const sourceSize = sourceElement.size();
        
        // Calculate the center points
        const sourceX = sourcePosition[0] + (sourceSize[0] / 2);
        const sourceY = sourcePosition[1] + (sourceSize[1] / 2);
        const destX = destPosition[0] + (destElement.size()[0] / 2);
        const destY = destPosition[1] + (destElement.size()[1] / 2);
        
        // Perform the drag and drop
        systemEvents.mouseMove({x: sourceX, y: sourceY});
        delay(0.2);
        systemEvents.mouseDown();
        delay(0.3);
        
        // Move to destination in steps
        const steps = 5;
        for (let i = 1; i <= steps; i++) {
            const x = sourceX + ((destX - sourceX) * (i / steps));
            const y = sourceY + ((destY - sourceY) * (i / steps));
            systemEvents.mouseMove({x: x, y: y});
            delay(0.1);
        }
        
        delay(0.2);
        systemEvents.mouseUp();
        
        return {
            success: true,
            message: "Drag and drop operation completed"
        };
    } catch (error) {
        return {
            success: false,
            error: `Error performing drag and drop: ${error.message}`
        };
    }
}

// Helper function to find a UI element based on criteria
function findUIElement(process, criteria) {
    try {
        if (!criteria || Object.keys(criteria).length === 0) {
            return null;
        }
        
        // Start with either a window or the process itself
        let startElement = process;
        if (criteria.windowIndex !== undefined) {
            const windowIndex = criteria.windowIndex;
            if (process.windows.length <= windowIndex) {
                return null;
            }
            startElement = process.windows[windowIndex];
        } else if (criteria.windowName) {
            let found = false;
            for (let i = 0; i < process.windows.length; i++) {
                const window = process.windows[i];
                const windowName = window.name ? window.name() : null;
                if (windowName && windowName.includes(criteria.windowName)) {
                    startElement = window;
                    found = true;
                    break;
                }
            }
            if (!found) return null;
        }
        
        // Search based on the criteria
        let element = null;
        
        // By UI element type and property
        if (criteria.uiType && criteria.property && criteria.value) {
            try {
                // Check if the type exists on the start element
                if (startElement[criteria.uiType]) {
                    const elements = startElement[criteria.uiType];
                    const property = criteria.property;
                    const value = criteria.value;
                    
                    // Find the first matching element
                    for (let i = 0; i < elements.length; i++) {
                        const el = elements[i];
                        try {
                            if (el[property] && el[property]() === value) {
                                element = el;
                                break;
                            }
                        } catch (e) {
                            // Skip elements that error when checking property
                        }
                    }
                }
            } catch (e) {
                // If this approach fails, continue to other methods
            }
        }
        
        // By name
        if (!element && criteria.name) {
            try {
                const uiElements = startElement.uiElements;
                for (let i = 0; i < uiElements.length; i++) {
                    const el = uiElements[i];
                    if (el.name && el.name() === criteria.name) {
                        element = el;
                        break;
                    }
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By exact role and name combination
        if (!element && criteria.role && criteria.name) {
            try {
                const uiElements = startElement.uiElements;
                for (let i = 0; i < uiElements.length; i++) {
                    const el = uiElements[i];
                    if (el.role && el.role() === criteria.role && 
                        el.name && el.name() === criteria.name) {
                        element = el;
                        break;
                    }
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By description (more flexible matching)
        if (!element && criteria.description) {
            try {
                // Search for UI elements matching the description
                const matchingDesc = startElement.uiElements.whose({
                    description: criteria.description
                });
                
                if (matchingDesc.length > 0) {
                    element = matchingDesc[0];
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By title (for windows, buttons, etc.)
        if (!element && criteria.title) {
            try {
                // Try to find elements with the given title
                const elementsWithTitle = [];
                
                // Check different types of elements that might have titles
                const typesToCheck = ["buttons", "checkboxes", "comboBoxes", "groups", 
                                     "menuButtons", "popUpButtons", "radioButtons", 
                                     "tabGroups", "textFields", "UI elements"];
                
                for (const type of typesToCheck) {
                    try {
                        const elements = startElement[type];
                        for (let i = 0; i < elements.length; i++) {
                            const el = elements[i];
                            if (el.title && el.title() === criteria.title) {
                                elementsWithTitle.push(el);
                            }
                        }
                    } catch (e) {
                        // Skip types that aren't available
                    }
                }
                
                if (elementsWithTitle.length > 0) {
                    element = elementsWithTitle[0];
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By text content (for static text, text fields, etc.)
        if (!element && criteria.text) {
            try {
                // Look for static text elements with matching content
                const staticTexts = startElement.staticTexts;
                for (let i = 0; i < staticTexts.length; i++) {
                    const text = staticTexts[i];
                    if (text.value && text.value() === criteria.text) {
                        element = text;
                        break;
                    }
                }
                
                // If not found in static text, try text fields
                if (!element) {
                    const textFields = startElement.textFields;
                    for (let i = 0; i < textFields.length; i++) {
                        const field = textFields[i];
                        if (field.value && field.value() === criteria.text) {
                            element = field;
                            break;
                        }
                    }
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By index of specific UI element type
        if (!element && criteria.elementType && criteria.index !== undefined) {
            try {
                const elementType = criteria.elementType;
                const index = criteria.index;
                
                if (startElement[elementType] && startElement[elementType].length > index) {
                    element = startElement[elementType][index];
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        // By position (approximate)
        if (!element && criteria.position) {
            try {
                const targetX = criteria.position[0];
                const targetY = criteria.position[1];
                const tolerance = criteria.positionTolerance || 5;
                
                // Get all UI elements
                const allElements = startElement.uiElements();
                let closestElement = null;
                let closestDistance = Infinity;
                
                // Find the element closest to the target position
                for (let i = 0; i < allElements.length; i++) {
                    const el = allElements[i];
                    try {
                        if (el.position && el.size) {
                            const pos = el.position();
                            const size = el.size();
                            
                            // Check if the point is within the element's bounds (with tolerance)
                            if (targetX >= pos[0] - tolerance && 
                                targetX <= pos[0] + size[0] + tolerance &&
                                targetY >= pos[1] - tolerance && 
                                targetY <= pos[1] + size[1] + tolerance) {
                                
                                // Calculate distance to element center
                                const centerX = pos[0] + (size[0] / 2);
                                const centerY = pos[1] + (size[1] / 2);
                                const distance = Math.sqrt(
                                    Math.pow(targetX - centerX, 2) + 
                                    Math.pow(targetY - centerY, 2)
                                );
                                
                                if (distance < closestDistance) {
                                    closestDistance = distance;
                                    closestElement = el;
                                }
                            }
                        }
                    } catch (e) {
                        // Skip elements that cause errors
                    }
                }
                
                if (closestElement) {
                    element = closestElement;
                }
            } catch (e) {
                // Continue to next method
            }
        }
        
        return element;
    } catch (error) {
        console.log(`Error finding UI element: ${error.message}`);
        return null;
    }
}

// Utility function to create a delay
function delay(seconds) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.delay(seconds);
}
```

## Example Input Parameters

When using with MCP, you can provide these parameters based on the action:

### Common Parameters for All Actions
- `action`: The action to perform (required)
- `appName`: The name of the application to target (required)
- `wait`: Seconds to wait after activating the application (default: 1)

### Target Specification
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

### Action-Specific Parameters
- `click` action: Requires `target`
- `getValue` action: Requires `target`
- `setValue` action: Requires `target` and `value`
- `getWindowInfo` action: Requires only `appName`
- `getUIHierarchy` action: Requires `appName`, optional `target`
- `performMenuAction` action: Requires `menuItems` (array of menu items)
- `waitForElement` action: Requires `target`, optional `timeout` (seconds)
- `scrollElement` action: Requires `target`, `direction` (up/down/left/right), optional `amount`
- `dragAndDrop` action: Requires `target` (source) and `destination`

## Example Usage

### Click a button by name

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

### Get the value of a text field

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

### Set text in a search field

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

### Perform a menu action

```json
{
  "action": "performMenuAction",
  "appName": "Safari",
  "menuItems": ["File", "New Window"]
}
```

### Wait for an element to appear

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

### Scroll a list view

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

### Drag and drop operation

```json
{
  "action": "dragAndDrop",
  "appName": "Finder",
  "target": {
    "name": "document.pdf"
  },
  "destination": {
    "name": "Documents"
  }
}
```

## Accessibility Requirements

Note that UI automation requires appropriate accessibility permissions for your application:

1. Go to System Settings > Privacy & Security > Accessibility
2. Enable your script execution environment (e.g., Script Editor, Terminal)

This script integrates deeply with macOS's accessibility features to provide robust UI automation capabilities beyond what traditional AppleScript can offer.