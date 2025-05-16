---
title: 'System Settings: Toggle Wi-Fi'
category: 04_system
id: system_settings_network_toggle_wifi
description: Toggles Wi-Fi on or off through System Settings or System Preferences.
keywords:
  - System Settings
  - Wi-Fi
  - network
  - toggle Wi-Fi
  - wireless
language: applescript
argumentsPrompt: >-
  Enter 'on' or 'off' to set Wi-Fi state, or 'toggle' to switch the current
  state
notes: >-
  Controls Wi-Fi connectivity. Supports both System Settings (macOS Ventura and
  later) and System Preferences (earlier macOS versions).
---

```applescript
on run {wifiAction}
  try
    -- Handle placeholder substitution
    if wifiAction is "" or wifiAction is missing value then
      set wifiAction to "--MCP_INPUT:wifiAction"
    end if
    
    -- Normalize input to lowercase
    set wifiAction to do shell script "echo " & quoted form of wifiAction & " | tr '[:upper:]' '[:lower:]'"
    
    -- Determine macOS version to choose correct approach
    set osVersion to system version of (system info)
    set majorVersion to word 1 of osVersion
    
    -- Set flag for modern macOS (Ventura/13 or later)
    set isModernMacOS to (majorVersion as number) ≥ 13
    
    -- Determine current Wi-Fi state using networksetup command
    set currentWifiState to do shell script "networksetup -getairportpower en0 | awk '{print $4}'"
    
    -- Normalize current state to "on" or "off"
    if currentWifiState is "On" then
      set currentWifiState to "on"
    else
      set currentWifiState to "off"
    end if
    
    -- Determine target state based on action
    if wifiAction is "toggle" then
      if currentWifiState is "on" then
        set targetState to "off"
      else
        set targetState to "on"
      end if
    else if wifiAction is "on" or wifiAction is "off" then
      set targetState to wifiAction
    else
      return "Error: Invalid action. Please use 'on', 'off', or 'toggle'."
    end if
    
    -- If current state already matches target state, no action needed
    if currentWifiState is targetState then
      return "Wi-Fi is already " & targetState & "."
    end if
    
    -- Use UI scripting to change Wi-Fi state
    if isModernMacOS then
      -- System Settings (macOS Ventura or later)
      tell application "System Settings"
        activate
        
        -- Ensure we have time to open
        delay 1
        
        tell application "System Events"
          tell process "System Settings"
            -- Click on Network in the sidebar
            repeat with sidebarItem in UI elements of scroll area 1 of group 1 of group 1 of window 1
              if exists static text 1 of sidebarItem then
                if value of static text 1 of sidebarItem is "Network" then
                  click sidebarItem
                  exit repeat
                end if
              end if
            end repeat
            
            delay 1
            
            -- Click on Wi-Fi in the Network pane
            repeat with networkItem in UI elements of outline 1 of scroll area 1 of group 1 of group 2 of window 1
              if exists static text 1 of networkItem then
                if value of static text 1 of networkItem is "Wi-Fi" then
                  click networkItem
                  exit repeat
                end if
              end if
            end repeat
            
            delay 1
            
            -- Toggle the Wi-Fi switch
            -- In Modern macOS, there's usually a checkbox or switch for Wi-Fi
            if exists checkbox "Wi-Fi" of group 1 of group 2 of window 1 then
              set switchControl to checkbox "Wi-Fi" of group 1 of group 2 of window 1
              
              -- Set the value based on target state
              if targetState is "on" then
                if not (value of switchControl as boolean) then
                  click switchControl
                end if
              else -- off
                if (value of switchControl as boolean) then
                  click switchControl
                end if
              end if
            else
              -- Try finding it as a switch instead of checkbox
              repeat with uiElement in UI elements of group 1 of group 2 of window 1
                if name of uiElement contains "Wi-Fi" then
                  click uiElement
                  exit repeat
                end if
              end repeat
            end if
            
            -- Wait a moment for the change to apply
            delay 1
            
            -- Quit System Settings
            click menu item "Quit System Settings" of menu "System Settings" of menu bar item "System Settings" of menu bar 1
          end tell
        end tell
      end tell
    else
      -- System Preferences (macOS Monterey or earlier)
      tell application "System Preferences"
        activate
        
        -- Ensure we have time to open
        delay 1
        
        -- Open the Network pane
        reveal pane id "com.apple.preference.network"
        
        delay 1
        
        tell application "System Events"
          tell process "System Preferences"
            -- Select Wi-Fi in the service list
            if exists row "Wi-Fi" of table 1 of scroll area 1 of window 1 then
              select row "Wi-Fi" of table 1 of scroll area 1 of window 1
            else if exists row "Wi-Fi" of table 1 of scroll area 1 of group 1 of window 1 then
              select row "Wi-Fi" of table 1 of scroll area 1 of group 1 of window 1
            end if
            
            delay 0.5
            
            -- Find and click the Turn Wi-Fi On/Off button
            if targetState is "on" then
              if exists button "Turn Wi-Fi On" of window 1 then
                click button "Turn Wi-Fi On" of window 1
              end if
            else -- off
              if exists button "Turn Wi-Fi Off" of window 1 then
                click button "Turn Wi-Fi Off" of window 1
              end if
            end if
            
            -- Wait a moment for the change to apply
            delay 1
            
            -- Quit System Preferences
            click menu item "Quit System Preferences" of menu "System Preferences" of menu bar item "System Preferences" of menu bar 1
          end tell
        end tell
      end tell
    end if
    
    -- Verify the change using networksetup again
    delay 1
    set newWifiState to do shell script "networksetup -getairportpower en0 | awk '{print $4}'"
    
    -- Normalize the result
    if newWifiState is "On" then
      set newWifiState to "on"
    else
      set newWifiState to "off"
    end if
    
    -- Check if the change was successful
    if newWifiState is targetState then
      return "Wi-Fi has been turned " & targetState & "."
    else
      return "Failed to change Wi-Fi state. Current state: " & newWifiState
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to toggle Wi-Fi - " & errMsg
  end try
end run
```
END_TIP
