---
title: "iOS Simulator: Rotate Device"
category: "09_developer_and_utility_apps"
id: ios_simulator_rotate_device
description: "Rotates iOS Simulator device to specific orientation."
keywords: ["iOS Simulator", "Xcode", "rotation", "orientation", "landscape", "portrait", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: false
argumentsPrompt: "Orientation as 'orientation' ('portrait', 'landscape-left', 'landscape-right', 'portrait-upsidedown'), and optional device identifier as 'deviceIdentifier' (defaults to 'booted')."
notes: |
  - Rotates the simulator to specified orientation
  - Tests app responsiveness to rotation changes
  - Useful for testing layout changes and rotation handling
  - Simulates physical device rotation
  - Can test multiple orientations in succession
  - Works with all iOS and iPadOS simulators
---

```applescript
--MCP_INPUT:orientation
--MCP_INPUT:deviceIdentifier

on rotateSimulatorDevice(orientation, deviceIdentifier)
  if orientation is missing value or orientation is "" then
    return "error: Orientation not provided. Available orientations: 'portrait', 'landscape-left', 'landscape-right', 'portrait-upsidedown'."
  end if
  
  -- Normalize to lowercase and handle some common variations
  set orientation to do shell script "echo " & quoted form of orientation & " | tr '[:upper:]' '[:lower:]'"
  
  -- Map variations to standard names
  if orientation contains "portrait" and orientation contains "upside" or orientation contains "down" then
    set orientation to "portrait-upsidedown"
  else if orientation contains "landscape" and orientation contains "left" then
    set orientation to "landscape-left"
  else if orientation contains "landscape" and orientation contains "right" then
    set orientation to "landscape-right"
  else if orientation contains "landscape" and not (orientation contains "left" or orientation contains "right") then
    set orientation to "landscape-left" -- Default to landscape-left if not specified
  else if orientation contains "portrait" then
    set orientation to "portrait"
  end if
  
  -- Validate orientation
  if orientation is not in {"portrait", "landscape-left", "landscape-right", "portrait-upsidedown"} then
    return "error: Invalid orientation. Available orientations: 'portrait', 'landscape-left', 'landscape-right', 'portrait-upsidedown'."
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
    
    -- Try using simctl orientation command first (newer Xcode versions)
    set rotationSuccess to false
    try
      set rotateCmd to "xcrun simctl orientation " & quoted form of deviceIdentifier & " " & orientation
      do shell script rotateCmd
      set rotationSuccess to true
    on error
      -- Command might not exist in older versions, we'll fall back to UI automation
      set rotationSuccess to false
    end try
    
    -- If direct command failed, try UI automation approach
    if not rotationSuccess then
      tell application "Simulator" to activate
      delay 0.5
      
      tell application "System Events"
        tell process "Simulator"
          -- Navigate to Device menu
          click menu item "Device" of menu bar 1
          delay 0.2
          
          -- Click Rotate menu
          click menu item "Rotate" of menu "Device" of menu bar 1
          delay 0.2
          
          -- Select appropriate rotation submenu item
          set menuItem to ""
          if orientation is "portrait" then
            set menuItem to "Portrait"
          else if orientation is "landscape-left" then
            set menuItem to "Landscape Left"
          else if orientation is "landscape-right" then
            set menuItem to "Landscape Right"
          else if orientation is "portrait-upsidedown" then
            set menuItem to "Portrait (Upside Down)"
          end if
          
          -- Select the menu item
          click menu item menuItem of menu "Rotate" of menu "Device" of menu bar 1
          set rotationSuccess to true
        end tell
      end tell
    end if
    
    if rotationSuccess then
      set orientationText to ""
      if orientation is "portrait" then
        set orientationText to "portrait"
      else if orientation is "landscape-left" then
        set orientationText to "landscape (home button on right)"
      else if orientation is "landscape-right" then
        set orientationText to "landscape (home button on left)"
      else if orientation is "portrait-upsidedown" then
        set orientationText to "portrait upside down"
      end if
      
      return "Successfully rotated " & deviceIdentifier & " simulator to " & orientationText & " orientation.

This simulates the user rotating the physical device, which triggers:
- Layout changes in responsive apps
- Rotation events and delegate methods
- Size class transitions"
    else
      return "Failed to rotate simulator. Make sure the simulator is running and try again."
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") rotating simulator device: " & errMsg
  end try
end rotateSimulatorDevice

return my rotateSimulatorDevice("--MCP_INPUT:orientation", "--MCP_INPUT:deviceIdentifier")
```