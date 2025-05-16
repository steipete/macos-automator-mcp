---
title: 'JXA: System Events and UI Control'
category: 03_jxa_core
id: jxa_system_events_ui_control
description: >-
  Demonstrates how to control UI elements, send keystrokes, and interact with
  menu items using JXA and System Events.
keywords:
  - jxa
  - javascript
  - system events
  - ui automation
  - keystroke
  - menu control
  - ui scripting
language: javascript
notes: >-
  Requires accessibility permissions to be granted to Script Editor or Terminal.
  Use with caution as UI structures may change across macOS versions.
---

```javascript
// Basic System Events setup
const systemEvents = Application('System Events');

// Activate app before sending input
function activateApp(appName) {
  const app = Application(appName);
  app.activate();
  delay(0.2); // Small delay to ensure app is ready
  return app;
}

// EXAMPLE 1: Sending basic keystrokes to an application
function sendKeystrokes() {
  // Activate TextEdit
  activateApp('TextEdit');
  
  // Type text
  systemEvents.keystroke('Hello from JXA!');
  
  // Press Enter/Return (keycode 36)
  systemEvents.keyCode(36);
  
  // Special key combinations
  systemEvents.keystroke('a', {using: 'command down'}); // Select all (Cmd+A)
  systemEvents.keystroke('c', {using: 'command down'}); // Copy (Cmd+C)
  
  // Multiple modifier keys
  systemEvents.keystroke(' ', {using: ['option down', 'command down']}); // Opt+Cmd+Space
}

// EXAMPLE 2: Working with application menus
function accessApplicationMenus(appName) {
  // Activate target app
  activateApp(appName);
  
  // Get process by name
  const process = systemEvents.processes.byName(appName);
  
  // Access menu structure (menu bar -> menu -> menu items)
  const fileMenu = process.menuBars[0].menuBarItems.byName('File');
  
  // Click a menu item
  fileMenu.click();
  delay(0.2); // Wait for menu to appear
  
  // Find and click a submenu item
  const menuItems = fileMenu.menus[0].menuItems();
  for (let i = 0; i < menuItems.length; i++) {
    const item = menuItems[i];
    // Check if enabled and matches name pattern
    if (item.enabled() && item.name().includes('New')) {
      item.click();
      break;
    }
  }
}

// EXAMPLE 3: Working with UI elements and windows
function controlUIElements() {
  // Activate System Preferences
  activateApp('System Preferences');
  
  const sysPref = systemEvents.processes.byName('System Preferences');
  
  // Click a button by its accessibility description
  const buttons = sysPref.windows[0].buttons();
  for (let i = 0; i < buttons.length; i++) {
    if (buttons[i].description() === 'Search') {
      buttons[i].click();
      break;
    }
  }
  
  // Type in a search field
  delay(0.5);
  systemEvents.keystroke('display');
  delay(1);
  
  // Press Escape to clear search
  systemEvents.keyCode(53);
}

// EXAMPLE 4: Control screen saver and system functions
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

// Call one of the examples
// sendKeystrokes();
// accessApplicationMenus('TextEdit');
// controlUIElements();
// controlSystem();

"System Events UI control examples completed.";
```
