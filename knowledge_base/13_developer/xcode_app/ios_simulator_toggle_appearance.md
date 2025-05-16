---
title: 'iOS Simulator: Toggle Dark/Light Mode'
category: 13_developer
id: ios_simulator_toggle_appearance
description: Toggles between Dark and Light appearance modes in iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - dark mode
  - light mode
  - appearance
  - theme
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: false
argumentsPrompt: >-
  Appearance mode as 'appearanceMode' ('dark', 'light', or 'toggle'), and
  optional device identifier as 'deviceIdentifier' (defaults to 'booted').
notes: |
  - Switches between dark and light appearance modes
  - Changes take effect immediately without simulator restart
  - Useful for testing how your app responds to appearance changes
  - Simulates user toggling appearance in Control Center
  - Works with iOS 13+ simulators that support dark mode
  - The simulator must be booted for this to work
---

```applescript
--MCP_INPUT:appearanceMode
--MCP_INPUT:deviceIdentifier

on toggleSimulatorAppearance(appearanceMode, deviceIdentifier)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default to toggle if appearance mode not specified
  if appearanceMode is missing value or appearanceMode is "" then
    set appearanceMode to "toggle"
  else
    -- Normalize to lowercase
    set appearanceMode to do shell script "echo " & quoted form of appearanceMode & " | tr '[:upper:]' '[:lower:]'"
  end if
  
  -- Check appearance mode is valid
  if appearanceMode is not in {"dark", "light", "toggle"} then
    return "error: Invalid appearance mode. Must be 'dark', 'light', or 'toggle'."
  end if
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- If toggle is requested, we need to determine current appearance first
    if appearanceMode is "toggle" then
      -- Try to determine current appearance via UI scripting as a fallback
      -- This is not reliable but can work in some cases
      try
        tell application "System Events"
          tell process "Simulator"
            -- Try clicking on Hardware menu
            click menu item "Features" of menu bar 1
            delay 0.2
            
            -- Check if Toggle Appearance menu item has a checkmark
            set toggle_item to menu item "Toggle Appearance" of menu "Features" of menu bar 1
            
            -- Click to hide the menu
            key code 53 -- Escape key
            delay 0.2
            
            -- Set the appearance based on best guess from menu state
            if value of attribute "AXMenuItemMarkChar" of toggle_item is missing value then
              -- No checkmark, assume light mode
              set appearanceMode to "dark"
            else
              -- Has checkmark, assume dark mode
              set appearanceMode to "light"
            end if
          end tell
        end tell
      on error errMsg
        -- If we failed to detect, default to dark mode
        set appearanceMode to "dark"
      end try
    end if
    
    -- Set the appearance using simctl ui command
    set appearanceCmd to "xcrun simctl ui " & quoted form of deviceIdentifier & " appearance " & appearanceMode
    
    try
      do shell script appearanceCmd
      set appearanceChanged to true
    on error errMsg
      -- Try with keyboard shortcut as a fallback if command fails
      try
        tell application "Simulator" to activate
        delay 0.5
        tell application "System Events"
          tell process "Simulator"
            -- Command+Shift+A toggles appearance
            keystroke "a" using {command down, shift down}
          end tell
        end tell
        set appearanceChanged to true
      on error
        return "Error changing appearance mode: " & errMsg
      end try
    end try
    
    if appearanceChanged then
      return "Successfully changed appearance to " & appearanceMode & " mode on " & deviceIdentifier & " simulator.

Note: This change takes effect immediately. All apps will update to reflect the new appearance."
    else
      return "Failed to change appearance for " & deviceIdentifier
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") toggling simulator appearance: " & errMsg
  end try
end toggleSimulatorAppearance

return my toggleSimulatorAppearance("--MCP_INPUT:appearanceMode", "--MCP_INPUT:deviceIdentifier")
```
