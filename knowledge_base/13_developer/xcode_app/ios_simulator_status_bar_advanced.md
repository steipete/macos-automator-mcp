---
title: 'iOS Simulator: Advanced Status Bar Control'
category: 13_developer/xcode_app
id: ios_simulator_status_bar_advanced
description: >-
  Provides advanced control of iOS Simulator status bar appearance including
  clock, network, battery, and more.
keywords:
  - iOS Simulator
  - Xcode
  - status bar
  - override
  - battery
  - network
  - clock
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional device identifier as 'deviceIdentifier' (defaults to 'booted'),
  optional action as 'action' ('override', 'clear', or 'list'), optional time as
  'time' (e.g., '9:41'), optional network as 'network' ('5G', 'LTE', 'wifi'),
  optional carrier name as 'carrier', and optional battery level as
  'batteryLevel' (0-100).
notes: |
  - Provides precise control over simulator status bar appearance
  - Can set the specific time, network type, signal strength
  - Controls carrier name and battery level/state
  - Perfect for creating screenshots and demos with consistent UI
  - Can reset status bar to default behavior
  - Works with iOS 13+ simulators
---

```applescript
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:action
--MCP_INPUT:time
--MCP_INPUT:network
--MCP_INPUT:carrier
--MCP_INPUT:batteryLevel

on controlSimulatorStatusBarAdvanced(deviceIdentifier, action, time, network, carrier, batteryLevel)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default action to override if not specified
  if action is missing value or action is "" then
    set action to "override"
  else
    -- Normalize to lowercase
    set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  end if
  
  -- Validate action
  if action is not in {"override", "clear", "list"} then
    return "error: Invalid action. Available actions: 'override', 'clear', 'list'."
  end if
  
  try
    -- Check if device exists
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Handle list action (just show current status)
    if action is "list" then
      set listCmd to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " list"
      try
        set statusInfo to do shell script listCmd
        return "Current status bar settings for " & deviceIdentifier & " simulator:

" & statusInfo & "

To override these settings, provide parameters like time, network, carrier, or batteryLevel."
      on error errMsg
        return "Error listing status bar settings: " & errMsg
      end try
    end if
    
    -- Handle clear action (reset to default)
    if action is "clear" then
      set clearCmd to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " clear"
      try
        do shell script clearCmd
        return "Successfully reset status bar to default behavior for " & deviceIdentifier & " simulator.

The status bar will now show actual system time, network status, etc."
      on error errMsg
        return "Error clearing status bar settings: " & errMsg
      end try
    end if
    
    -- Handle override action
    if action is "override" then
      -- Build command parts based on provided parameters
      set cmdParts to {}
      
      -- Time setting
      if time is not missing value and time is not "" then
        set end of cmdParts to "--time " & quoted form of time
      end if
      
      -- Network setting
      if network is not missing value and network is not "" then
        -- Normalize to lowercase
        set network to do shell script "echo " & quoted form of network & " | tr '[:upper:]' '[:lower:]'"
        
        if network contains "wifi" or network is "wi-fi" then
          set end of cmdParts to "--dataNetwork wifi"
          set end of cmdParts to "--wifiMode active"
          set end of cmdParts to "--wifiBars 3"
          set end of cmdParts to "--cellularMode notSupported"
        else if network contains "5g" then
          set end of cmdParts to "--dataNetwork 5G"
          set end of cmdParts to "--cellularMode active"
          set end of cmdParts to "--cellularBars 4"
          set end of cmdParts to "--wifiMode notSupported"
        else if network contains "lte" or network is "4g" then
          set end of cmdParts to "--dataNetwork LTE"
          set end of cmdParts to "--cellularMode active"
          set end of cmdParts to "--cellularBars 4"
          set end of cmdParts to "--wifiMode notSupported"
        else if network contains "3g" then
          set end of cmdParts to "--dataNetwork 3G"
          set end of cmdParts to "--cellularMode active"
          set end of cmdParts to "--cellularBars 3"
          set end of cmdParts to "--wifiMode notSupported"
        else if network contains "edge" or network is "2g" then
          set end of cmdParts to "--dataNetwork EDGE"
          set end of cmdParts to "--cellularMode active"
          set end of cmdParts to "--cellularBars 2"
          set end of cmdParts to "--wifiMode notSupported"
        else if network contains "none" or network is "no signal" then
          set end of cmdParts to "--cellularMode active"
          set end of cmdParts to "--cellularBars 0"
          set end of cmdParts to "--wifiMode notSupported"
        end if
      end if
      
      -- Carrier name
      if carrier is not missing value and carrier is not "" then
        set end of cmdParts to "--operatorName " & quoted form of carrier
      end if
      
      -- Battery level
      if batteryLevel is not missing value and batteryLevel is not "" then
        try
          set batteryLevelNum to batteryLevel as number
          if batteryLevelNum ≥ 0 and batteryLevelNum ≤ 100 then
            set end of cmdParts to "--batteryLevel " & batteryLevelNum
            
            -- Determine battery state based on level
            if batteryLevelNum = 100 then
              set end of cmdParts to "--batteryState charged"
            else if batteryLevelNum > 20 then
              set end of cmdParts to "--batteryState charging"
            else
              set end of cmdParts to "--batteryState discharging"
            end if
          end if
        on error
          -- Not a valid number, ignore
        end try
      end if
      
      -- If no override parts were provided, set some demo-ready defaults
      if (count of cmdParts) is 0 then
        set cmdParts to {"--time 9:41", "--batteryLevel 100", "--batteryState charged", "--operatorName Carrier", "--dataNetwork 5G", "--cellularMode active", "--cellularBars 4"}
      end if
      
      -- Build the final command
      set cmdString to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " override " & (my join_list(cmdParts, " "))
      
      try
        do shell script cmdString
        
        -- Get current status bar settings
        set statusCmd to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " list"
        set currentStatus to do shell script statusCmd
        
        return "Successfully updated status bar for " & deviceIdentifier & " simulator.

Current status bar settings:
" & currentStatus & "

To reset the status bar to default, use:
xcrun simctl status_bar " & deviceIdentifier & " clear"
      on error errMsg
        return "Error updating status bar: " & errMsg
      end try
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") controlling simulator status bar: " & errMsg
  end try
end controlSimulatorStatusBarAdvanced

-- Helper function to join list items with a separator
on join_list(theList, theSeparator)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theSeparator
  set theString to theList as text
  set AppleScript's text item delimiters to oldDelimiters
  return theString
end join_list

return my controlSimulatorStatusBarAdvanced("--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:action", "--MCP_INPUT:time", "--MCP_INPUT:network", "--MCP_INPUT:carrier", "--MCP_INPUT:batteryLevel")
```
