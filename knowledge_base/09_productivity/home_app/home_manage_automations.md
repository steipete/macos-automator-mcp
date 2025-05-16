---
id: home_manage_automations
title: 'Home App: Manage Automations'
description: >-
  Launches the Home app, lists existing automations (scenes, schedules, etc.),
  and provides functionality to enable or disable them.
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
  - automations
  - scenes
  - schedules
  - home automation
  - System Events
  - UI scripting
requirements:
  - System Events accessibility permissions
  - Home app configured with at least one HomeKit automation
  - macOS 10.14 (Mojave) or later
argumentsPrompt: >-
  Optional: Provide 'action' ('list', 'enable', 'disable') and 'automationName'
  (required for enable/disable actions) in inputData.
deprecated: false
---

# Home App: Manage Automations

This script interacts with the Home app to list all existing automations (scenes, schedules, rules) and provides functionality to enable or disable specific automations by name.

```applescript
--MCP_INPUT:action
--MCP_INPUT:automationName

on run
    -- Default action is to list automations if no specific action is provided
    set actionToUse to "list"
    set automationNameToUse to ""
    
    -- Process input parameters
    if "--MCP_INPUT:action" is not equal to "--MCP_INPUT:action" then
        set actionToUse to "--MCP_INPUT:action"
    end if
    
    if "--MCP_INPUT:automationName" is not equal to "--MCP_INPUT:automationName" then
        set automationNameToUse to "--MCP_INPUT:automationName"
    end if
    
    return manageHomeAutomations(actionToUse, automationNameToUse)
end run

on manageHomeAutomations(action, automationName)
    -- Validate input parameters
    if action is not "list" and action is not "enable" and action is not "disable" then
        return {success:false, error:"Invalid action. Supported actions: list, enable, disable."}
    end if
    
    -- For enable/disable actions, automation name is required
    if (action is "enable" or action is "disable") and (automationName is "" or automationName is missing value) then
        return {success:false, error:"Automation name is required for enable/disable actions."}
    end if
    
    -- Initialize result structure
    set resultData to {success:false, automations:[], error:""}
    
    try
        -- Launch Home app
        tell application "Home"
            activate
            -- Give the app time to fully load
            delay 2
        end tell
        
        -- Use UI scripting to interact with Home app
        tell application "System Events"
            tell process "Home"
                -- Wait for the main window to appear
                repeat until (exists window 1)
                    delay 0.5
                end repeat
                
                -- Navigate to Automations tab
                set foundAutomationsTab to false
                
                -- Look for the Automations tab in the bottom navigation
                if exists tab group 1 of window 1 then
                    repeat with tabItem in tabs of tab group 1 of window 1
                        try
                            if exists static text 1 of tabItem then
                                set tabName to value of static text 1 of tabItem
                                if tabName contains "Automation" then
                                    click tabItem
                                    set foundAutomationsTab to true
                                    delay 1
                                    exit repeat
                                end if
                            end if
                        end try
                    end repeat
                end if
                
                -- If we didn't find the tab in the modern UI, try the sidebar approach (older versions)
                if not foundAutomationsTab then
                    if exists toolbar 1 of window 1 then
                        if exists button "Sidebar" of toolbar 1 of window 1 then
                            click button "Sidebar" of toolbar 1 of window 1
                            delay 1
                            
                            -- Look for Automations in the sidebar
                            if exists outline 1 of window 1 then
                                repeat with sidebarItem in rows of outline 1 of window 1
                                    try
                                        if exists static text 1 of sidebarItem then
                                            set itemName to value of static text 1 of sidebarItem
                                            if itemName contains "Automation" then
                                                click sidebarItem
                                                set foundAutomationsTab to true
                                                delay 1
                                                exit repeat
                                            end if
                                        end if
                                    end try
                                end repeat
                            end if
                        end if
                    end if
                end if
                
                if not foundAutomationsTab then
                    set resultData's error to "Could not locate Automations tab or section."
                    error "Failed to navigate to Automations"
                end if
                
                -- At this point, we should be in the Automations view
                -- Handle the requested action
                
                if action is "list" then
                    -- List all automations
                    set automationsList to []
                    
                    -- Try to find automations in the current view
                    -- The UI structure can vary based on macOS version and Home app version
                    -- This handles multiple potential UI layouts
                    
                    -- First try scroll area that might contain automations
                    if exists scroll area 1 of window 1 then
                        -- Look for automations in scroll area
                        set uiElements to {}
                        
                        -- Different UI versions might list automations in different nested elements
                        -- Try direct groups first
                        if exists group 1 of scroll area 1 of window 1 then
                            set uiElements to groups of group 1 of scroll area 1 of window 1
                        else
                            -- Try getting all UI elements as a fallback
                            set uiElements to UI elements of scroll area 1 of window 1
                        end if
                        
                        repeat with anElement in uiElements
                            try
                                -- An automation will typically have a name in a static text element
                                -- and might have a checkbox or switch to enable/disable
                                set automationName to ""
                                set automationEnabled to false
                                
                                -- Try to get the name
                                if exists static text 1 of anElement then
                                    set automationName to value of static text 1 of anElement
                                end if
                                
                                -- Try to determine if it's enabled
                                -- Look for checkboxes, switches or other toggle elements
                                set toggleFound to false
                                
                                -- Try checkbox approach first
                                try
                                    if exists checkbox 1 of anElement then
                                        set automationEnabled to value of checkbox 1 of anElement
                                        set toggleFound to true
                                    end if
                                end try
                                
                                -- If no checkbox, try switch
                                if not toggleFound then
                                    try
                                        repeat with subElement in UI elements of anElement
                                            if role of subElement is "AXSwitch" or (class of subElement is checkbox) then
                                                set automationEnabled to value of subElement
                                                set toggleFound to true
                                                exit repeat
                                            end if
                                        end repeat
                                    end try
                                end if
                                
                                -- Add to our results if we found a valid automation
                                if automationName is not "" then
                                    set end of automationsList to {name:automationName, enabled:automationEnabled}
                                end if
                            end try
                        end repeat
                    end if
                    
                    -- Store the collected automation data
                    set resultData's automations to automationsList
                    set resultData's success to true
                    
                else if action is "enable" or action is "disable" then
                    -- Enable or disable a specific automation
                    set targetAutomation to automationName
                    set targetState to (action is "enable")
                    set automationFound to false
                    
                    -- Find and interact with the specific automation
                    if exists scroll area 1 of window 1 then
                        -- Look through elements that might contain automations
                        set uiElements to {}
                        
                        -- Try direct groups first
                        if exists group 1 of scroll area 1 of window 1 then
                            set uiElements to groups of group 1 of scroll area 1 of window 1
                        else
                            -- Try getting all UI elements as a fallback
                            set uiElements to UI elements of scroll area 1 of window 1
                        end if
                        
                        repeat with anElement in uiElements
                            try
                                -- Check if this element represents our target automation
                                if exists static text 1 of anElement then
                                    set currentName to value of static text 1 of anElement
                                    
                                    if currentName contains targetAutomation then
                                        -- Found the automation, now find its toggle control
                                        set automationFound to true
                                        set toggleFound to false
                                        
                                        -- Try checkbox approach first
                                        try
                                            if exists checkbox 1 of anElement then
                                                set currentState to value of checkbox 1 of anElement
                                                
                                                -- Only toggle if the current state doesn't match target state
                                                if currentState is not targetState then
                                                    click checkbox 1 of anElement
                                                end if
                                                
                                                set toggleFound to true
                                            end if
                                        end try
                                        
                                        -- If no checkbox, try switch or other toggle elements
                                        if not toggleFound then
                                            try
                                                repeat with subElement in UI elements of anElement
                                                    if role of subElement is "AXSwitch" or (class of subElement is checkbox) then
                                                        set currentState to value of subElement
                                                        
                                                        -- Only toggle if the current state doesn't match target state
                                                        if currentState is not targetState then
                                                            click subElement
                                                        end if
                                                        
                                                        set toggleFound to true
                                                        exit repeat
                                                    end if
                                                end repeat
                                            end try
                                        end if
                                        
                                        -- If we still haven't found a toggle, try clicking the element itself
                                        if not toggleFound then
                                            -- Some automations require clicking into details view first
                                            click anElement
                                            delay 1
                                            
                                            -- Look for enable/disable button or toggle in details view
                                            repeat with detailElement in UI elements of window 1
                                                try
                                                    if name of detailElement contains "Enable" or name of detailElement contains "Disable" then
                                                        -- Determine if we need to click based on current name vs desired state
                                                        set shouldClick to false
                                                        
                                                        if (name of detailElement contains "Enable") and targetState then
                                                            set shouldClick to true
                                                        else if (name of detailElement contains "Disable") and not targetState then
                                                            set shouldClick to true
                                                        end if
                                                        
                                                        if shouldClick then
                                                            click detailElement
                                                            delay 0.5
                                                        end if
                                                        
                                                        set toggleFound to true
                                                        exit repeat
                                                    end if
                                                end try
                                            end repeat
                                            
                                            -- Return to main automations list view if needed
                                            if exists button "Back" of window 1 then
                                                click button "Back" of window 1
                                                delay 0.5
                                            end if
                                        end if
                                        
                                        -- Report success or failure based on whether we found a toggle
                                        if toggleFound then
                                            set resultData's success to true
                                            set resultData's error to ""
                                        else
                                            set resultData's error to "Found automation '" & targetAutomation & "' but couldn't locate its enable/disable control."
                                        end if
                                        
                                        exit repeat
                                    end if
                                end if
                            end try
                        end repeat
                        
                        if not automationFound then
                            set resultData's error to "Automation '" & targetAutomation & "' not found."
                        end if
                    else
                        set resultData's error to "Could not locate automations list view."
                    end if
                end if
                
            end tell
        end tell
        
        -- Close the Home app when finished
        tell application "Home" to quit
        
    on error errMsg
        -- Handle errors and ensure app is closed
        set resultData's error to "Error processing Home automations: " & errMsg
        set resultData's success to false
        
        try
            tell application "Home" to quit
        end try
    end try
    
    -- Return the results
    return resultData
end manageHomeAutomations

-- Example of calling with MCP
-- Get list of all automations:
-- execute_script(id="home_manage_automations", inputData={action:"list"})
-- Enable a specific automation:
-- execute_script(id="home_manage_automations", inputData={action:"enable", automationName:"Morning Lights"})
-- Disable a specific automation:
-- execute_script(id="home_manage_automations", inputData={action:"disable", automationName:"Evening Lights"})
```

## Usage Notes

- This script requires accessibility permissions to be granted to the process running the script.
- The script automatically launches and quits the Home app.
- The Home app must be properly set up with at least one HomeKit home and automation.
- The script supports three actions:
  - `list`: Lists all automations with their current enabled state
  - `enable`: Enables a specific automation by name
  - `disable`: Disables a specific automation by name
- For enable/disable actions, you must provide the automation name (or part of it) to match.
- Returns a structured record with automation data or success/error information.

## Error Handling

The script includes comprehensive error handling to:
- Validate input parameters before execution
- Wait for the Home app and UI elements to become available
- Handle different Home app layouts across macOS versions
- Skip UI elements that don't match the expected structure
- Ensure the Home app is closed even if an error occurs
- Return descriptive error messages if operations fail

## Performance Considerations

- The script includes necessary delays to allow UI elements to load properly
- For homes with many automations, the script may take longer to complete
- The Home app's UI structure can vary between macOS versions, which may affect reliability
- If the Home app prompts for authentication, the script may not be able to proceed automatically

## Security Notes

- The script only interacts with automations that already exist and doesn't create new ones
- No sensitive information is accessed or exposed by this script
- The script doesn't modify any critical system settings
