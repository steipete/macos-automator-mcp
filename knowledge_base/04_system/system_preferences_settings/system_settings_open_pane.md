---
title: 'System Settings: Open Specific Pane'
category: 04_system
id: system_settings_open_pane
description: >-
  Opens System Settings (formerly System Preferences) to a specific settings
  pane.
keywords:
  - System Settings
  - System Preferences
  - settings
  - preferences
  - control panel
language: applescript
argumentsPrompt: Enter the name of the settings pane to open
notes: >-
  Works with macOS Ventura and later (System Settings) as well as older versions
  (System Preferences).
---

```applescript
on run {paneName}
  try
    if paneName is "" or paneName is missing value then
      set paneName to "--MCP_INPUT:paneName"
    end if
    
    -- Determine if we're using the new System Settings or older System Preferences
    set osVersion to system version of (system info)
    set majorVersion to word 1 of osVersion
    
    if majorVersion ? 13 then
      -- macOS Ventura (13) or later - use System Settings
      tell application "System Settings"
        activate
        
        -- Wait for System Settings to launch
        delay 1
        
        tell application "System Events"
          tell process "System Settings"
            -- Search for the settings pane
            keystroke "f" using {command down}
            delay 0.5
            keystroke paneName
            delay 1
            
            -- Click the first matching result
            if exists row 1 of table 1 of scroll area 1 of group 1 of window 1 then
              click row 1 of table 1 of scroll area 1 of group 1 of window 1
              return "Opened System Settings pane for: " & paneName
            else
              return "Could not find settings pane: " & paneName
            end if
          end tell
        end tell
      end tell
    else
      -- macOS Monterey (12) or earlier - use System Preferences
      tell application "System Preferences"
        activate
        
        -- Try to open the pane directly
        try
          reveal pane id paneName
          return "Opened System Preferences pane: " & paneName
        on error
          -- If the direct approach fails, search for it
          tell application "System Events"
            tell process "System Preferences"
              keystroke "f" using {command down}
              delay 0.5
              keystroke paneName
              delay 1
              
              -- Try to click the first search result
              if exists row 1 of table 1 of scroll area 1 of window 1 then
                click row 1 of table 1 of scroll area 1 of window 1
                return "Opened System Preferences pane for: " & paneName
              else
                return "Could not find preferences pane: " & paneName
              end if
            end tell
          end tell
        end try
      end tell
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to open settings pane - " & errMsg
  end try
end run
```
END_TIP
