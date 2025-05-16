---
title: 'System: App-Specific Volume Control'
category: 04_system/audio_control
id: app_specific_volume
description: >-
  Control volume levels for specific applications independently from the system
  volume.
keywords:
  - volume
  - audio
  - app-specific
  - application
  - sound
  - control
  - mixer
language: applescript
parameters: >
  - app_name (required): Name of the application to control (e.g., "Safari",
  "Music", "Spotify")

  - action (required): Action to perform - "get", "set", "mute", "unmute"

  - volume_level (optional): Volume level to set (0-100) for "set" action
notes: >
  - This script requires a third-party utility for full functionality.

  - The most reliable way to control per-app volume is with utilities like
  Background Music or Sound Control.

  - The script will attempt to use various methods to control app-specific
  volume.

  - For Safari, Chrome, and some other browsers, HTML5 audio can be controlled
  via JavaScript.

  - For apps with AppleScript support, their own volume commands will be used if
  available.

  - For other apps, the script will provide instructions for installing a
  third-party utility.

  - Some actions may require accessibility permissions to be granted to the
  script runner.
---

Control volume levels for specific applications independently from the system volume.

```applescript
-- Get parameters
set appNameParam to "--MCP_INPUT:app_name"
if appNameParam is "" or appNameParam is "--MCP_INPUT:app_name" then
  return "Error: No application name provided. Please specify the app_name parameter."
end if

set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "get" -- Default action: get volume
end if

set volumeLevelParam to "--MCP_INPUT:volume_level"
if volumeLevelParam is "" or volumeLevelParam is "--MCP_INPUT:volume_level" then
  set volumeLevelParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"get", "set", "mute", "unmute"}
set isValidAction to false
repeat with validAction in validActions
  if actionParam is validAction then
    set isValidAction to true
    exit repeat
  end if
end repeat

if not isValidAction then
  return "Error: Invalid action. Valid options are: " & validActions
end if

-- Validate required parameters for specific actions
if actionParam is "set" and volumeLevelParam is "" then
  return "Error: The 'set' action requires a volume_level parameter (0-100)."
end if

-- Validate volume level parameter if provided
if volumeLevelParam is not "" then
  try
    set volumeLevel to volumeLevelParam as number
    if volumeLevel < 0 or volumeLevel > 100 then
      return "Error: Volume level must be between 0 and 100."
    end if
  on error
    return "Error: Volume level must be a number between 0 and 100."
  end try
end if

-- Check if Background Music is installed
set backgroundMusicInstalled to false
tell application "System Events"
  set backgroundMusicInstalled to exists application process "Background Music"
end tell

-- Check if Sound Control is installed
set soundControlInstalled to false
tell application "System Events"
  set soundControlInstalled to exists application process "Sound Control"
end tell

-- Determine if the app is running
set appIsRunning to false
tell application "System Events"
  set appIsRunning to exists application process appNameParam
end tell

if not appIsRunning then
  return "Error: Application '" & appNameParam & "' is not running. Please launch it first."
end if

-- Handle special cases for different apps
if appNameParam is "Music" or appNameParam is "iTunes" then
  -- Handle Music.app / iTunes.app (which have built-in volume control)
  set appName to "Music"
  if application "Music" is not running and application "iTunes" is running then
    set appName to "iTunes"
  end if
  
  tell application appName
    if actionParam is "get" then
      -- Get current volume
      set currentVolume to sound volume
      return "Current volume for " & appName & ": " & currentVolume & "%"
      
    else if actionParam is "set" then
      -- Set volume
      set sound volume to volumeLevel
      return "Set " & appName & " volume to " & volumeLevel & "%"
      
    else if actionParam is "mute" then
      -- Mute by setting volume to 0
      set oldVolume to sound volume
      set sound volume to 0
      return "Muted " & appName & " (previous volume was " & oldVolume & "%)"
      
    else if actionParam is "unmute" then
      -- Unmute if volume is 0
      if sound volume is 0 then
        -- Unmute to 50% if volume was 0
        set sound volume to 50
        return "Unmuted " & appName & " (set to 50%)"
      else
        return appName & " is already unmuted (volume: " & sound volume & "%)"
      end if
    end if
  end tell
  
else if appNameParam is "Spotify" then
  -- Handle Spotify (which has built-in volume control)
  tell application "Spotify"
    if actionParam is "get" then
      -- Get current volume
      set currentVolume to sound volume
      return "Current volume for Spotify: " & currentVolume & "%"
      
    else if actionParam is "set" then
      -- Set volume
      set sound volume to volumeLevel
      return "Set Spotify volume to " & volumeLevel & "%"
      
    else if actionParam is "mute" then
      -- Mute by setting volume to 0
      set oldVolume to sound volume
      set sound volume to 0
      return "Muted Spotify (previous volume was " & oldVolume & "%)"
      
    else if actionParam is "unmute" then
      -- Unmute if volume is 0
      if sound volume is 0 then
        -- Unmute to 50% if volume was 0
        set sound volume to 50
        return "Unmuted Spotify (set to 50%)"
      else
        return "Spotify is already unmuted (volume: " & sound volume & "%)"
      end if
    end if
  end tell
  
else if appNameParam contains "Safari" or appNameParam contains "Chrome" or appNameParam contains "Firefox" or appNameParam contains "Edge" then
  -- Handle web browsers (can use JavaScript to control volume of media elements)
  
  -- Determine which browser we're working with
  set browserName to appNameParam
  set browserApp to appNameParam
  
  if actionParam is "get" then
    -- We can't reliably get the volume of media elements across tabs
    return "Getting browser media volume is not supported directly." & return & return & 
      "Browser media volume control requires the active tab to have playing media." & return & 
      "Consider using a browser extension for better control of media volume."
    
  else
    -- For set, mute, unmute - try to use JavaScript to control media elements
    set jsCommand to ""
    
    if actionParam is "set" then
      set jsCommand to "document.querySelectorAll('audio, video').forEach(function(el) { el.volume = " & (volumeLevel / 100) & "; });"
    else if actionParam is "mute" then
      set jsCommand to "document.querySelectorAll('audio, video').forEach(function(el) { el.muted = true; });"
    else if actionParam is "unmute" then
      set jsCommand to "document.querySelectorAll('audio, video').forEach(function(el) { el.muted = false; });"
    end if
    
    -- Try to execute JavaScript in the browser
    if browserName contains "Safari" then
      tell application "Safari"
        tell current tab of front window
          do JavaScript jsCommand
        end tell
      end tell
      
      if actionParam is "set" then
        return "Attempted to set media volume to " & volumeLevel & "% in Safari's active tab."
      else if actionParam is "mute" then
        return "Attempted to mute media in Safari's active tab."
      else if actionParam is "unmute" then
        return "Attempted to unmute media in Safari's active tab."
      end if
      
    else if browserName contains "Chrome" then
      tell application "Google Chrome"
        tell active tab of front window
          execute javascript jsCommand
        end tell
      end tell
      
      if actionParam is "set" then
        return "Attempted to set media volume to " & volumeLevel & "% in Chrome's active tab."
      else if actionParam is "mute" then
        return "Attempted to mute media in Chrome's active tab."
      else if actionParam is "unmute" then
        return "Attempted to unmute media in Chrome's active tab."
      end if
      
    else
      -- For other browsers, we don't have a reliable way to execute JS
      return "JavaScript volume control is only supported for Safari and Chrome." & return & return & 
        "Consider using one of these third-party utilities:" & return & 
        "- Background Music: https://github.com/kyleneideck/BackgroundMusic" & return & 
        "- Sound Control: https://staticz.com/soundcontrol/"
    end if
  end if
  
else if soundControlInstalled then
  -- If Sound Control is installed, use it
  if actionParam is "get" then
    try
      tell application "Sound Control"
        set apps to audio apps
        repeat with anApp in apps
          if id of anApp contains appNameParam then
            set appVolume to volume of anApp
            set appMuted to muted of anApp
            
            set resultText to "Current volume for '" & appNameParam & "' (via Sound Control): " & (appVolume * 100) & "%"
            if appMuted then
              set resultText to resultText & " (muted)"
            end if
            
            return resultText
          end if
        end repeat
      end tell
      
      return "Could not find '" & appNameParam & "' in Sound Control's audio apps."
    on error errMsg
      return "Error getting volume via Sound Control: " & errMsg
    end try
    
  else if actionParam is "set" then
    try
      tell application "Sound Control"
        set apps to audio apps
        repeat with anApp in apps
          if id of anApp contains appNameParam then
            set volume of anApp to (volumeLevel / 100)
            return "Set volume for '" & appNameParam & "' to " & volumeLevel & "% via Sound Control."
          end if
        end repeat
      end tell
      
      return "Could not find '" & appNameParam & "' in Sound Control's audio apps."
    on error errMsg
      return "Error setting volume via Sound Control: " & errMsg
    end try
    
  else if actionParam is "mute" then
    try
      tell application "Sound Control"
        set apps to audio apps
        repeat with anApp in apps
          if id of anApp contains appNameParam then
            set muted of anApp to true
            return "Muted '" & appNameParam & "' via Sound Control."
          end if
        end repeat
      end tell
      
      return "Could not find '" & appNameParam & "' in Sound Control's audio apps."
    on error errMsg
      return "Error muting via Sound Control: " & errMsg
    end try
    
  else if actionParam is "unmute" then
    try
      tell application "Sound Control"
        set apps to audio apps
        repeat with anApp in apps
          if id of anApp contains appNameParam then
            set muted of anApp to false
            return "Unmuted '" & appNameParam & "' via Sound Control."
          end if
        end repeat
      end tell
      
      return "Could not find '" & appNameParam & "' in Sound Control's audio apps."
    on error errMsg
      return "Error unmuting via Sound Control: " & errMsg
    end try
  end if
  
else if backgroundMusicInstalled then
  -- If Background Music is installed, provide information
  -- (Background Music doesn't have AppleScript support, but the user should know it's available)
  return "Background Music is installed, but it doesn't support AppleScript control." & return & return & 
    "You can control app-specific volume through the Background Music menu bar icon."
  
else
  -- No app-specific volume control available
  set resultText to "App-specific volume control for '" & appNameParam & "' is not directly available." & return & return
  
  set resultText to resultText & "For app-specific volume control, you can install one of these utilities:" & return
  set resultText to resultText & "1. Background Music (free): https://github.com/kyleneideck/BackgroundMusic" & return
  set resultText to resultText & "2. Sound Control (paid): https://staticz.com/soundcontrol/" & return & return
  
  set resultText to resultText & "These utilities allow you to control the volume of individual applications independently from your system volume."
  
  return resultText
end if
```
