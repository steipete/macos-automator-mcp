---
id: sublime_text_project_management
title: Manage Sublime Text projects
description: Create, open, or switch between Sublime Text projects
language: applescript
author: Claude
keywords:
  - project workspace
  - project files
  - workspace management
  - organization
  - project switching
usage_examples:
  - "Create a new Sublime Text project for a folder"
  - "Open an existing Sublime Text project"
  - "Switch between open projects"
parameters:
  - name: action
    description: The action to perform ('create', 'open', or 'switch')
    required: true
  - name: projectPath
    description: The path to the project file (.sublime-project) or folder (for create action)
    required: false
---

# Manage Sublime Text projects

This script provides functionality for managing Sublime Text projects. It can create new projects, open existing project files, or switch between open projects.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set projectPath to "--MCP_INPUT:projectPath"
    
    -- Validate action
    if action is not "create" and action is not "open" and action is not "switch" then
        return "Error: Invalid action. Use 'create', 'open', or 'switch'."
    end if
    
    -- Check if Sublime Text is running
    tell application "System Events"
        set isRunning to (exists process "Sublime Text")
    end tell
    
    if not isRunning and action is not "open" then
        tell application "Sublime Text" to activate
        delay 1 -- Give time for Sublime Text to start
    end if
    
    if action is "create" then
        return my createProject(projectPath)
    else if action is "open" then
        return my openProject(projectPath)
    else if action is "switch" then
        return my switchProject()
    end if
end run

-- Create a new Sublime Text project
on createProject(folderPath)
    -- Validate folder path
    if folderPath is "" or folderPath is missing value then
        tell application "Finder"
            if exists Finder window 1 then
                set selectedItem to selection
                if selectedItem is {} then
                    -- Use current folder if no selection
                    set currentFolder to target of Finder window 1 as alias
                    set folderPath to POSIX path of currentFolder
                else
                    -- Use first selected item
                    set folderPath to POSIX path of (item 1 of selectedItem as alias)
                end if
            else
                return "Error: No folder specified and no Finder window open"
            end if
        end tell
    end if
    
    -- Activate Sublime Text
    tell application "Sublime Text" to activate
    delay 0.5
    
    -- Create a new project using the command palette
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Type "Project: Save As" command
            keystroke "Project: Save As"
            delay 0.3
            
            -- Execute the command
            keystroke return
            delay 0.5
            
            -- A save dialog should appear. Instead of trying to navigate it,
            -- we'll provide instructions for the user
        end tell
    end tell
    
    return "Project creation dialog opened. Please enter a name for your project and save it in your desired location."
end createProject

-- Open an existing Sublime Text project
on openProject(projectPath)
    -- Validate project path
    if projectPath is "" or projectPath is missing value then
        -- Open the quick switch project dialog
        return my switchProject()
    end if
    
    -- Check if the path ends with .sublime-project
    if projectPath does not end with ".sublime-project" then
        set projectPath to projectPath & ".sublime-project"
    end if
    
    -- Ensure the path is properly quoted to handle spaces and special characters
    set quotedPath to quoted form of projectPath
    
    -- Open the project
    do shell script "open -a 'Sublime Text' " & quotedPath
    
    return "Opened Sublime Text project at: " & projectPath
end openProject

-- Switch between open projects
on switchProject()
    -- Activate Sublime Text
    tell application "Sublime Text" to activate
    delay 0.5
    
    -- Open the quick switch project dialog (Ctrl+Cmd+P)
    tell application "System Events"
        tell process "Sublime Text"
            keystroke "p" using {control down, command down}
        end tell
    end tell
    
    return "Project quick-switch dialog opened. Use arrow keys to select a project and press Return to open."
end switchProject
```