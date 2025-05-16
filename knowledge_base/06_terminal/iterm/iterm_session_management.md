---
id: iterm_session_management
title: iTerm2 Session Management
description: Saves, restores, and manages iTerm2 window arrangements and sessions
language: applescript
author: Claude
keywords: ["arrangements", "layouts", "sessions", "persistence", "workflow"]
usage_examples:
  - "Save the current iTerm2 window arrangement for later restoration"
  - "Restore a previously saved window arrangement with all tabs and panes"
  - "Create named session configurations for different workflows"
parameters:
  - name: action
    description: Action to perform - save, restore, list, or delete
    required: true
  - name: name
    description: Name of the arrangement to save, restore, or delete
    required: false
  - name: includeContents
    description: Whether to save terminal contents (true/false, default false)
    required: false
---

# iTerm2 Session Management

This script provides comprehensive control over iTerm2's session and window arrangement management, allowing you to save and restore complex terminal layouts.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set arrangementName to "--MCP_INPUT:name"
    set includeContents to "--MCP_INPUT:includeContents"
    
    -- Validate and set defaults for parameters
    if action is "" or action is missing value then
        return "Error: Please specify an action (save, restore, list, or delete)"
    end if
    
    -- Convert parameters to lowercase for case-insensitive comparison
    set action to my toLowerCase(action)
    
    -- Set default arrangement name if not provided
    if arrangementName is "" or arrangementName is missing value then
        if action is "list" then
            -- For list action, we don't need a name
        else
            set arrangementName to "Default"
        end if
    end if
    
    -- Set default for includeContents
    if includeContents is "" or includeContents is missing value then
        set includeContents to false
    else
        try
            set includeContents to includeContents as boolean
        on error
            set includeContents to false
        end try
    end if
    
    -- Check if iTerm2 is running
    tell application "System Events"
        if not (exists process "iTerm2") then
            if action is "restore" then
                tell application "iTerm2" to activate
                delay 1 -- Give iTerm2 time to launch
            else if action is "list" then
                -- For listing, we don't need iTerm2 to be running
            else
                return "Error: iTerm2 is not running."
            end if
        end if
    end tell
    
    -- Perform the requested action
    if action is "save" then
        return saveArrangement(arrangementName, includeContents)
    else if action is "restore" then
        return restoreArrangement(arrangementName)
    else if action is "list" then
        return listArrangements()
    else if action is "delete" then
        return deleteArrangement(arrangementName)
    else
        return "Error: Invalid action. Use 'save', 'restore', 'list', or 'delete'."
    end if
end run

-- Save the current window arrangement
on saveArrangement(arrangementName, includeContents)
    tell application "iTerm2"
        activate
        
        -- Use the Arrangements submenu via UI automation
        tell application "System Events"
            tell process "iTerm2"
                set frontmost to true
                delay 0.3
                
                -- Select Window > Save Window Arrangement...
                click menu item "Save Window Arrangement…" of menu "Window" of menu bar 1
                delay 0.3
                
                -- Now handle the dialog with the name field
                set arrangementDialog to window "Save Window Arrangement"
                
                -- Enter the arrangement name
                set value of text field 1 of arrangementDialog to arrangementName
                
                -- Set the checkbox for including contents if needed
                if includeContents then
                    -- Check if the checkbox exists and set it
                    try
                        set theCheckbox to checkbox "Include contents of tabs" of arrangementDialog
                        if value of theCheckbox is 0 then
                            click theCheckbox
                        end if
                    on error
                        -- If the checkbox doesn't exist or has a different name, just continue
                    end try
                end if
                
                -- Click the Save button
                click button "Save" of arrangementDialog
                
                return "Saved current window arrangement as '" & arrangementName & "'."
            end tell
        end tell
    end tell
end saveArrangement

-- Restore a previously saved window arrangement
on restoreArrangement(arrangementName)
    tell application "iTerm2"
        activate
        
        -- Check if the arrangement exists
        set arrangementExists to false
        set existingArrangements to my getExistingArrangements()
        
        repeat with i from 1 to count of existingArrangements
            if item i of existingArrangements is arrangementName then
                set arrangementExists to true
                exit repeat
            end if
        end repeat
        
        if not arrangementExists then
            return "Error: No saved arrangement found with name '" & arrangementName & "'."
        end if
        
        -- Use the Arrangements submenu via UI automation
        tell application "System Events"
            tell process "iTerm2"
                set frontmost to true
                delay 0.3
                
                -- Navigate to the Window menu
                tell menu bar 1
                    tell menu bar item "Window"
                        tell menu "Window"
                            tell menu item "Restore Window Arrangement"
                                -- Click on the specific arrangement name in the submenu
                                tell menu "Restore Window Arrangement"
                                    click menu item arrangementName
                                end tell
                            end tell
                        end tell
                    end tell
                end tell
                
                return "Restored window arrangement '" & arrangementName & "'."
            end tell
        end tell
    end tell
end restoreArrangement

-- List all saved window arrangements
on listArrangements()
    set existingArrangements to my getExistingArrangements()
    
    if (count of existingArrangements) is 0 then
        return "No saved window arrangements found."
    else
        set arrangementsList to "Available window arrangements:
"
        
        repeat with i from 1 to count of existingArrangements
            set arrangementsList to arrangementsList & "• " & item i of existingArrangements & "
"
        end repeat
        
        return arrangementsList
    end if
end listArrangements

-- Delete a saved window arrangement
on deleteArrangement(arrangementName)
    tell application "iTerm2"
        activate
        
        -- Check if the arrangement exists
        set arrangementExists to false
        set existingArrangements to my getExistingArrangements()
        
        repeat with i from 1 to count of existingArrangements
            if item i of existingArrangements is arrangementName then
                set arrangementExists to true
                exit repeat
            end if
        end repeat
        
        if not arrangementExists then
            return "Error: No saved arrangement found with name '" & arrangementName & "'."
        end if
        
        -- Use the Arrangements management dialog via UI automation
        tell application "System Events"
            tell process "iTerm2"
                set frontmost to true
                delay 0.3
                
                -- Navigate to the Window menu
                tell menu bar 1
                    tell menu bar item "Window"
                        tell menu "Window"
                            click menu item "Manage Window Arrangements…"
                            delay 0.3
                        end tell
                    end tell
                end tell
                
                -- Handle the Manage Window Arrangements dialog
                set manageDialog to window "Window Arrangements"
                
                -- Select the arrangement to delete in the table
                tell table 1 of scroll area 1 of manageDialog
                    set selectedRow to 0
                    
                    -- Find and select the row with our arrangement name
                    repeat with i from 1 to count of rows
                        if value of text field 1 of row i is arrangementName then
                            select row i
                            set selectedRow to i
                            exit repeat
                        end if
                    end repeat
                    
                    if selectedRow is 0 then
                        -- Close the dialog since we didn't find the arrangement
                        click button "OK" of manageDialog
                        return "Error: Could not find arrangement '" & arrangementName & "' in the management dialog."
                    end if
                end tell
                
                -- Click the - button to delete the selected arrangement
                click button "-" of manageDialog
                delay 0.2
                
                -- Confirm the deletion if a confirmation dialog appears
                try
                    click button "Delete" of sheet 1 of manageDialog
                    delay 0.2
                on error
                    -- No confirmation dialog appeared, which is fine
                end try
                
                -- Close the management dialog
                click button "OK" of manageDialog
                
                return "Deleted window arrangement '" & arrangementName & "'."
            end tell
        end tell
    end tell
end deleteArrangement

-- Helper function to get existing arrangements
on getExistingArrangements()
    set arrangementsPath to (POSIX path of (path to home folder)) & "Library/Application Support/iTerm2/Arrangements"
    
    -- Check if the Arrangements directory exists
    try
        do shell script "test -d " & quoted form of arrangementsPath
    on error
        -- Directory doesn't exist, so no arrangements
        return {}
    end try
    
    -- Get arrangement files from the directory
    set arrangementFiles to paragraphs of (do shell script "ls " & quoted form of arrangementsPath & " | grep '.arrangement'")
    set arrangements to {}
    
    -- Extract arrangement names from filenames
    repeat with arrangementFile in arrangementFiles
        if arrangementFile ends with ".arrangement" then
            set arrangementName to text 1 thru -13 of arrangementFile
            set end of arrangements to arrangementName
        end if
    end repeat
    
    return arrangements
end getExistingArrangements

-- Helper function to convert text to lowercase
on toLowerCase(theText)
    return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```

## iTerm2 Session Management Concepts

iTerm2 provides powerful capabilities for saving and restoring window arrangements, allowing you to recreate complex terminal setups with multiple windows, tabs, and panes.

### Understanding Window Arrangements

Window arrangements in iTerm2 include:

1. **Window Layout**: The size and position of all terminal windows
2. **Tab Structure**: The number and organization of tabs in each window
3. **Pane Configuration**: The split pane layout within each tab
4. **Profile Association**: Which profile is used for each session
5. **Working Directories**: The current directory for each session
6. **Optional Content**: Terminal buffer contents (when selected)

### Where Arrangements Are Stored

iTerm2 stores window arrangements as `.arrangement` files in:
`~/Library/Application Support/iTerm2/Arrangements/`

Each arrangement is a JSON file containing the complete configuration for all windows, tabs, and panes.

### Use Cases for Session Management

#### 1. Development Environments

Save different arrangements for different projects or development tasks:

- **Web Development**: Arrangement with server, client, and database terminals
- **DevOps**: Arrangement with monitoring, logs, and command terminals
- **Multi-Project**: Separate windows for different concurrent projects

#### 2. System Administration

Create arrangements for managing multiple systems:

- **Server Monitoring**: Sessions connected to different servers
- **Database Management**: Sessions for different database instances
- **Network Operations**: Tools for network diagnostics and monitoring

#### 3. Context Switching

Use arrangements to quickly switch between different work contexts:

- **Morning Routine**: Arrangement with email, calendar, and task management
- **Focused Coding**: Distraction-free arrangement with just development tools
- **On-Call Setup**: Arrangement with monitoring and alert tools

### Advanced Features

#### Including Terminal Contents

When saving an arrangement with `includeContents` set to `true`:

- Terminal buffer contents are saved
- Command history is preserved
- Output from running commands is maintained

This is useful for:
- Preserving the state of long-running processes
- Maintaining context between work sessions
- Documentation and reviewing previous output

#### Autoloading Arrangements

iTerm2 can be configured to load a specific arrangement on startup:

1. Open iTerm2 Preferences
2. Go to General > Startup
3. Select "Open default window arrangement"
4. Ensure your desired arrangement is saved as "Default"

#### Programmatic Integration

This script can be integrated with other workflows:

```applescript
-- Example: Save an arrangement before shutting down
on prepareForShutdown()
    set currentDate to do shell script "date +%Y-%m-%d"
    my saveArrangement("Shutdown-" & currentDate, true)
    -- Other shutdown preparation tasks...
end prepareForShutdown

-- Example: Load different arrangements based on the time of day
on loadTimeBasedArrangement()
    set currentHour to (do shell script "date +%H") as integer
    
    if currentHour ≥ 9 and currentHour < 12 then
        my restoreArrangement("Morning")
    else if currentHour ≥ 12 and currentHour < 17 then
        my restoreArrangement("Afternoon")
    else
        my restoreArrangement("Evening")
    end if
end loadTimeBasedArrangement
```

### Troubleshooting

If you encounter issues with arrangement saving or restoration:

1. **Permission Issues**: Ensure the script has access to iTerm2's Application Support directory
2. **UI Changes**: If iTerm2 updates its UI, the menu navigation in the script may need adjustment
3. **Non-Standard Profiles**: Arrangements may behave unexpectedly if they reference profiles that don't exist on the current system
4. **Window Positioning**: On different screen setups, window positions may need manual adjustment after restoration

### Best Practices

1. **Naming Conventions**: Use descriptive names for arrangements based on their purpose (e.g., "WebDev", "ServerMonitoring")
2. **Regular Updates**: Re-save arrangements after making significant changes to your workflow
3. **Content Considerations**: Only include contents when necessary, as it increases file size and load time
4. **Backup Arrangements**: Consider backing up your arrangements directory when setting up a new machine