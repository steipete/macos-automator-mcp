---
title: "Logic Pro: Project Management"
category: "08_creative_and_document_apps"
id: logic_pro_project_management
description: "Manage Logic Pro projects including creating, opening, saving, and backing up projects."
keywords: ["Logic Pro", "DAW", "project", "management", "save", "open", "backup", "music production"]
language: applescript
parameters: |
  - action (required): Action to perform - "new", "open", "save", "save_as", "backup", "close"
  - file_path (optional): Path to project file (required for open and save_as actions)
  - template (optional): Template to use for new project (for new action)
notes: |
  - Logic Pro must be running for these commands to work.
  - Logic Pro has limited AppleScript support, so this script uses UI automation through System Events.
  - For the "open" action, provide a full path to a .logicx project file.
  - For the "save_as" action, provide a directory path where the project should be saved.
  - The "backup" action creates a timestamped copy of the current project.
  - Some actions may require Accessibility permissions to be granted to the script runner.
---

Manage Logic Pro projects with automation.

```applescript
-- Get parameters
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  return "Error: No action specified. Please specify an action: new, open, save, save_as, backup, or close."
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
set validActions to {"new", "open", "save", "save_as", "backup", "close"}
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
if (actionParam is "open") and filePathParam is "" then
  return "Error: The 'open' action requires a file_path parameter."
end if

if (actionParam is "save_as") and filePathParam is "" then
  return "Error: The 'save_as' action requires a file_path parameter."
end if

-- Check if Logic Pro is running
tell application "System Events"
  set logicRunning to exists process "Logic Pro"
end tell

if not logicRunning then
  -- For most actions, Logic Pro must be running
  if actionParam is not "open" then
    return "Error: Logic Pro is not running. Please launch Logic Pro first."
  else
    -- For "open" action, we can launch Logic Pro
    tell application "Logic Pro" to activate
    delay 2 -- Give time for Logic Pro to launch
  end if
end if

-- Get the frontmost application to restore focus later if needed
tell application "System Events"
  set frontApp to name of first process whose frontmost is true
end tell

-- Execute the requested action
tell application "Logic Pro"
  -- Activate Logic Pro
  activate
  delay 0.5 -- Give time for Logic Pro to come to foreground
  
  -- Initialize result
  set resultText to ""
  
  if actionParam is "new" then
    -- Create a new project
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+N to create a new project
        keystroke "n" using {command down}
        delay 1
        
        -- Check if template chooser appears
        try
          -- Look for dialog with template options
          if (count of windows whose title contains "Project") > 0 or (count of windows whose title contains "Template") > 0 then
            -- If a specific template was requested
            if templateParam is not "" then
              -- Try to find and click the template
              -- This is challenging without knowing exact UI elements
              -- A basic approach that may work in some cases:
              try
                -- Try to select template by typing search text
                keystroke templateParam
                delay 0.5
                
                -- Hit return to select
                keystroke return
                delay 1
              on error
                -- If template selection fails, just create a default project
                -- Hit return to accept defaults
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
          -- Ignore errors in template detection
        end try
      end tell
    end tell
    
    -- Check if we need to handle a save dialog for the new project
    my handlePossibleSaveDialog("")
    
    set resultText to "New Logic Pro project created."
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
    
    if fileExtension is not ".logicx" then
      return "Error: File does not appear to be a Logic Pro project. Expected extension .logicx, got: " & fileExtension
    end if
    
    -- Try to open the project
    try
      -- Open the file
      open filePathParam
      delay 2
      
      set resultText to "Opened Logic Pro project: " & filePathParam
    on error errMsg
      set resultText to "Error opening Logic Pro project: " & errMsg
    end try
    
  else if actionParam is "save" then
    -- Save the current project
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+S to save
        keystroke "s" using {command down}
        delay 1
      end tell
    end tell
    
    -- Handle possible save dialog if this is a new unsaved project
    my handlePossibleSaveDialog("")
    
    set resultText to "Saved current Logic Pro project."
    
  else if actionParam is "save_as" then
    -- Save the project with a new name/location
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+Shift+S for Save As
        keystroke "s" using {command down, shift down}
        delay 1
      end tell
    end tell
    
    -- Handle save dialog
    my handlePossibleSaveDialog(filePathParam)
    
    set resultText to "Saved Logic Pro project as: " & filePathParam
    
  else if actionParam is "backup" then
    -- Create a backup of the current project
    
    -- First, determine the current project's path
    -- This is challenging with Logic Pro's limited AppleScript support
    -- We'll try to use Save As and then cancel to get the current path
    
    set currentProjectPath to ""
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+Shift+S for Save As dialog to see current path
        keystroke "s" using {command down, shift down}
        delay 1
        
        -- Try to get current path from dialog
        try
          set saveDialog to window 1 whose subrole is "AXStandardWindow" and role is "AXSheet"
          
          -- Try to get text from name field
          try
            set nameField to text field 1 of saveDialog
            set currentProjectName to value of nameField
          on error
            set currentProjectName to "LogicProject" -- Default name if we can't detect
          end try
          
          -- Now that we have the info, cancel the dialog
          keystroke escape
          delay 0.5
          
        on error
          -- If we can't detect dialog, just cancel anyway
          keystroke escape
          delay 0.5
        end try
      end tell
    end tell
    
    -- Now create a backup by saving as a new file
    -- Generate a timestamped name for the backup
    set currentDate to current date
    set timestamp to (year of currentDate as string) & "-" & ¬
      my padNumber(month of currentDate as integer) & "-" & ¬
      my padNumber(day of currentDate) & "_" & ¬
      my padNumber(hours of currentDate) & "-" & ¬
      my padNumber(minutes of currentDate)
    
    if currentProjectName is "" then
      set currentProjectName to "LogicProject"
    end if
    
    -- Remove .logicx extension if present
    if currentProjectName ends with ".logicx" then
      set currentProjectName to text 1 thru -8 of currentProjectName
    end if
    
    set backupName to currentProjectName & "_Backup_" & timestamp & ".logicx"
    
    -- Determine backup folder path
    set backupFolder to ""
    if filePathParam is "" then
      -- Use Desktop as default backup location
      set backupFolder to (path to desktop folder as text)
    else
      set backupFolder to filePathParam
      
      -- Ensure path ends with a slash
      if backupFolder does not end with "/" then
        set backupFolder to backupFolder & "/"
      end if
    end if
    
    -- Convert to POSIX path if needed
    if backupFolder does not start with "/" then
      set backupFolder to POSIX path of backupFolder
    end if
    
    -- Full backup path
    set backupPath to backupFolder & backupName
    
    -- Now save as the backup
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+Shift+S for Save As
        keystroke "s" using {command down, shift down}
        delay 1
      end tell
    end tell
    
    -- Handle save dialog
    my handlePossibleSaveDialog(backupPath)
    
    -- After saving backup, save original again
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+S to save
        keystroke "s" using {command down}
        delay 1
      end tell
    end tell
    
    set resultText to "Created backup of Logic Pro project at: " & backupPath
    
  else if actionParam is "close" then
    -- Close the current project
    tell application "System Events"
      tell process "Logic Pro"
        -- Use Command+W to close
        keystroke "w" using {command down}
        delay 1
        
        -- Handle possible save dialog
        try
          set saveDialog to window 1 whose role is "AXSheet"
          
          -- Click "Save" button to save changes
          click button "Save" of saveDialog
          delay 1
          
          -- Handle possible save dialog if this is a new unsaved project
          my handlePossibleSaveDialog("")
        on error
          -- No save dialog appeared or couldn't be detected
        end try
      end tell
    end tell
    
    set resultText to "Closed current Logic Pro project."
  end if
  
  -- Return result
  return resultText
end tell

-- Helper function to handle save dialogs
on handlePossibleSaveDialog(targetPath)
  try
    tell application "System Events"
      tell process "Logic Pro"
        -- Check if save dialog is present
        try
          set saveDialog to window 1 whose subrole is "AXStandardWindow" and role is "AXSheet"
          
          -- Save dialog detected
          
          if targetPath is not "" then
            -- Fill in the name field if we have a target path
            
            -- Extract file name from path
            set lastSlashPos to offset of "/" in targetPath from -1 -- Search from end of string
            set fileName to text (-(lastSlashPos - 1)) thru -1 of targetPath
            
            -- Enter the file name
            keystroke "a" using {command down} -- Select all
            delay 0.2
            keystroke fileName -- Type the new name
            delay 0.2
            
            -- If we have a directory path, try to navigate to it
            if lastSlashPos > 0 then
              -- Try to expand the folder selection dropdown
              try
                -- Click on the folder dropdown button
                -- This is best-effort and may need adjustment
                click pop up button 1 of saveDialog
                delay 0.5
                
                -- Navigate to specified folder using "Other..."
                keystroke "o" -- Type 'o' to select "Other..."
                delay 0.5
                
                -- In the folder selection dialog
                set folderPath to text 1 thru (-lastSlashPos - 1) of targetPath
                
                -- Enter the folder path
                keystroke "g" using {command down, shift down} -- Command+Shift+G for "Go to Folder"
                delay 0.5
                keystroke folderPath -- Type the folder path
                delay 0.2
                keystroke return -- Confirm
                delay 0.5
                keystroke return -- Confirm again
                delay 0.5
              on error
                -- Folder navigation failed, just save with the file name
              end try
            end if
          end if
          
          -- Click Save button
          click button "Save" of saveDialog
          delay 1
          
          -- Handle possible overwrite confirmation
          try
            delay 0.5
            set confirmDialog to window 1 whose role is "AXSheet"
            click button "Replace" of confirmDialog
            delay 1
          on error
            -- No overwrite dialog appeared or couldn't be detected
          end try
        on error
          -- No save dialog appeared or couldn't be detected
        end try
      end tell
    end tell
  on error
    -- Ignore errors in dialog handling
  end try
end handlePossibleSaveDialog

-- Helper function to pad numbers with leading zero
on padNumber(num)
  set numText to num as text
  if (count numText) < 2 then
    set numText to "0" & numText
  end if
  return numText
end padNumber
```