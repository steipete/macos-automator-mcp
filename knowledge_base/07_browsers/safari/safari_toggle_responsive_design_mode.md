---
title: 'Safari: Toggle Responsive Design Mode'
category: 07_browsers/safari
id: safari_toggle_responsive_design_mode
description: >-
  Toggles responsive design mode in Safari for mobile device testing and
  responsive design development.
keywords:
  - Safari
  - responsive design
  - mobile
  - development
  - testing
  - web development
  - device simulation
language: applescript
isComplex: false
argumentsPrompt: >-
  Optional device preset name as 'devicePreset' in inputData. If provided, will
  attempt to select that device preset.
notes: >
  - Safari must be running with at least one open tab.

  - The Develop menu must be enabled in Safari preferences.

  - This script uses UI automation via System Events, so Accessibility
  permissions are required.

  - If a device preset name is provided, the script will attempt to select that
  preset.

  - Common device presets include: "iPhone", "iPad", "Apple Watch",
  "Responsive", etc.

  - If no preset is specified, the script will simply toggle responsive design
  mode on/off.
---

This script toggles responsive design mode in Safari and optionally selects a specific device preset.

```applescript
--MCP_INPUT:devicePreset

on toggleResponsiveDesignMode(devicePreset)
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    if (count of windows) is 0 or (count of tabs of front window) is 0 then
      return "error: No tabs open in Safari."
    end if
    
    activate
    delay 0.5
    
    try
      tell application "System Events"
        tell process "Safari"
          -- Check if the Develop menu exists
          if not (exists menu bar item "Develop" of menu bar 1) then
            return "error: Develop menu not enabled in Safari. Enable it in Safari > Preferences > Advanced."
          end if
          
          -- Toggle the Responsive Design Mode
          click menu bar item "Develop" of menu bar 1
          delay 0.2
          
          if devicePreset is missing value or devicePreset is "" then
            -- Simple toggle behavior
            click menu item "Enter Responsive Design Mode" of menu of menu bar item "Develop" of menu bar 1
            
            -- Determine if we entered or exited responsive mode
            delay 1
            set exitMenuItem to exists of menu item "Exit Responsive Design Mode" of menu of menu bar item "Develop" of menu bar 1
            if exitMenuItem then
              return "Successfully entered responsive design mode."
            else
              return "Successfully exited responsive design mode."
            end if
          else
            -- First check if we need to enter responsive mode
            if not (exists of menu item "Exit Responsive Design Mode" of menu of menu bar item "Develop" of menu bar 1) then
              click menu item "Enter Responsive Design Mode" of menu of menu bar item "Develop" of menu bar 1
              delay 1
            end if
            
            -- Now select the device preset
            -- We need to click the responsive icon in the toolbar
            set responsiveButtonFound to false
            
            -- Try multiple ways to find the responsive design button
            try
              -- First try using the toolbar
              repeat with toolbarButton in toolbar buttons of front window
                -- The toolbar button for responsive design typically has a descriptive name
                set btnName to name of toolbarButton
                if btnName contains "Responsive" or btnName contains "Device" then
                  click toolbarButton
                  set responsiveButtonFound to true
                  exit repeat
                end if
              end repeat
            end try
            
            if not responsiveButtonFound then
              -- Use the Web Inspector UI
              tell window 1
                -- Locate and click the responsive button in the toolbar
                -- The exact UI element varies by Safari version, so we try multiple approaches
                
                -- Try to find the button by accessibility description
                set responsiveButtons to buttons whose description contains "Responsive"
                if (count of responsiveButtons) > 0 then
                  click item 1 of responsiveButtons
                  set responsiveButtonFound to true
                else
                  -- Try to find by class or other attributes
                  set responsiveButtons to buttons whose value contains "Responsive"
                  if (count of responsiveButtons) > 0 then
                    click item 1 of responsiveButtons
                    set responsiveButtonFound to true
                  end if
                end if
              end tell
            end if
            
            if responsiveButtonFound then
              delay 0.5
              
              -- Try to select the specified device preset
              -- Look for a menu item that contains the device preset name (case insensitive)
              set deviceMenuItemFound to false
              set devicePresetLower to my toLowerCase(devicePreset)
              
              repeat with menuItem in menu items of front menu
                set menuItemNameLower to my toLowerCase(name of menuItem)
                if menuItemNameLower contains devicePresetLower then
                  click menuItem
                  set deviceMenuItemFound to true
                  exit repeat
                end if
              end repeat
              
              if deviceMenuItemFound then
                return "Successfully selected device preset: " & devicePreset
              else
                return "Entered responsive design mode, but could not find device preset: " & devicePreset
              end if
            else
              return "Entered responsive design mode, but could not find device preset selector UI."
            end if
          end if
        end tell
      end tell
    on error errMsg
      return "error: Failed to toggle responsive design mode - " & errMsg & ". Make sure the Develop menu is enabled in Safari preferences."
    end try
  end tell
end toggleResponsiveDesignMode

-- Helper function to convert text to lowercase
on toLowerCase(sourceText)
  set lowercaseText to ""
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  
  repeat with i from 1 to length of sourceText
    set currentChar to character i of sourceText
    set charPos to offset of currentChar in upperChars
    
    if charPos > 0 then
      set lowercaseText to lowercaseText & character charPos of lowerChars
    else
      set lowercaseText to lowercaseText & currentChar
    end if
  end repeat
  
  return lowercaseText
end toLowerCase

return my toggleResponsiveDesignMode("--MCP_INPUT:devicePreset")
```
