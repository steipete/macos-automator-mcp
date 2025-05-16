---
title: "Find My: Get Device Location and Play Sound"
category: "07_productivity_apps"
id: find_my_device_location
description: "Launches Find My app, retrieves a device's last known location, and provides functionality to play a sound on the device."
keywords: ["Find My", "device location", "play sound", "locate device", "Apple devices"]
language: applescript
requires_permissions: ["Automation", "Accessibility"]
parameter_docs: |
  - deviceName (string): The name of the device to locate. This should match the device name shown in Find My app.
  - playSound (boolean, optional): Whether to play a sound on the device. Default is false.
notes: "Requires Find My app to be signed in with an Apple ID. Uses UI scripting (System Events) as Find My has limited direct AppleScript support."
---

```applescript
-- Get device location and optionally play a sound on a device using Find My app
-- Parameters:
--   deviceName: string - The name of the device to locate
--   playSound: boolean (optional) - Whether to play a sound on the device (default: false)

on run argv
  -- Extract parameters
  set deviceName to ""
  set shouldPlaySound to false
  
  -- Handle input parameters
  if count of argv > 0 then
    set deviceName to item 1 of argv
  end if
  
  if count of argv > 1 then
    set shouldPlaySound to (item 2 of argv is "true" or item 2 of argv is "yes" or item 2 of argv is "1")
  end if
  
  if deviceName is "" then
    return "Error: Device name is required."
  end if
  
  -- Main script
  return findDeviceAndGetLocation(deviceName, shouldPlaySound)
end run

on findDeviceAndGetLocation(deviceName, shouldPlaySound)
  try
    -- Launch Find My app
    tell application "Find My"
      activate
      -- Give the app time to open and display devices
      delay 2
    end tell
    
    -- Use UI scripting to interact with the app
    tell application "System Events"
      tell process "Find My"
        set foundDevice to false
        
        -- Check if the devices list is showing
        if exists group 1 of window 1 then
          set devicesList to group 1 of window 1
          
          -- Look for the specified device in the sidebar
          repeat with i from 1 to count of (UI elements of devicesList)
            if exists UI element i of devicesList then
              set currentElement to UI element i of devicesList
              
              -- Check if this is a device row and if it matches our device name
              if exists static text 1 of currentElement then
                set deviceText to value of static text 1 of currentElement as text
                
                if deviceText contains deviceName then
                  -- Found our device, click on it
                  click currentElement
                  set foundDevice to true
                  
                  -- Wait for device info to load
                  delay 1
                  
                  -- Get location information from the detail panel
                  set locationInfo to ""
                  
                  -- Try to get location from the main information area
                  if exists group 2 of window 1 then
                    if exists static text 2 of group 2 of window 1 then
                      set locationInfo to value of static text 2 of group 2 of window 1
                    end if
                  end if
                  
                  -- Play sound on device if requested
                  if shouldPlaySound then
                    try
                      -- Look for "Play Sound" button in the actions menu
                      if exists button "Actions" of window 1 then
                        click button "Actions" of window 1
                        delay 0.5
                        
                        -- Click "Play Sound" if it exists in the menu
                        if exists menu item "Play Sound" of menu 1 of window 1 then
                          click menu item "Play Sound" of menu 1 of window 1
                          set soundResult to "Sound playing on device"
                        else
                          set soundResult to "Play Sound option not available for this device"
                        end if
                      else
                        set soundResult to "Actions button not found"
                      end if
                    on error errMsg
                      set soundResult to "Failed to play sound: " & errMsg
                    end try
                  else
                    set soundResult to "Sound not requested"
                  end if
                  
                  -- Combine location and sound info
                  if locationInfo is "" then
                    set deviceStatus to "Device found but location information not available"
                  else
                    set deviceStatus to "Last known location: " & locationInfo
                  end if
                  
                  if shouldPlaySound then
                    return deviceStatus & return & "Sound status: " & soundResult
                  else
                    return deviceStatus
                  end if
                  
                  exit repeat
                end if
              end if
            end if
          end repeat
          
          if not foundDevice then
            return "Error: Device '" & deviceName & "' not found in Find My app"
          end if
        else
          return "Error: Could not access devices list in Find My app"
        end if
      end tell
    end tell
  on error errMsg number errNum
    return "Error (" & errNum & "): " & errMsg
  end try
end findDeviceAndGetLocation
```