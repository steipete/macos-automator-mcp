---
id: find_my_track_items
title: Track Items in Find My App (AirTags and Accessories)
description: >-
  Launches the Find My app, switches to the Items tab, lists all tracked items
  and their last locations, and provides functionality to play a sound on a
  specific item
language: applescript
contributors:
  - Claude AI
created: 2024-05-16T00:00:00.000Z
category: 09_productivity
platforms:
  - macOS
keywords:
  - Find My
  - AirTag
  - accessories
  - item tracking
  - play sound
  - locate items
requirements:
  - System Events accessibility permissions
  - Find My app
  - macOS 11 (Big Sur) or later
  - At least one item registered with Find My
deprecated: false
parameter_docs: >
  - itemName (string, optional): The name of the specific item to play a sound
  on. If not provided, the script will list all items.

  - playSound (boolean, optional): Whether to play a sound on the specified
  item. Default is false.
---

# Track Items in Find My App (AirTags and Accessories)

This script launches the Find My app, switches to the Items tab, lists all tracked Find My-enabled accessories (like AirTags), and can optionally play a sound on a specified item.

```applescript
-- Track Items in Find My App (AirTags and Accessories)
-- This script lists all items tracked in Find My app and optionally plays a sound on a specific item
-- Parameters:
--   itemName: string (optional) - The name of the specific item to play a sound on
--   playSound: boolean (optional) - Whether to play a sound on the specified item (default: false)

on run argv
    -- Initialize parameters with default values
    set targetItemName to ""
    set shouldPlaySound to false
    
    -- Parse command-line arguments
    if count of argv > 0 then
        set targetItemName to item 1 of argv
    end if
    
    if count of argv > 1 then
        set shouldPlaySound to (item 2 of argv is "true" or item 2 of argv is "yes" or item 2 of argv is "1")
    end if
    
    -- If no specific item is targeted, just list all items
    if targetItemName is "" then
        return listFindMyItems()
    else
        -- Otherwise, try to find the specific item and possibly play a sound
        return trackSpecificItem(targetItemName, shouldPlaySound)
    end if
end run

-- Main handler to list all items in Find My
on listFindMyItems()
    set itemsList to {}
    
    try
        -- Launch Find My app
        tell application "Find My"
            activate
            -- Give the app time to fully load
            delay 2
        end tell
        
        -- Use UI scripting to interact with the app
        tell application "System Events"
            tell process "Find My"
                -- Wait for the window to appear
                repeat until (exists window 1)
                    delay 0.5
                end repeat
                
                -- Switch to Items tab - this is typically the third tab in the toolbar
                -- Note: UI element specifics might vary slightly across macOS versions
                if exists toolbar 1 of window 1 then
                    set toolbarButtons to buttons of toolbar 1 of window 1
                    
                    -- Look for the Items button - usually the 3rd button
                    if (count of toolbarButtons) ≥ 3 then
                        click item 3 of toolbarButtons
                        -- Give the app time to switch tabs and load items
                        delay 1
                    else
                        error "Items tab not found in toolbar"
                    end if
                else
                    error "Toolbar not found in Find My app"
                end if
                
                -- Look for the sidebar where items are listed
                if exists group 1 of window 1 then
                    if exists scroll area 1 of group 1 of window 1 then
                        set sidebarItems to UI elements of scroll area 1 of group 1 of window 1
                        
                        -- Extract item information
                        repeat with anItem in sidebarItems
                            try
                                if exists static text 1 of anItem then
                                    set itemName to value of static text 1 of anItem
                                    
                                    -- Try to get location (might not exist for all items)
                                    set itemLocation to "Unknown location"
                                    try
                                        if exists static text 2 of anItem then
                                            set itemLocation to value of static text 2 of anItem
                                        end if
                                    end try
                                    
                                    -- Add item to our list
                                    set end of itemsList to {name:itemName, location:itemLocation}
                                end if
                            on error
                                -- Skip items that don't have the expected structure
                            end try
                        end repeat
                    else
                        error "Items list not found in sidebar"
                    end if
                else
                    error "Sidebar not found in Find My app"
                end if
            end tell
        end tell
        
        -- Quit Find My app when done
        tell application "Find My" to quit
        
        if (count of itemsList) is 0 then
            return {error:"No items found. Make sure you have items registered in Find My."}
        end if
        
        return itemsList
    on error errMsg
        -- Ensure the app quits if there's an error
        try
            tell application "Find My" to quit
        end try
        
        return {error:"Error retrieving items: " & errMsg}
    end try
end listFindMyItems

-- Handler to track a specific item and play a sound if requested
on trackSpecificItem(targetItemName, shouldPlaySound)
    try
        -- Launch Find My app
        tell application "Find My"
            activate
            -- Give the app time to fully load
            delay 2
        end tell
        
        -- Use UI scripting to interact with the app
        tell application "System Events"
            tell process "Find My"
                -- Wait for the window to appear
                repeat until (exists window 1)
                    delay 0.5
                end repeat
                
                -- Switch to Items tab - third tab in the toolbar
                if exists toolbar 1 of window 1 then
                    set toolbarButtons to buttons of toolbar 1 of window 1
                    
                    -- Look for the Items button - usually the 3rd button
                    if (count of toolbarButtons) ≥ 3 then
                        click item 3 of toolbarButtons
                        -- Give the app time to switch tabs
                        delay 1
                    else
                        error "Items tab not found in toolbar"
                    end if
                else
                    error "Toolbar not found in Find My app"
                end if
                
                -- Initialize result variables
                set foundItem to false
                set itemInfo to {}
                
                -- Look for the item in the sidebar
                if exists group 1 of window 1 then
                    if exists scroll area 1 of group 1 of window 1 then
                        set sidebarItems to UI elements of scroll area 1 of group 1 of window 1
                        
                        repeat with anItem in sidebarItems
                            try
                                if exists static text 1 of anItem then
                                    set itemName to value of static text 1 of anItem
                                    
                                    -- Check if this is our target item
                                    if itemName contains targetItemName then
                                        -- Click on the item to select it
                                        click anItem
                                        set foundItem to true
                                        
                                        -- Wait for item details to load
                                        delay 1
                                        
                                        -- Try to get location
                                        set itemLocation to "Unknown location"
                                        try
                                            if exists static text 2 of anItem then
                                                set itemLocation to value of static text 2 of anItem
                                            end if
                                        end try
                                        
                                        set itemInfo to {name:itemName, location:itemLocation}
                                        
                                        -- Play sound if requested
                                        if shouldPlaySound then
                                            set soundResult to playSound()
                                            set itemInfo to itemInfo & {sound:soundResult}
                                        end if
                                        
                                        exit repeat
                                    end if
                                end if
                            on error
                                -- Skip items that don't have the expected structure
                            end try
                        end repeat
                    else
                        error "Items list not found in sidebar"
                    end if
                else
                    error "Sidebar not found in Find My app"
                end if
                
                -- Handle item not found
                if not foundItem then
                    tell application "Find My" to quit
                    return {error:"Item '" & targetItemName & "' not found in Find My app"}
                end if
            end tell
        end tell
        
        -- Quit Find My app when done
        tell application "Find My" to quit
        
        return itemInfo
    on error errMsg
        -- Ensure the app quits if there's an error
        try
            tell application "Find My" to quit
        end try
        
        return {error:"Error tracking item: " & errMsg}
    end try
end trackSpecificItem

-- Helper handler to play a sound on the currently selected item
on playSound()
    try
        tell application "System Events"
            tell process "Find My"
                -- Look for the Play Sound button or menu item
                
                -- First check if there's a direct Play Sound button
                if exists button "Play Sound" of window 1 then
                    click button "Play Sound" of window 1
                    return "Sound is playing on the item"
                end if
                
                -- If not, check if there's an Actions menu with Play Sound option
                if exists button "Actions" of window 1 then
                    click button "Actions" of window 1
                    delay 0.5
                    
                    -- Try to find and click the Play Sound menu item
                    if exists menu item "Play Sound" of menu 1 of window 1 then
                        click menu item "Play Sound" of menu 1 of window 1
                        return "Sound is playing on the item"
                    else
                        return "Play Sound option not available for this item"
                    end if
                else
                    return "Could not find Play Sound action for this item"
                end if
            end tell
        end tell
    on error errMsg
        return "Failed to play sound: " & errMsg
    end try
end playSound

-- Example of calling with MCP
-- List all items:
-- execute_script(id="find_my_track_items")
-- Response: [{name:"Car Keys", location:"Home"}, {name:"Backpack", location:"Office"}, ...]

-- Play sound on a specific item:
-- execute_script(id="find_my_track_items", input={"AirTag", "true"})
-- Response: {name:"AirTag", location:"Living Room", sound:"Sound is playing on the item"}
```

## Usage Notes

- This script requires accessibility permissions to be granted to the process running the script.
- The script automatically launches and quits the Find My app.
- The Items tab in Find My is specifically for accessories like AirTags, not Apple devices.
- Location information may include descriptive locations like "Home" or "Last seen 20 minutes ago."
- When requesting to play a sound, the sound will continue for a period determined by Apple (usually around 15-20 seconds).

## Error Handling

The script includes comprehensive error handling to:
- Ensure the Find My app is launched properly
- Navigate to the correct tab for items
- Handle cases where no items are found
- Properly select and interact with a specific item
- Track whether the Play Sound action is available
- Ensure the Find My app is closed even if an error occurs
- Return descriptive error messages for various failure cases

## Performance Considerations

- The script includes necessary delays to allow the UI to load properly
- Switching tabs and loading item data may take a few seconds
- The Play Sound functionality depends on the Find My network and the item's connectivity
