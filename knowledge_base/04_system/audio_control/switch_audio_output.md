---
title: 'System: Switch Audio Output Device'
category: 04_system/audio_control
id: switch_audio_output
description: >-
  Switch between different audio output devices on macOS, such as speakers,
  headphones, and external audio interfaces.
keywords:
  - audio
  - output
  - device
  - switch
  - speaker
  - headphone
  - audio interface
  - sound output
language: applescript
parameters: >
  - device_name (optional): Name of audio device to switch to (if empty, will
  list available devices)
notes: >
  - This script works with macOS system audio devices.

  - If no device_name is specified, the script will list all available output
  devices.

  - The device name must match exactly as shown in System Preferences/Settings >
  Sound > Output.

  - This script requires SwitchAudioSource command line tool to be installed.

  - You can install SwitchAudioSource using Homebrew: brew install
  switchaudio-osx

  - For full functionality, the Terminal app may need Accessibility permissions.
---

Switch between audio output devices on macOS.

```applescript
-- Get device name parameter
set deviceNameParam to "--MCP_INPUT:device_name"
if deviceNameParam is "" or deviceNameParam is "--MCP_INPUT:device_name" then
  set deviceNameParam to "" -- Empty means list available devices
end if

-- Initialize result
set resultText to ""

-- First, check if SwitchAudioSource is installed
try
  do shell script "which SwitchAudioSource"
  set switchAudioInstalled to true
on error
  set switchAudioInstalled to false
  
  -- Try common Homebrew installation paths
  try
    do shell script "test -f /usr/local/bin/SwitchAudioSource && echo 'Found'"
    set switchAudioInstalled to true
    set switchAudioPath to "/usr/local/bin/SwitchAudioSource"
  on error
    try
      do shell script "test -f /opt/homebrew/bin/SwitchAudioSource && echo 'Found'"
      set switchAudioInstalled to true
      set switchAudioPath to "/opt/homebrew/bin/SwitchAudioSource"
    on error
      -- Not found in common locations
    end try
  end try
end try

-- If SwitchAudioSource is not installed, provide installation instructions
if not switchAudioInstalled then
  set resultText to "Error: SwitchAudioSource command line tool is not installed." & return & return
  set resultText to resultText & "To install SwitchAudioSource, run this command in Terminal:" & return
  set resultText to resultText & "    brew install switchaudio-osx" & return & return
  set resultText to resultText & "If you don't have Homebrew installed, run this first:" & return
  set resultText to resultText & "    /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" & return & return
  set resultText to resultText & "After installing, run this script again to switch audio output devices."
  
  return resultText
end if

-- If SwitchAudioSource is installed but we don't have the path
if switchAudioInstalled and not exists variable "switchAudioPath" then
  set switchAudioPath to "SwitchAudioSource" -- Use the command directly
end if

-- Get list of available audio devices
try
  set availableDevices to do shell script switchAudioPath & " -a -t output"
  set devicesList to paragraphs of availableDevices
  
  -- Get current output device
  set currentDevice to do shell script switchAudioPath & " -c -t output"
on error errMsg
  return "Error getting audio devices list: " & errMsg
end try

-- If no device name provided, list available devices
if deviceNameParam is "" then
  set resultText to "Available Audio Output Devices:" & return & return
  
  set deviceCounter to 1
  repeat with deviceName in devicesList
    -- Mark current device with an asterisk
    if deviceName is currentDevice then
      set resultText to resultText & deviceCounter & ". " & deviceName & " (current)" & return
    else
      set resultText to resultText & deviceCounter & ". " & deviceName & return
    end if
    
    set deviceCounter to deviceCounter + 1
  end repeat
  
  set resultText to resultText & return & "Current Output Device: " & currentDevice & return & return
  set resultText to resultText & "To switch to a specific device, provide the device_name parameter."
  
  return resultText
end if

-- Check if the requested device exists in the list
set deviceExists to false
repeat with deviceName in devicesList
  if deviceName is deviceNameParam then
    set deviceExists to true
    exit repeat
  end if
end repeat

if not deviceExists then
  set resultText to "Error: Device '" & deviceNameParam & "' not found in the list of available output devices." & return & return
  set resultText to resultText & "Available Audio Output Devices:" & return
  
  repeat with deviceName in devicesList
    set resultText to resultText & "- " & deviceName & return
  end repeat
  
  return resultText
end if

-- If device already selected, no need to switch
if currentDevice is deviceNameParam then
  set resultText to "Device '" & deviceNameParam & "' is already the current output device."
  return resultText
end if

-- Switch to the requested device
try
  do shell script switchAudioPath & " -s \"" & deviceNameParam & "\" -t output"
  
  -- Verify the switch was successful
  set newCurrentDevice to do shell script switchAudioPath & " -c -t output"
  
  if newCurrentDevice is deviceNameParam then
    set resultText to "Successfully switched audio output to:" & return
    set resultText to resultText & "'" & deviceNameParam & "'"
  else
    set resultText to "Error: Switch command completed but device did not change." & return
    set resultText to resultText & "Current device is still: " & newCurrentDevice
  end if
  
  return resultText
on error errMsg
  return "Error switching audio output device: " & errMsg
end try
```
