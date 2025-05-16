---
title: 'GarageBand: Project Management'
category: 10_creative
id: garageband_project_management
description: >-
  Manage GarageBand projects including creating, opening, saving, and exporting
  projects.
keywords:
  - GarageBand
  - project
  - save
  - open
  - export
  - new
  - management
  - music production
language: applescript
parameters: >
  - action (required): Action to perform - "new", "open", "save", "export",
  "close"

  - file_path (optional): Path for file operations (required for open/export
  actions)

  - template (optional): Template name for new project (e.g., "Electronic", "Hip
  Hop", "Voice")
notes: >
  - GarageBand must be running for most of these commands to work.

  - GarageBand has limited AppleScript support, so this script uses UI
  automation.

  - For the "open" action, provide a full path to a GarageBand project file
  (.band).

  - For the "export" action, provide a directory path where the project should
  be exported.

  - Templates are not always consistent between GarageBand versions, so template
  selection may vary.

  - This script requires Accessibility permissions to be granted for the script
  runner.
---

Manage GarageBand projects with automation.

```applescript
-- Get parameters
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  return "Error: No action specified. Please specify an action: new, open, save, export, or close."
end if

set filePathParam to "--MCP_INPUT:file_path"
if filePathParam is "" or filePathParam is "--MCP_INPUT:file_path" then
  set filePathParam to "" -- Empty means no file path provided
end if

set templateParam to "--MCP_INPUT:template"
if templateParam is "" or templateParam is "--MCP_INPUT:template" then
  set templateParam to "" -- Empty means no template specified
end if

-- Validate action parameter
set validActions to {"new", "open", "save", "export", "close"}
set isValidAction to false
repeat with validAction in validActions
  if actionParam is validAction then
    set isValidAction to true
    exit repeat
  end if
end repeat

if not isValidAction then
  return "Error: Invalid action. Valid options are: " & validActions
end if

-- Validate required parameters for specific actions
if actionParam is "open" and filePathParam is "" then
  return "Error: The 'open' action requires a file_path parameter."
end if

if actionParam is "export" and filePathParam is "" then
  return "Error: The 'export' action requires a file_path parameter."
end if

-- Check if GarageBand is running
tell application "System Events"
  set garageBandRunning to exists process "GarageBand"
end tell

if not garageBandRunning then
  -- For most actions, GarageBand must be running
  if actionParam is not "open" then
    return "Error: GarageBand is not running. Please launch GarageBand first."
  else
    -- For "open" action, we can launch GarageBand
    tell application "GarageBand" to activate
    delay 2 -- Give time for GarageBand to launch
  end if
end if

-- Get the frontmost application to restore focus later if needed
tell application "System Events"
  set frontApp to name of first process whose frontmost is true
end tell

-- Execute the requested action
tell application "GarageBand"
  -- Activate GarageBand
  activate
  delay 0.5 -- Give time for GarageBand to come to foreground
  
  -- Initialize result
  set resultText to ""
  
  if actionParam is "new" then
    -- Create a new project
    tell application "System Events"
      tell process "GarageBand"
        -- Use Command+N to create a new project
        keystroke "n" using {command down}
        delay 1
        
        -- Check if template chooser appears and try to handle it
        try
          -- This will vary by GarageBand version, so we'll try a few approaches
          
          -- Look for dialog with template options
          if (count of windows whose subrole is "AXStandardWindow") > 0 then
            set templateWindow to window 1 whose subrole is "AXStandardWindow"
            
            -- If a specific template was requested
            if templateParam is not "" then
              -- Try to find and click the template
              -- This is challenging without knowing exact UI elements
              try
                -- Try various approaches to select template
                
                -- Approach 1: Search for template by name
                try
                  -- Type the template name to search
                  keystroke templateParam
                  delay 0.5
                  
                  -- Press return to select it
                  keystroke return
                  delay 1
                on error
                  -- Search approach failed
                end try
                
                -- Approach 2: Try to locate template by name in the window
                try
                  -- Look for a text element, static text, or button with the template name
                  set templateElements to UI elements of templateWindow whose name contains templateParam
                  if (count of templateElements) > 0 then
                    click item 1 of templateElements
                    delay 1
                    
                    -- Click Choose/Create button
                    keystroke return
                    delay 1
                  end if
                on error
                  -- Element search approach failed
                end try
                
                -- If we failed to select the template, just accept the default
                keystroke return
                delay 1
              on error
                -- If template selection fails, just create a default project
                keystroke return
                delay 1
              end try
            else
              -- No specific template, just use default
              keystroke return
              delay 1
            end if
          end if
        on error
          -- Template handling failed, try to proceed anyway
        end try
      end tell
    end tell
    
    -- Wait for project to be created
    delay 2
    
    set resultText to "New GarageBand project created."
    if templateParam is not "" then
      set resultText to resultText & " Attempted to use template: " & templateParam
    end if
    
  else if actionParam is "open" then
    -- Open an existing project
    
    -- Check if file exists
    tell application "System Events"
      if not (exists POSIX file filePathParam) then
        return "Error: File not found at path: " & filePathParam
      end if
    end tell
    
    -- Get and check file extension
    set fileExtension to ""
    set lastDotPos to offset of "." in filePathParam from -1 -- Search from end of string
    if lastDotPos > 0 then
      set fileExtension to text (-(lastDotPos - 1)) thru -1 of filePathParam
    end if
    
    if fileExtension is not ".band" then
      return "Error: File does not appear to be a GarageBand project. Expected extension .band, got: " & fileExtension
    end if
    
    -- Try to open the project
    try
      -- Use open command if supported
      open filePathParam
      delay 2
      
      set resultText to "Opened GarageBand project: " & filePathParam
    on error errMsg
      -- If direct open fails, try UI approach
      try
        tell application "System Events"
          tell process "GarageBand"
            -- Use Command+O for Open dialog
            keystroke "o" using {command down}
            delay 1
            
            -- Navigate to the file
            -- Use Command+Shift+G to go to folder
            keystroke "g" using {command down, shift down}
            delay 0.5
            
            -- Extract directory path from file path
            set lastSlashPos to offset of "/" in filePathParam from -1 -- Search from end of string
            set dirPath to text 1 thru (-lastSlashPos - 1) of filePathParam
            
            -- Type the directory path
            keystroke dirPath
            delay 0.2
            keystroke return
            delay 1
            
            -- Now find and select the file in the dialog
            set fileName to text (-(lastSlashPos - 1)) thru -1 of filePathParam
            keystroke fileName
            delay 0.5
            keystroke return
            delay 2
            
            set resultText to "Opened GarageBand project using file dialog: " & filePathParam
          end tell
        end tell
      on error openUIErr
        return "Error opening GarageBand project using multiple methods: " & openUIErr
      end try
    end try
    
  else if actionParam is "save" then
    -- Save the current project
    tell application "System Events"
      tell process "GarageBand"
        -- Use Command+S to save
        keystroke "s" using {command down}
        delay 1
        
        -- Handle possible save dialog if this is a new unsaved project
        try
          -- Look for save dialog
          repeat with i from 1 to 5 -- Try a few times to find the dialog
            if (count of windows whose role is "AXSheet") > 0 then
              -- Save dialog detected, enter a name and save
              set saveDialog to window 1 whose role is "AXSheet"
              
              -- Generate a default name if needed
              set defaultName to "GarageBand Project " & (current date)
              
              -- Type a name
              keystroke defaultName
              delay 0.2
              
              -- Click Save button or press return
              keystroke return
              delay 1
              
              exit repeat
            end if
            delay 0.2
          end repeat
        on error
          -- No save dialog or couldn't be detected
        end try
      end tell
    end tell
    
    set resultText to "Saved current GarageBand project."
    
  else if actionParam is "export" then
    -- Export the project (typically as audio file)
    tell application "System Events"
      tell process "GarageBand"
        -- Use Share menu
        try
          -- Click on Share menu
          click menu item "Share" of menu bar 1
          delay 0.5
          
          -- Click on Export Song to Disk submenu
          click menu item "Export Song to Disk..." of menu "Share" of menu bar 1
          delay 1
          
          -- Handle export dialog
          try
            -- Look for export dialog
            if (count of windows whose role is "AXSheet") > 0 then
              set exportDialog to window 1 whose role is "AXSheet"
              
              -- Set export settings (format, quality, etc.)
              -- This is highly dependent on GarageBand version and UI
              -- We'll focus on navigation for now
              
              -- Click Export button or press return
              keystroke return
              delay 1
              
              -- In the save dialog
              try
                -- Extract directory path
                set dirPath to filePathParam
                
                -- If path includes filename, extract directory
                if dirPath contains "." then
                  set lastSlashPos to offset of "/" in dirPath from -1 -- Search from end of string
                  set dirPath to text 1 thru (-lastSlashPos - 1) of dirPath
                end if
                
                -- Navigate to the directory
                -- Use Command+Shift+G to go to folder
                keystroke "g" using {command down, shift down}
                delay 0.5
                keystroke dirPath
                delay 0.2
                keystroke return
                delay 1
                
                -- Enter a filename if needed or use default
                -- We'll let GarageBand use its default naming
                
                -- Click Save/Export button or press return
                keystroke return
                delay 2
                
                set resultText to "Exported GarageBand project to: " & filePathParam
              on error navErr
                set resultText to "Error navigating to export location: " & navErr
              end try
            end if
          on error dlgErr
            set resultText to "Error handling export dialog: " & dlgErr
          end try
        on error menuErr
          -- If menu navigation fails, try keyboard shortcut if known
          try
            -- Try Shift+Command+E (common export shortcut in some versions)
            keystroke "e" using {command down, shift down}
            delay 1
            
            -- Handle dialogs as above... (would repeat code)
            set resultText to "Attempted export using keyboard shortcut."
          on error
            set resultText to "Error accessing export functionality: " & menuErr
          end try
        end try
      end tell
    end tell
    
  else if actionParam is "close" then
    -- Close the current project
    tell application "System Events"
      tell process "GarageBand"
        -- Use Command+W to close
        keystroke "w" using {command down}
        delay 1
        
        -- Handle possible save dialog
        try
          repeat with i from 1 to 5 -- Try a few times to find the dialog
            if (count of windows whose role is "AXSheet") > 0 then
              -- Save dialog detected, handle it
              
              -- Click "Save" button to save changes (or press Return)
              keystroke return
              delay 1
              
              -- Handle possible save dialog if this is a new unsaved project
              -- (similar to save action above)
              try
                -- Look for another save dialog
                if (count of windows whose role is "AXSheet") > 0 then
                  -- Enter a default name and save
                  set defaultName to "GarageBand Project " & (current date)
                  keystroke defaultName
                  delay 0.2
                  keystroke return
                  delay 1
                end if
              on error
                -- No additional dialog
              end try
              
              exit repeat
            end if
            delay 0.2
          end repeat
        on error
          -- No save dialog appeared or couldn't be detected
        end try
      end tell
    end tell
    
    set resultText to "Closed current GarageBand project."
  end if
  
  -- Return result
  return resultText
end tell

-- Restore focus to original application if needed
if frontApp is not "GarageBand" then
  tell application frontApp to activate
end if
```
