---
id: sublime_text_manipulate_text
title: Manipulate text in Sublime Text
description: 'Insert, replace, or modify text in Sublime Text'
language: applescript
author: Claude
keywords:
  - clipboard
  - text transformation
  - editing
  - formatting
  - code manipulation
usage_examples:
  - Insert text at cursor position
  - Replace selected text
  - Transform text with common operations
parameters:
  - name: action
    description: 'The action to perform (''insert'', ''replace'', ''transform'')'
    required: true
  - name: text
    description: The text to insert or replace with
    required: false
  - name: transformType
    description: >-
      The type of transformation ('uppercase', 'lowercase', 'titlecase',
      'indent', 'outdent', 'trim', 'sort')
    required: false
category: 08_editors
---

# Manipulate text in Sublime Text

This script provides functionality for manipulating text in Sublime Text. It can insert new text at the cursor position, replace selected text, or apply common text transformations.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set textContent to "--MCP_INPUT:text"
    set transformType to "--MCP_INPUT:transformType"
    
    -- Validate action
    if action is not "insert" and action is not "replace" and action is not "transform" then
        return "Error: Invalid action. Use 'insert', 'replace', or 'transform'."
    end if
    
    -- Check if Sublime Text is running
    tell application "System Events"
        set isRunning to (exists process "Sublime Text")
    end tell
    
    if not isRunning then
        tell application "Sublime Text" to activate
        delay 1 -- Give time for Sublime Text to start
    end if
    
    -- Activate Sublime Text
    tell application "Sublime Text"
        activate
        delay 0.5
    end tell
    
    -- Perform the requested action
    if action is "insert" then
        return my insertText(textContent)
    else if action is "replace" then
        return my replaceText(textContent)
    else if action is "transform" then
        return my transformText(transformType)
    end if
end run

-- Insert text at the current cursor position
on insertText(textToInsert)
    if textToInsert is "" or textToInsert is missing value then
        return "Error: No text provided to insert"
    end if
    
    -- Save text to clipboard
    set the clipboard to textToInsert
    
    -- Paste the text at the cursor position
    tell application "System Events"
        tell process "Sublime Text"
            keystroke "v" using {command down}
        end tell
    end tell
    
    return "Inserted text at cursor position"
end insertText

-- Replace selected text with new text
on replaceText(newText)
    if newText is "" or newText is missing value then
        return "Error: No replacement text provided"
    end if
    
    -- Check if there's a selection
    set hasSelection to false
    
    -- Save current clipboard
    set oldClipboard to my getClipboard()
    
    -- Copy current selection to check if there's something selected
    tell application "System Events"
        tell process "Sublime Text"
            keystroke "c" using {command down}
            delay 0.3
        end tell
    end tell
    
    set selection to my getClipboard()
    
    -- If nothing was copied, there was no selection
    if selection is not "" then
        set hasSelection to true
    end if
    
    if not hasSelection then
        -- Restore original clipboard
        my setClipboard(oldClipboard)
        return "Error: No text is currently selected in Sublime Text"
    end if
    
    -- Set new text to clipboard
    set the clipboard to newText
    
    -- Paste to replace selection
    tell application "System Events"
        tell process "Sublime Text"
            keystroke "v" using {command down}
        end tell
    end tell
    
    -- Restore original clipboard
    delay 0.3
    my setClipboard(oldClipboard)
    
    return "Replaced selected text"
end replaceText

-- Apply a text transformation to the selected text
on transformText(transform)
    if transform is "" or transform is missing value then
        return "Error: No transformation type specified"
    end if
    
    -- Map transformation types to Sublime Text commands
    if transform is "uppercase" then
        return my executeTransformCommand("Upper Case")
    else if transform is "lowercase" then
        return my executeTransformCommand("Lower Case")
    else if transform is "titlecase" then
        return my executeTransformCommand("Title Case")
    else if transform is "indent" then
        -- Just press Tab key
        tell application "System Events"
            tell process "Sublime Text"
                keystroke tab
            end tell
        end tell
        return "Indented text"
    else if transform is "outdent" then
        -- Press Shift+Tab
        tell application "System Events"
            tell process "Sublime Text"
                keystroke tab using {shift down}
            end tell
        end tell
        return "Outdented text"
    else if transform is "trim" then
        return my executeTransformCommand("Trim Trailing Whitespace")
    else if transform is "sort" then
        return my executeTransformCommand("Sort Lines")
    else
        return "Error: Unknown transformation type: " & transform
    end if
end transformText

-- Execute a transformation command via command palette
on executeTransformCommand(commandName)
    tell application "System Events"
        tell process "Sublime Text"
            -- Open command palette
            keystroke "p" using {command down, shift down}
            delay 0.3
            
            -- Type the command
            keystroke commandName
            delay 0.3
            
            -- Execute the command
            keystroke return
        end tell
    end tell
    
    return "Applied transformation: " & commandName
end executeTransformCommand

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
