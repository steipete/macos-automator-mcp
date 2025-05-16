---
title: JXA UI Find Element
category: 03_jxa_core
id: jxa_ui_find_element
description: >-
  Helper function for finding UI elements in macOS applications by various criteria using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - find
  - search
  - element
  - locate
  - criteria
---

# JXA UI Find Element

This script provides a helper function for finding UI elements in macOS applications using JavaScript for Automation (JXA). It supports various search criteria to locate specific elements in the UI hierarchy.

## Usage

The function is used by other UI automation scripts to find elements based on various criteria.

```javascript
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
```

## Element Search Criteria

The function supports a wide range of criteria for finding UI elements:

1. **Window selection**:
   - `windowIndex`: Index of the window to search in
   - `windowName`: Name of the window to search in

2. **Element type and property**:
   - `uiType`: Type of UI element (e.g., "buttons", "textFields")
   - `property`: Property name to match
   - `value`: Value to match against the property

3. **Element properties**:
   - `name`: Name of the element
   - `role`: Accessibility role of the element (e.g., "AXButton", "AXTextField")
   - `description`: Description of the element
   - `title`: Title of the element
   - `text`: Text content of the element

4. **Element by index**:
   - `elementType`: Type of element to select by index
   - `index`: Index of the element within its type

5. **Element by position**:
   - `position`: [x, y] coordinates of the element
   - `positionTolerance`: Tolerance for position matching (default: 5 pixels)

## Example Usage

This function is used internally by other UI automation functions. Here's how criteria can be structured:

```javascript
// Find a button by name
const buttonCriteria = {
    uiType: "buttons",
    property: "name",
    value: "OK"
};

// Find a text field in a specific window
const textFieldCriteria = {
    windowName: "Preferences",
    elementType: "textFields",
    index: 0
};

// Find an element by position
const positionCriteria = {
    position: [500, 300],
    positionTolerance: 10
};

// Find an element by role and name
const accessibilityCriteria = {
    role: "AXButton",
    name: "Cancel"
};
```

This helper function provides a robust way to find UI elements across different applications and interface designs.