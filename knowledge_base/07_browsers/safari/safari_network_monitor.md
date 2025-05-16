---
title: "Safari: Network Monitor"
category: "05_web_browsers"
id: safari_network_monitor
description: "Opens Safari's Web Inspector in Network tab to monitor network requests and optionally records network activity."
keywords: ["Safari", "network", "monitor", "web development", "debugging", "HTTP", "requests", "performance", "Web Inspector", "HAR"]
language: applescript
isComplex: true
argumentsPrompt: "Optional record setting as 'record' in inputData ('true' to start recording, 'false' to stop). If not provided, just opens the network panel without changing recording state."
notes: |
  - Safari must be running with at least one open tab.
  - The Develop menu must be enabled in Safari preferences.
  - This script uses UI automation via System Events, so Accessibility permissions are required.
  - The script opens the Web Inspector in Network tab for monitoring requests.
  - If recording is enabled, the script will start capturing all network activity.
  - Recording can consume significant memory for busy sites, so use with care.
  - Network recording can be exported using the export button in the UI.
---

This script opens Safari's Network Monitor in Web Inspector and optionally starts/stops recording network activity.

```applescript
--MCP_INPUT:record

on monitorSafariNetwork(recordOption)
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
          
          -- First check if Web Inspector is already open
          set inspectorOpen to false
          try
            if window "Web Inspector" exists then
              set inspectorOpen to true
            end if
          end try
          
          if not inspectorOpen then
            -- Open the Web Inspector if not already open
            click menu bar item "Develop" of menu bar 1
            delay 0.2
            click menu item "Show Web Inspector" of menu of menu bar item "Develop" of menu bar 1
            delay 1
          end if
          
          -- Switch to Network tab in Web Inspector
          try
            -- Look for Network tab button in the Web Inspector
            set networkTabFound to false
            
            repeat with btn in (buttons of tab group 1 of group 1 of splitter group 1 of window "Web Inspector")
              if the name of btn is "Network" then
                click btn
                set networkTabFound to true
                exit repeat
              end if
            end repeat
            
            if not networkTabFound then
              -- Try clicking by position (Network is typically the 3rd tab)
              try
                click button 3 of tab group 1 of group 1 of splitter group 1 of window "Web Inspector"
                set networkTabFound to true
              on error
                -- Last resort: use keyboard to cycle through tabs
                keystroke "]" using {command down, option down}
                delay 0.2
                keystroke "]" using {command down, option down}
                delay 0.2
                set networkTabFound to true
              end try
            end if
            
            delay 0.5
          end try
          
          -- Handle recording option if provided
          if recordOption is not missing value and recordOption is not "" then
            set shouldRecord to false
            
            -- Convert string to boolean
            if recordOption is "true" or recordOption is "yes" or recordOption is "1" then
              set shouldRecord to true
            end if
            
            -- Find the record button
            try
              set recordButtonFound to false
              
              -- Try different ways to find the record button
              repeat with btn in (buttons of toolbar 1 of window "Web Inspector")
                set btnDesc to ""
                try
                  set btnDesc to description of btn
                end try
                
                if btnDesc contains "Record" or btnDesc contains "recording" then
                  -- Check if the button is already in the desired state
                  set buttonValue to ""
                  try
                    set buttonValue to value of btn
                  end try
                  
                  -- Only click if we need to change state
                  if (shouldRecord and buttonValue does not contain "recording") or (not shouldRecord and buttonValue contains "recording") then
                    click btn
                  end if
                  
                  set recordButtonFound to true
                  exit repeat
                end if
              end repeat
              
              if not recordButtonFound then
                -- Try to find the record button by its position or other attributes
                -- Try the first few buttons in the toolbar
                repeat with i from 1 to 5
                  try
                    click button i of toolbar 1 of window "Web Inspector"
                    delay 0.5
                    set recordButtonFound to true
                    exit repeat
                  on error
                    -- Continue trying next button
                  end try
                end repeat
              end if
              
              if recordButtonFound then
                if shouldRecord then
                  return "Web Inspector opened in Network tab with recording started."
                else
                  return "Web Inspector opened in Network tab with recording stopped."
                end if
              else
                return "Web Inspector opened in Network tab, but could not find recording controls."
              end if
            on error errMsg
              return "Web Inspector opened in Network tab, but error with recording controls: " & errMsg
            end try
          else
            -- No recording option provided, just opened network tab
            return "Web Inspector opened in Network tab ready for monitoring."
          end if
        end tell
      end tell
    on error errMsg
      return "error: Failed to open Network monitor - " & errMsg & ". Make sure the Develop menu is enabled in Safari preferences."
    end try
  end tell
end monitorSafariNetwork

return my monitorSafariNetwork("--MCP_INPUT:record")
```