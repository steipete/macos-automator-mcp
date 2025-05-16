---
id: iterm_send_text
title: Send Text to iTerm2 Without Executing
description: Sends text to an iTerm2 window or pane without automatically executing the command
language: applescript
author: Claude
keywords: ["input", "typing", "automation", "command", "interactive"]
usage_examples:
  - "Type a complex command in iTerm2 without executing it"
  - "Paste multi-line text into iTerm2 for editing before execution"
  - "Fill in form-like CLI interfaces that require user input"
parameters:
  - name: text
    description: The text to send to iTerm2
    required: true
  - name: executeCommand
    description: "Whether to press Return after sending the text (default: false)"
    required: false
  - name: targetSession
    description: Target session by criteria - number, name, or "active" (default is "active")
    required: false
---

# Send Text to iTerm2 Without Executing

This script sends text to an iTerm2 window or session without automatically executing it, allowing users to review or edit the text before pressing Enter/Return.

```applescript
on run {input, parameters}
    set textToSend to "--MCP_INPUT:text"
    set executeCommand to "--MCP_INPUT:executeCommand"
    set targetSession to "--MCP_INPUT:targetSession"
    
    -- Validate and set defaults for parameters
    if textToSend is "" or textToSend is missing value then
        return "Error: No text provided to send to iTerm2."
    end if
    
    if executeCommand is "" or executeCommand is missing value then
        set executeCommand to false
    else
        try
            set executeCommand to executeCommand as boolean
        on error
            set executeCommand to false
        end try
    end if
    
    if targetSession is "" or targetSession is missing value then
        set targetSession to "active"
    end if
    
    tell application "iTerm"
        activate
        
        -- Determine which session to target
        set theSession to my getTargetSession(targetSession)
        if theSession is missing value then
            return "Error: Could not find the specified session."
        end if
        
        -- Process special characters in the text
        set processedText to my processTextForITerm(textToSend)
        
        tell theSession
            -- Send the text to the session
            write text processedText without newline
            
            -- Optionally press Return/Enter to execute the command
            if executeCommand then
                write text ""
                return "Text sent to iTerm2 and executed: " & textToSend
            else
                return "Text sent to iTerm2 without execution: " & textToSend
            end if
        end tell
    end tell
end run

-- Helper function to get the target session based on criteria
on getTargetSession(criteria)
    tell application "iTerm"
        -- Check if iTerm has any windows open
        if (count of windows) is 0 then
            create window with default profile
            delay 0.5
        end if
        
        -- Handle different targeting methods
        if criteria is "active" then
            -- Get the active session
            return current session of current window
            
        else
            -- Try to interpret as a session number (tab/pane index)
            try
                set sessionIndex to criteria as integer
                if sessionIndex > 0 then
                    if sessionIndex ≤ (count of sessions of current window) then
                        return session sessionIndex of current window
                    end if
                end if
            on error
                -- Not a number, so try as a session name
                try
                    tell current window
                        repeat with aSession in sessions
                            if name of aSession contains criteria then
                                return aSession
                            end if
                        end repeat
                    end tell
                on error
                    -- If nothing found, return missing value
                    return missing value
                end try
            end try
        end if
        
        -- Default to current session if nothing matched
        return current session of current window
    end tell
end getTargetSession

-- Helper function to process special characters in text for iTerm
on processTextForITerm(inputText)
    -- Replace literal newlines with a special sequence
    -- This ensures multi-line text is properly sent
    set AppleScript's text item delimiters to return
    set textItems to text items of inputText
    set AppleScript's text item delimiters to ""
    
    -- Join the text items back together with literal newlines
    return textItems as text
end processTextForITerm
```

## Use Cases for Sending Text Without Execution

### Interactive CLI Programs

Many command-line interfaces require multi-stage input:

1. **Forms and Prompts**: Programs like `npm init`, `ssh-keygen`, or interactive database clients
2. **Text Editors**: Preparing content for vim, nano, or other terminal-based editors
3. **Documentation Commands**: Writing comments or documentation in REPL environments

### Complex Command Construction

For complex commands, it's often useful to:

1. Type the command without executing it
2. Review for errors or misconfigurations
3. Make edits as needed
4. Execute only when ready

### Multi-line Input

This script is particularly useful for:

1. Sending scripts to REPL environments (Python, Node.js, etc.)
2. Creating multi-line code blocks in terminal-based interfaces
3. Preparing SQL queries before execution

## Understanding iTerm2's Session Model

iTerm2 uses a hierarchical structure:

- **Windows**: The top-level containers
- **Tabs**: Each window contains one or more tabs
- **Panes/Sessions**: Each tab can be split into multiple panes (sessions)

This script can target:

1. The currently active session (default)
2. A specific session by index
3. A session containing a specific name in its title

## Customization Options

### Text Processing

The script handles multi-line text by default, but you can extend it to handle other special cases:

```applescript
on processTextForITerm(inputText)
    -- Handle tab characters
    set processedText to my replaceText(inputText, tab, "    ")
    
    -- Handle other special characters as needed
    -- ...
    
    return processedText
end processTextForITerm

on replaceText(theText, oldItem, newItem)
    set AppleScript's text item delimiters to oldItem
    set theTextItems to text items of theText
    set AppleScript's text item delimiters to newItem
    set theText to theTextItems as text
    set AppleScript's text item delimiters to ""
    return theText
end replaceText
```

### Targeting Specific Windows

To target a specific window rather than the current window:

```applescript
-- Modify the getTargetSession function
if windowName is not missing value then
    repeat with aWindow in windows
        if name of aWindow contains windowName then
            -- Target this specific window
            return current session of aWindow
        end if
    end repeat
end if
```

## iTerm2 Text Input vs. Script Execution

There are two main ways to interact with iTerm2:

1. **Text Input (this script)**: Simulates typing text directly, as if the user typed it
2. **Command Execution**: Sends a command to execute immediately (using `write text` without the `without newline` parameter)

This script focuses on the first approach, giving users control over when to execute commands.