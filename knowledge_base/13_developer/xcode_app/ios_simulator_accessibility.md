---
title: 'iOS Simulator: Configure Accessibility Features'
category: 13_developer
id: ios_simulator_accessibility
description: >-
  Configures accessibility features in iOS Simulator for testing app
  accessibility.
keywords:
  - iOS Simulator
  - Xcode
  - accessibility
  - VoiceOver
  - testing
  - AX
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Accessibility feature as 'feature' ('voiceover', 'invert-colors',
  'reduce-motion', 'bold-text', 'increase-contrast', 'reduce-transparency',
  'zoom'), action as 'action' ('enable', 'disable'), and optional device
  identifier as 'deviceIdentifier' (defaults to 'booted').
notes: |
  - Configures accessibility features in simulator
  - Helps test app accessibility compliance
  - Useful for validating accessibility label correctness
  - Simulates accessibility needs for comprehensive testing
  - Changes take effect immediately without simulator restart
  - Features include VoiceOver, visual accommodations, and text adaptations
---

```applescript
--MCP_INPUT:feature
--MCP_INPUT:action
--MCP_INPUT:deviceIdentifier

on configureSimulatorAccessibility(feature, action, deviceIdentifier)
  if feature is missing value or feature is "" then
    return "error: Accessibility feature not provided. Available features: 'voiceover', 'invert-colors', 'reduce-motion', 'bold-text', 'increase-contrast', 'reduce-transparency', 'zoom'."
  end if
  
  if action is missing value or action is "" then
    return "error: Action not provided. Available actions: 'enable', 'disable'."
  end if
  
  -- Normalize to lowercase
  set feature to do shell script "echo " & quoted form of feature & " | tr '[:upper:]' '[:lower:]'"
  set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  
  -- Map feature names to their settings keys
  set featureMap to {¬
    {"voiceover", "com.apple.Accessibility.VoiceOverTouchEnabled"}, ¬
    {"invert-colors", "com.apple.Accessibility.invert-colors"}, ¬
    {"reduce-motion", "com.apple.Accessibility.ReduceMotion"}, ¬
    {"bold-text", "com.apple.Accessibility.BoldText"}, ¬
    {"increase-contrast", "com.apple.Accessibility.IncreaseContrast"}, ¬
    {"reduce-transparency", "com.apple.Accessibility.ReduceTransparency"}, ¬
    {"zoom", "com.apple.Accessibility.zoom"} ¬
  }
  
  -- Find the setting key for the requested feature
  set settingKey to ""
  repeat with featurePair in featureMap
    if item 1 of featurePair is feature then
      set settingKey to item 2 of featurePair
      exit repeat
    end if
  end repeat
  
  if settingKey is "" then
    return "error: Unrecognized accessibility feature '" & feature & "'. Available features: 'voiceover', 'invert-colors', 'reduce-motion', 'bold-text', 'increase-contrast', 'reduce-transparency', 'zoom'."
  end if
  
  -- Validate action
  if action is not in {"enable", "disable"} then
    return "error: Invalid action. Available actions: 'enable', 'disable'."
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
    
    -- Convert action to boolean value
    set boolValue to (action is "enable")
    
    -- Build the command to change the accessibility setting
    set accessibilityCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults write com.apple.Accessibility " & settingKey & " -bool " & boolValue
    
    try
      do shell script accessibilityCmd
      set accessibilityChanged to true
    on error errMsg
      return "Error changing accessibility setting: " & errMsg
    end try
    
    -- Special handling for VoiceOver which may require additional notifications
    if feature is "voiceover" and accessibilityChanged then
      -- Notify system about the VoiceOver state change
      try
        set notifyCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -p com.apple.Accessibility.VoiceOverStatusChanged"
        do shell script notifyCmd
      end try
    end if
    
    -- For some features like bold text, a restart is required
    set requiresRestart to (feature is in {"bold-text"})
    
    if accessibilityChanged then
      set featureDisplayName to ""
      if feature is "voiceover" then
        set featureDisplayName to "VoiceOver"
      else if feature is "invert-colors" then
        set featureDisplayName to "Invert Colors"
      else if feature is "reduce-motion" then
        set featureDisplayName to "Reduce Motion"
      else if feature is "bold-text" then
        set featureDisplayName to "Bold Text"
      else if feature is "increase-contrast" then
        set featureDisplayName to "Increase Contrast"
      else if feature is "reduce-transparency" then
        set featureDisplayName to "Reduce Transparency"
      else if feature is "zoom" then
        set featureDisplayName to "Zoom"
      else
        set featureDisplayName to feature
      end if
      
      set resultMessage to "Successfully " & action & "d " & featureDisplayName & " accessibility feature on " & deviceIdentifier & " simulator."
      
      if requiresRestart then
        set resultMessage to resultMessage & "

Note: The simulator needs to be restarted for this change to take effect. You can restart it with:
xcrun simctl shutdown " & deviceIdentifier & " && xcrun simctl boot " & deviceIdentifier
      end if
      
      if feature is "voiceover" and action is "enable" then
        set resultMessage to resultMessage & "

VoiceOver Gestures:
- Single tap: Speak item
- Double tap: Activate selected item
- Three-finger swipe: Scroll
- Flick right/left: Move to next/previous item

To disable VoiceOver in simulator UI: Settings > Accessibility > VoiceOver"
      end if
      
      return resultMessage
    else
      return "Failed to " & action & " " & feature & " accessibility feature on " & deviceIdentifier & " simulator."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") configuring simulator accessibility: " & errMsg
  end try
end configureSimulatorAccessibility

return my configureSimulatorAccessibility("--MCP_INPUT:feature", "--MCP_INPUT:action", "--MCP_INPUT:deviceIdentifier")
```
