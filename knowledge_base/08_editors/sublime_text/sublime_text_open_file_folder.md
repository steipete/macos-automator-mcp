---
id: sublime_text_open_file_folder
title: Open file or folder in Sublime Text
description: Opens a specified file or folder in Sublime Text
language: applescript
author: Claude
keywords:
  - file access
  - directory
  - Finder integration
  - project loading
  - file management
usage_examples:
  - Open the current Finder selection in Sublime Text
  - Open a specific project folder in Sublime Text
parameters:
  - name: itemPath
    description: The path to the file or folder to open (POSIX path)
    required: true
category: 08_editors/sublime_text
---

# Open file or folder in Sublime Text

This script opens a specified file or folder in Sublime Text. It supports opening both individual files and entire directories.

```applescript
on run {input, parameters}
    set itemPath to "--MCP_INPUT:itemPath"
    
    -- Check if we have a path or if we should use the current Finder selection
    if itemPath is "" or itemPath is missing value then
        tell application "Finder"
            if exists Finder window 1 then
                set selectedItem to selection
                if selectedItem is {} then
                    -- Use current folder if no selection
                    set currentFolder to target of Finder window 1 as alias
                    set itemPath to POSIX path of currentFolder
                else
                    -- Use first selected item
                    set itemPath to POSIX path of (item 1 of selectedItem as alias)
                end if
            else
                display dialog "No Finder window open and no path provided." buttons {"OK"} default button "OK" with icon stop
                return
            end if
        end tell
    end if
    
    -- Ensure the path is properly quoted to handle spaces and special characters
    set quotedPath to quoted form of itemPath
    
    -- Check if Sublime Text is installed and get the application path
    set sublimeAppPaths to {¬
        "/Applications/Sublime Text.app", ¬
        "/Applications/Sublime Text 3.app", ¬
        "/Applications/Sublime Text 2.app" ¬
    }
    
    set sublimeAppPath to ""
    repeat with appPath in sublimeAppPaths
        tell application "System Events"
            if exists file appPath then
                set sublimeAppPath to appPath
                exit repeat
            end if
        end tell
    end repeat
    
    if sublimeAppPath is "" then
        return "Error: Sublime Text not found in Applications folder"
    end if
    
    -- Extract application name without .app extension for shell command
    set sublimeAppName to text 1 thru ((offset of ".app" in sublimeAppPath) - 1) of sublimeAppPath
    set sublimeAppName to text ((offset of "/" in (reverse of characters of sublimeAppName as string)) + 1) thru -1 of sublimeAppName
    
    -- Open the file or folder in Sublime Text
    -- Method 1: Using 'open' command
    try
        do shell script "open -a " & quoted form of sublimeAppName & " " & quotedPath
        return "Opened " & itemPath & " in Sublime Text"
    on error openError
        -- Method 2: Using subl command-line tool if available
        try
            do shell script "subl " & quotedPath
            return "Opened " & itemPath & " in Sublime Text using subl command"
        on error sublError
            return "Error opening " & itemPath & " in Sublime Text: " & openError
        end try
    end try
end run
```
