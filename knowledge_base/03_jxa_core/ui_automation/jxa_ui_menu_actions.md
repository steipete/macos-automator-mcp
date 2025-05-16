---
title: JXA UI Menu Actions
category: 03_jxa_core
id: jxa_ui_menu_actions
description: >-
  Perform menu actions in macOS applications using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - automation
  - ui
  - menu
  - menubar
  - click
  - command
  - interaction
---

# JXA UI Menu Actions

This script provides functionality to perform menu actions in macOS applications using JavaScript for Automation (JXA). It allows you to automate menu selections as if you were clicking through the menu bar.

## Usage

The function can be used to perform menu actions by specifying the path of menu items to click.

```javascript
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
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `action`: Must be "performMenuAction"
- `appName`: The name of the application to target
- `menuItems`: Array of menu item names representing the path in the menu hierarchy

## Example Usage

Here's an example of how to use the `performMenuAction` function to create a new window in Safari:

```json
{
  "action": "performMenuAction",
  "appName": "Safari",
  "menuItems": ["File", "New Window"]
}
```

You can perform multi-level menu actions by adding more items to the array:

```json
{
  "action": "performMenuAction",
  "appName": "Safari",
  "menuItems": ["View", "Show", "Favorites Bar"]
}
```

The function attempts two different approaches to perform the menu action, making it more robust against different application behaviors: