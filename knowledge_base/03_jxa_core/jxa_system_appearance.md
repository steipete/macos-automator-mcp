---
id: jxa_system_appearance
title: Toggle System Appearance with JXA
description: Use JavaScript for Automation to switch between Light and Dark mode
language: javascript
keywords: ["dark mode", "light mode", "appearance", "theme", "system preferences"]
---

# Toggle System Appearance with JXA

JavaScript for Automation (JXA) can be used to toggle the macOS appearance between Light and Dark modes. This script works on macOS Mojave (10.14) and later.

## Basic Dark Mode Toggle

This script toggles between Light and Dark modes:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use System Events to access the appearance preferences
const systemEvents = Application("System Events");
const appearancePrefs = systemEvents.appearancePreferences();

// Toggle the dark mode setting
appearancePrefs.darkMode = !appearancePrefs.darkMode();

// Display which mode was set
const newMode = appearancePrefs.darkMode() ? "Dark" : "Light";
app.displayNotification(`Appearance switched to ${newMode} Mode`, {
    withTitle: "System Appearance"
});
```

## Check Current Appearance Mode

To check the current system appearance without changing it:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;
const systemEvents = Application("System Events");

// Get current appearance setting
const isDarkMode = systemEvents.appearancePreferences.darkMode();
const currentMode = isDarkMode ? "Dark" : "Light";

// Display the result
console.log(`Current appearance: ${currentMode} Mode`);
```

## Schedule Appearance Change Based on Time

This script sets the appearance mode based on the current time:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;
const systemEvents = Application("System Events");

// Get current hour (0-23)
const currentHour = new Date().getHours();

// Set dark mode in evening/night (after 7:00 PM or before 7:00 AM)
const shouldBeDarkMode = currentHour >= 19 || currentHour < 7;

// Only change if needed
const currentIsDarkMode = systemEvents.appearancePreferences.darkMode();
if (shouldBeDarkMode !== currentIsDarkMode) {
    systemEvents.appearancePreferences.darkMode = shouldBeDarkMode;
    
    // Display notification about the change
    const newMode = shouldBeDarkMode ? "Dark" : "Light";
    app.displayNotification(`Appearance automatically switched to ${newMode} Mode`, {
        withTitle: "System Appearance",
        subtitle: `Current time: ${new Date().toLocaleTimeString()}`
    });
}
```

## Toggle Appearance with Additional Settings

This more advanced script toggles appearance and also adjusts related system settings:

```javascript
function toggleAppearance() {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    const systemEvents = Application("System Events");
    
    // Toggle dark mode
    const isDarkMode = systemEvents.appearancePreferences.darkMode();
    const newMode = !isDarkMode;
    systemEvents.appearancePreferences.darkMode = newMode;
    
    // Optional: Also adjust desktop picture for each mode
    try {
        const desktop = systemEvents.desktops[0];
        if (newMode) {
            // Set dark mode desktop picture (replace with actual path)
            desktop.picture = "/Library/Desktop Pictures/Solar Gradients.heic";
        } else {
            // Set light mode desktop picture (replace with actual path)
            desktop.picture = "/Library/Desktop Pictures/Monterey Graphic.heic";
        }
    } catch (error) {
        console.log("Could not change desktop picture: " + error);
    }
    
    // Optional: Adjust other settings (True Tone, Night Shift, etc.)
    // These would require additional scripting or shell commands
    
    return newMode ? "Dark" : "Light";
}

// Execute the function and display the result
const app = Application.currentApplication();
app.includeStandardAdditions = true;
const newAppearance = toggleAppearance();

app.displayNotification(`Appearance switched to ${newAppearance} Mode`, {
    withTitle: "System Appearance",
    soundName: "Pop"
});
```

## Complete Appearance Management Tool

Here's a more complete script that offers multiple appearance management options:

```javascript
(() => {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    
    // Function to get/set appearance mode
    function manageAppearance(action) {
        const systemEvents = Application("System Events");
        const prefs = systemEvents.appearancePreferences;
        
        switch (action) {
            case "status":
                return prefs.darkMode() ? "dark" : "light";
                
            case "toggle":
                prefs.darkMode = !prefs.darkMode();
                return prefs.darkMode() ? "dark" : "light";
                
            case "dark":
                prefs.darkMode = true;
                return "dark";
                
            case "light":
                prefs.darkMode = false;
                return "light";
                
            default:
                throw new Error("Unknown action. Use: status, toggle, dark, or light");
        }
    }
    
    // Prompt user for action
    const actions = ["Check current status", "Toggle appearance", "Set to Dark Mode", "Set to Light Mode", "Set based on time"];
    const choice = app.chooseFromList(actions, {
        withPrompt: "Select an appearance management action:",
        defaultItems: ["Toggle appearance"],
        okButtonName: "Execute",
        cancelButtonName: "Cancel"
    });
    
    if (!choice) {
        return; // User cancelled
    }
    
    // Process the selected action
    let result;
    switch (choice[0]) {
        case "Check current status":
            result = manageAppearance("status");
            app.displayDialog(`Current appearance mode: ${result.toUpperCase()}`, {
                withTitle: "System Appearance",
                buttons: ["OK"],
                defaultButton: "OK"
            });
            break;
            
        case "Toggle appearance":
            result = manageAppearance("toggle");
            app.displayNotification(`Appearance switched to ${result.toUpperCase()} Mode`, {
                withTitle: "System Appearance"
            });
            break;
            
        case "Set to Dark Mode":
            result = manageAppearance("dark");
            app.displayNotification("Dark Mode enabled", {
                withTitle: "System Appearance"
            });
            break;
            
        case "Set to Light Mode":
            result = manageAppearance("light");
            app.displayNotification("Light Mode enabled", {
                withTitle: "System Appearance"
            });
            break;
            
        case "Set based on time":
            const hour = new Date().getHours();
            const setToDark = hour >= 19 || hour < 7; // Dark 7 PM - 7 AM
            result = manageAppearance(setToDark ? "dark" : "light");
            app.displayNotification(`Time-based appearance set to ${result.toUpperCase()} Mode`, {
                withTitle: "System Appearance",
                subtitle: `Based on current time: ${new Date().toLocaleTimeString()}`
            });
            break;
    }
})();
```

This script provides a complete appearance management tool with various options for controlling macOS Dark Mode, making it an excellent utility for both general use and specific workflows.