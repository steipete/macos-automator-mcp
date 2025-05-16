---
id: iterm_manage_titles
title: Manage iTerm2 Window and Tab Titles
description: 'Sets, gets, or resets custom titles for iTerm2 windows, tabs, and sessions'
language: applescript
author: Claude
keywords:
  - titles
  - labeling
  - organization
  - windows
  - tabs
usage_examples:
  - Set descriptive titles for iTerm2 windows
  - Label tabs based on their purpose
  - Create a consistent naming scheme across multiple terminal sessions
parameters:
  - name: action
    description: 'Action to perform - set, get, or reset'
    required: true
  - name: title
    description: New title text (for 'set' action only)
    required: false
  - name: target
    description: 'Where to apply the title - window, tab, or session'
    required: false
category: 06_terminal/iterm
---

# Manage iTerm2 Window and Tab Titles

This script provides comprehensive control over the titles of iTerm2 windows, tabs, and sessions, allowing you to create a more organized terminal environment.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set title to "--MCP_INPUT:title"
    set target to "--MCP_INPUT:target"
    
    -- Validate and set defaults for parameters
    if action is "" or action is missing value then
        return "Error: Please specify an action (set, get, or reset)"
    end if
    
    -- Convert action to lowercase for case-insensitive comparison
    set action to my toLowerCase(action)
    
    -- Set a default target if not provided
    if target is "" or target is missing value then
        set target to "tab"
    end if
    
    -- Convert target to lowercase for case-insensitive comparison
    set target to my toLowerCase(target)
    
    -- Validate the target
    if target is not in {"window", "tab", "session"} then
        return "Error: Invalid target. Use 'window', 'tab', or 'session'."
    end if
    
    -- Check if title is provided for 'set' action
    if action is "set" and (title is "" or title is missing value) then
        return "Error: Title must be provided when using the 'set' action."
    end if
    
    -- Check if iTerm2 is running
    tell application "System Events"
        if not (exists process "iTerm2") then
            tell application "iTerm2" to activate
            delay 1 -- Give iTerm2 time to launch
        end if
    end tell
    
    -- Perform the requested action
    tell application "iTerm2"
        if (count of windows) is 0 then
            create window with default profile
            delay 0.5
        end if
        
        set currentWindow to current window
        
        if action is "set" then
            -- Set custom title based on target
            if target is "window" then
                set name of currentWindow to title
                return "Window title set to: " & title
                
            else if target is "tab" then
                tell current session of currentWindow
                    set name to title
                end tell
                return "Tab title set to: " & title
                
            else if target is "session" then
                tell current session of current tab of currentWindow
                    set name to title
                end tell
                return "Session title set to: " & title
            end if
            
        else if action is "get" then
            -- Get current title based on target
            if target is "window" then
                set currentTitle to name of currentWindow
                return "Current window title: " & currentTitle
                
            else if target is "tab" then
                tell current tab of currentWindow
                    set currentTitle to name
                end tell
                return "Current tab title: " & currentTitle
                
            else if target is "session" then
                tell current session of current tab of currentWindow
                    set currentTitle to name
                end tell
                return "Current session title: " & currentTitle
            end if
            
        else if action is "reset" then
            -- Reset title based on target (send special escape sequences)
            if target is "window" then
                -- Reset window title using escape sequence
                tell current session of currentWindow
                    write text (ASCII character 27) & "]2;" & (ASCII character 7) without newline
                end tell
                return "Window title reset to default."
                
            else if target is "tab" then
                -- Reset tab title using escape sequence
                tell current session of currentWindow
                    write text (ASCII character 27) & "]1;" & (ASCII character 7) without newline
                end tell
                return "Tab title reset to default."
                
            else if target is "session" then
                -- Reset session title (which will revert to showing current command/path)
                tell current session of current tab of currentWindow
                    -- Just set to empty which causes iTerm2 to revert to dynamic title
                    set name to ""
                end tell
                return "Session title reset to default."
            end if
            
        else
            return "Error: Invalid action. Use 'set', 'get', or 'reset'."
        end if
    end tell
end run

-- Helper function to convert text to lowercase
on toLowerCase(theText)
    return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```

## Understanding iTerm2's Title Hierarchy

iTerm2 has a three-level hierarchy for titles:

1. **Window Title**: The title displayed in the macOS window title bar
2. **Tab Title**: The title shown on individual tabs when multiple tabs are open
3. **Session Title**: The title for a specific session/pane within a tab

Each level can be independently controlled, allowing for detailed organization of your terminal workspace.

## Title Types in iTerm2

### Dynamic Titles (Default)

By default, iTerm2 displays dynamic titles that usually show:
- Current username and hostname
- Working directory
- Running command
- Shell information

These titles update automatically as you change directories or run different commands.

### Static/Custom Titles

Setting a custom title through this script creates a static title that:
- Remains fixed regardless of the current directory or command
- Provides consistent labeling for identification purposes
- Can be more descriptive of the terminal's purpose

## Use Cases for iTerm2 Title Management

### Development Workflows

For complex development projects:
- Label windows by project name
- Label tabs by component (backend, frontend, database)
- Label sessions by specific function (logs, builds, tests)

### Server Management

When managing multiple servers:
- Label windows by environment (production, staging, development)
- Label tabs by server role (web, database, cache)
- Include hostnames in titles for quick identification

### Task Organization

For different ongoing tasks:
- Group related terminals under descriptive window titles
- Use color coding (through profiles) alongside titles
- Create a consistent naming convention for better workflow

## Advanced Title Management

### Terminal Escape Sequences

iTerm2 supports ANSI escape sequences for title management directly from the terminal:

- **Window Title**: `echo -ne "\033]0;TITLE\007"`
- **Tab Title**: `echo -ne "\033]1;TITLE\007"`
- **Both Window and Tab**: `echo -ne "\033]2;TITLE\007"`

The reset function in this script uses these escape sequences to revert to default behavior.

### Profile-Based Title Settings

For more permanent title configurations, iTerm2 profiles can be configured to:
- Set default title formats
- Control automatic title updates
- Specify custom title components

Access these settings in iTerm2 > Preferences > Profiles > Terminal > Terminal Title.

## Integrating with Workflow Automation

This script can be integrated with other workflow automation tools:

### Example: Project Workspace Setup

```applescript
-- Example of setting up a complete project workspace
on setupProjectWorkspace(projectName, projectPath)
    tell application "iTerm2"
        create window with default profile
        
        -- Set window title to project name
        set name of current window to projectName
        
        -- Create and label tabs for different components
        tell current window
            -- First tab is already created
            tell current session of current tab
                set name to "Server"
                write text "cd " & quoted form of projectPath
            end tell
            
            -- Create tab for database
            set dbTab to (create tab with default profile)
            tell current session of dbTab
                set name to "Database"
                write text "cd " & quoted form of projectPath & "/database"
            end tell
            
            -- Create tab for frontend
            set frontendTab to (create tab with default profile)
            tell current session of frontendTab
                set name to "Frontend"
                write text "cd " & quoted form of projectPath & "/frontend"
            end tell
        end tell
    end tell
end setupProjectWorkspace
```
