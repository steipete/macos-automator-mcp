---
title: 'iOS Simulator: Configure Touch Indicators'
category: 13_developer/xcode_app
id: ios_simulator_touch_indicators
description: Configures touch indicators and visual feedback in iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - touch
  - indicators
  - visual
  - feedback
  - interaction
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: false
argumentsPrompt: >-
  Enable touch indicators as 'enableTouchIndicators' ('true' or 'false'),
  optional boolean to enable edge gestures highlights as 'enableEdgeGestures'
  (default matches enableTouchIndicators), and optional boolean to show touch
  points coordinates as 'showCoordinates' (default is false).
notes: |
  - Shows visual indicators for touches and gestures in simulator
  - Useful for demonstrations, tutorials, and recordings
  - Helps visualize touch points in screen recordings
  - Can show edge gestures for screen edge interactions
  - Displays actual touch point coordinates for precision
  - Takes effect immediately without simulator restart
---

```applescript
--MCP_INPUT:enableTouchIndicators
--MCP_INPUT:enableEdgeGestures
--MCP_INPUT:showCoordinates

on configureTouchIndicators(enableTouchIndicators, enableEdgeGestures, showCoordinates)
  if enableTouchIndicators is missing value or enableTouchIndicators is "" then
    return "error: Touch indicator setting not provided. Specify 'true' to enable touch indicators or 'false' to disable them."
  end if
  
  -- Normalize settings
  if enableTouchIndicators is "true" or enableTouchIndicators is "yes" or enableTouchIndicators is "1" then
    set enableTouchIndicators to true
  else
    set enableTouchIndicators to false
  end if
  
  -- Default edge gestures to match touch indicators if not specified
  if enableEdgeGestures is missing value or enableEdgeGestures is "" then
    set enableEdgeGestures to enableTouchIndicators
  else if enableEdgeGestures is "true" or enableEdgeGestures is "yes" or enableEdgeGestures is "1" then
    set enableEdgeGestures to true
  else
    set enableEdgeGestures to false
  end if
  
  -- Default coordinate display to false if not specified
  if showCoordinates is missing value or showCoordinates is "" then
    set showCoordinates to false
  else if showCoordinates is "true" or showCoordinates is "yes" or showCoordinates is "1" then
    set showCoordinates to true
  else
    set showCoordinates to false
  end if
  
  try
    -- Close simulator before changing settings
    set simulatorRunning to false
    tell application "System Events"
      if exists process "Simulator" then
        set simulatorRunning to true
      end if
    end tell
    
    -- Set the single touch indicator preference
    do shell script "defaults write com.apple.iphonesimulator ShowSingleTouches -bool " & enableTouchIndicators
    
    -- Set the edge gestures preference
    do shell script "defaults write com.apple.iphonesimulator ShowEdgeGestures -bool " & enableEdgeGestures
    
    -- Set the coordinate display preference
    if showCoordinates then
      do shell script "defaults write com.apple.iphonesimulator ShowPointCoordinates -bool true"
    else
      do shell script "defaults delete com.apple.iphonesimulator ShowPointCoordinates 2>/dev/null || true"
    end if
    
    -- If simulator was running, restart it to apply settings
    if simulatorRunning then
      tell application "Simulator" to quit
      delay 2
      tell application "Simulator" to activate
      delay 3
    end if
    
    -- Build result message
    set resultMessage to "Successfully " & (if enableTouchIndicators then "enabled" else "disabled") & " touch indicators"
    
    if enableEdgeGestures is not equal to enableTouchIndicators then
      set resultMessage to resultMessage & " and " & (if enableEdgeGestures then "enabled" else "disabled") & " edge gesture indicators"
    end if
    
    if showCoordinates then
      set resultMessage to resultMessage & " with coordinate display enabled"
    end if
    
    set resultMessage to resultMessage & ".

Current simulator touch visualization settings:
- Touch points: " & (if enableTouchIndicators then "Visible" else "Hidden") & "
- Edge gestures: " & (if enableEdgeGestures then "Visible" else "Hidden") & "
- Coordinate display: " & (if showCoordinates then "Visible" else "Hidden") & "

" & (if simulatorRunning then "The simulator has been restarted to apply these settings." else "These settings will take effect the next time you launch the simulator.") & "

Touch indicators are particularly useful for:
- Recording tutorial videos
- Demonstrating app interactions
- Precise positioning of UI elements"
    
    return resultMessage
  on error errMsg number errNum
    return "error (" & errNum & ") configuring touch indicators: " & errMsg
  end try
end configureTouchIndicators

return my configureTouchIndicators("--MCP_INPUT:enableTouchIndicators", "--MCP_INPUT:enableEdgeGestures", "--MCP_INPUT:showCoordinates")
```
