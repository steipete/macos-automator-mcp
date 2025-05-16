---
title: 'Xcode: Launch and Control iOS Simulator'
category: 13_developer/xcode_app
id: xcode_launch_simulator
description: Launches the iOS Simulator and controls it through menu commands.
keywords:
  - Xcode
  - iOS Simulator
  - simulator
  - device
  - control
  - developer
  - iOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Device type to launch (e.g., 'iPhone 15', 'iPad Pro') as 'deviceType' in
  inputData. Optional 'menuCommand' (e.g., 'Home', 'Rotate Left', 'Shake') to
  execute a simulator command.
notes: |
  - Can launch Simulator directly (not through Xcode)
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Menu commands include: Home, Lock, Rotate, Shake, Reset Content and Settings
  - Device selection from the Device menu requires a valid device name
  - This script works as an interface to the Simulator app for iOS testing
---

```applescript
--MCP_INPUT:deviceType
--MCP_INPUT:menuCommand

on launchAndControlSimulator(deviceType, menuCommand)
  -- First check if Simulator is already running
  set isSimulatorRunning to false
  try
    tell application "System Events"
      if exists (process "Simulator") then
        set isSimulatorRunning to true
      end if
    end tell
  end try
  
  -- Launch Simulator if it's not running
  if not isSimulatorRunning then
    tell application "Simulator"
      activate
      delay 2  -- Give Simulator time to launch
    end tell
  else
    tell application "Simulator"
      activate
      delay 1
    end tell
  end if
  
  set resultMessage to "Simulator launched"
  
  -- If a device type is specified, select it
  if deviceType is not missing value and deviceType is not "" then
    try
      tell application "System Events"
        tell process "Simulator"
          tell menu bar 1
            tell menu bar item "Device"
              tell menu "Device"
                set foundDevice to false
                
                -- Try to find the device directly in the menu
                try
                  click menu item deviceType
                  set foundDevice to true
                  set resultMessage to resultMessage & ", selected device: " & deviceType
                on error
                  -- Device might be in a submenu, so look in all submenus
                  set parentMenus to menu items
                  repeat with parentMenu in parentMenus
                    -- Skip non-menu items
                    try
                      set submenuItems to menu items of menu 1 of parentMenu
                      repeat with submenuItem in submenuItems
                        if name of submenuItem contains deviceType then
                          click submenuItem
                          set foundDevice to true
                          set resultMessage to resultMessage & ", selected device: " & deviceType
                          exit repeat
                        end if
                      end repeat
                      if foundDevice then exit repeat
                    end try
                  end repeat
                end try
                
                if not foundDevice then
                  set resultMessage to resultMessage & ", but device '" & deviceType & "' not found"
                end if
              end tell
            end tell
          end tell
        end tell
      end tell
    on error errMsg
      set resultMessage to resultMessage & ", error selecting device: " & errMsg
    end try
  end if
  
  -- If a menu command is specified, execute it
  if menuCommand is not missing value and menuCommand is not "" then
    try
      tell application "System Events"
        tell process "Simulator"
          tell menu bar 1
            -- Determine which menu contains the desired command
            if menuCommand is in {"Home", "Lock", "Shake Gesture", "Shake"} then
              tell menu bar item "Hardware"
                tell menu "Hardware"
                  -- Handle special case for "Shake" (actual menu item is "Shake Gesture")
                  if menuCommand is "Shake" then
                    click menu item "Shake Gesture"
                  else
                    click menu item menuCommand
                  end if
                end tell
              end tell
              set resultMessage to resultMessage & ", executed command: " & menuCommand
            else if menuCommand is in {"Rotate Left", "Rotate Right"} then
              tell menu bar item "Hardware"
                tell menu "Hardware"
                  click menu item menuCommand
                end tell
              end tell
              set resultMessage to resultMessage & ", executed command: " & menuCommand
            else if menuCommand is "Reset Content and Settings" then
              tell menu bar item "Simulator"
                tell menu "Simulator"
                  click menu item "Reset Content and Settings…"
                  delay 1
                  -- Confirm the dialog
                  try
                    click button "Reset" of sheet 1 of window 1
                  end try
                end tell
              end tell
              set resultMessage to resultMessage & ", executed command: " & menuCommand
            else
              set resultMessage to resultMessage & ", unknown command: " & menuCommand
            end if
          end tell
        end tell
      end tell
    on error errMsg
      set resultMessage to resultMessage & ", error executing command: " & errMsg
    end try
  end if
  
  return resultMessage
end launchAndControlSimulator

return my launchAndControlSimulator("--MCP_INPUT:deviceType", "--MCP_INPUT:menuCommand")
```
