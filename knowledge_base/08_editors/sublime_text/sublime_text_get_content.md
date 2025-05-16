---
id: sublime_text_get_content
title: Get content from Sublime Text
description: Retrieves the content of the current file open in Sublime Text
language: applescript
author: Claude
keywords:
  - sublime-text
  - clipboard
  - content-extraction
  - file-content
  - text-selection
usage_examples:
  - "Get the content of the currently active file in Sublime Text"
  - "Extract selected text from Sublime Text"
parameters:
  - name: selectionOnly
    description: If 'true', gets only the selected text; otherwise gets entire file content
    required: false
    default: "false"
---

# Get content from Sublime Text

This script retrieves the content of the currently active file in Sublime Text. It can either get the entire file content or just the selected text, depending on the `selectionOnly` parameter.

```applescript
on run {input, parameters}
    set selectionOnly to "--MCP_INPUT:selectionOnly"
    
    -- Default to getting entire content if parameter not specified
    if selectionOnly is "" or selectionOnly is missing value then
        set selectionOnly to "false"
    end if
    
    -- Convert string parameter to boolean
    set getSelectionOnly to (selectionOnly is "true")
    
    -- Check if Sublime Text is running
    tell application "System Events"
        set isRunning to (exists process "Sublime Text")
    end tell
    
    if not isRunning then
        return "Error: Sublime Text is not running"
    end if
    
    -- Get the content using clipboard
    tell application "Sublime Text"
        activate
        delay 0.5 -- Give time for Sublime Text to activate
    end tell
    
    -- Save current clipboard content
    set previousClipboard to my getClipboard()
    
    -- Select all text or use current selection based on parameter
    tell application "System Events"
        tell process "Sublime Text"
            set frontmost to true
            
            if not getSelectionOnly then
                -- Select all text (Command+A)
                keystroke "a" using {command down}
                delay 0.1
            end if
            
            -- Copy the selection to clipboard (Command+C)
            keystroke "c" using {command down}
            delay 0.3 -- Give time for copying to complete
        end tell
    end tell
    
    -- Get the content from clipboard
    set fileContent to my getClipboard()
    
    -- Restore previous clipboard content
    my setClipboard(previousClipboard)
    
    if fileContent is "" then
        if getSelectionOnly then
            return "No text is currently selected in Sublime Text"
        else
            return "The current file in Sublime Text is empty or no file is open"
        end if
    end if
    
    -- Return the content
    return fileContent
end run

-- Helper function to get clipboard content
on getClipboard()
    set clipboardContent to ""
    try
        set clipboardContent to the clipboard as text
    on error
        -- Clipboard might not contain text
    end try
    return clipboardContent
end getClipboard

-- Helper function to set clipboard content
on setClipboard(content)
    set the clipboard to content
end setClipboard
```