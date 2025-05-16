---
title: 'iOS Simulator: Boot and Launch Device'
category: 13_developer/xcode_app
id: ios_simulator_boot_device
description: Boots a specific iOS simulator device and launches the Simulator app.
keywords:
  - iOS Simulator
  - Xcode
  - boot
  - launch
  - device
  - UDID
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Device identifier as 'deviceIdentifier' in inputData (can be a name like
  'iPhone 15' or a device UDID). Optional wait time in seconds as 'waitTime'
  (default 10).
notes: >
  - Boots a specific simulator device using xcrun simctl

  - Opens the Simulator app to display the booted device

  - Works with both device names and UDIDs for identification

  - Waits for simulator to boot up with configurable timeout

  - Helps for testing when you need a specific simulator configuration

  - Use ios_simulator_list_devices script first to find available device
  identifiers
---

```applescript
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:waitTime

on bootIOSSimulatorDevice(deviceIdentifier, waitTime)
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    return "error: Device identifier not provided. Specify a device name like 'iPhone 15' or a device UDID."
  end if
  
  -- Default wait time of 10 seconds if not specified
  if waitTime is missing value or waitTime is "" then
    set waitTime to 10
  else
    try
      set waitTime to waitTime as number
    on error
      set waitTime to 10
    end try
  end if
  
  try
    -- Check if the device is already booted
    set isAlreadyBooted to false
    set checkBootedCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & ".*Booted'"
    try
      do shell script checkBootedCmd
      set isAlreadyBooted to true
    on error
      set isAlreadyBooted to false
    end try
    
    -- Boot the device if it's not already booted
    if not isAlreadyBooted then
      -- Use the boot command with the device identifier
      set bootCmd to "xcrun simctl boot " & quoted form of deviceIdentifier
      try
        do shell script bootCmd
        set deviceBooted to true
      on error errMsg
        -- If the boot command fails, it might be because the device is already booted
        -- or because the identifier isn't valid
        if errMsg contains "already booted" then
          set isAlreadyBooted to true
          set deviceBooted to true
        else
          return "Error booting simulator device: " & errMsg
        end if
      end try
    else
      set deviceBooted to true
    end if
    
    -- Launch the Simulator app to show the device
    if deviceBooted then
      -- Launch Simulator app
      tell application "Simulator"
        activate
      end tell
      
      -- Wait for the specified time to allow simulator to fully boot
      delay waitTime
      
      -- Construct a result message
      if isAlreadyBooted then
        set resultMessage to "Device '" & deviceIdentifier & "' is already booted. Simulator app has been launched."
      else
        set resultMessage to "Successfully booted device '" & deviceIdentifier & "' and launched Simulator app."
      end if
      
      -- Add device info to the result message
      try
        set deviceInfoCmd to "xcrun simctl list devices | grep -A1 -B1 '" & deviceIdentifier & "'"
        set deviceInfo to do shell script deviceInfoCmd
        set resultMessage to resultMessage & "

Device information:
" & deviceInfo
      end try
      
      return resultMessage
    else
      return "Failed to boot simulator device '" & deviceIdentifier & "'. The device may not exist or there might be a problem with the simulator runtime."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") booting iOS simulator device: " & errMsg
  end try
end bootIOSSimulatorDevice

return my bootIOSSimulatorDevice("--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:waitTime")
```
