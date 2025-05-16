---
id: vscode_open_folder
title: Open folder in VS Code
description: Opens a folder in Visual Studio Code using shell command
language: applescript
author: Claude
keywords:
  - vscode
  - folder
  - project
  - editor
  - workspace
usage_examples:
  - "Open the current Finder selection in VS Code"
  - "Open a specific project folder in VS Code"
parameters:
  - name: folderPath
    description: The path to the folder to open (POSIX path)
    required: true
---

# Open folder in VS Code

This script opens a specified folder in Visual Studio Code. It requires VS Code's command-line interface to be installed via the "Shell Command: Install 'code' command in PATH" command in VS Code.

```applescript
on run {input, parameters}
    set folderPath to "--MCP_INPUT:folderPath"
    
    -- Check if we have a path or if we should use the current Finder selection
    if folderPath is "" or folderPath is missing value then
        tell application "Finder"
            if exists Finder window 1 then
                set currentFolder to target of Finder window 1 as alias
                set folderPath to POSIX path of currentFolder
            else
                display dialog "No Finder window open and no folder path provided." buttons {"OK"} default button "OK" with icon stop
                return
            end if
        end tell
    end if
    
    -- Ensure the path is properly quoted to handle spaces and special characters
    set quotedPath to quoted form of folderPath
    
    -- Open the folder in VS Code
    do shell script "code " & quotedPath
    
    return "Opened " & folderPath & " in VS Code"
end run
```