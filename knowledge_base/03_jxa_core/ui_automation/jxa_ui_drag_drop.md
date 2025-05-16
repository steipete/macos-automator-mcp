---
title: JXA UI Drag and Drop
category: 03_jxa_core
id: jxa_ui_drag_drop
description: >-
  Perform drag and drop operations in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - accessibility
  - drag
  - drop
  - move
  - mouse
  - interaction
---

# JXA UI Drag and Drop

This script provides functionality to perform drag and drop operations in macOS applications using JavaScript for Automation (JXA). It allows you to programmatically drag elements from one location to another.

## Usage

The function can be used to drag files, folders, text selections, and other draggable elements.

```javascript
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
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "dragAndDrop"
- `appName`: The name of the application to target
- `target`: Object specifying the source element to drag (see Target Specification in the Base documentation)
- `destination`: Object specifying the destination element to drop onto

## Example Usage

Here's an example of how to use the `dragAndDrop` function to drag a file to a folder in Finder:

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

You can also use this for dragging UI elements in other applications:

```json
{
  "action": "dragAndDrop",
  "appName": "Photos",
  "target": {
    "role": "AXImage",
    "index": 0
  },
  "destination": {
    "name": "My Album"
  }
}
```

This function simulates actual mouse movements and button presses, moving the mouse smoothly from the source to the destination location. It's particularly useful for operations that require drag and drop interactions, such as file organization, rearranging items, or moving content between applications.