---
id: iterm_dev_environment
title: Set up iTerm2 development environment
description: Creates a multi-pane iTerm2 development environment for a project
language: applescript
author: Claude
keywords:
  - terminal
  - development
  - workspace
  - panes
  - project setup
usage_examples:
  - >-
    Set up a development environment for a web project with server, client, and
    terminal panes
  - Create a standardized multi-pane terminal workspace
parameters:
  - name: projectPath
    description: Path to the project directory (POSIX path)
    required: true
  - name: serverCommand
    description: Command to start the server (optional)
    required: false
  - name: clientCommand
    description: Command to start the client (optional)
    required: false
category: 06_terminal
---

# Set up iTerm2 Development Environment

This script creates a standardized multi-pane iTerm2 development environment for a project with server, client, and free terminal panes.

```applescript
on run {input, parameters}
    set projectPath to "--MCP_INPUT:projectPath"
    set serverCommand to "--MCP_INPUT:serverCommand"
    set clientCommand to "--MCP_INPUT:clientCommand"
    
    if projectPath is "" or projectPath is missing value then
        tell application "Finder"
            if exists Finder window 1 then
                set currentFolder to target of Finder window 1 as alias
                set projectPath to POSIX path of currentFolder
            else
                display dialog "No Finder window open and no project path provided." buttons {"OK"} default button "OK" with icon stop
                return
            end if
        end tell
    end if
    
    -- Set default commands if not provided
    if serverCommand is "" or serverCommand is missing value then
        set serverCommand to ""
    end if
    
    if clientCommand is "" or clientCommand is missing value then
        set clientCommand to ""
    end if
    
    tell application "iTerm"
        -- Create a new window or use existing
        if exists window 1 then
            set projectWindow to window 1
        else
            set projectWindow to (create window with default profile)
        end if
        
        tell projectWindow
            -- Set up server pane (top)
            tell current session
                set name to "Server"
                write text "cd " & quoted form of projectPath
                if serverCommand is not "" then
                    write text serverCommand
                end if
                
                -- Split horizontally for client pane (middle)
                set clientPane to (split horizontally with default profile)
                tell clientPane
                    set name to "Client"
                    write text "cd " & quoted form of projectPath
                    if clientCommand is not "" then
                        write text clientCommand
                    end if
                end tell
                
                -- Split client pane horizontally for free terminal (bottom)
                tell clientPane
                    set freePane to (split horizontally with default profile)
                    tell freePane
                        set name to "Terminal"
                        write text "cd " & quoted form of projectPath
                    end tell
                end tell
            end tell
            
            -- Create a second tab for utility functions
            set utilityTab to (create tab with default profile)
            tell utilityTab
                tell current session
                    set name to "Utility"
                    write text "cd " & quoted form of projectPath
                end tell
            end tell
        end tell
        
        -- Activate iTerm and bring to front
        activate
    end tell
    
    return "Created development environment for project at " & projectPath
end run
```

## Common Server Commands

For different project types, you might want to use these standard commands:

### Node.js Projects
```
npm start
```

### React Projects
```
npm run dev
```

### Python Projects
```
python manage.py runserver  # Django
flask run                   # Flask
```

### Ruby on Rails
```
rails server
```

## Customization Options

This script provides a standard three-pane layout, but you can modify it to:

1. Create different split orientations (vertical vs horizontal)
2. Add more or fewer panes
3. Change the default commands
4. Launch related applications (like VS Code or a browser)

To create a vertical split instead of horizontal:

```applescript
set clientPane to (split vertically with default profile)
```

To launch VS Code alongside the terminal setup, add:

```applescript
do shell script "code " & quoted form of projectPath
```

## Note on iTerm2 Version

This script works with iTerm2 3.x and later. For earlier versions, the AppleScript syntax may differ slightly. Ensure you have the latest version of iTerm2 installed for best results.
