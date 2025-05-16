---
title: "System Settings: Configure Notifications"
category: "02_system_interaction"
id: system_settings_notifications
description: "Toggles Do Not Disturb or Focus modes for notifications in macOS."
keywords: ["System Settings", "Do Not Disturb", "Focus", "notifications", "DND"]
language: applescript
argumentsPrompt: "Enter 'on' or 'off' to toggle Do Not Disturb mode"
notes: "Controls notification settings by toggling Do Not Disturb or Focus modes. Works with both modern and older macOS versions."
---

```applescript
on run {dndState}
  try
    -- Handle placeholder substitution
    if dndState is "" or dndState is missing value then
      set dndState to "--MCP_INPUT:dndState"
    end if
    
    -- Normalize input to lowercase
    set dndState to do shell script "echo " & quoted form of dndState & " | tr '[:upper:]' '[:lower:]'"
    
    -- Validate input
    if dndState is not "on" and dndState is not "off" then
      return "Error: Please specify either 'on' or 'off' for Do Not Disturb mode."
    end if
    
    -- Determine macOS version to choose correct approach
    set osVersion to system version of (system info)
    set majorVersion to word 1 of osVersion
    
    -- Set flag for modern macOS
    set isModernMacOS to (majorVersion as number) ≥ 12 -- Monterey or later uses Focus/Control Center
    
    if isModernMacOS then
      -- Modern approach: Use Control Center for Monterey (12) and later
      tell application "System Events"
        -- Click on Control Center in the menu bar
        tell process "ControlCenter"
          -- Make sure Control Center is running
          if not (exists menu bar 1) then
            tell application "ControlCenter" to activate
            delay 0.5
          end if
          
          -- Click the Control Center icon in the menu bar
          click menu bar item 1 of menu bar 1
          delay 0.5
          
          -- Look for Focus or Do Not Disturb button
          set targetButtonName to ""
          
          -- Try to find the Focus button
          if exists button "Focus" of window 1 then
            set targetButtonName to "Focus"
          else if exists button "Do Not Disturb" of window 1 then
            set targetButtonName to "Do Not Disturb"
          end if
          
          if targetButtonName is not "" then
            -- Click on Focus or DND button to see options
            click button targetButtonName of window 1
            delay 0.5
            
            -- Handle the Do Not Disturb/Focus toggle based on desired state
            if dndState is "on" then
              -- Turn on Do Not Disturb
              if exists checkbox "Do Not Disturb" of window 1 then
                if not (value of checkbox "Do Not Disturb" of window 1 as boolean) then
                  click checkbox "Do Not Disturb" of window 1
                end if
              end if
            else -- dndState is "off"
              -- Turn off Do Not Disturb
              if exists checkbox "Do Not Disturb" of window 1 then
                if (value of checkbox "Do Not Disturb" of window 1 as boolean) then
                  click checkbox "Do Not Disturb" of window 1
                end if
              end if
            end if
            
            -- Dismiss Control Center by clicking elsewhere
            click at {0, 0}
            
            return "Do Not Disturb has been turned " & dndState & "."
          else
            -- Dismiss Control Center (since we couldn't find the button)
            click at {0, 0}
            return "Could not find Focus or Do Not Disturb button in Control Center."
          end if
        end tell
      end tell
    else
      -- Legacy approach: Use Notification Center for Big Sur (11) and earlier
      tell application "System Events"
        -- Click on Notification Center in the menu bar
        if exists menu bar item "Notification Center" of menu bar 1 then
          click menu bar item "Notification Center" of menu bar 1
          delay 0.5
          
          -- Look for Do Not Disturb button
          if exists button "Do Not Disturb" of scroll area 1 of window "Notification Center" then
            set dndButton to button "Do Not Disturb" of scroll area 1 of window "Notification Center"
            
            -- Get current state (On/Off)
            set currentState to value of dndButton as boolean
            
            -- Toggle based on desired state
            if dndState is "on" and not currentState then
              click dndButton
            else if dndState is "off" and currentState then
              click dndButton
            end if
            
            -- Dismiss Notification Center by clicking elsewhere
            click at {0, 0}
            
            return "Do Not Disturb has been turned " & dndState & "."
          else
            -- Dismiss Notification Center (since we couldn't find the button)
            click at {0, 0}
            return "Could not find Do Not Disturb button in Notification Center."
          end if
        else
          return "Could not access Notification Center."
        end if
      end tell
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to configure notifications - " & errMsg
  end try
end run
```
END_TIP