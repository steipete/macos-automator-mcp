---
id: vscode_run_command
title: Run VS Code command
description: Executes commands in Visual Studio Code using the command palette
language: applescript
author: Claude
keywords:
  - vscode
  - command
  - palette
  - automation
  - shortcut
usage_examples:
  - "Open terminal in VS Code"
  - "Run build task in VS Code"
  - "Toggle sidebar in VS Code"
parameters:
  - name: command
    description: The command to execute (e.g., 'workbench.action.terminal.toggleTerminal')
    required: true
---

# Run VS Code command

This script activates VS Code and executes a specified command using keyboard shortcuts to access the Command Palette. 

```applescript
on run {input, parameters}
    set commandToRun to "--MCP_INPUT:command"
    
    if commandToRun is "" or commandToRun is missing value then
        display dialog "Please provide a VS Code command to execute." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Activate VS Code
    tell application "Visual Studio Code"
        activate
    end tell
    
    -- Allow time for VS Code to be in focus
    delay 0.5
    
    -- Open command palette and run command
    tell application "System Events"
        tell process "Code"
            -- Open command palette (Cmd+Shift+P)
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Clear any existing command text
            key code 53 -- Escape key
            delay 0.1
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Enter the command
            keystroke ">" -- Prefix to run a command directly
            keystroke commandToRun
            delay 0.3
            keystroke return
        end tell
    end tell
    
    return "Executed VS Code command: " & commandToRun
end run
```

## Common VS Code Commands

Here are some useful VS Code commands:

- `workbench.action.terminal.toggleTerminal`: Toggle integrated terminal
- `workbench.action.toggleSidebarVisibility`: Toggle sidebar visibility
- `workbench.action.tasks.build`: Run build task
- `workbench.action.files.save`: Save current file
- `workbench.action.files.saveAll`: Save all files
- `workbench.action.quickOpen`: Quick open file selector
- `editor.action.formatDocument`: Format document
- `workbench.action.debug.start`: Start debugging