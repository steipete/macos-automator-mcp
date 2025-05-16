---
title: "Control macOS Appearance Settings with AppleScript"
description: "Change and manage macOS appearance settings including dark mode, accent colors, and highlight colors using AppleScript and UI scripting"
author: "Claude"
category: "02_system_interaction"
subcategory: "system_preferences_settings"
keywords: ["appearance", "dark mode", "accent color", "highlight color", "system settings", "ui scripting"]
language: "applescript"
version: "1.0"
validated: true
---

# Control macOS Appearance Settings with AppleScript

Modern macOS appearance settings like Dark Mode, accent colors, highlight colors, and sidebar icons can be controlled programmatically using AppleScript's UI scripting capabilities.

## Controlling Dark Mode

```applescript
tell application "System Settings"
  activate
  delay 1 -- Give time for the app to fully load
  
  -- Navigate to Appearance settings
  tell application "System Events"
    tell process "System Settings"
      -- Click on Appearance in the sidebar
      click button "Appearance" of scroll area 1 of group 1 of window 1
      
      -- Wait for the panel to load
      delay 0.5
      
      -- Here we toggle between "Light" and "Dark" using the radio buttons
      -- Find the radio buttons in the appearance section
      set appearanceOptions to radio buttons of radio group 1 of group 1 of scroll area 1 of group 1 of window 1
      
      -- Get the radio button names (could be "Light", "Dark", "Auto")
      set optionNames to name of appearanceOptions
      
      -- Toggle to Dark Mode
      click radio button "Dark" of radio group 1 of group 1 of scroll area 1 of group 1 of window 1
      
      -- Or toggle to Light Mode
      -- click radio button "Light" of radio group 1 of group 1 of scroll area 1 of group 1 of window 1
      
      -- Or set to Auto
      -- click radio button "Auto" of radio group 1 of group 1 of scroll area 1 of group 1 of window 1
      
      delay 0.5 -- Wait for the setting to apply
    end tell
  end tell
  
  quit
end tell
```

## Getting Current Dark Mode State via Shell Script

You can check the current dark mode state using `defaults` command:

```applescript
set isDarkMode to do shell script "defaults read -g AppleInterfaceStyle 2>/dev/null; exit 0"

if isDarkMode is "Dark" then
  display dialog "System is currently in Dark Mode"
else
  display dialog "System is currently in Light Mode"
end if
```

## Setting Accent and Highlight Colors

```applescript
tell application "System Settings"
  activate
  delay 1
  
  tell application "System Events"
    tell process "System Settings"
      -- Navigate to Appearance settings
      click button "Appearance" of scroll area 1 of group 1 of window 1
      delay 0.5
      
      -- Set accent color (options may include: Blue, Purple, Pink, Red, Orange, Yellow, Green, Graphite)
      -- Find the accent colors popup button
      set accentPopup to pop up button 1 of group 1 of scroll area 1 of group 1 of window 1
      click accentPopup
      delay 0.3
      
      -- Select a color from the menu
      click menu item "Blue" of menu 1 of accentPopup
      
      -- Set highlight color
      set highlightPopup to pop up button 2 of group 1 of scroll area 1 of group 1 of window 1
      click highlightPopup
      delay 0.3
      
      -- Select a highlight color
      click menu item "Blue" of menu 1 of highlightPopup
      
      delay 0.5
    end tell
  end tell
  
  quit
end tell
```

## Setting Show Scroll Bars Behavior

```applescript
tell application "System Settings"
  activate
  delay 1
  
  tell application "System Events"
    tell process "System Settings"
      -- Navigate to Appearance settings
      click button "Appearance" of scroll area 1 of group 1 of window 1
      delay 0.5
      
      -- Find the radio buttons for scroll bar appearance in the second radio group
      set scrollBarOptions to radio buttons of radio group 2 of group 1 of scroll area 1 of group 1 of window 1
      
      -- Options are typically: "Automatically based on mouse or trackpad", "When scrolling", "Always"
      click radio button "Always" of radio group 2 of group 1 of scroll area 1 of group 1 of window 1
      
      delay 0.5
    end tell
  end tell
  
  quit
end tell
```

## Error Handling

```applescript
try
  tell application "System Settings"
    activate
    delay 1
    
    tell application "System Events"
      tell process "System Settings"
        -- Navigate to Appearance settings
        click button "Appearance" of scroll area 1 of group 1 of window 1
        -- Rest of the code...
      end tell
    end tell
    
    quit
  end tell
on error errorMessage
  display dialog "Error changing appearance settings: " & errorMessage buttons {"OK"} default button "OK" with icon stop
end try
```

## Notes and Limitations

1. **UI Scripting Reliability**: These scripts rely on UI scripting, which is dependent on the exact UI layout of System Settings. Apple may change this layout in macOS updates, requiring script adjustments.

2. **Accessibility Permissions**: Your script must have accessibility permissions to control System Settings. Users will need to grant these in Security & Privacy preferences.

3. **System Version Differences**: The UI elements and their hierarchies may differ between macOS versions.

4. **Performance**: UI scripting is slower than direct API access, which isn't available for many system preferences.

5. **Alternative via Terminal**: For some settings, using `defaults write` commands via `do shell script` may provide a more reliable solution than UI scripting.