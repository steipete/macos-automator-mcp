---
id: ghostty_manage_titles
title: Manage Ghostty Window Titles
description: Sets or resets window titles for Ghostty terminal
language: applescript
author: Claude
keywords:
  - terminal
  - ghostty
  - window-title
  - customization
  - organization
usage_examples:
  - Set a descriptive title for a Ghostty window
  - Reset a Ghostty window title to its default value
  - Get the current title of a Ghostty window
parameters:
  - name: action
    description: 'Action to perform - set, get, or reset'
    required: true
  - name: title
    description: New title text (for 'set' action only)
    required: false
category: 06_terminal
---

# Manage Ghostty Window Titles

This script allows you to manage the window titles in Ghostty terminal, providing a way to set custom titles for better organization of your terminal environment.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set title to "--MCP_INPUT:title"
    
    -- Validate and set defaults for parameters
    if action is "" or action is missing value then
        return "Error: Please specify an action (set, get, or reset)"
    end if
    
    -- Convert action to lowercase for case-insensitive comparison
    set action to my toLowerCase(action)
    
    -- Validate the action
    if action is not in {"set", "get", "reset"} then
        return "Error: Invalid action. Use 'set', 'get', or 'reset'."
    end if
    
    -- Check if title is provided for 'set' action
    if action is "set" and (title is "" or title is missing value) then
        return "Error: Title must be provided when using the 'set' action."
    end if
    
    -- Check if Ghostty is installed and running
    try
        tell application "System Events"
            set ghosttyRunning to exists process "Ghostty"
        end tell
        
        if not ghosttyRunning then
            tell application "Ghostty" to activate
            delay 1 -- Give Ghostty time to start up
        end if
    on error
        return "Error: Ghostty terminal application is not installed or cannot be started."
    end try
    
    -- Perform the requested action
    if action is "get" then
        -- Get the current window title
        tell application "System Events"
            tell process "Ghostty"
                set currentTitle to name of front window
                return "Current Ghostty window title: " & currentTitle
            end tell
        end tell
        
    else if action is "set" then
        -- Set custom title using terminal escape sequence via keyboard input
        -- The escape sequence to set window title is: "\033]2;NEW_TITLE\007"
        set escapedTitle to (ASCII character 27) & "]2;" & title & (ASCII character 7)
        
        tell application "System Events"
            tell process "Ghostty"
                set frontmost to true
                delay 0.3 -- Give window time to activate
                
                -- Send the escape sequence to set the title
                -- This technique works via UI automation
                keystroke "t" using {command down} -- Open a new tab
                delay 0.3
                
                -- Execute echo command to set title
                keystroke "echo -ne \"\\033]2;" & title & "\\007\""
                keystroke return
                
                -- Close the temporary tab
                keystroke "w" using {command down}
                
                return "Window title set to: " & title
            end tell
        end tell
        
    else if action is "reset" then
        -- Reset title using terminal escape sequence
        -- Send an empty title which will reset to default behavior
        
        tell application "System Events"
            tell process "Ghostty"
                set frontmost to true
                delay 0.3 -- Give window time to activate
                
                -- Same technique as setting but with empty title
                keystroke "t" using {command down} -- Open a new tab
                delay 0.3
                
                -- Execute echo command to reset title
                keystroke "echo -ne \"\\033]2;\\007\""
                keystroke return
                
                -- Close the temporary tab
                keystroke "w" using {command down}
                
                return "Window title reset to default."
            end tell
        end tell
    end if
end run

-- Helper function to convert text to lowercase
on toLowerCase(theText)
    return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```

## Working with Ghostty Terminal Titles

Ghostty is a modern, GPU-accelerated terminal emulator that, like other terminals, supports window title customization. This script helps you manage these titles for better organization of your terminal environment.

### Understanding Terminal Title Behavior

Terminal titles in Ghostty follow these general principles:

1. **Default Titles**: By default, Ghostty displays dynamic titles that typically show:
   - Current shell or application name
   - Working directory
   - Running command information

2. **Custom Titles**: Setting a custom title:
   - Overrides the default dynamic behavior
   - Provides a static label regardless of the current command or directory
   - Helps identify the purpose of specific terminal windows

### Title Management Through ANSI Escape Sequences

This script uses ANSI escape sequences to control the window title. The primary sequences used are:

- **Set Window Title**: `\033]2;TITLE\007`
- **Reset Window Title**: `\033]2;\007` (empty title resets to default behavior)

These escape sequences are standard across most terminal emulators and are sent to the terminal through keyboard automation in this script.

### Alternative Implementation Methods

There are multiple ways to set terminal titles in Ghostty:

1. **UI Automation (used in this script)**:
   - Opens a temporary tab
   - Executes an echo command with the escape sequence
   - Closes the temporary tab
   - Works without requiring direct script execution in the terminal

2. **Direct Command Execution (alternative approach)**:
   ```applescript
   tell application "Ghostty"
       -- Assuming Ghostty has AppleScript support similar to iTerm2
       tell current session of current window
           write text "echo -ne \"\\033]2;" & title & "\\007\""
       end tell
   end tell
   ```

3. **Configuration File Approach**:
   - Ghostty's configuration file (typically `~/.config/ghostty/config`) can set default title formats
   - This is more permanent but requires file modification

### Use Cases for Title Management

#### Development and Server Administration

- Label windows according to their environment (Production, Staging, Development)
- Identify windows running specific services or applications
- Group related terminals with consistent naming schemes

#### Multi-Project Management

When working on multiple projects simultaneously:
- Set distinct titles for each project's terminal
- Include project name and function in the title
- Create visual separation between different contexts

#### Remote Session Identification

For SSH sessions to different servers:
- Include the hostname in the window title
- Add environment indicators (Prod/Stage/Dev)
- Include username for multi-user systems

### Integration with Terminal Multiplexers

When using terminal multiplexers like tmux or screen:

1. **Set tmux window titles**:
   ```bash
   # In your .tmux.conf
   set-option -g set-titles on
   set-option -g set-titles-string "#S:#I:#W - #T"
   ```

2. **Coordinate with Ghostty**:
   - Ghostty will respect tmux's title settings
   - This script can be used to set the outer window title

### Advanced Title Patterns

For more sophisticated needs, consider these title patterns:

```
[Environment] Project - Function
[Prod] Backend - API Server
[Dev] Frontend - Build Process
```

or

```
[Server: hostname] Service Status
[Server: db-01] MySQL Monitor
[Server: web-02] Nginx Logs
```

### Notes on Ghostty's AppleScript Support

Ghostty is a relatively new terminal emulator and its AppleScript support may evolve. This script uses UI automation via System Events rather than direct AppleScript commands, which provides compatibility regardless of Ghostty's native AppleScript implementation level.
