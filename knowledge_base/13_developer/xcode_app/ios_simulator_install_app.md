---
title: 'iOS Simulator: Install App'
category: 13_developer/xcode_app
id: ios_simulator_install_app
description: Installs an app on an iOS simulator device and optionally launches it.
keywords:
  - iOS Simulator
  - Xcode
  - install
  - app
  - launch
  - bundle
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  App path as 'appPath' (path to .app bundle), device identifier as
  'deviceIdentifier' (device name or UDID, or 'booted' for currently booted
  device), and optional launch boolean as 'launchAfterInstall' (default is
  true).
notes: >
  - Installs an app bundle to a simulator device

  - Can target a specific device by name or UDID, or use 'booted' for active
  device

  - Optionally launches the app after installation

  - Returns the bundle identifier of the installed app

  - Useful for testing app installations without going through Xcode

  - The app path must be to a simulator-compatible .app bundle
---

```applescript
--MCP_INPUT:appPath
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:launchAfterInstall

on installAppOnSimulator(appPath, deviceIdentifier, launchAfterInstall)
  if appPath is missing value or appPath is "" then
    return "error: App path not provided. Specify a path to a .app bundle built for simulator."
  end if
  
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default to launching after install unless explicitly set to false
  if launchAfterInstall is missing value or launchAfterInstall is "" then
    set launchAfterInstall to true
  else if launchAfterInstall is "false" then
    set launchAfterInstall to false
  end if
  
  try
    -- Ensure the app exists
    set checkAppCmd to "test -d " & quoted form of appPath & " && echo 'exists' || echo 'not found'"
    set appExistsResult to do shell script checkAppCmd
    
    if appExistsResult is "not found" then
      return "error: App not found at path: " & appPath
    end if
    
    -- Check if the app path ends with .app
    if not (appPath ends with ".app") then
      return "error: The provided path does not appear to be an app bundle (should end with .app): " & appPath
    end if
    
    -- Extract the bundle identifier from the app's Info.plist
    set bundleIdCmd to "defaults read " & quoted form of appPath & "/Info CFBundleIdentifier"
    set bundleId to do shell script bundleIdCmd
    
    -- Check if the device exists or is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Install the app
    set installCmd to "xcrun simctl install " & quoted form of deviceIdentifier & " " & quoted form of appPath
    try
      do shell script installCmd
      set installSuccessful to true
    on error errMsg
      return "error: Failed to install app: " & errMsg
    end try
    
    -- Launch the app if requested
    set launchResult to ""
    if launchAfterInstall and installSuccessful then
      try
        set launchCmd to "xcrun simctl launch " & quoted form of deviceIdentifier & " " & bundleId
        set launchOutput to do shell script launchCmd
        set launchResult to "
App launched successfully. " & launchOutput
      on error errMsg
        set launchResult to "
App installed but launch failed: " & errMsg
      end try
    end if
    
    return "Successfully installed app '" & bundleId & "' on " & deviceIdentifier & " simulator device." & launchResult & "

App path: " & appPath & "
Bundle identifier: " & bundleId
  on error errMsg number errNum
    return "error (" & errNum & ") installing app on iOS simulator: " & errMsg
  end try
end installAppOnSimulator

return my installAppOnSimulator("--MCP_INPUT:appPath", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:launchAfterInstall")
```
