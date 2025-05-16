---
title: "System: Volume Control"
category: "02_system_interaction"
id: system_volume_control
description: "Control system volume, mute status, and audio output devices on macOS."
keywords: ["volume", "audio", "sound", "mute", "unmute", "output device", "system sound", "macOS audio"]
language: applescript
parameters: |
  - action (required): Action to perform - "set_volume", "mute", "unmute", "toggle_mute", "get_status"
  - volume_level (optional): Volume level to set (0-100) for set_volume action
notes: |
  - This script controls the main system volume and mute status.
  - The "set_volume" action requires a volume_level parameter (0-100).
  - The "mute", "unmute", and "toggle_mute" actions control the system mute status.
  - The "get_status" action returns the current volume level and mute status.
  - MacOS volume range internally is 0-7, but this script converts to/from 0-100 for better usability.
  - Some actions may require accessibility permissions to be granted to the script runner.
---

Control macOS system volume and mute status.

```applescript
-- Get action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "get_status" -- Default action: get volume status
end if

-- Get volume level parameter
set volumeLevelParam to "--MCP_INPUT:volume_level"
if volumeLevelParam is "" or volumeLevelParam is "--MCP_INPUT:volume_level" then
  set volumeLevelParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"set_volume", "mute", "unmute", "toggle_mute", "get_status"}
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
if actionParam is "set_volume" and volumeLevelParam is "" then
  return "Error: The 'set_volume' action requires a volume_level parameter (0-100)."
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

-- Execute the requested action
if actionParam is "get_status" then
  -- Get current volume status
  set currentVolumeInfo to my getVolumeInfo()
  
  set resultText to "Current System Audio Status:" & return & return
  set resultText to resultText & "Volume: " & (item 1 of currentVolumeInfo) & "%" & return
  set resultText to resultText & "Muted: " & (item 2 of currentVolumeInfo) & return
  
  -- Try to get output device information
  try
    set outputDeviceInfo to my getOutputDeviceInfo()
    
    set resultText to resultText & return & "Current Output Device:" & return
    set resultText to resultText & "Name: " & (item 1 of outputDeviceInfo) & return
    set resultText to resultText & "Type: " & (item 2 of outputDeviceInfo) & return
  on error
    -- Skip if output device info is not available
  end try
  
  return resultText
  
else if actionParam is "set_volume" then
  -- Set system volume
  try
    -- Convert volume from 0-100 to 0-7 for macOS
    set volumeLevel to volumeLevelParam as number
    set macOsVolume to round ((volumeLevel / 100) * 7)
    
    -- Set the volume
    set volume output volume volumeLevel
    
    -- Get new volume status
    set currentVolumeInfo to my getVolumeInfo()
    
    set resultText to "Volume set successfully:" & return & return
    set resultText to resultText & "New Volume: " & (item 1 of currentVolumeInfo) & "%" & return
    set resultText to resultText & "Muted: " & (item 2 of currentVolumeInfo)
    
    return resultText
  on error errMsg
    return "Error setting volume: " & errMsg
  end try
  
else if actionParam is "mute" then
  -- Mute the system volume
  try
    set volume with output muted
    
    return "System audio muted successfully."
  on error errMsg
    return "Error muting system audio: " & errMsg
  end try
  
else if actionParam is "unmute" then
  -- Unmute the system volume
  try
    set volume without output muted
    
    -- Get current volume status
    set currentVolumeInfo to my getVolumeInfo()
    
    set resultText to "System audio unmuted successfully:" & return & return
    set resultText to resultText & "Current Volume: " & (item 1 of currentVolumeInfo) & "%"
    
    return resultText
  on error errMsg
    return "Error unmuting system audio: " & errMsg
  end try
  
else if actionParam is "toggle_mute" then
  -- Toggle mute status
  try
    -- Get current mute status
    set currentVolumeInfo to my getVolumeInfo()
    set isMuted to item 2 of currentVolumeInfo
    
    if isMuted is "Yes" then
      -- Currently muted, so unmute
      set volume without output muted
      set newMuteStatus to "No"
    else
      -- Currently unmuted, so mute
      set volume with output muted
      set newMuteStatus to "Yes"
    end if
    
    set resultText to "Toggled mute status:" & return & return
    set resultText to resultText & "Previous Status: " & isMuted & return
    set resultText to resultText & "New Status: " & newMuteStatus
    
    return resultText
  on error errMsg
    return "Error toggling mute status: " & errMsg
  end try
end if

-- Helper functions

-- Get current volume and mute status
on getVolumeInfo()
  set volumeInfo to {}
  
  try
    -- Get current output volume (0-100)
    set currentVolume to output volume of (get volume settings)
    set end of volumeInfo to currentVolume
    
    -- Get current mute status
    set isMuted to output muted of (get volume settings)
    if isMuted then
      set end of volumeInfo to "Yes"
    else
      set end of volumeInfo to "No"
    end if
  on error
    set end of volumeInfo to "Unknown"
    set end of volumeInfo to "Unknown"
  end try
  
  return volumeInfo
end getVolumeInfo

-- Get information about the current output device
on getOutputDeviceInfo()
  set deviceInfo to {}
  
  try
    do shell script "system_profiler SPAudioDataType | grep 'Output'"
    
    -- Parse the output to extract device name
    set deviceOutput to (do shell script "system_profiler SPAudioDataType | grep -A 3 'Output'")
    
    -- Extract the device name (this is a simple approach and may need refinement)
    set deviceLines to paragraphs of deviceOutput
    
    -- Initialize with unknown values
    set deviceName to "Unknown"
    set deviceType to "Unknown"
    
    repeat with aLine in deviceLines
      if aLine contains ":" then
        -- Try to extract property and value
        set colonOffset to offset of ":" in aLine
        if colonOffset > 1 then
          set propName to trim(text 1 thru (colonOffset - 1) of aLine)
          set propValue to trim(text (colonOffset + 1) thru end of aLine)
          
          if propName contains "Name" then
            set deviceName to propValue
          else if propName contains "Type" then
            set deviceType to propValue
          end if
        end if
      end if
    end repeat
    
    set end of deviceInfo to deviceName
    set end of deviceInfo to deviceType
  on error
    set end of deviceInfo to "Unknown"
    set end of deviceInfo to "Unknown"
  end try
  
  return deviceInfo
end getOutputDeviceInfo

-- Trim whitespace from a string
on trim(inputString)
  set trimmedString to inputString
  
  -- Trim leading whitespace
  repeat while trimmedString begins with " " or trimmedString begins with tab
    set trimmedString to text 2 thru end of trimmedString
  end repeat
  
  -- Trim trailing whitespace
  repeat while trimmedString ends with " " or trimmedString ends with tab
    set trimmedString to text 1 thru ((length of trimmedString) - 1) of trimmedString
  end repeat
  
  return trimmedString
end trim
```