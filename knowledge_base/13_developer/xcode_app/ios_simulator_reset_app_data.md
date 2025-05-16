---
title: 'iOS Simulator: Reset App Data'
category: 13_developer/xcode_app
id: ios_simulator_reset_app_data
description: Resets app data for a specific app on the iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - reset
  - app data
  - delete
  - clean
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  App bundle ID as 'bundleID', optional device identifier as 'deviceIdentifier'
  (defaults to 'booted'), and optional boolean to reinstall app after reset as
  'reinstallApp' (default is false).
notes: |
  - Removes app data while keeping the app installed
  - Useful for testing first-launch experiences repeatedly
  - Can optionally reinstall the app completely
  - Simulates user deleting and reinstalling the app
  - Alternative to manually resetting through simulator settings
  - The simulator and app must be installed for this to work
---

```applescript
--MCP_INPUT:bundleID
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:reinstallApp

on resetSimulatorAppData(bundleID, deviceIdentifier, reinstallApp)
  if bundleID is missing value or bundleID is "" then
    return "error: Bundle ID not provided. Specify the app's bundle identifier."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default reinstall to false if not specified
  if reinstallApp is missing value or reinstallApp is "" then
    set reinstallApp to false
  else if reinstallApp is "true" then
    set reinstallApp to true
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
    
    -- Check if the app is installed
    set checkAppCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " 2>/dev/null || echo 'not installed'"
    set appContainer to do shell script checkAppCmd
    
    if appContainer is "not installed" then
      return "error: App with bundle ID '" & bundleID & "' not installed on " & deviceIdentifier & " simulator."
    end if
    
    -- If reinstalling, we need to get the app path first
    set appPath to ""
    if reinstallApp then
      set getAppPathCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " app"
      set appPath to do shell script getAppPathCmd
    end if
    
    -- Terminate the app if it's running
    try
      do shell script "xcrun simctl terminate " & quoted form of deviceIdentifier & " " & quoted form of bundleID
      delay 1
    end try
    
    set dataReset to false
    
    if reinstallApp then
      -- Uninstall and reinstall the app
      try
        do shell script "xcrun simctl uninstall " & quoted form of deviceIdentifier & " " & quoted form of bundleID
        delay 1
        do shell script "xcrun simctl install " & quoted form of deviceIdentifier & " " & quoted form of appPath
        set dataReset to true
      on error errMsg
        return "Error reinstalling app: " & errMsg
      end try
    else
      -- Get the app data container path
      set getDataPathCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " data"
      set dataPath to do shell script getDataPathCmd
      
      -- Clean the data directory contents but keep the directory itself
      try
        do shell script "rm -rf " & quoted form of dataPath & "/*"
        set dataReset to true
      on error errMsg
        return "Error resetting app data: " & errMsg
      end try
    end if
    
    if dataReset then
      if reinstallApp then
        set actionText to "reinstalled the app (which reset data)"
      else
        set actionText to "reset app data while keeping the app installed"
      end if
      
      return "Successfully " & actionText & " for " & bundleID & " on " & deviceIdentifier & " simulator.

The app will now start fresh as if it was newly installed.
App container: " & appContainer
    else
      return "Failed to reset data for " & bundleID
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") resetting app data: " & errMsg
  end try
end resetSimulatorAppData

return my resetSimulatorAppData("--MCP_INPUT:bundleID", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:reinstallApp")
```
