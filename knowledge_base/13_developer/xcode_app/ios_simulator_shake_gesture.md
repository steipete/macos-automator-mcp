---
title: 'iOS Simulator: Simulate Shake Gesture'
category: 13_developer/xcode_app
id: ios_simulator_shake_gesture
description: Simulates device shake gesture in iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - shake
  - gesture
  - motion
  - acceleration
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: false
argumentsPrompt: >-
  Optional device identifier as 'deviceIdentifier' (defaults to 'booted'),
  optional intensity as 'intensity' (1-5, defaults to 3).
notes: |
  - Simulates device shake gesture for testing motion responses
  - Tests shake-to-undo and other shake-based interactions
  - Can specify the shake intensity
  - Helps test motion handling without physical device
  - Requires simulator to be running
  - Works with all iOS simulators
---

```applescript
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:intensity

on simulateShakeGesture(deviceIdentifier, intensity)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default intensity to 3 (medium) if not specified or invalid
  if intensity is missing value or intensity is "" then
    set intensity to 3
  else
    try
      set intensity to intensity as number
      if intensity < 1 or intensity > 5 then
        set intensity to 3
      end if
    on error
      set intensity to 3
    end try
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
    
    -- There are multiple ways to trigger shake:
    -- 1. Use simctl directly - most reliable when available
    set shakeSuccess to false
    
    -- Try direct simctl command (newer Xcode versions)
    try
      set shakeCmd to "xcrun simctl shake " & quoted form of deviceIdentifier
      do shell script shakeCmd
      set shakeSuccess to true
    on error
      -- Command may not exist in older Xcode versions
      set shakeSuccess to false
    end try
    
    -- If direct command failed, try UI automation approach
    if not shakeSuccess then
      -- Make sure simulator is running and frontmost
      tell application "Simulator" to activate
      delay 0.5
      
      -- Try sending keyboard shortcut Ctrl+Cmd+Z which triggers shake in the simulator
      try
        tell application "System Events"
          tell process "Simulator"
            keystroke "z" using {control down, command down}
          end tell
        end tell
        set shakeSuccess to true
      on error
        -- If keyboard shortcut fails, try menu selection
        try
          tell application "System Events"
            tell process "Simulator"
              click menu item "Shake Gesture" of menu "Hardware" of menu bar 1
            end tell
          end tell
          set shakeSuccess to true
        on error errMenu
          return "Error simulating shake via menu: " & errMenu
        end try
      end try
    end if
    
    -- For intensity > 3, simulate multiple shakes
    if intensity > 3 and shakeSuccess then
      -- Number of repeated shakes based on intensity
      set shakeCount to intensity - 2
      
      repeat (shakeCount) times
        delay 0.3
        -- Repeat the most successful method
        if shakeSuccess then
          try
            do shell script shakeCmd
          on error
            -- Fall back to UI method
            tell application "System Events"
              tell process "Simulator"
                keystroke "z" using {control down, command down}
              end tell
            end tell
          end try
        end if
      end repeat
    end if
    
    if shakeSuccess then
      set intensityText to ""
      if intensity is 1 then
        set intensityText to "light"
      else if intensity is 2 then
        set intensityText to "moderate"
      else if intensity is 3 then
        set intensityText to "medium"
      else if intensity is 4 then
        set intensityText to "strong"
      else
        set intensityText to "very strong"
      end if
      
      return "Successfully simulated " & intensityText & " shake gesture on " & deviceIdentifier & " simulator.

This simulates the user shaking the device, which can trigger:
- Shake to undo/redo functionality
- Motion events in games and other apps
- Custom shake gesture handlers"
    else
      return "Failed to simulate shake gesture. Make sure the simulator is running and your Xcode version supports this feature."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") simulating shake gesture: " & errMsg
  end try
end simulateShakeGesture

return my simulateShakeGesture("--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:intensity")
```
