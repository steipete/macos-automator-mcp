---
title: "Terminal: Session Management"
id: terminal_session_management
category: "04_terminal_emulators"
description: "Saves and restores Terminal.app window arrangements, including tabs, window positions, and working directories."
keywords: ["Terminal.app", "session", "window", "arrangement", "save", "restore", "management", "tabs", "layout"]
language: applescript
argumentsPrompt: "Expects inputData with: { \"action\": \"save\", \"restore\", \"list\", or \"delete\", \"name\": \"arrangement name\" } (name defaults to \"Default\" if omitted)."
isComplex: true
---

This script provides functionality to save and restore Terminal.app window configurations, allowing you to recreate complex terminal setups without manually recreating each window and tab.

**Features:**
- Save the current Terminal.app window arrangement (positions, sizes, and tabs)
- Restore previously saved window arrangements
- List all available saved arrangements
- Delete arrangements that are no longer needed
- Automatically capture working directories for each tab

**Important Note:**
- Since Terminal.app doesn't have built-in arrangement support like iTerm2, this script uses a custom implementation that stores arrangements as property list files in `~/Library/Application Support/Terminal Custom Arrangements/`.

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultAction to "list"
    set defaultName to "Default"
    
    -- Parse input parameters
    set theAction to defaultAction
    set theName to defaultName
    
    if inputData is not missing value then
        if inputData contains {action:""} then
            set theAction to action of inputData
        end if
        if inputData contains {name:""} then
            set theName to name of inputData
        end if
    end if
    
    -- MCP placeholders for input
    set theAction to "--MCP_INPUT:action" -- save, restore, list, or delete
    set theName to "--MCP_INPUT:name" -- arrangement name (defaults to "Default" if omitted)
    
    -- Convert action to lowercase
    set theAction to my toLower(theAction)
    
    -- Create arrangements directory if it doesn't exist
    set arrangementsDir to (POSIX path of (path to home folder)) & "Library/Application Support/Terminal Custom Arrangements"
    do shell script "mkdir -p " & quoted form of arrangementsDir
    
    -- Perform the requested action
    if theAction is "save" then
        return saveArrangement(theName, arrangementsDir)
    else if theAction is "restore" then
        return restoreArrangement(theName, arrangementsDir)
    else if theAction is "list" then
        return listArrangements(arrangementsDir)
    else if theAction is "delete" then
        return deleteArrangement(theName, arrangementsDir)
    else
        return "Error: Invalid action. Use 'save', 'restore', 'list', or 'delete'."
    end if
end runWithInput

on saveArrangement(arrangementName, arrangementsDir)
    set arrangementFile to arrangementsDir & "/" & arrangementName & ".plist"
    
    tell application "Terminal"
        -- Check if Terminal.app is running and has open windows
        if not (exists window 1) then
            return "Error: No Terminal windows are open to save."
        end if
        
        -- Collect information about all windows
        set windowCount to count of windows
        set windowData to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>windows</key>
    <array>
"
        
        repeat with i from 1 to windowCount
            set currentWindow to window i
            
            -- Get window position and size
            set winBounds to bounds of currentWindow
            set winLeft to item 1 of winBounds
            set winTop to item 2 of winBounds
            set winRight to item 3 of winBounds
            set winBottom to item 4 of winBounds
            set winWidth to winRight - winLeft
            set winHeight to winBottom - winTop
            
            -- Get window title if custom title exists
            set winTitle to ""
            try
                set winTitle to custom title of currentWindow
                if winTitle is missing value then set winTitle to ""
            on error
                set winTitle to ""
            end try
            
            -- Start window information
            set windowData to windowData & "        <dict>
            <key>bounds</key>
            <dict>
                <key>x</key>
                <integer>" & winLeft & "</integer>
                <key>y</key>
                <integer>" & winTop & "</integer>
                <key>width</key>
                <integer>" & winWidth & "</integer>
                <key>height</key>
                <integer>" & winHeight & "</integer>
            </dict>
            <key>customTitle</key>
            <string>" & winTitle & "</string>
            <key>tabs</key>
            <array>
"
            
            -- Get information about all tabs in this window
            set tabCount to count of tabs of currentWindow
            set selectedTabIndex to 1
            
            -- Find which tab is selected
            repeat with j from 1 to tabCount
                if selected of tab j of currentWindow then
                    set selectedTabIndex to j
                    exit repeat
                end if
            end repeat
            
            -- Process each tab
            repeat with j from 1 to tabCount
                set currentTab to tab j of currentWindow
                
                -- Capture the working directory by running pwd
                set cwd to ""
                try
                    tell currentTab
                        do script "pwd" in currentTab
                        delay 0.5 -- Allow time for the command to execute
                        
                        -- Extract the output of pwd from the tab's history
                        set tabHistory to history
                        set historyLines to paragraphs of tabHistory
                        set lineCount to count of historyLines
                        
                        -- Look for the pwd output (will be the last non-empty line in most cases)
                        repeat with k from lineCount to 1 by -1
                            set currentLine to item k of historyLines
                            if currentLine does not start with "pwd" and currentLine is not "" then
                                set cwd to currentLine
                                exit repeat
                            end if
                        end repeat
                    end tell
                on error errMsg
                    set cwd to "~" -- Default to home if we can't determine the directory
                end try
                
                -- Get tab title if custom title exists
                set tabTitle to ""
                try
                    set tabTitle to custom title of currentTab
                    if tabTitle is missing value then set tabTitle to ""
                on error
                    set tabTitle to ""
                end try
                
                -- Add tab information
                set windowData to windowData & "                <dict>
                    <key>workingDirectory</key>
                    <string>" & cwd & "</string>
                    <key>customTitle</key>
                    <string>" & tabTitle & "</string>
                </dict>
"
            end repeat
            
            -- Add selected tab index and close the tabs array and window dict
            set windowData to windowData & "            </array>
            <key>selectedTab</key>
            <integer>" & selectedTabIndex & "</integer>
        </dict>
"
        end repeat
        
        -- Close the array and dictionary
        set windowData to windowData & "    </array>
</dict>
</plist>"
        
        -- Write the configuration to a file
        do shell script "echo " & quoted form of windowData & " > " & quoted form of arrangementFile
        
        return "Saved current Terminal arrangement as '" & arrangementName & "'."
    end tell
end saveArrangement

on restoreArrangement(arrangementName, arrangementsDir)
    set arrangementFile to arrangementsDir & "/" & arrangementName & ".plist"
    
    -- Check if the arrangement file exists
    try
        do shell script "test -f " & quoted form of arrangementFile
    on error
        return "Error: Arrangement '" & arrangementName & "' not found."
    end try
    
    -- Parse the saved arrangement file
    set xmlData to do shell script "cat " & quoted form of arrangementFile
    
    -- Since AppleScript doesn't have good XML parsing, we'll use plutil to convert to JSON
    set tempFile to "/tmp/terminal_arrangement_temp.json"
    do shell script "plutil -convert json -o " & quoted form of tempFile & " " & quoted form of arrangementFile
    set jsonData to do shell script "cat " & quoted form of tempFile
    
    -- Parse window information using the shell and jq (must be installed)
    try
        set windowCount to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(len(json.load(sys.stdin)[\"windows\"]))'"
        set windowCount to windowCount as integer
    on error
        return "Error: Failed to parse arrangement file. Make sure the file is valid."
    end try
    
    if windowCount is 0 then
        return "Error: No windows found in the arrangement file."
    end if
    
    tell application "Terminal"
        -- Close all existing windows if user confirms
        set existingWindowCount to count of windows
        if existingWindowCount > 0 then
            display dialog "Restore will close all existing Terminal windows. Continue?" buttons {"Cancel", "Continue"} default button "Continue" with icon caution
            close every window
        end if
        
        -- Restore each window from the arrangement
        repeat with i from 1 to windowCount
            set iIndex to i - 1 -- For zero-based indexing in JSON
            
            -- Extract window position and size
            set winX to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"bounds\"][\"x\"])'"
            set winY to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"bounds\"][\"y\"])'"
            set winWidth to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"bounds\"][\"width\"])'"
            set winHeight to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"bounds\"][\"height\"])'"
            
            -- Get custom window title
            set winTitle to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"customTitle\"])'"
            
            -- Get selected tab index
            set selectedTabIndex to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"selectedTab\"])'"
            set selectedTabIndex to selectedTabIndex as integer
            
            -- Get tab count
            set tabCount to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(len(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"tabs\"]))'"
            set tabCount to tabCount as integer
            
            -- Create the first window/tab
            set newWindow to do script ""
            
            -- Set window position and size
            set bounds of newWindow to {winX as integer, winY as integer, (winX as integer) + (winWidth as integer), (winY as integer) + (winHeight as integer)}
            
            -- Set custom window title if specified
            if winTitle is not "" then
                set custom title of newWindow to winTitle
            end if
            
            -- Set up the first tab
            if tabCount > 0 then
                -- Get working directory and title for the first tab
                set firstTabCWD to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"tabs\"][0][\"workingDirectory\"])'"
                set firstTabTitle to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"tabs\"][0][\"customTitle\"])'"
                
                -- Change to the working directory for the first tab
                if firstTabCWD is not "" then
                    do script "cd " & quoted form of firstTabCWD in newWindow
                end if
                
                -- Set custom tab title if specified
                if firstTabTitle is not "" then
                    set custom title of (selected tab of newWindow) to firstTabTitle
                end if
                
                -- Create the remaining tabs
                repeat with j from 2 to tabCount
                    set jIndex to j - 1 -- For zero-based indexing in JSON
                    
                    -- Get working directory and title for this tab
                    set tabCWD to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"tabs\"][" & jIndex & "][\"workingDirectory\"])'"
                    set tabTitle to do shell script "echo '" & jsonData & "' | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)[\"windows\"][" & iIndex & "][\"tabs\"][" & jIndex & "][\"customTitle\"])'"
                    
                    -- Create a new tab
                    tell application "System Events" to tell process "Terminal" to keystroke "t" using command down
                    delay 0.3
                    
                    -- Change to the working directory for this tab
                    if tabCWD is not "" then
                        do script "cd " & quoted form of tabCWD in newWindow
                    end if
                    
                    -- Set custom tab title if specified
                    if tabTitle is not "" then
                        set custom title of (selected tab of newWindow) to tabTitle
                    end if
                end repeat
                
                -- Select the originally selected tab
                if selectedTabIndex > 0 and selectedTabIndex ≤ tabCount then
                    -- Navigate to the first tab
                    tell application "System Events" to tell process "Terminal" to keystroke "1" using command down
                    delay 0.2
                    
                    -- Then navigate to the selected tab
                    if selectedTabIndex > 1 then
                        tell application "System Events" to tell process "Terminal" to keystroke (selectedTabIndex as string) using command down
                    end if
                end if
            end if
        end repeat
        
        return "Restored Terminal arrangement '" & arrangementName & "' with " & windowCount & " window(s)."
    end tell
end restoreArrangement

on listArrangements(arrangementsDir)
    -- Get list of arrangement files
    try
        set arrangementFiles to paragraphs of (do shell script "ls -1 " & quoted form of arrangementsDir & "/*.plist 2>/dev/null || echo ''")
    on error
        set arrangementFiles to {}
    end try
    
    if arrangementFiles is {} or arrangementFiles is "" then
        return "No saved Terminal arrangements found."
    end if
    
    set arrangementNames to {}
    
    -- Extract arrangement names from filenames
    repeat with arrangementFile in arrangementFiles
        set arrangementFile to arrangementFile as text
        if arrangementFile ends with ".plist" then
            -- Extract the basename without path and extension
            set arrangementName to do shell script "basename " & quoted form of arrangementFile & " .plist"
            set end of arrangementNames to arrangementName
        end if
    end repeat
    
    -- Sort the arrangement names alphabetically
    set sortedNames to my sortList(arrangementNames)
    
    -- Format the list for display
    set resultText to "Available Terminal arrangements:
"
    
    repeat with arrangementName in sortedNames
        set resultText to resultText & "• " & arrangementName & "
"
    end repeat
    
    return resultText
end listArrangements

on deleteArrangement(arrangementName, arrangementsDir)
    set arrangementFile to arrangementsDir & "/" & arrangementName & ".plist"
    
    -- Check if the arrangement file exists
    try
        do shell script "test -f " & quoted form of arrangementFile
    on error
        return "Error: Arrangement '" & arrangementName & "' not found."
    end try
    
    -- Ask for confirmation before deleting
    display dialog "Are you sure you want to delete the Terminal arrangement '" & arrangementName & "'?" buttons {"Cancel", "Delete"} default button "Cancel" with icon caution
    
    -- Delete the file
    do shell script "rm " & quoted form of arrangementFile
    
    return "Deleted Terminal arrangement '" & arrangementName & "'."
end deleteArrangement

-- Helper function to convert text to lowercase
on toLower(theText)
    set lowercaseText to ""
    repeat with i from 1 to length of theText
        set currentChar to character i of theText
        if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
            -- Convert uppercase letter to lowercase
            set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
        else
            -- Keep the character as is
            set lowercaseText to lowercaseText & currentChar
        end if
    end repeat
    return lowercaseText
end toLower

-- Helper function to sort a list of text items
on sortList(theList)
    set theListCount to count of theList
    set resultList to {}
    
    if theListCount > 0 then
        -- Create a temporary file with the list items
        set tempFile to "/tmp/terminal_arrangement_sort_temp.txt"
        do shell script "rm -f " & quoted form of tempFile
        
        repeat with i from 1 to theListCount
            do shell script "echo " & quoted form of (item i of theList) & " >> " & quoted form of tempFile
        end repeat
        
        -- Sort the file and read it back
        set sortedItems to paragraphs of (do shell script "sort " & quoted form of tempFile)
        
        -- Cleanup
        do shell script "rm -f " & quoted form of tempFile
        
        return sortedItems
    else
        return {}
    end if
end sortList
```

## Managing Terminal Sessions

Unlike iTerm2, Terminal.app doesn't have built-in functionality for saving and restoring window arrangements. This script implements a custom solution to provide similar capabilities, allowing you to save and recreate complex terminal setups.

### Understanding the Implementation

This script:

1. **Captures Window Information**:
   - Window positions and sizes
   - Custom window titles
   - Number and arrangement of tabs
   - Selected tab within each window

2. **Captures Tab Information**:
   - Working directory for each tab
   - Custom tab titles
   - Tab selection state

3. **Stores Data in Property List Files**:
   - Saves as XML property lists in `~/Library/Application Support/Terminal Custom Arrangements/`
   - Each arrangement is stored in a separate file with the `.plist` extension

4. **Restores Arrangements**:
   - Creates windows with the saved positions and sizes
   - Creates tabs within each window
   - Sets working directories for each tab
   - Applies custom titles
   - Selects the appropriate tab in each window

### Use Cases for Session Management

#### 1. Project-Specific Terminal Setups

Save different arrangements for different projects:

- **Web Development**: One window with tabs for server, client, and database
- **System Administration**: Window with tabs for logs, monitoring, and command execution
- **Documentation**: Window positioned alongside a text editor or browser

#### 2. Multi-Machine Management

Create arrangements for managing multiple systems:

- **Window per Server**: Each window dedicated to a different server
- **Tab Organization**: Tabs within each window for different server functions
- **Color Coding**: Use different terminal settings for different environments

#### 3. Context Switching

Quickly switch between different terminal configurations based on your current task:

- **Morning Routine**: Arrangement with email checking, calendar review
- **Development Mode**: Arrangement with code editing, building, and debugging
- **Presentation Setup**: Clean arrangement for demonstrations

### Working with Custom Arrangements

#### Customization Possibilities

The script can be extended to:

1. **Capture More Settings**:
   - Terminal profile information
   - Font and color settings
   - Background transparency

2. **Add Additional Features**:
   - Automatic command execution upon restoration
   - Scheduled arrangement switches
   - Integration with system events

#### Limitations

There are some limitations compared to iTerm2's built-in arrangement system:

1. **No Content Preservation**: Terminal buffer contents cannot be saved
2. **Command History**: Command history is not preserved between sessions
3. **Split Panes**: Terminal.app split panes cannot be directly saved/restored

### Tips for Effective Usage

1. **Naming Conventions**: Use descriptive names for arrangements (e.g., "WebDev", "ServerAdmin")
2. **Regular Updates**: Re-save arrangements when your workflow changes
3. **Backup Your Arrangements**: Include the arrangements directory in backups
4. **Tab Titles**: Set meaningful tab titles before saving to make restoration more useful

### Example Scenarios

#### Development Workflow

1. Open Terminal with 3 tabs: Editor, Server, and Build
2. Position the window on your primary monitor
3. Save as "Development"

Later, you can restore this exact setup with a single command.

#### Server Management

1. Create a window for each environment (Production, Staging, Development)
2. Set different titles and positions for each
3. Save as "ServerManagement"

This allows quick access to all your server environments in a consistent layout.

#### Presentation Mode

1. Set up a clean Terminal window with large font
2. Position it for optimal visibility during screen sharing
3. Save as "Presentation"

Now you can instantly switch to presentation mode when needed.