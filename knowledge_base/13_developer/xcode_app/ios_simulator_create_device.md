---
title: "iOS Simulator: Create Custom Device"
category: "developer"
id: ios_simulator_create_device
description: "Creates a custom iOS Simulator device with specific device type and runtime."
keywords: ["iOS Simulator", "Xcode", "create", "device", "custom", "runtime", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Device name as 'deviceName', device type as 'deviceType' (e.g., 'iPhone 15', 'iPad Pro (12.9-inch)'), and runtime as 'runtime' (e.g., 'iOS 17.0', 'iOS 16.4'). Optional boot parameter 'bootAfterCreation' (default is false)."
notes: |
  - Creates custom simulator devices with specific types and runtimes
  - Provides detailed information on available device types and runtimes
  - Can optionally boot the device after creating it
  - Useful for testing on specific device/OS combinations
  - Device persists between Xcode sessions until manually deleted
  - Requires Xcode with appropriate simulator runtimes installed
---

```applescript
--MCP_INPUT:deviceName
--MCP_INPUT:deviceType
--MCP_INPUT:runtime
--MCP_INPUT:bootAfterCreation

on createSimulatorDevice(deviceName, deviceType, runtime, bootAfterCreation)
  if deviceName is missing value or deviceName is "" then
    return "error: Device name not provided. Specify a name for the new simulator device."
  end if
  
  -- Default bootAfterCreation to false if not specified
  if bootAfterCreation is missing value or bootAfterCreation is "" then
    set bootAfterCreation to false
  else if bootAfterCreation is "true" then
    set bootAfterCreation to true
  end if
  
  -- If device type or runtime not provided, we'll list available options
  set showOptions to false
  if deviceType is missing value or deviceType is "" or runtime is missing value or runtime is "" then
    set showOptions to true
  end if
  
  try
    -- Get available device types and runtimes
    set deviceTypesCmd to "xcrun simctl list devicetypes"
    set runtimesCmd to "xcrun simctl list runtimes"
    
    set deviceTypesList to do shell script deviceTypesCmd
    set runtimesList to do shell script runtimesCmd
    
    -- If just showing options, return the available choices
    if showOptions then
      return "Please provide both a device type and runtime from the available options:

Available Device Types:
" & deviceTypesList & "

Available Runtimes:
" & runtimesList & "

Example usage:
deviceName: 'My Test iPhone'
deviceType: 'iPhone 15'
runtime: 'iOS 17.0'
bootAfterCreation: 'true'"
    end if
    
    -- Find the full identifier for the device type
    set deviceTypeId to ""
    set deviceTypeLookupCmd to "xcrun simctl list devicetypes | grep -i " & quoted form of deviceType & " | head -1 | awk -F ' \\(' '{print $2}' | sed 's/)//'"
    
    try
      set deviceTypeId to do shell script deviceTypeLookupCmd
      if deviceTypeId is "" then
        return "error: Device type '" & deviceType & "' not found. Run the script without device type to see available options."
      end if
    on error errMsg
      return "error: Failed to find device type '" & deviceType & "'. " & errMsg
    end try
    
    -- Find the full identifier for the runtime
    set runtimeId to ""
    set runtimeLookupCmd to "xcrun simctl list runtimes | grep -i " & quoted form of runtime & " | grep -v unavailable | head -1 | awk -F ' \\(' '{print $2}' | sed 's/)//'"
    
    try
      set runtimeId to do shell script runtimeLookupCmd
      if runtimeId is "" then
        return "error: Runtime '" & runtime & "' not found or not available. Run the script without runtime to see available options."
      end if
    on error errMsg
      return "error: Failed to find runtime '" & runtime & "'. " & errMsg
    end try
    
    -- Create the simulator device
    set createCmd to "xcrun simctl create " & quoted form of deviceName & " " & quoted form of deviceTypeId & " " & quoted form of runtimeId
    
    try
      set deviceUUID to do shell script createCmd
      set deviceCreated to true
    on error errMsg
      return "Error creating simulator device: " & errMsg
    end try
    
    -- If requested, boot the device
    set bootOutput to ""
    if bootAfterCreation and deviceCreated then
      try
        set bootCmd to "xcrun simctl boot " & quoted form of deviceUUID
        do shell script bootCmd
        set bootOutput to "
Device booted successfully. Launch the Simulator app to view it."
      on error errMsg
        set bootOutput to "
Note: Failed to boot device after creation: " & errMsg
      end try
    end if
    
    if deviceCreated then
      return "Successfully created simulator device:
Name: " & deviceName & "
Type: " & deviceType & " (" & deviceTypeId & ")
Runtime: " & runtime & " (" & runtimeId & ")
UUID: " & deviceUUID & bootOutput & "

To use this device in the future, you can reference it by name or UUID."
    else
      return "Failed to create simulator device."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") creating simulator device: " & errMsg
  end try
end createSimulatorDevice

return my createSimulatorDevice("--MCP_INPUT:deviceName", "--MCP_INPUT:deviceType", "--MCP_INPUT:runtime", "--MCP_INPUT:bootAfterCreation")
```