---
title: 'Terminal: Open and Close Windows'
id: terminal_open_close_window
category: 06_terminal/terminal_app
description: >-
  Opens a new Terminal.app window, optionally runs a command, and provides
  functionality to close windows.
keywords:
  - Terminal.app
  - window
  - open
  - close
  - create
  - quit
  - command
language: applescript
argumentsPrompt: >-
  Expects inputData with: { "command": "optional command to run", "action":
  "open or close", "targetWindow": "all, front, or a number" } (action defaults
  to 'open' if omitted).
isComplex: false
---

This script manages Terminal.app windows, allowing you to open new windows and close existing ones.

**Features:**
- Open a new Terminal.app window (optionally executing a command)
- Close the frontmost window, a specific window by number, or all windows
- Control Terminal.app without closing the entire application

**Usage Examples:**
- Open a new Terminal window and execute a command
- Close only the frontmost Terminal window
- Close all Terminal windows at once

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultCommand to ""
    set defaultAction to "open"
    set defaultTargetWindow to "front"
    
    -- Parse input parameters
    set command to defaultCommand
    set action to defaultAction
    set targetWindow to defaultTargetWindow
    
    if inputData is not missing value then
        if inputData contains {command:""} then
            set command to command of inputData
        end if
        if inputData contains {action:""} then
            set action to action of inputData
        end if
        if inputData contains {targetWindow:""} then
            set targetWindow to targetWindow of inputData
        end if
    end if
    
    -- MCP placeholders for input
    set command to "--MCP_INPUT:command" -- optional command to run
    set action to "--MCP_INPUT:action" -- open or close (defaults to "open" if omitted)
    set targetWindow to "--MCP_INPUT:targetWindow" -- all, front, or a number
    
    -- Handle different actions
    if action is "open" then
        return openTerminalWindow(command)
    else if action is "close" then
        return closeTerminalWindow(targetWindow)
    else
        return "Error: Invalid action. Use 'open' or 'close'."
    end if
end runWithInput

on openTerminalWindow(command)
    tell application "Terminal"
        -- Activate Terminal application
        activate
        
        -- Create a new window
        set newWindow to do script ""
        
        -- Run the command if provided
        if command is not "" then
            do script command in newWindow
        end if
        
        return "New Terminal window opened" & (if command is not "" then " and executed: " & command else "")
    end tell
end openTerminalWindow

on closeTerminalWindow(targetWindow)
    tell application "Terminal"
        -- Handle closing terminal windows based on targetWindow parameter
        if targetWindow is "all" then
            -- Close all windows
            close every window
            return "Closed all Terminal windows"
            
        else if targetWindow is "front" or targetWindow is "" then
            -- Close the frontmost window
            if (count of windows) > 0 then
                close front window
                return "Closed frontmost Terminal window"
            else
                return "No Terminal windows to close"
            end if
            
        else
            -- Try to close a specific window by number
            try
                set windowNumber to targetWindow as integer
                if windowNumber > 0 and windowNumber ≤ (count of windows) then
                    close window windowNumber
                    return "Closed Terminal window #" & windowNumber
                else
                    return "Error: Window number out of range. Valid range: 1-" & (count of windows)
                end if
            on error
                return "Error: Invalid window target. Use 'all', 'front', or a window number."
            end try
        end if
    end tell
end closeTerminalWindow
```

## Window Management in Terminal.app

Terminal.app allows for multiple windows and tabs, each potentially running different processes. This script provides programmatic control over window creation and closure without affecting the entire application.

### Opening Windows

When opening a new window, you can:

1. Open an empty window by providing no command
2. Execute a specific command in the new window
3. Set up environments by running initialization commands

### Closing Windows

When closing windows, you have several options:

1. Close only the frontmost/active window
2. Close a specific window by its number (starting from 1)
3. Close all windows at once

### Use Cases

- **Development Scripts**: Open multiple Terminal windows for different parts of your development workflow
- **Cleanup Routines**: Close unnecessary windows when finishing a task
- **Application Integration**: Control Terminal windows from other applications or scripts
