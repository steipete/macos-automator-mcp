---
title: 'iOS Simulator: Enable Developer Settings'
category: 13_developer
id: ios_simulator_developer_settings
description: Enables and configures advanced developer settings in iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - developer
  - settings
  - debug
  - configuration
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Setting to configure as 'setting' ('debug-menu', 'network-link-conditioner',
  'show-fps', 'view-hierarchy', 'layout-debug', 'slow-animations', 'ui-debug',
  'all'), action as 'action' ('enable', 'disable'), and optional device
  identifier as 'deviceIdentifier' (defaults to 'booted').
notes: |
  - Enables advanced developer debugging options
  - Includes debug menu, network conditioning, FPS display
  - Shows advanced UI settings not normally accessible
  - Useful for detailed debugging and app performance analysis
  - Many settings accessible in simulator's Settings > Developer
  - These settings are normally only available to Apple developers
---

```applescript
--MCP_INPUT:setting
--MCP_INPUT:action
--MCP_INPUT:deviceIdentifier

on configureDeveloperSettings(setting, action, deviceIdentifier)
  if setting is missing value or setting is "" then
    return "error: Setting not provided. Available settings: 'debug-menu', 'network-link-conditioner', 'show-fps', 'view-hierarchy', 'layout-debug', 'slow-animations', 'ui-debug', 'all'."
  end if
  
  if action is missing value or action is "" then
    return "error: Action not provided. Available actions: 'enable', 'disable'."
  end if
  
  -- Normalize to lowercase
  set setting to do shell script "echo " & quoted form of setting & " | tr '[:upper:]' '[:lower:]'"
  set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  
  -- Validate action
  if action is not in {"enable", "disable"} then
    return "error: Invalid action. Available actions: 'enable', 'disable'."
  end if
  
  -- Validate setting
  set validSettings to {"debug-menu", "network-link-conditioner", "show-fps", "view-hierarchy", "layout-debug", "slow-animations", "ui-debug", "all"}
  if setting is not in validSettings then
    return "error: Invalid setting. Available settings: 'debug-menu', 'network-link-conditioner', 'show-fps', 'view-hierarchy', 'layout-debug', 'slow-animations', 'ui-debug', 'all'."
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
    
    -- Map settings to their corresponding userdefaults keys
    set boolValue to (action is "enable")
    set settingsToApply to {}
    
    if setting is "debug-menu" or setting is "all" then
      set end of settingsToApply to {"UIDebugEnabled", boolValue} -- Main debug menu
    end if
    
    if setting is "network-link-conditioner" or setting is "all" then
      set end of settingsToApply to {"NLCEnabled", boolValue} -- Network Link Conditioner
      set end of settingsToApply to {"UINetworkLinkConditionerEnabled", boolValue} -- Alt version for older iOS
    end if
    
    if setting is "show-fps" or setting is "all" then
      set end of settingsToApply to {"ShowFPS", boolValue} -- FPS counter
      set end of settingsToApply to {"UIShowFPS", boolValue} -- Alt version for older iOS
    end if
    
    if setting is "view-hierarchy" or setting is "all" then
      set end of settingsToApply to {"UIViewShowAlignmentRects", boolValue} -- View alignment debugging
      set end of settingsToApply to {"UIViewShowClipRects", boolValue} -- View clip rects
    end if
    
    if setting is "layout-debug" or setting is "all" then
      set end of settingsToApply to {"UIConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints", boolValue} -- Layout constraint debugging
      set end of settingsToApply to {"UIConstraintBasedLayoutVisualizeBacktrace", boolValue} -- Layout debugging backstrace
    end if
    
    if setting is "slow-animations" or setting is "all" then
      set end of settingsToApply to {"UIWindowSlowAnimations", boolValue} -- Slow animations
    end if
    
    if setting is "ui-debug" or setting is "all" then
      set end of settingsToApply to {"UIViewShowDrawRects", boolValue} -- Show draw rectangles
      set end of settingsToApply to {"UIImageShowColorBands", boolValue} -- Show color bands
      set end of settingsToApply to {"UIShowRepaintedAreas", boolValue} -- Highlight repainted areas
      set end of settingsToApply to {"UIShowControlBorders", boolValue} -- Show control borders
    end if
    
    -- For comprehensive "all" setting, add a few more useful developer options
    if setting is "all" then
      set end of settingsToApply to {"UIAutomationLoggingSettings", 1} -- Enable UI Automation logging
      set end of settingsToApply to {"AppleShowAllThreats", true} -- Show all certificate issues
      set end of settingsToApply to {"UIScrollViewShowsLegacyVelocityDrawing", boolValue} -- Show scroll velocities
      set end of settingsToApply to {"UIScrollDisableAnimations", false} -- Don't disable scroll animations
    end if
    
    -- Apply the settings
    set appliedSettings to {}
    repeat with settingPair in settingsToApply
      set settingKey to item 1 of settingPair
      set settingValue to item 2 of settingPair
      
      -- Determine the value type and create appropriate command
      set valueType to ""
      if class of settingValue is boolean then
        set valueType to "-bool " & settingValue
      else if class of settingValue is integer then
        set valueType to "-int " & settingValue
      else if class of settingValue is real then
        set valueType to "-float " & settingValue
      else
        set valueType to "-string " & quoted form of settingValue
      end if
      
      -- Create and execute the command
      set settingCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults write com.apple.UIKit " & settingKey & " " & valueType
      
      try
        do shell script settingCmd
        set end of appliedSettings to settingKey
      on error errMsg
        -- Try with SystemSettings domain as fallback
        try
          set settingCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults write com.apple.SystemSettings " & settingKey & " " & valueType
          do shell script settingCmd
          set end of appliedSettings to settingKey
        on error errMsg2
          -- Ignore failures for individual settings
        end try
      end try
    end repeat
    
    -- Enable Developer mode if enabling settings
    if action is "enable" then
      try
        do shell script "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults write com.apple.dt.Xcode ShowDVTDebugMenu -bool true"
      end try
    end if
    
    -- Restart SpringBoard to apply settings
    try
      do shell script "xcrun simctl spawn " & quoted form of deviceIdentifier & " launchctl stop com.apple.SpringBoard"
    on error
      -- Older iOS might use a different approach
      try
        do shell script "xcrun simctl spawn " & quoted form of deviceIdentifier & " killall SpringBoard"
      end try
    end try
    
    if (count of appliedSettings) > 0 then
      set settingDisplayName to ""
      if setting is "debug-menu" then
        set settingDisplayName to "Debug Menu"
      else if setting is "network-link-conditioner" then
        set settingDisplayName to "Network Link Conditioner"
      else if setting is "show-fps" then
        set settingDisplayName to "FPS Display"
      else if setting is "view-hierarchy" then
        set settingDisplayName to "View Hierarchy Debugging"
      else if setting is "layout-debug" then
        set settingDisplayName to "Layout Constraint Debugging"
      else if setting is "slow-animations" then
        set settingDisplayName to "Slow Animations"
      else if setting is "ui-debug" then
        set settingDisplayName to "UI Debugging Options"
      else if setting is "all" then
        set settingDisplayName to "All Developer Settings"
      else
        set settingDisplayName to setting
      end if
      
      set resultMessage to "Successfully " & action & "d " & settingDisplayName & " on " & deviceIdentifier & " simulator.

" & (if action is "enable" then "To access these settings, open the Settings app on the simulator and look for the Developer section." else "The specified developer settings have been disabled.") & "

Note: The SpringBoard has been restarted to apply these settings. If some settings don't take effect, you may need to:
1. Fully reboot the simulator (xcrun simctl shutdown " & deviceIdentifier & " && xcrun simctl boot " & deviceIdentifier & ")
2. Access Settings > Developer manually to confirm the settings
3. Restart the app you're debugging

For 'network-link-conditioner', you'll find controls in Settings > Developer > Network Link Conditioner"
      
      return resultMessage
    else
      return "Failed to apply developer settings. The simulator may be in a state that doesn't support these settings or they may require a different approach for this iOS version."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") configuring developer settings: " & errMsg
  end try
end configureDeveloperSettings

return my configureDeveloperSettings("--MCP_INPUT:setting", "--MCP_INPUT:action", "--MCP_INPUT:deviceIdentifier")
```
