---
title: 'iOS Simulator: Control Status Bar'
category: 13_developer/xcode_app
id: ios_simulator_status_bar
description: >-
  Customizes the status bar appearance in iOS Simulator for screenshots and
  videos.
keywords:
  - iOS Simulator
  - Xcode
  - status bar
  - customize
  - screenshot
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional device identifier as 'deviceIdentifier' (defaults to 'booted'), time
  display as 'statusTime' (e.g., '9:41'), battery level as 'batteryLevel'
  (0-100), optional carrier name as 'carrierName', and optional data network as
  'dataNetwork' (e.g., 'wifi', '5G', 'LTE').
notes: |
  - Customizes iOS simulator status bar for clean screenshots and videos
  - Can set perfect time (like Apple's 9:41), battery level, carrier name
  - Controls network indicators (WiFi, cellular) and signal strength
  - Affects current appearance but doesn't persist after simulator restart
  - Useful for marketing screenshots, demos, and documentation
  - The simulator must be booted for this to work
---

```applescript
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:statusTime
--MCP_INPUT:batteryLevel
--MCP_INPUT:carrierName
--MCP_INPUT:dataNetwork

on controlSimulatorStatusBar(deviceIdentifier, statusTime, batteryLevel, carrierName, dataNetwork)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Build command parts based on provided parameters
  set cmdParts to {}
  
  -- Time setting
  if statusTime is not missing value and statusTime is not "" then
    set end of cmdParts to "--time " & quoted form of statusTime
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
  
  -- Carrier name
  if carrierName is not missing value and carrierName is not "" then
    set end of cmdParts to "--operatorName " & quoted form of carrierName
  end if
  
  -- Data network settings
  if dataNetwork is not missing value and dataNetwork is not "" then
    set dataNetwork to my normalize_data_network(dataNetwork)
    
    if dataNetwork is "wifi" then
      set end of cmdParts to "--dataNetwork wifi"
      set end of cmdParts to "--wifiMode active"
      set end of cmdParts to "--wifiBars 3"
      set end of cmdParts to "--cellularMode notSupported"
    else if dataNetwork is in {"3g", "4g", "5g", "lte"} then
      -- Convert to uppercase for display
      set dataNetworkUpper to my toUppercase(dataNetwork)
      set end of cmdParts to "--dataNetwork " & dataNetworkUpper
      set end of cmdParts to "--cellularMode active"
      set end of cmdParts to "--cellularBars 4"
      set end of cmdParts to "--wifiMode notSupported"
    end if
  end if
  
  -- If no custom settings were provided, set demo-ready defaults
  if (count of cmdParts) is 0 then
    set cmdParts to {"--time 9:41", "--batteryLevel 100", "--batteryState charged", "--operatorName Carrier", "--dataNetwork 5G", "--cellularMode active", "--cellularBars 4"}
  end if
  
  try
    -- Build the final command
    set cmdString to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " override " & (my join_list(cmdParts, " "))
    
    -- Execute the command
    set statusBarResult to do shell script cmdString
    
    -- Get current status bar settings
    set statusCmd to "xcrun simctl status_bar " & quoted form of deviceIdentifier & " list"
    set currentStatus to do shell script statusCmd
    
    return "Successfully updated simulator status bar.

Current status bar settings:
" & currentStatus & "

To reset the status bar to default, use: 
xcrun simctl status_bar " & deviceIdentifier & " clear"
  on error errMsg number errNum
    return "error (" & errNum & ") updating simulator status bar: " & errMsg
  end try
end controlSimulatorStatusBar

-- Helper function to join list items with a separator
on join_list(theList, theSeparator)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theSeparator
  set theString to theList as text
  set AppleScript's text item delimiters to oldDelimiters
  return theString
end join_list

-- Helper function to normalize data network input
on normalize_data_network(network)
  set lowercaseNetwork to my toLowercase(network)
  
  if lowercaseNetwork contains "wi" and lowercaseNetwork contains "fi" then
    return "wifi"
  else if lowercaseNetwork contains "5g" or lowercaseNetwork is "5g" then
    return "5g"
  else if lowercaseNetwork contains "lte" or lowercaseNetwork is "lte" then
    return "lte"
  else if lowercaseNetwork contains "4g" or lowercaseNetwork is "4g" then
    return "4g"
  else if lowercaseNetwork contains "3g" or lowercaseNetwork is "3g" then
    return "3g"
  else
    return "wifi" -- Default to wifi
  end if
end normalize_data_network

-- Helper function to convert text to lowercase
on toLowercase(theText)
  return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowercase

-- Helper function to convert text to uppercase
on toUppercase(theText)
  return do shell script "echo " & quoted form of theText & " | tr '[:lower:]' '[:upper:]'"
end toUppercase

return my controlSimulatorStatusBar("--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:statusTime", "--MCP_INPUT:batteryLevel", "--MCP_INPUT:carrierName", "--MCP_INPUT:dataNetwork")
```
