---
id: jetbrains_open_project
title: Open project in JetBrains IDE
description: Opens a project in a specific JetBrains IDE (IntelliJ, WebStorm, etc.)
language: applescript
author: Claude
keywords:
  - jetbrains
  - project-management
  - IDE
  - development
  - workspace
usage_examples:
  - "Open a project in IntelliJ IDEA"
  - "Open a project in WebStorm"
  - "Open a project in PyCharm"
parameters:
  - name: ideName
    description: The name of the JetBrains IDE (e.g., 'IntelliJ IDEA', 'WebStorm', 'PyCharm')
    required: true
  - name: projectPath
    description: Path to the project to open (POSIX path)
    required: true
---

# Open project in JetBrains IDE

This script opens a specific project in a JetBrains IDE (IntelliJ IDEA, WebStorm, PyCharm, etc.).

```applescript
on run {input, parameters}
    set ideName to "--MCP_INPUT:ideName"
    set projectPath to "--MCP_INPUT:projectPath"
    
    if ideName is "" or ideName is missing value then
        display dialog "Please specify a JetBrains IDE name (e.g., 'IntelliJ IDEA', 'WebStorm', 'PyCharm')." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
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
    
    -- Check if the IDE is running
    set isRunning to false
    try
        tell application "System Events"
            set isRunning to (count of (every process whose name is ideName)) > 0
        end tell
    end try
    
    -- Generate the correct shell command based on IDE
    set shellCommand to ""
    if ideName contains "IntelliJ" then
        set shellCommand to "open -a \"" & ideName & "\" \"" & projectPath & "\""
    else if ideName is "WebStorm" then
        set shellCommand to "open -a WebStorm \"" & projectPath & "\""
    else if ideName is "PyCharm" then
        set shellCommand to "open -a PyCharm \"" & projectPath & "\""
    else if ideName is "CLion" then
        set shellCommand to "open -a CLion \"" & projectPath & "\""
    else if ideName is "PhpStorm" then
        set shellCommand to "open -a PhpStorm \"" & projectPath & "\""
    else if ideName is "Rider" then
        set shellCommand to "open -a Rider \"" & projectPath & "\""
    else if ideName is "GoLand" then
        set shellCommand to "open -a GoLand \"" & projectPath & "\""
    else if ideName is "RubyMine" then
        set shellCommand to "open -a RubyMine \"" & projectPath & "\""
    else
        -- Generic fallback
        set shellCommand to "open -a \"" & ideName & "\" \"" & projectPath & "\""
    end if
    
    -- Execute the command
    do shell script shellCommand
    
    return "Opened project " & projectPath & " in " & ideName
end run
```