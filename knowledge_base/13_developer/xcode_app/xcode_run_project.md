---
title: "Xcode: Run Project"
category: "09_developer_and_utility_apps"
id: xcode_run_project
description: "Runs an open Xcode project, launching the app in the simulator or on a device."
keywords: ["Xcode", "run", "launch", "simulator", "device", "developer", "iOS", "macOS"]
language: applescript
isComplex: true
argumentsPrompt: "Optional wait time (in seconds) after run starts as 'waitTime' in inputData (default is 20 seconds)"
notes: |
  - Requires Xcode to be already open with a project loaded
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Waits for the specified time before continuing
  - Handles both running and debugging modes
---

```applescript
--MCP_INPUT:waitTime
--MCP_INPUT:useDebugMode

on runXcodeProject(waitTime, useDebugMode)
  -- Default wait time of 20 seconds if not specified
  if waitTime is missing value or waitTime is "" then
    set waitTime to 20
  else
    try
      set waitTime to waitTime as number
    on error
      set waitTime to 20
    end try
  end if
  
  -- Default debug mode to false if not specified
  if useDebugMode is missing value or useDebugMode is "" then
    set useDebugMode to false
  else if useDebugMode is "true" or useDebugMode is true then
    set useDebugMode to true
  else
    set useDebugMode to false
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Select Product menu
        click menu item "Product" of menu bar 1
        delay 0.5
        
        -- Click Run or Debug menu item based on debug mode preference
        if useDebugMode then
          click menu item "Debug" of menu "Product" of menu bar 1
        else
          click menu item "Run" of menu "Product" of menu bar 1
        end if
        
        -- Wait for app to launch
        delay waitTime
        
        -- Return result based on debug mode
        if useDebugMode then
          return "Debug started successfully, waiting " & waitTime & " seconds for launch"
        else
          return "Run started successfully, waiting " & waitTime & " seconds for launch"
        end if
      end tell
    end tell
  on error errMsg number errNum
    return "error (" & errNum & ") running Xcode project: " & errMsg
  end try
end runXcodeProject

return my runXcodeProject("--MCP_INPUT:waitTime", "--MCP_INPUT:useDebugMode")
```