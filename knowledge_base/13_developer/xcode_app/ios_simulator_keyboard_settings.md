---
title: "iOS Simulator: Configure Keyboard Settings"
category: "09_developer_and_utility_apps"
id: ios_simulator_keyboard_settings
description: "Configures hardware keyboard settings for iOS Simulator."
keywords: ["iOS Simulator", "Xcode", "keyboard", "hardware", "input", "settings", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Enable hardware keyboard as 'enableHardwareKeyboard' ('true' or 'false'), optional device identifier as 'deviceIdentifier' (defaults to all devices), optional boolean to show keyboard as 'showKeyboard' (default is false)."
notes: |
  - Controls hardware keyboard connection to simulator
  - Disabling forces on-screen keyboard for testing
  - Can be set globally or per specific device
  - Useful for UI testing and keyboard interaction testing
  - Settings persist between simulator sessions
  - Takes effect after simulator restart
---

```applescript
--MCP_INPUT:enableHardwareKeyboard
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:showKeyboard

on configureSimulatorKeyboardSettings(enableHardwareKeyboard, deviceIdentifier, showKeyboard)
  if enableHardwareKeyboard is missing value or enableHardwareKeyboard is "" then
    return "error: Keyboard setting not provided. Specify 'true' to enable hardware keyboard or 'false' to disable it."
  end if
  
  -- Normalize hardware keyboard setting
  if enableHardwareKeyboard is "true" or enableHardwareKeyboard is "yes" or enableHardwareKeyboard is "1" then
    set enableHardwareKeyboard to true
  else
    set enableHardwareKeyboard to false
  end if
  
  -- Default to all devices if not specified
  set isSpecificDevice to false
  if deviceIdentifier is not missing value and deviceIdentifier is not "" and deviceIdentifier is not "all" then
    set isSpecificDevice to true
  end if
  
  -- Default show keyboard to false if not specified
  if showKeyboard is missing value or showKeyboard is "" then
    set showKeyboard to false
  else if showKeyboard is "true" then
    set showKeyboard to true
  end if
  
  try
    -- If specific device is provided, validate it exists
    if isSpecificDevice then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Check available devices with 'xcrun simctl list devices'."
      end try
      
      -- Get the device UUID if name was provided
      if deviceIdentifier does not contain "-" then
        set getUUIDCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "' | head -1 | sed -E 's/.*\\(([A-Z0-9-]+)\\).*/\\1/'"
        try
          set deviceUUID to do shell script getUUIDCmd
          if deviceUUID is "" then
            return "error: Could not determine UUID for device '" & deviceIdentifier & "'."
          end if
        on error
          return "error: Could not determine UUID for device '" & deviceIdentifier & "'."
        end try
      else
        set deviceUUID to deviceIdentifier
      end if
    end if
    
    -- Close simulator before changing settings
    tell application "System Events"
      if exists process "Simulator" then
        tell application "Simulator" to quit
        delay 2
      end if
    end tell
    
    -- Set the hardware keyboard preference
    if isSpecificDevice then
      -- For a specific device
      set keyboardSettingCmd to "plutil -replace DevicePreferences." & deviceUUID & ".ConnectHardwareKeyboard -bool " & enableHardwareKeyboard & " ~/Library/Preferences/com.apple.iphonesimulator.plist"
    else
      -- For all devices
      set keyboardSettingCmd to "defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool " & enableHardwareKeyboard
    end if
    
    do shell script keyboardSettingCmd
    
    -- Additional keyboard settings
    if enableHardwareKeyboard is false then
      -- When disabling hardware keyboard, you might also want to touch interactions to remain visible
      do shell script "defaults write com.apple.iphonesimulator ShowSingleTouches -bool true"
    end if
    
    -- Launch simulator if requested to show keyboard
    set keyboardStateText to ""
    if showKeyboard then
      tell application "Simulator" to activate
      delay 2
      
      -- Try to show the keyboard if requested
      tell application "System Events"
        tell process "Simulator"
          -- Click on a text field (we'll use the search field in the springboard)
          -- First go to home screen using Command+Shift+H
          keystroke "h" using {command down, shift down}
          delay 1
          
          -- Swipe down to show search (Option+Command+drag down)
          key down option
          key down command
          set {xPosition, yPosition} to {200, 200}
          mouse move {xPosition, yPosition}
          mouse down at {xPosition, yPosition}
          delay 0.2
          mouse move {xPosition, yPosition + 200}
          delay 0.2
          mouse up at {xPosition, yPosition + 200}
          key up command
          key up option
          delay 1
          
          -- Click in the search field
          click at {200, 100}
          delay 1
          
          set keyboardStateText to "

The simulator has been launched with the search field active. 
The on-screen keyboard " & (if enableHardwareKeyboard then "may not" else "should") & " be visible."
        end tell
      end tell
    end if
    
    -- Result message
    set targetText to ""
    if isSpecificDevice then
      set targetText to "device " & deviceIdentifier
    else
      set targetText to "all simulator devices"
    end if
    
    return "Successfully " & (if enableHardwareKeyboard then "enabled" else "disabled") & " hardware keyboard for " & targetText & ".

" & (if enableHardwareKeyboard then "Your Mac's keyboard will be used for text input in the simulator." else "The simulator will show the on-screen iOS keyboard for text input.") & "

The setting will take effect when the simulator is restarted." & keyboardStateText & "

Note: For UI testing, it's often better to disable the hardware keyboard to ensure the on-screen keyboard appears as it would on a physical device."
  on error errMsg number errNum
    return "error (" & errNum & ") configuring simulator keyboard settings: " & errMsg
  end try
end configureSimulatorKeyboardSettings

return my configureSimulatorKeyboardSettings("--MCP_INPUT:enableHardwareKeyboard", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:showKeyboard")
```