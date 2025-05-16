---
title: 'JXA System Functions Control'
category: 03_jxa_core
id: jxa_system_functions_control
description: Controlling system-wide functionality like screen saver and menu bar using JXA
keywords:
  - jxa
  - javascript
  - system events
  - screen saver
  - menu bar
  - system functions
  - system preferences
language: javascript
---

# JXA System Functions Control

This script demonstrates how to control system-wide functionality such as the screen saver and menu bar using JavaScript for Automation and System Events.

## Prerequisites

You need to grant accessibility permissions to your script's host application (Script Editor, Terminal, etc.) in System Settings → Privacy & Security → Accessibility.

```javascript
// Basic System Events setup
const systemEvents = Application('System Events');

// Include standard additions for additional functionality
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## System Functions Control

```javascript
function controlSystem() {
  // Start the screen saver
  systemEvents.startScreenSaver();
  
  // Toggle menu bar visibility (macOS Dock preferences)
  const menuHidden = systemEvents.dockPreferences.autohideMenuBar();
  systemEvents.dockPreferences.autohideMenuBar = !menuHidden;
  
  // Get current date and time from system
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  const now = app.currentDate();
  
  app.displayDialog("Current time: " + now.toString());
}
```

## System Control Techniques

The script demonstrates the following system control techniques:

1. Starting the screen saver
2. Toggling menu bar visibility
3. Getting system date and time

## Common System Functions

### Screen Saver Control

```javascript
// Start the screen saver
systemEvents.startScreenSaver();

// Stop the screen saver (using keyCode)
systemEvents.keyCode(53); // Escape key
```

### Dock Preferences

```javascript
// Get current Dock settings
const dockPrefs = systemEvents.dockPreferences;

// Check if auto-hide is enabled
const isAutoHide = dockPrefs.autohide();

// Enable/disable auto-hide
dockPrefs.autohide = true; // Enable auto-hide

// Check menu bar auto-hide status
const isMenuBarHidden = dockPrefs.autohideMenuBar();

// Toggle menu bar auto-hide
dockPrefs.autohideMenuBar = !isMenuBarHidden;

// Get Dock size
const dockSize = dockPrefs.dockSize();

// Set Dock size (values typically range from 0.0 to 1.0)
dockPrefs.dockSize = 0.5;
```

### Display and Sleep Control

With additional privileges, you can control displays and sleep settings:

```javascript
// Put display to sleep (using shell command)
app.doShellScript('pmset displaysleepnow');

// Put system to sleep
app.doShellScript('pmset sleepnow');

// Prevent sleep temporarily
app.doShellScript('caffeinate -d -t 3600'); // Prevent sleep for 1 hour
```

### System Information

```javascript
// Get system date and time
const now = app.currentDate();

// Get system version (using shell command)
const osVersion = app.doShellScript('sw_vers -productVersion');

// Get computer name
const computerName = systemEvents.properties().computerName;

// Get current user
const currentUser = systemEvents.currentUser.name();
```

## Important Considerations

- System control functions may require elevated permissions
- Some functions may behave differently across macOS versions
- Be cautious when modifying system settings that affect user experience
- Consider using shell commands via `doShellScript()` for advanced system control
- Handle errors gracefully when system functions are restricted
- Some operations may require administrator privileges