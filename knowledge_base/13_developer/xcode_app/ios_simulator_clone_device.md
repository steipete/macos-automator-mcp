---
title: "iOS Simulator: Clone Device with Content"
category: "developer"
id: ios_simulator_clone_device
description: "Clones an iOS Simulator device including all its installed apps and content."
keywords: ["iOS Simulator", "Xcode", "clone", "duplicate", "copy", "backup", "device", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Source device identifier as 'sourceDevice' (device name or UDID), name for cloned device as 'cloneName', and optional boolean to boot the clone after creation as 'bootAfterCloning' (default is false)."
notes: |
  - Creates an exact copy of an existing simulator device
  - Preserves all installed apps, user settings, files, and data
  - Useful for preserving a specific device state for testing
  - Perfect for creating test device templates with pre-installed apps
  - Clone is an independent device that can run alongside the original
  - Both devices will have the same ECID, which may affect some testing
---

```applescript
--MCP_INPUT:sourceDevice
--MCP_INPUT:cloneName
--MCP_INPUT:bootAfterCloning

on cloneSimulatorDevice(sourceDevice, cloneName, bootAfterCloning)
  if sourceDevice is missing value or sourceDevice is "" then
    return "error: Source device not provided. Specify the name or UDID of the device to clone."
  end if
  
  if cloneName is missing value or cloneName is "" then
    return "error: Clone name not provided. Specify a name for the cloned device."
  end if
  
  -- Default boot option to false if not specified
  if bootAfterCloning is missing value or bootAfterCloning is "" then
    set bootAfterCloning to false
  else if bootAfterCloning is "true" then
    set bootAfterCloning to true
  end if
  
  try
    -- Check if source device exists
    set checkDeviceCmd to "xcrun simctl list devices | grep -i '" & sourceDevice & "'"
    try
      do shell script checkDeviceCmd
    on error
      return "error: Source device '" & sourceDevice & "' not found. Check available devices with 'xcrun simctl list devices'."
    end try
    
    -- Clone the device
    set cloneCmd to "xcrun simctl clone " & quoted form of sourceDevice & " " & quoted form of cloneName
    
    try
      set cloneUUID to do shell script cloneCmd
      set deviceCloned to true
    on error errMsg
      return "Error cloning device: " & errMsg
    end try
    
    -- Boot the cloned device if requested
    set bootOutput to ""
    if bootAfterCloning and deviceCloned then
      try
        set bootCmd to "xcrun simctl boot " & quoted form of cloneUUID
        do shell script bootCmd
        
        -- Launch Simulator app to show the device
        tell application "Simulator" to activate
        
        set bootOutput to "
Device booted successfully. Launch the Simulator app to view it."
      on error errMsg
        set bootOutput to "
Note: Failed to boot cloned device: " & errMsg
      end try
    end if
    
    if deviceCloned then
      -- Get device info
      set deviceInfoCmd to "xcrun simctl list devices | grep -A1 -B1 '" & cloneUUID & "'"
      set deviceInfo to do shell script deviceInfoCmd
      
      return "Successfully cloned simulator device:
Source: " & sourceDevice & "
Clone Name: " & cloneName & "
UUID: " & cloneUUID & bootOutput & "

Device information:
" & deviceInfo & "

The cloned device has all the same apps, data, and settings as the original device.
It functions as an independent device that can run alongside the original."
    else
      return "Failed to clone simulator device."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") cloning simulator device: " & errMsg
  end try
end cloneSimulatorDevice

return my cloneSimulatorDevice("--MCP_INPUT:sourceDevice", "--MCP_INPUT:cloneName", "--MCP_INPUT:bootAfterCloning")
```