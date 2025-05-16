---
title: "iOS Simulator: Open URL"
category: "09_developer_and_utility_apps"
id: ios_simulator_open_url
description: "Opens a URL in iOS Simulator's Safari or in an app with a custom URL scheme."
keywords: ["iOS Simulator", "Xcode", "URL", "Safari", "browser", "deep link", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: false
argumentsPrompt: "URL to open as 'url' (web URL or custom URL scheme), and optional device identifier as 'deviceIdentifier' (defaults to 'booted')."
notes: |
  - Opens web URLs in simulator's Safari browser
  - Can open apps using custom URL schemes (e.g., maps://)
  - Tests deep linking functionality in apps
  - Useful for debugging web content in simulator Safari
  - Can target specific simulator by device identifier
  - The simulator must be booted and running for this to work
---

```applescript
--MCP_INPUT:url
--MCP_INPUT:deviceIdentifier

on openURLInSimulator(url, deviceIdentifier)
  if url is missing value or url is "" then
    return "error: URL not provided. Specify a URL to open in the simulator."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Ensure URL is properly formatted
  if not (url starts with "http://" or url starts with "https://" or url contains "://") then
    -- If it's a plain domain, add https:// prefix
    if url contains "." and not (url contains " ") and not (url contains "/") then
      set url to "https://" & url
    else
      -- If it's not a URL scheme and not a domain, assume it's a search query
      set searchQueryEncoded to do shell script "python -c 'import urllib.parse; print(urllib.parse.quote(\"" & url & "\"))'"
      set url to "https://www.google.com/search?q=" & searchQueryEncoded
    end if
  end if
  
  try
    -- Check if the simulator is running
    set checkSimulatorCmd to "pgrep -q Simulator && echo 'running' || echo 'not running'"
    set simulatorStatus to do shell script checkSimulatorCmd
    
    if simulatorStatus is "not running" then
      -- Launch Simulator
      tell application "Simulator" to activate
      delay 3
    end if
    
    -- Check if the device is booted
    if deviceIdentifier is "booted" then
      set checkBootedCmd to "xcrun simctl list devices | grep '(Booted)'"
      try
        do shell script checkBootedCmd
      on error
        return "error: No booted simulator devices found. Please boot a simulator device first."
      end try
    else
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & ".*Booted'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found or not booted. Please boot the device first."
      end try
    end if
    
    -- Open the URL in the simulator
    set openURLCmd to "xcrun simctl openurl " & quoted form of deviceIdentifier & " " & quoted form of url
    do shell script openURLCmd
    
    -- Determine what kind of URL it is for better messaging
    set urlType to "web page"
    if not (url starts with "http://" or url starts with "https://") then
      set urlType to "app using custom URL scheme"
    end if
    
    return "Successfully opened " & urlType & " in simulator:
URL: " & url & "
Device: " & deviceIdentifier
  on error errMsg number errNum
    return "error (" & errNum & ") opening URL in simulator: " & errMsg
  end try
end openURLInSimulator

return my openURLInSimulator("--MCP_INPUT:url", "--MCP_INPUT:deviceIdentifier")
```