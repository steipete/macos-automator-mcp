---
title: 'iOS Simulator: Set App Launch Arguments'
category: 13_developer
id: ios_simulator_launch_arguments
description: >-
  Launches an app in iOS Simulator with custom launch arguments and environment
  variables.
keywords:
  - iOS Simulator
  - Xcode
  - launch arguments
  - environment variables
  - testing
  - debug
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  App bundle ID as 'bundleID', optional launch arguments as 'launchArgs'
  (comma-separated list), optional environment variables as 'environmentVars'
  (JSON object), and optional device identifier as 'deviceIdentifier' (defaults
  to 'booted').
notes: |
  - Launches apps with custom launch arguments and environment variables
  - Useful for enabling testing modes and debug features
  - Helps test different app configurations
  - Can simulate specific app states without code changes
  - Particularly useful for UI testing and screenshots
  - Requires the app to be installed on the simulator
---

```applescript
--MCP_INPUT:bundleID
--MCP_INPUT:launchArgs
--MCP_INPUT:environmentVars
--MCP_INPUT:deviceIdentifier

on setAppLaunchArguments(bundleID, launchArgs, environmentVars, deviceIdentifier)
  if bundleID is missing value or bundleID is "" then
    return "error: Bundle ID not provided. Specify the app's bundle identifier."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
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
    
    -- Process launch arguments
    set formattedArgs to ""
    if launchArgs is not missing value and launchArgs is not "" then
      -- Split comma-separated arguments
      set AppleScript's text item delimiters to ","
      set argsList to text items of launchArgs
      set AppleScript's text item delimiters to ""
      
      -- Format each argument with proper quoting
      repeat with arg in argsList
        set trimmedArg to my trim_string(arg)
        if trimmedArg is not "" then
          set formattedArgs to formattedArgs & " " & quoted form of trimmedArg
        end if
      end repeat
    end if
    
    -- Process environment variables
    set envVarCmd to ""
    if environmentVars is not missing value and environmentVars is not "" then
      -- Check if it's valid JSON format
      if not (environmentVars starts with "{" and environmentVars ends with "}") then
        return "error: Environment variables must be provided in JSON format: {\"VAR_NAME\": \"value\", ...}"
      end if
      
      -- Create a temporary file for the JSON data
      set tempJsonFile to do shell script "mktemp /tmp/env_vars_XXXXX.json"
      do shell script "echo " & quoted form of environmentVars & " > " & quoted form of tempJsonFile
      
      -- Build the environment variables section of the command
      set envVarCmd to "-e " & quoted form of tempJsonFile
    end if
    
    -- Build the launch command
    set launchCmd to "xcrun simctl launch " & quoted form of deviceIdentifier & " " & envVarCmd & " " & quoted form of bundleID & formattedArgs
    
    -- Execute the launch command
    set launchOutput to do shell script launchCmd
    
    -- Clean up temporary file if created
    if environmentVars is not missing value and environmentVars is not "" then
      do shell script "rm " & quoted form of tempJsonFile
    end if
    
    -- Build result message
    set resultMessage to "Successfully launched " & bundleID & " on " & deviceIdentifier & " simulator"
    
    if launchArgs is not missing value and launchArgs is not "" then
      set resultMessage to resultMessage & " with launch arguments:
" & launchArgs
    end if
    
    if environmentVars is not missing value and environmentVars is not "" then
      set resultMessage to resultMessage & "
Environment variables:
" & environmentVars
    end if
    
    set resultMessage to resultMessage & "

Launch output:
" & launchOutput & "

Note: Launch arguments and environment variables will only have an effect if the app is specifically coded to look for them. Common arguments include:
- UITesting
- FASTLANE_SNAPSHOT
- ResetUserDefaults
- ClearKeychainItems"
    
    return resultMessage
  on error errMsg number errNum
    return "error (" & errNum & ") launching app with arguments: " & errMsg
  end try
end setAppLaunchArguments

-- Helper function to trim whitespace from string
on trim_string(input_string)
  local input_string, trimmed_string
  set whitespace to {" ", tab, return, linefeed}
  set trimmed_string to input_string
  
  repeat while trimmed_string begins with any item of whitespace
    set trimmed_string to text 2 thru -1 of trimmed_string
  end repeat
  
  repeat while trimmed_string ends with any item of whitespace
    set trimmed_string to text 1 thru -2 of trimmed_string
  end repeat
  
  return trimmed_string
end trim_string

return my setAppLaunchArguments("--MCP_INPUT:bundleID", "--MCP_INPUT:launchArgs", "--MCP_INPUT:environmentVars", "--MCP_INPUT:deviceIdentifier")
```
