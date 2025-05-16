---
id: sublime_text_run_command
title: Run command in Sublime Text
description: Executes a command in Sublime Text via keyboard shortcuts and command palette
language: applescript
author: Claude
keywords:
  - command palette
  - keyboard shortcuts
  - automation
  - workflow
  - code commands
usage_examples:
  - "Open the command palette in Sublime Text"
  - "Execute specific commands like 'Save All', 'Format File', etc."
parameters:
  - name: command
    description: The command to execute (either a specific command for the command palette or a shortcut key sequence)
    required: true
  - name: useCommandPalette
    description: If 'true', opens the command palette and enters the command; if 'false', executes the command directly as keyboard shortcut
    required: false
    default: "true"
---

# Run command in Sublime Text

This script executes commands in Sublime Text, either by using the command palette or by directly sending keyboard shortcuts. It's useful for automating repetitive tasks or executing specific commands programmatically.

```applescript
on run {input, parameters}
    set command to "--MCP_INPUT:command"
    set useCommandPalette to "--MCP_INPUT:useCommandPalette"
    
    -- Default to using command palette if parameter not specified
    if useCommandPalette is "" or useCommandPalette is missing value then
        set useCommandPalette to "true"
    end if
    
    -- Convert string parameter to boolean
    set useCommandPaletteFlag to (useCommandPalette is "true")
    
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
        delay 0.5 -- Give time for Sublime Text to come to front
    end tell
    
    -- Execute the command
    tell application "System Events"
        tell process "Sublime Text"
            set frontmost to true
            
            if useCommandPaletteFlag then
                -- Open the command palette (Command+Shift+P)
                keystroke "p" using {command down, shift down}
                delay 0.3 -- Wait for command palette to open
                
                -- Type the command
                keystroke command
                delay 0.3 -- Wait for command to be entered
                
                -- Press Return to execute
                keystroke return
            else
                -- Parse and execute keyboard shortcut
                my executeShortcut(command)
            end if
        end tell
    end tell
    
    return "Executed command '" & command & "' in Sublime Text"
end run

-- Helper function to parse and execute keyboard shortcuts
on executeShortcut(shortcutString)
    -- Extract modifier keys and key from string like "cmd+shift+p"
    set modifierMap to {¬
        "cmd" to command down, ¬
        "command" to command down, ¬
        "ctrl" to control down, ¬
        "control" to control down, ¬
        "opt" to option down, ¬
        "option" to option down, ¬
        "alt" to option down, ¬
        "shift" to shift down ¬
    }
    
    -- Default, no modifiers
    set modifiers to {}
    set keyToPress to shortcutString
    
    -- If the shortcut contains "+" symbol, it has modifiers
    if shortcutString contains "+" then
        set shortcutParts to my splitString(shortcutString, "+")
        set keyToPress to last item of shortcutParts
        
        -- Remove the last item (the key) to get only modifiers
        set end of shortcutParts to ""
        set shortcutParts to items 1 thru ((count of shortcutParts) - 1) of shortcutParts
        
        -- Convert string modifiers to modifier keys
        repeat with modName in shortcutParts
            set trimmedModName to trimString(modName)
            if trimmedModName is not "" and trimmedModName is not " " then
                if modifierMap contains trimmedModName then
                    set end of modifiers to modifierMap's trimmedModName
                end if
            end if
        end repeat
    end if
    
    -- Execute the keystroke with modifiers
    tell application "System Events"
        keystroke keyToPress using modifiers
    end tell
end executeShortcut

-- Helper function to split a string by delimiter
on splitString(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theArray to every text item of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theArray
end splitString

-- Helper function to trim whitespace from string
on trimString(theString)
    set trimmed to ""
    if theString is not "" then
        repeat with charIndex from 1 to count of characters of theString
            set currentChar to character charIndex of theString
            if currentChar is not space and currentChar is not tab then
                set trimmed to characters charIndex thru -1 of theString as string
                exit repeat
            end if
        end repeat
        
        repeat with charIndex from (count characters of trimmed) to 1 by -1
            set currentChar to character charIndex of trimmed
            if currentChar is not space and currentChar is not tab then
                set trimmed to characters 1 thru charIndex of trimmed as string
                exit repeat
            end if
        end repeat
    end if
    return trimmed
end trimString
```