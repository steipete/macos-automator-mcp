---
title: System Preferences Control
category: 04_system
id: system_preferences_control
description: >-
  Controls various system preferences and settings through AppleScript including
  appearance, sound, display, and security options
keywords:
  - system preferences
  - settings
  - appearance
  - dark mode
  - sound
  - resolution
  - security
  - privacy
  - accessibility
  - night shift
  - true tone
language: applescript
notes: >-
  Many advanced preferences require accessibility permissions. Some settings may
  require slightly different approaches on newer macOS versions.
---

```applescript
-- System Preferences Control
-- Allows controlling various system settings through AppleScript

-- Toggle Dark Mode
on toggleDarkMode()
  tell application "System Events"
    tell appearance preferences
      set dark mode to not dark mode
      return "Dark mode is now " & (if dark mode then "enabled" else "disabled")
    end tell
  end tell
end toggleDarkMode

-- Set Dark Mode explicitly
on setDarkMode(enableDarkMode)
  tell application "System Events"
    tell appearance preferences
      set dark mode to enableDarkMode
      return "Dark mode set to " & (if dark mode then "enabled" else "disabled")
    end tell
  end tell
end setDarkMode

-- Toggle Night Shift
on toggleNightShift()
  try
    -- Check if Night Shift is active
    set nightShiftStatus to do shell script "defaults read com.apple.CoreBrightness CBDisplaySuppressBlueLight_Enabled"
    
    -- Toggle Night Shift based on current status
    if nightShiftStatus is "1" then
      do shell script "nightlight off" -- Requires 'nightlight' CLI tool
      return "Night Shift disabled"
    else
      do shell script "nightlight on" -- Requires 'nightlight' CLI tool
      return "Night Shift enabled"
    end if
  on error
    return "Unable to toggle Night Shift. Make sure the 'nightlight' CLI tool is installed."
  end try
end toggleNightShift

-- Set True Tone (on supported devices)
on setTrueTone(enableTrueTone)
  try
    if enableTrueTone then
      do shell script "defaults write com.apple.CoreBrightness CBDisplaySuppressAutoDimming -bool false"
      return "True Tone enabled"
    else
      do shell script "defaults write com.apple.CoreBrightness CBDisplaySuppressAutoDimming -bool true"
      return "True Tone disabled"
    end if
  on error
    return "Error setting True Tone or device does not support True Tone"
  end try
end setTrueTone

-- Set screen resolution
on setScreenResolution(width, height)
  try
    -- This uses displayplacer tool which should be installed
    -- Install via: brew install jakehilborn/jakehilborn/displayplacer
    do shell script "displayplacer \"id:1 res:" & width & "x" & height & " color_depth:8 scaling:off origin:(0,0) degree:0\""
    return "Screen resolution set to " & width & "x" & height
  on error errMsg
    return "Error setting screen resolution: " & errMsg & return & "Make sure displayplacer is installed."
  end try
end setScreenResolution

-- Get current screen resolution
on getCurrentScreenResolution()
  set resInfo to do shell script "system_profiler SPDisplaysDataType | grep Resolution"
  return resInfo
end getCurrentScreenResolution

-- Control system volume
on setSystemVolume(volumeLevel)
  -- Volume level should be between 0 and 100
  if volumeLevel < 0 then set volumeLevel to 0
  if volumeLevel > 100 then set volumeLevel to 100
  
  set volume output volume volumeLevel
  return "Volume set to " & volumeLevel & "%"
end setSystemVolume

-- Mute/unmute system volume
on setSystemMute(shouldMute)
  if shouldMute then
    set volume with output muted
    return "System audio muted"
  else
    set volume without output muted
    return "System audio unmuted"
  end if
end setSystemMute

-- Control screen brightness
on setScreenBrightness(brightnessLevel)
  -- Brightness level should be between 0 and 100
  if brightnessLevel < 0 then set brightnessLevel to 0
  if brightnessLevel > 100 then set brightnessLevel to 100
  
  -- Convert percentage to decimal for brightness command
  set brightnessDecimal to brightnessLevel / 100
  
  try
    do shell script "brightness " & brightnessDecimal -- Requires brightness CLI tool
    return "Screen brightness set to " & brightnessLevel & "%"
  on error
    -- Fallback to System Events UI scripting
    tell application "System Events"
      tell process "System Preferences"
        try
          -- Open Displays preferences
          tell application "System Preferences"
            set current pane to pane "com.apple.preference.displays"
            reveal anchor "displaysDisplayTab" of pane "com.apple.preference.displays"
          end tell
          delay 1
          
          -- Adjust brightness slider
          set brightnessSlider to slider 1 of group 1 of tab group 1 of window 1
          tell brightnessSlider
            set value to brightnessLevel / 100
          end tell
          
          -- Close System Preferences
          tell application "System Preferences" to quit
          
          return "Screen brightness set to " & brightnessLevel & "%"
        on error
          tell application "System Preferences" to quit
          return "Error setting brightness through UI"
        end try
      end tell
    end tell
  end try
end setScreenBrightness

-- Enable/disable Wi-Fi
on setWiFiState(enableWiFi)
  try
    if enableWiFi then
      do shell script "networksetup -setairportpower en0 on"
      return "Wi-Fi enabled"
    else
      do shell script "networksetup -setairportpower en0 off"
      return "Wi-Fi disabled"
    end if
  on error errMsg
    return "Error controlling Wi-Fi: " & errMsg
  end try
end setWiFiState

-- Enable/disable Bluetooth
on setBluetoothState(enableBluetooth)
  try
    if enableBluetooth then
      do shell script "blueutil -p 1" -- Requires blueutil CLI tool
      return "Bluetooth enabled"
    else
      do shell script "blueutil -p 0" -- Requires blueutil CLI tool
      return "Bluetooth disabled"
    end if
  on error
    return "Error controlling Bluetooth. Make sure blueutil is installed."
  end try
end setBluetoothState

-- Enable/disable Do Not Disturb
on setDoNotDisturb(enableDND)
  try
    -- Method for macOS Monterey and newer
    if enableDND then
      do shell script "shortcuts run 'Turn On Focus'"
      return "Do Not Disturb enabled"
    else
      do shell script "shortcuts run 'Turn Off Focus'"
      return "Do Not Disturb disabled"
    end if
  on error
    -- Method for older macOS versions
    try
      if enableDND then
        do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb -boolean true"
        do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturbDate -date \"`date -u +\"%Y-%m-%d %H:%M:%S +0000\"`\""
      else
        do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb -boolean false"
      end if
      
      do shell script "killall NotificationCenter"
      return "Do Not Disturb " & (if enableDND then "enabled" else "disabled")
    on error errMsg
      return "Error controlling Do Not Disturb: " & errMsg
    end try
  end try
end setDoNotDisturb

-- Enable/disable Automatic Software Updates
on setAutomaticUpdates(enableUpdates)
  try
    if enableUpdates then
      do shell script "sudo softwareupdate --schedule on" with administrator privileges
      return "Automatic software updates enabled"
    else
      do shell script "sudo softwareupdate --schedule off" with administrator privileges
      return "Automatic software updates disabled"
    end if
  on error errMsg
    return "Error controlling automatic updates: " & errMsg
  end try
end setAutomaticUpdates

-- Set keyboard key repeat rate
on setKeyRepeatRate(repeatRate)
  -- Lower numbers mean faster repeat rate
  -- Default is 6, fast is 2, slowest is 120
  try
    do shell script "defaults write NSGlobalDomain KeyRepeat -int " & repeatRate
    do shell script "defaults write NSGlobalDomain InitialKeyRepeat -int " & (repeatRate * 10)
    
    -- Restart required services
    do shell script "killall SystemUIServer"
    
    return "Keyboard repeat rate set to " & repeatRate
  on error errMsg
    return "Error setting keyboard repeat rate: " & errMsg
  end try
end setKeyRepeatRate

-- Set mouse tracking speed
on setMouseTrackingSpeed(trackingSpeed)
  -- trackingSpeed should be between 0.0 (slowest) and 3.0 (fastest)
  if trackingSpeed < 0.0 then set trackingSpeed to 0.0
  if trackingSpeed > 3.0 then set trackingSpeed to 3.0
  
  try
    do shell script "defaults write -g com.apple.mouse.scaling " & trackingSpeed
    do shell script "killall SystemUIServer"
    
    return "Mouse tracking speed set to " & trackingSpeed
  on error errMsg
    return "Error setting mouse tracking speed: " & errMsg
  end try
end setMouseTrackingSpeed

-- Enable/disable auto-hide Dock
on setDockAutoHide(enableAutoHide)
  try
    do shell script "defaults write com.apple.dock autohide -bool " & enableAutoHide
    do shell script "killall Dock"
    
    return "Dock auto-hide " & (if enableAutoHide then "enabled" else "disabled")
  on error errMsg
    return "Error configuring Dock auto-hide: " & errMsg
  end try
end setDockAutoHide

-- Set Dock position
on setDockPosition(position)
  -- position should be "left", "bottom", or "right"
  try
    do shell script "defaults write com.apple.dock orientation -string " & position
    do shell script "killall Dock"
    
    return "Dock position set to " & position
  on error errMsg
    return "Error setting Dock position: " & errMsg
  end try
end setDockPosition

-- Control Hot Corners
on setHotCorner(corner, action)
  -- corner: "top-left", "top-right", "bottom-left", "bottom-right"
  -- action: "mission-control", "application-windows", "desktop", "dashboard",
  --         "notification-center", "launchpad", "sleep", "screen-saver", "disable"
  
  -- Convert corner to wvous ID
  set cornerID to ""
  if corner is "top-left" then
    set cornerID to "wvous-tl-corner"
  else if corner is "top-right" then
    set cornerID to "wvous-tr-corner"
  else if corner is "bottom-left" then
    set cornerID to "wvous-bl-corner"
  else if corner is "bottom-right" then
    set cornerID to "wvous-br-corner"
  else
    return "Invalid corner specified"
  end if
  
  -- Convert action to code
  set actionCode to 0 -- Disabled
  if action is "mission-control" then
    set actionCode to 2
  else if action is "application-windows" then
    set actionCode to 3
  else if action is "desktop" then
    set actionCode to 4
  else if action is "dashboard" then
    set actionCode to 7
  else if action is "notification-center" then
    set actionCode to 12
  else if action is "launchpad" then
    set actionCode to 11
  else if action is "sleep" then
    set actionCode to 10
  else if action is "screen-saver" then
    set actionCode to 5
  else if action is not "disable" then
    return "Invalid action specified"
  end if
  
  try
    do shell script "defaults write com.apple.dock " & cornerID & " -int " & actionCode
    do shell script "killall Dock"
    
    return "Hot corner " & corner & " set to " & action
  on error errMsg
    return "Error setting hot corner: " & errMsg
  end try
end setHotCorner

-- Show Settings Menu Dialog
on showSettingsMenu()
  set settingsOptions to {"Dark Mode", "Night Shift", "Screen Resolution", "System Volume", "Screen Brightness", "Wi-Fi", "Bluetooth", "Do Not Disturb", "Dock Settings", "Hot Corners", "Keyboard Settings", "Mouse Settings", "Cancel"}
  
  set selectedOption to choose from list settingsOptions with prompt "Select System Setting to Control:" default items {"Dark Mode"}
  
  if selectedOption is false then
    return "Settings control cancelled"
  end if
  
  set choice to item 1 of selectedOption
  
  if choice is "Dark Mode" then
    -- Dark Mode Toggle
    set modeOptions to {"Toggle Dark Mode", "Enable Dark Mode", "Disable Dark Mode"}
    set modeChoice to choose from list modeOptions with prompt "Dark Mode Options:" default items {"Toggle Dark Mode"}
    
    if modeChoice is false then
      return "Dark Mode control cancelled"
    end if
    
    set modeAction to item 1 of modeChoice
    
    if modeAction is "Toggle Dark Mode" then
      return toggleDarkMode()
    else if modeAction is "Enable Dark Mode" then
      return setDarkMode(true)
    else if modeAction is "Disable Dark Mode" then
      return setDarkMode(false)
    end if
    
  else if choice is "Night Shift" then
    -- Night Shift Toggle
    return toggleNightShift()
    
  else if choice is "Screen Resolution" then
    -- Screen Resolution Control
    set resInfo to getCurrentScreenResolution()
    set resPrompt to display dialog "Set screen resolution (width x height):" default answer "1920 1080" buttons {"Cancel", "Set Resolution"} default button "Set Resolution"
    
    if button returned of resPrompt is "Cancel" then
      return "Resolution change cancelled"
    end if
    
    set resValues to text returned of resPrompt
    set AppleScript's text item delimiters to " "
    set resComponents to text items of resValues
    set AppleScript's text item delimiters to ""
    
    if (count of resComponents) >= 2 then
      set resWidth to item 1 of resComponents as number
      set resHeight to item 2 of resComponents as number
      return setScreenResolution(resWidth, resHeight)
    else
      return "Invalid resolution format"
    end if
    
  else if choice is "System Volume" then
    -- Volume Control
    set volumePrompt to display dialog "Set system volume (0-100):" default answer "50" buttons {"Cancel", "Mute", "Unmute", "Set Volume"} default button "Set Volume"
    
    set buttonClicked to button returned of volumePrompt
    
    if buttonClicked is "Cancel" then
      return "Volume change cancelled"
    else if buttonClicked is "Mute" then
      return setSystemMute(true)
    else if buttonClicked is "Unmute" then
      return setSystemMute(false)
    else
      set volumeValue to text returned of volumePrompt
      return setSystemVolume(volumeValue as number)
    end if
    
  else if choice is "Screen Brightness" then
    -- Brightness Control
    set brightnessPrompt to display dialog "Set screen brightness (0-100):" default answer "75" buttons {"Cancel", "Set Brightness"} default button "Set Brightness"
    
    if button returned of brightnessPrompt is "Cancel" then
      return "Brightness change cancelled"
    end if
    
    set brightnessValue to text returned of brightnessPrompt
    return setScreenBrightness(brightnessValue as number)
    
  else if choice is "Wi-Fi" then
    -- Wi-Fi Control
    set wifiOptions to {"Enable Wi-Fi", "Disable Wi-Fi"}
    set wifiChoice to choose from list wifiOptions with prompt "Wi-Fi Options:" default items {"Enable Wi-Fi"}
    
    if wifiChoice is false then
      return "Wi-Fi control cancelled"
    end if
    
    set wifiAction to item 1 of wifiChoice
    
    if wifiAction is "Enable Wi-Fi" then
      return setWiFiState(true)
    else if wifiAction is "Disable Wi-Fi" then
      return setWiFiState(false)
    end if
    
  else if choice is "Bluetooth" then
    -- Bluetooth Control
    set bluetoothOptions to {"Enable Bluetooth", "Disable Bluetooth"}
    set bluetoothChoice to choose from list bluetoothOptions with prompt "Bluetooth Options:" default items {"Enable Bluetooth"}
    
    if bluetoothChoice is false then
      return "Bluetooth control cancelled"
    end if
    
    set bluetoothAction to item 1 of bluetoothChoice
    
    if bluetoothAction is "Enable Bluetooth" then
      return setBluetoothState(true)
    else if bluetoothAction is "Disable Bluetooth" then
      return setBluetoothState(false)
    end if
    
  else if choice is "Do Not Disturb" then
    -- Do Not Disturb Control
    set dndOptions to {"Enable Do Not Disturb", "Disable Do Not Disturb"}
    set dndChoice to choose from list dndOptions with prompt "Do Not Disturb Options:" default items {"Enable Do Not Disturb"}
    
    if dndChoice is false then
      return "Do Not Disturb control cancelled"
    end if
    
    set dndAction to item 1 of dndChoice
    
    if dndAction is "Enable Do Not Disturb" then
      return setDoNotDisturb(true)
    else if dndAction is "Disable Do Not Disturb" then
      return setDoNotDisturb(false)
    end if
    
  else if choice is "Dock Settings" then
    -- Dock Settings
    set dockOptions to {"Set Dock Position", "Toggle Auto-Hide"}
    set dockChoice to choose from list dockOptions with prompt "Dock Settings:" default items {"Set Dock Position"}
    
    if dockChoice is false then
      return "Dock settings cancelled"
    end if
    
    set dockAction to item 1 of dockChoice
    
    if dockAction is "Set Dock Position" then
      set posOptions to {"left", "bottom", "right"}
      set posChoice to choose from list posOptions with prompt "Select Dock Position:" default items {"bottom"}
      
      if posChoice is false then
        return "Dock position change cancelled"
      end if
      
      return setDockPosition(item 1 of posChoice)
      
    else if dockAction is "Toggle Auto-Hide" then
      set autoHideOptions to {"Enable Auto-Hide", "Disable Auto-Hide"}
      set autoHideChoice to choose from list autoHideOptions with prompt "Dock Auto-Hide:" default items {"Enable Auto-Hide"}
      
      if autoHideChoice is false then
        return "Dock auto-hide change cancelled"
      end if
      
      if (item 1 of autoHideChoice) is "Enable Auto-Hide" then
        return setDockAutoHide(true)
      else
        return setDockAutoHide(false)
      end if
    end if
    
  else if choice is "Hot Corners" then
    -- Hot Corners Settings
    set cornerOptions to {"top-left", "top-right", "bottom-left", "bottom-right"}
    set cornerChoice to choose from list cornerOptions with prompt "Select Hot Corner to Configure:" default items {"bottom-right"}
    
    if cornerChoice is false then
      return "Hot corner configuration cancelled"
    end if
    
    set selectedCorner to item 1 of cornerChoice
    
    set actionOptions to {"mission-control", "application-windows", "desktop", "dashboard", "notification-center", "launchpad", "sleep", "screen-saver", "disable"}
    set actionChoice to choose from list actionOptions with prompt "Select Action for " & selectedCorner & " Corner:" default items {"disable"}
    
    if actionChoice is false then
      return "Hot corner action selection cancelled"
    end if
    
    set selectedAction to item 1 of actionChoice
    return setHotCorner(selectedCorner, selectedAction)
    
  else if choice is "Keyboard Settings" then
    -- Keyboard Settings
    set keyboardPrompt to display dialog "Set keyboard repeat rate (2=fast, 6=normal, 120=slow):" default answer "6" buttons {"Cancel", "Set Repeat Rate"} default button "Set Repeat Rate"
    
    if button returned of keyboardPrompt is "Cancel" then
      return "Keyboard settings cancelled"
    end if
    
    set repeatValue to text returned of keyboardPrompt
    return setKeyRepeatRate(repeatValue as number)
    
  else if choice is "Mouse Settings" then
    -- Mouse Settings
    set mousePrompt to display dialog "Set mouse tracking speed (0.0-3.0):" default answer "1.5" buttons {"Cancel", "Set Tracking Speed"} default button "Set Tracking Speed"
    
    if button returned of mousePrompt is "Cancel" then
      return "Mouse settings cancelled"
    end if
    
    set speedValue to text returned of mousePrompt
    return setMouseTrackingSpeed(speedValue as number)
    
  end if
  
  return "Settings operation completed"
end showSettingsMenu

-- Run the main settings menu
showSettingsMenu()
```

This script provides a comprehensive system for controlling various macOS system preferences and settings through AppleScript. It includes functions for manipulating appearance, sound, displays, networking, and more, with both command-line and UI scripting approaches to maximize compatibility across different macOS versions.

### Key Features:

1. **Appearance Control**:
   - Toggle or set Dark Mode on/off
   - Toggle Night Shift for reducing blue light
   - Enable/disable True Tone on supported devices

2. **Display Management**:
   - Set screen resolution (using displayplacer tool)
   - Adjust screen brightness
   - Get current display information

3. **Audio Control**:
   - Set system volume with precise percentage values
   - Mute/unmute system audio

4. **Network Settings**:
   - Enable/disable Wi-Fi
   - Enable/disable Bluetooth (requires blueutil tool)

5. **Notification Management**:
   - Enable/disable Do Not Disturb mode
   - Supports both modern Focus system and legacy Do Not Disturb

6. **System Customization**:
   - Control Dock position (left, bottom, right)
   - Toggle Dock auto-hide feature
   - Configure Hot Corners for various system actions
   - Adjust keyboard repeat rate
   - Set mouse tracking speed

7. **Update Management**:
   - Enable/disable automatic software updates

8. **Interactive UI**:
   - Full menu-based interface for all settings
   - Prompts for specific values when needed
   - Clear feedback on operations

Many of these settings require administrator privileges or additional tools (like displayplacer or blueutil) for full functionality. Some operations interact directly with macOS system preferences and may require the System Events accessibility permission to be granted.

The script is designed to be both user-friendly with its menu interface and modular so that individual functions can be extracted and used in other scripts. Many functions include fallback methods to accommodate different macOS versions.
