---
id: home_list_devices
title: List All Home Devices and Rooms
description: >-
  Launches the Home app and retrieves a list of all rooms and
  devices/accessories with their status information
language: applescript
contributors:
  - Claude AI
created: 2024-05-16T00:00:00.000Z
category: 09_productivity/home_app
platforms:
  - macOS
keywords:
  - Home app
  - HomeKit
  - smart home
  - accessories
  - rooms
  - device status
  - home automation
requirements:
  - System Events accessibility permissions
  - Home app configured with at least one HomeKit device
  - macOS 10.14 (Mojave) or later
deprecated: false
---

# List All Home Devices and Rooms

This script launches the Home app and retrieves a list of rooms and devices with their current status information when available.

```applescript
-- List all rooms and devices in the Home app
-- Returns a structured list of rooms and their accessories with status information

on run
    return listHomeDevices()
end run

on listHomeDevices()
    set homeData to {rooms:[], error:""}
    
    try
        -- Launch Home app
        tell application "Home"
            activate
            -- Give the app time to fully load
            delay 2
        end tell
        
        -- Use UI scripting to interact with the app
        tell application "System Events"
            tell process "Home"
                -- Wait for the window to appear
                repeat until (exists window 1)
                    delay 0.5
                end repeat
                
                -- Check if we're logged in and have access to homes
                if (count of windows) > 0 then
                    
                    -- Check if we need to select a home first
                    if (exists button "Continue" of window 1) then
                        -- We're at the home selection screen
                        click button "Continue" of window 1
                        delay 1
                    end if
                    
                    -- Get information about rooms (tabs in the Home app)
                    set roomList to {}
                    
                    -- First, try to check if we're in a sidebar mode or tab mode
                    set sidebarMode to false
                    if exists toolbar 1 of window 1 then
                        if exists button "Sidebar" of toolbar 1 of window 1 then
                            -- Click the sidebar button to show rooms/accessories
                            click button "Sidebar" of toolbar 1 of window 1
                            delay 1
                            set sidebarMode to true
                        end if
                    end if
                    
                    if sidebarMode and (exists outline 1 of window 1) then
                        -- Process rooms and accessories in sidebar view
                        set sidebarItems to rows of outline 1 of window 1
                        
                        set currentRoom to "Default Room"
                        set deviceList to {}
                        
                        repeat with anItem in sidebarItems
                            try
                                -- Check if it's a room (level 1) or device (level 2)
                                set itemLevel to value of attribute "AXDisclosureLevel" of anItem
                                
                                if itemLevel is 0 then
                                    -- This is a room or section header
                                    if (exists static text 1 of anItem) then
                                        -- First save previous room data if any
                                        if (count of deviceList) > 0 then
                                            set end of roomList to {name:currentRoom, devices:deviceList}
                                            set deviceList to {}
                                        end if
                                        
                                        -- Get new room name
                                        set currentRoom to value of static text 1 of anItem
                                    end if
                                else if itemLevel is 1 then
                                    -- This is a device under a room
                                    if (exists static text 1 of anItem) then
                                        set deviceName to value of static text 1 of anItem
                                        
                                        -- Get status information if available
                                        set deviceStatus to "Unknown"
                                        try
                                            if (exists static text 2 of anItem) then
                                                set deviceStatus to value of static text 2 of anItem
                                            end if
                                        end try
                                        
                                        -- Add to device list
                                        set end of deviceList to {name:deviceName, status:deviceStatus}
                                    end if
                                end if
                            on error
                                -- Skip items that don't match the expected structure
                            end try
                        end repeat
                        
                        -- Add final room data
                        if (count of deviceList) > 0 then
                            set end of roomList to {name:currentRoom, devices:deviceList}
                        end if
                    else
                        -- Tab view mode - less detailed but still useful
                        if exists tab group 1 of window 1 then
                            set roomTabs to tabs of tab group 1 of window 1
                            
                            repeat with aRoom in roomTabs
                                if exists static text 1 of aRoom then
                                    set roomName to value of static text 1 of aRoom
                                    
                                    -- Select this room tab to see its devices
                                    click aRoom
                                    delay 1
                                    
                                    -- Collect devices in this room
                                    set roomDevices to {}
                                    
                                    -- Attempt to find accessories in the current room view
                                    if exists scroll area 1 of window 1 then
                                        if exists group 1 of scroll area 1 of window 1 then
                                            set deviceGroups to groups of group 1 of scroll area 1 of window 1
                                            
                                            repeat with aDevice in deviceGroups
                                                try
                                                    if exists static text 1 of aDevice then
                                                        set deviceName to value of static text 1 of aDevice
                                                        
                                                        -- Try to determine status from UI elements
                                                        set deviceStatus to "Unknown"
                                                        try
                                                            if exists static text 2 of aDevice then
                                                                set deviceStatus to value of static text 2 of aDevice
                                                            end if
                                                        end try
                                                        
                                                        set end of roomDevices to {name:deviceName, status:deviceStatus}
                                                    end if
                                                on error
                                                    -- Skip this device if structure doesn't match
                                                end try
                                            end repeat
                                        end if
                                    end if
                                    
                                    -- Add room and its devices to the main list
                                    set end of roomList to {name:roomName, devices:roomDevices}
                                end if
                            end repeat
                        end if
                    end if
                    
                    -- Store the collected room data
                    set homeData's rooms to roomList
                end if
            end tell
        end tell
        
        -- Quit Home app when finished
        tell application "Home" to quit
        
    on error errMsg
        -- Make sure we capture and report any errors
        set homeData's error to "Error accessing Home app: " & errMsg
        
        -- Ensure the app quits if there's an error
        try
            tell application "Home" to quit
        end try
    end try
    
    return homeData
end listHomeDevices

-- Example of calling with MCP
-- execute_script(id="home_list_devices")
-- Response: {rooms:[{name:"Living Room", devices:[{name:"Table Lamp", status:"On"}, {name:"Fan", status:"Off"}]}, ...], error:""}
```

## Usage Notes

- This script requires accessibility permissions to be granted to the process running the script (such as Script Editor or Terminal).
- The script automatically launches and quits the Home app.
- The Home app must be properly set up with at least one HomeKit home and device.
- Device status information varies by device type (e.g., "On"/"Off" for switches, percentage for dimmers, temperature for thermostats).
- The script attempts to handle both the sidebar view and tab view layouts of the Home app.
- Returns a structured record with rooms and devices, or an error message if something went wrong.

## Error Handling

The script includes comprehensive error handling to:
- Wait for the app and UI elements to become available
- Skip any UI elements that don't match the expected structure
- Handle different Home app layouts (sidebar or tab view)
- Ensure the Home app is closed even if an error occurs
- Return a descriptive error message if something goes wrong

## Performance Considerations

- The script includes delays to allow the UI to load properly, which may take several seconds
- For homes with many rooms and devices, the script may take longer to complete
- The Home app's UI structure can vary between macOS versions, which may affect reliability
- If the Home app prompts for authentication, the script may not be able to proceed automatically
