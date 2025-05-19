---
title: 'JXA Application Menu Control'
category: 03_jxa_core
id: jxa_application_menu_control
description: Working with application menus and menu items using JXA
keywords:
  - jxa
  - javascript
  - system events
  - menu bar
  - menu items
  - application menus
  - ui automation
language: javascript
---

# JXA Application Menu Control

This script demonstrates how to work with application menus and menu items using JavaScript for Automation and System Events.

## Prerequisites

You need to grant accessibility permissions to your script's host application (Script Editor, Terminal, etc.) in System Settings → Privacy & Security → Accessibility.

```javascript
// Basic System Events setup
const systemEvents = Application('System Events');

// Activate app before accessing menus
function activateApp(appName) {
  const app = Application(appName);
  app.activate();
  delay(0.2); // Small delay to ensure app is ready
  return app;
}
```

## Working with Application Menus

```javascript
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
```

## Menu Navigation Techniques

The script demonstrates the following menu control techniques:

1. Activating an application before accessing its menus
2. Getting a reference to the application process
3. Accessing the menu bar and specific menu items
4. Opening menus and submenus
5. Checking if menu items are enabled
6. Clicking specific menu items

## Menu Hierarchy in System Events

System Events represents menus in the following hierarchy:

```
process
  └── menuBar
       └── menuBarItem (e.g., "File", "Edit", "View")
            └── menu
                 └── menuItem (e.g., "New", "Open", "Save")
                      └── menu (if submenu exists)
                           └── menuItem (submenu items)
```

## Common Menu Access Methods

### Access a Main Menu Item

```javascript
// Get a reference to the File menu
const fileMenu = process.menuBars[0].menuBarItems.byName('File');
```

### Get All Menu Items in a Menu

```javascript
// Get all items in the File menu
const fileMenuItems = process.menuBars[0].menuBarItems.byName('File').menus[0].menuItems();
```

### Click a Specific Menu Item

```javascript
// Click the "Save" item in the File menu
process.menuBars[0].menuBarItems.byName('File').menus[0].menuItems.byName('Save').click();
```

### Check if a Menu Item is Enabled

```javascript
// Check if the "Save" menu item is enabled
const isSaveEnabled = process.menuBars[0].menuBarItems.byName('File').menus[0].menuItems.byName('Save').enabled();
```

### Access a Submenu Item

```javascript
// Access "Export As" submenu in the File menu
const exportMenu = process.menuBars[0].menuBarItems.byName('File').menus[0].menuItems.byName('Export As').menus[0];
// Click "PDF" in the Export submenu
exportMenu.menuItems.byName('PDF').click();
```

## Important Considerations

- Menu item names may change based on the application's localization
- Menu structures can vary across different versions of the same application
- Add appropriate delays when interacting with menus to allow time for them to appear
- Handle cases where menu items may be disabled
- Use partial name matching with `includes()` for more resilient scripts