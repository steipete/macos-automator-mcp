---
title: JXA UI Window Information
category: 03_jxa_core
id: jxa_ui_window_info
description: >-
  Get information about application windows using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - window
  - accessibility
  - size
  - position
  - title
  - info
---

# JXA UI Window Information

This script provides functionality to get detailed information about the windows of macOS applications using JavaScript for Automation (JXA).

## Usage

The function can be used to retrieve information such as window names, titles, positions, and sizes.

```javascript
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
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "getWindowInfo"
- `appName`: The name of the application to get window information for

## Example Usage

Here's an example of how to use the `getWindowInformation` function:

```json
{
  "action": "getWindowInfo",
  "appName": "Safari"
}
```

The function will return information about all windows for the specified application, including:

- `index`: The window index (0-based)
- `name`: The window name (if available)
- `title`: The window title (if available)
- `position`: The window's position [x, y] on screen
- `size`: The window's size [width, height]
- `isMainWindow`: Whether this is the application's main window

This information can be useful for positioning windows, finding specific windows for automation, or simply gathering information about the current state of an application.