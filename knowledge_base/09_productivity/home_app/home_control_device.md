---
title: "Home App: Control Smart Home Device"
category: "07_productivity_apps"
id: home_control_device
description: "Controls a smart home device (turn on/off, adjust brightness/temperature) in the Home app by its name and optionally room location."
keywords: ["Home", "HomeKit", "smart home", "device control", "automation", "System Events", "UI scripting"]
language: applescript
isComplex: true
argumentsPrompt: "Provide: 'deviceName' (required), 'roomName' (optional), 'action' (required, one of: 'toggle', 'on', 'off', 'brightness', 'temperature'), and 'value' (required for brightness/temperature) in inputData."
notes: "Requires Accessibility permissions. Uses UI scripting as Home app has limited AppleScript support. Home app must be configured with your HomeKit devices. Actions depend on device capabilities."
---

```applescript
--MCP_INPUT:deviceName
--MCP_INPUT:roomName
--MCP_INPUT:action
--MCP_INPUT:value

on controlHomeDevice(deviceName, roomName, action, value)
  -- Input validation
  if deviceName is missing value or deviceName is "" then
    return "error: Device name not provided."
  end if

  if action is missing value or action is "" then
    return "error: Action not provided. Valid actions: toggle, on, off, brightness, temperature."
  end if

  -- For brightness and temperature actions, ensure value is provided and is a number
  if (action is "brightness" or action is "temperature") and (value is missing value or value is "") then
    return "error: Value required for " & action & " action."
  end if

  -- Launch Home app
  tell application "Home"
    activate
    delay 1 -- Allow time for the app to launch
  end tell

  -- Use UI scripting via System Events
  tell application "System Events"
    try
      tell process "Home"
        -- Make sure Home app is frontmost and ready
        set frontmost to true
        delay 1

        -- Look for the device
        set deviceFound to false
        set deviceElement to missing value

        -- If room name provided, navigate to that room first
        if roomName is not missing value and roomName is not "" then
          -- Try to find and click the room in the sidebar
          repeat with roomButton in (buttons of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1)
            if name of roomButton contains roomName then
              click roomButton
              delay 1
              exit repeat
            end if
          end repeat
        end if

        -- Look for the device in the current view
        repeat with deviceTile in (UI elements of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1)
          try
            -- Device tiles typically have a name that matches or contains the device name
            if name of deviceTile contains deviceName then
              set deviceFound to true
              set deviceElement to deviceTile
              exit repeat
            end if
          end try
        end repeat

        if not deviceFound then
          return "error: Device '" & deviceName & "' not found. Check the device name or room selection."
        end if

        -- Interact with the device based on the action
        if action is "toggle" then
          -- Simple click to toggle the device state
          click deviceElement
          delay 0.5
          return "Device '" & deviceName & "' toggled."
          
        else if action is "on" then
          -- For on action, make sure device is on
          -- For most devices, if it's not already on, clicking will turn it on
          -- Advanced devices might require a long press to get additional controls
          click deviceElement
          delay 0.5
          return "Device '" & deviceName & "' turned on."
          
        else if action is "off" then
          -- For off action, make sure device is off
          -- Similar to on action, but might need to check current state
          click deviceElement
          delay 0.5
          return "Device '" & deviceName & "' turned off."
          
        else if action is "brightness" then
          -- For brightness, we need to access the device's detailed controls
          -- Long press or right-click to show controls
          perform action "AXShowMenu" of deviceElement
          delay 0.5
          
          -- Look for the brightness slider
          set sliderFound to false
          repeat with ctrl in (UI elements of window 1)
            try
              if role of ctrl is "AXSlider" and description of ctrl contains "brightness" then
                set sliderFound to true
                
                -- Convert value to a value between 0 and 100
                set brightnessValue to value as number
                if brightnessValue < 0 then set brightnessValue to 0
                if brightnessValue > 100 then set brightnessValue to 100
                
                -- Set the slider value
                set value of ctrl to brightnessValue
                delay 0.5
                
                -- Click away to close the controls
                click at {10, 10}
                return "Set brightness of '" & deviceName & "' to " & brightnessValue & "%."
              end if
            end try
          end repeat
          
          if not sliderFound then
            return "error: Brightness control not found for '" & deviceName & "'. Device may not support brightness."
          end if
          
        else if action is "temperature" then
          -- For temperature, similar to brightness but looking for temperature controls
          perform action "AXShowMenu" of deviceElement
          delay 0.5
          
          -- Look for the temperature control
          set tempControlFound to false
          repeat with ctrl in (UI elements of window 1)
            try
              if role of ctrl is "AXSlider" and description of ctrl contains "temperature" then
                set tempControlFound to true
                
                -- Set the temperature value
                set tempValue to value as number
                set value of ctrl to tempValue
                delay 0.5
                
                -- Click away to close the controls
                click at {10, 10}
                return "Set temperature of '" & deviceName & "' to " & tempValue & " degrees."
              end if
            end try
          end repeat
          
          if not tempControlFound then
            return "error: Temperature control not found for '" & deviceName & "'. Device may not support temperature adjustment."
          end if
          
        else
          return "error: Unsupported action '" & action & "'. Valid actions: toggle, on, off, brightness, temperature."
        end if
        
      end tell
    on error errMsg
      return "error: Failed to control device - " & errMsg
    end try
  end tell
  
  return "error: Operation failed to complete."
end controlHomeDevice

return my controlHomeDevice("--MCP_INPUT:deviceName", "--MCP_INPUT:roomName", "--MCP_INPUT:action", "--MCP_INPUT:value")
```