---
title: "Terminal: Manage Window and Tab Titles"
id: terminal_manage_titles
category: "04_terminal_emulators"
description: "Sets, gets, or resets custom titles for Terminal.app windows and tabs."
keywords: ["Terminal.app", "window", "tab", "title", "rename", "custom title", "reset"]
language: applescript
argumentsPrompt: "Expects inputData with: { \"action\": \"set\", \"getOrReset\", \"title\": \"New title text\", \"target\": \"window\" or \"tab\" } (target defaults to \"window\" if omitted)."
isComplex: false
---

This script allows you to manage the titles of Terminal.app windows and tabs, providing control over how your terminal sessions are labeled and identified.

**Features:**
- Set custom titles for Terminal.app windows or tabs
- Get the current title of a window or tab
- Reset titles to their default values (typically displaying current directory and command)
- Works with the frontmost window/tab by default

**Usage Examples:**
- Label terminal windows based on their purpose (e.g., "Backend Server", "Database", "Logs")
- Create consistent naming schemes for your terminal environment
- Restore default dynamic titles when custom titles are no longer needed

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultAction to "get"
    set defaultTitle to ""
    set defaultTarget to "window"
    
    -- Parse input parameters
    set action to defaultAction
    set newTitle to defaultTitle
    set target to defaultTarget
    
    if inputData is not missing value then
        if inputData contains {action:""} then
            set action to action of inputData
            --MCP_INPUT:action
        end if
        if inputData contains {title:""} then
            set newTitle to title of inputData
            --MCP_INPUT:title
        end if
        if inputData contains {target:""} then
            set target to target of inputData
            --MCP_INPUT:target
        end if
    end if
    
    -- Normalize action and target to lowercase
    set action to my toLower(action)
    set target to my toLower(target)
    
    -- Validate parameters
    if action is not in {"set", "get", "reset"} then
        return "Error: Invalid action. Use 'set', 'get', or 'reset'."
    end if
    
    if target is not in {"window", "tab"} then
        return "Error: Invalid target. Use 'window' or 'tab'."
    end if
    
    if action is "set" and newTitle is "" then
        return "Error: For 'set' action, a title must be provided."
    end if
    
    tell application "Terminal"
        if not (exists window 1) then
            return "Error: No Terminal windows are open."
        end if
        
        -- Get references to the frontmost window and its selected tab
        set frontWindow to window 1
        set currentTab to selected tab of frontWindow
        
        -- Perform the requested action
        if action is "set" then
            if target is "window" then
                -- Set custom title for the window
                set custom title of frontWindow to newTitle
                return "Window title set to: " & newTitle
            else
                -- Set custom title for the tab
                set custom title of currentTab to newTitle
                return "Tab title set to: " & newTitle
            end if
            
        else if action is "get" then
            if target is "window" then
                -- Get the window title (custom or default)
                set currentTitle to custom title of frontWindow
                if currentTitle is missing value then
                    set currentTitle to name of frontWindow
                    return "Current window title (default): " & currentTitle
                else
                    return "Current window title (custom): " & currentTitle
                end if
            else
                -- Get the tab title (custom or default)
                set currentTitle to custom title of currentTab
                if currentTitle is missing value then
                    set currentTitle to name of currentTab
                    return "Current tab title (default): " & currentTitle
                else
                    return "Current tab title (custom): " & currentTitle
                end if
            end if
            
        else if action is "reset" then
            if target is "window" then
                -- Reset window title to default
                set custom title of frontWindow to missing value
                return "Window title reset to default."
            else
                -- Reset tab title to default
                set custom title of currentTab to missing value
                return "Tab title reset to default."
            end if
        end if
    end tell
end runWithInput

-- Helper function to convert text to lowercase
on toLower(theText)
    set lowercaseText to ""
    repeat with i from 1 to length of theText
        set currentChar to character i of theText
        if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
            -- Convert uppercase letter to lowercase
            set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
        else
            -- Keep the character as is
            set lowercaseText to lowercaseText & currentChar
        end if
    end repeat
    return lowercaseText
end toLower
```

## Terminal Title Management

Terminal.app's title management system allows for both custom static titles and dynamic titles that update based on the current directory and running command.

### Understanding Title Types

1. **Default Titles**: By default, Terminal.app displays dynamic titles that show information such as:
   - Current username and hostname
   - Current working directory
   - Running command or process name
   - Terminal dimensions and shell information

2. **Custom Titles**: You can set a fixed custom title that:
   - Overrides the dynamic default title
   - Remains unchanged when changing directories or commands
   - Helps identify the purpose of a specific terminal session

### Use Cases for Title Management

#### 1. Context-Specific Labeling

- Label terminals based on their function (e.g., "API Server", "Database", "DevTools")
- Indicate environment (e.g., "Production", "Staging", "Development")
- Show project names for better organization

#### 2. Multi-Window Workflow Organization

When working with multiple terminal windows:
- Set clear titles to distinguish between different parts of your workflow
- Create a consistent naming scheme for improved productivity
- Make it easier to find the right terminal when using Exposé or Mission Control

#### 3. Documentation and Sharing

- Set descriptive titles before taking screenshots for documentation
- Make terminal recordings clearer with labeled windows
- Help team members understand your terminal setup

### Terminal vs. Tab Titles

This script allows you to control both window titles and tab titles independently:

- **Window Title**: The title that appears in the window's title bar and is visible when the window is active
- **Tab Title**: The label shown on the tab itself, useful when you have multiple tabs in one window

### Compatibility with Terminal Preferences

Terminal.app's preferences also allow you to configure title behavior:

1. In Terminal Preferences > Profiles > Window, you can set:
   - Default window title format
   - Default tab title format

2. The script's "reset" action will revert to these default formats

### Example Usage Patterns

1. **Project Setup**:
   ```json
   {
     "action": "set",
     "title": "Project: Frontend",
     "target": "window"
   }
   ```

2. **Get Current Title**:
   ```json
   {
     "action": "get",
     "target": "tab"
   }
   ```

3. **Reset to Default**:
   ```json
   {
     "action": "reset",
     "target": "window"
   }
   ```