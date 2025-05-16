---
title: "Xcode: Reset All Simulators"
category: "09_developer_and_utility_apps"
id: xcode_reset_all_simulators
description: "Resets all iOS, iPadOS, watchOS, and tvOS simulators to clean state."
keywords: ["Xcode", "simulator", "reset", "erase", "clean", "iOS", "iPadOS", "watchOS", "tvOS", "developer"]
language: applescript
isComplex: true
argumentsPrompt: "Optional boolean 'shutdownAfterReset' to shut down simulator service after reset (default is true)"
notes: |
  - Forces Simulator app to quit before resetting
  - Uses xcrun simctl to reset all simulators at once
  - Erases all content and settings from all simulator devices
  - Optionally shuts down the CoreSimulator service when finished
  - Helps resolve simulator-related issues quickly by starting fresh
  - More efficient than resetting simulators one by one through the UI
---

```applescript
--MCP_INPUT:shutdownAfterReset

on resetAllSimulators(shutdownAfterReset)
  -- Default to shutdown after reset unless explicitly set to false
  if shutdownAfterReset is missing value or shutdownAfterReset is "" then
    set shutdownAfterReset to true
  else if shutdownAfterReset is "false" then
    set shutdownAfterReset to false
  end if
  
  -- Quit Simulator if it's running
  set isSimulatorRunning to false
  try
    tell application "System Events"
      if exists (process "Simulator") then
        set isSimulatorRunning to true
      end if
    end tell
    
    if isSimulatorRunning then
      tell application "Simulator" to quit
      delay 2 -- Wait for Simulator to quit properly
    end if
  on error errMsg
    return "Error checking if Simulator is running: " & errMsg
  end try
  
  -- Reset all simulators using xcrun simctl
  try
    set resetOutput to do shell script "xcrun simctl erase all"
    set resetSuccessful to true
  on error errMsg
    set resetOutput to errMsg
    set resetSuccessful to false
  end try
  
  -- Optionally shut down the CoreSimulator service
  set shutdownResults to "CoreSimulator service not shut down (per user request)"
  if shutdownAfterReset then
    try
      set shutdownOutput to do shell script "xcrun simctl shutdown all && pkill -int com.apple.CoreSimulator.CoreSimulatorService"
      set shutdownResults to "CoreSimulator service shut down successfully"
    on error errMsg
      set shutdownResults to "Error shutting down CoreSimulator service: " & errMsg
    end try
  end if
  
  -- Return results
  if resetSuccessful then
    set resultText to "Successfully reset all simulators.
" & shutdownResults & "

Reset output:
" & resetOutput & "

All simulators have been reset to factory settings.
Any installed apps and user data have been removed."
  else
    set resultText to "Failed to reset simulators.
Error: " & resetOutput
  end if
  
  return resultText
end resetAllSimulators

return my resetAllSimulators("--MCP_INPUT:shutdownAfterReset")
```