---
title: 'Terminal: Split Pane Management'
id: terminal_split_pane
category: 06_terminal
description: >-
  Creates and manages split panes in Terminal.app through UI automation of menu
  commands.
keywords:
  - Terminal.app
  - split
  - pane
  - vertical
  - horizontal
  - divide
  - window
  - UI automation
language: applescript
argumentsPrompt: >-
  Expects inputData with: { "action": "create", "close", or "navigate",
  "direction": "horizontal" or "vertical" (for create), "target": "next",
  "previous", "up", "down", "left", or "right" (for navigate) }
isComplex: true
---

This script manages split panes in Terminal.app, allowing you to create split layouts and navigate between panes. It works through UI automation since Terminal.app doesn't provide direct AppleScript access to its split pane functionality.

**Features:**
- Create horizontal or vertical split panes
- Close the current pane
- Navigate between panes (next, previous, or in a specific direction)
- Works with Terminal.app's built-in split pane system

**Important Notes:**
- Requires Accessibility permissions for UI scripting
- Terminal.app must be the frontmost application when running this script
- Uses menu commands to trigger Terminal's native split pane functionality

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultAction to "create"
    set defaultDirection to "horizontal"
    set defaultTarget to "next"
    
    -- Parse input parameters
    set action to defaultAction
    set direction to defaultDirection
    set target to defaultTarget
    
    if inputData is not missing value then
        if inputData contains {action:""} then
            set action to action of inputData
        end if
        if inputData contains {direction:""} then
            set direction to direction of inputData
        end if
        if inputData contains {target:""} then
            set target to target of inputData
        end if
    end if
    
    -- MCP placeholders for input
    set action to "--MCP_INPUT:action" -- create, close, or navigate
    set direction to "--MCP_INPUT:direction" -- horizontal or vertical (for create action)
    set target to "--MCP_INPUT:target" -- next, previous, up, down, left, or right (for navigate action)
    
    -- Normalize inputs to lowercase
    set action to my toLower(action)
    set direction to my toLower(direction)
    set target to my toLower(target)
    
    -- Validate inputs
    if action is not in {"create", "close", "navigate"} then
        return "Error: Invalid action. Use 'create', 'close', or 'navigate'."
    end if
    
    if action is "create" and direction is not in {"horizontal", "vertical"} then
        return "Error: For 'create' action, direction must be 'horizontal' or 'vertical'."
    end if
    
    if action is "navigate" and target is not in {"next", "previous", "up", "down", "left", "right"} then
        return "Error: For 'navigate' action, target must be 'next', 'previous', 'up', 'down', 'left', or 'right'."
    end if
    
    -- Ensure Terminal.app is active
    tell application "Terminal" to activate
    delay 0.5 -- Give Terminal time to become active
    
    -- Perform the requested action via UI automation
    if action is "create" then
        return createSplitPane(direction)
    else if action is "close" then
        return closeSplitPane()
    else if action is "navigate" then
        return navigateSplitPane(target)
    end if
end runWithInput

-- Helper function to create a split pane
on createSplitPane(direction)
    tell application "System Events"
        tell process "Terminal"
            set frontmost to true
            
            -- Use Window menu to create split pane
            tell menu bar 1
                tell menu bar item "Window"
                    tell menu "Window"
                        if direction is "horizontal" then
                            -- Select "Split Pane Horizontally"
                            -- This creates a side-by-side split (left and right panes)
                            click menu item "Split Pane Horizontally"
                            return "Created horizontal split pane (side by side)."
                        else
                            -- Select "Split Pane Vertically"
                            -- This creates a top-bottom split
                            click menu item "Split Pane Vertically"
                            return "Created vertical split pane (top and bottom)."
                        end if
                    end tell
                end tell
            end tell
        end tell
    end tell
end createSplitPane

-- Helper function to close the current split pane
on closeSplitPane()
    tell application "System Events"
        tell process "Terminal"
            set frontmost to true
            
            -- Use Window menu to close split pane
            tell menu bar 1
                tell menu bar item "Window"
                    tell menu "Window"
                        click menu item "Close Split Pane"
                        return "Closed current split pane."
                    end tell
                end tell
            end tell
        end tell
    end tell
end closeSplitPane

-- Helper function to navigate between split panes
on navigateSplitPane(target)
    tell application "System Events"
        tell process "Terminal"
            set frontmost to true
            
            -- Use Window menu to navigate between panes
            tell menu bar 1
                tell menu bar item "Window"
                    tell menu "Window"
                        if target is "next" then
                            click menu item "Select Next Pane"
                            return "Navigated to next pane."
                        else if target is "previous" then
                            click menu item "Select Previous Pane"
                            return "Navigated to previous pane."
                        else
                            -- Directional navigation
                            set menuItemName to "Move Focus to " & my capitalize(target)
                            try
                                click menu item menuItemName
                                return "Moved focus " & target & "."
                            on error
                                return "Error: Could not move focus " & target & ". Ensure there is a pane in that direction."
                            end try
                        end if
                    end tell
                end tell
            end tell
        end tell
    end tell
end navigateSplitPane

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

-- Helper function to capitalize first letter
on capitalize(theText)
    if length of theText is 0 then
        return ""
    end if
    
    set firstChar to character 1 of theText
    set restOfText to text 2 thru -1 of theText
    
    if ASCII number of firstChar ≥ 97 and ASCII number of firstChar ≤ 122 then
        -- Convert lowercase letter to uppercase
        set capitalizedChar to ASCII character ((ASCII number of firstChar) - 32)
    else
        set capitalizedChar to firstChar
    end if
    
    return capitalizedChar & restOfText
end capitalize
```

## Using Terminal.app Split Panes

Terminal.app provides split pane functionality that allows you to divide a single window into multiple terminal sessions, making it easier to manage multiple tasks simultaneously without the need for separate windows or tabs.

### Split Pane Functionality in Terminal.app

Terminal.app offers these split pane features:

1. **Horizontal Split**: Divides the window into left and right panes
2. **Vertical Split**: Divides the window into top and bottom panes
3. **Nested Splits**: You can further split existing panes to create complex layouts
4. **Navigation**: You can move between panes in various ways
5. **Resizing**: You can adjust the size of each pane

### Why This Script Uses UI Automation

Terminal.app does not expose its split pane functionality directly through AppleScript, unlike some other terminal emulators like iTerm2. This script uses UI automation (System Events) to simulate menu selections that trigger Terminal's built-in split pane commands.

### Accessibility Permissions

To use this script, you'll need to grant Accessibility permissions:

1. Open System Preferences/Settings > Security & Privacy/Privacy & Security > Accessibility
2. Add the application that will run this script (such as Script Editor or the MCP server)
3. Make sure the checkbox next to the application is selected

Without these permissions, the UI automation components of this script will fail.

### Creating Split Pane Layouts

You can create various layouts by combining horizontal and vertical splits:

1. **Simple Side-by-Side**: Create a single horizontal split
2. **Top-Bottom**: Create a single vertical split
3. **Grid Layout**: Create a horizontal split, then select each pane and create vertical splits
4. **Main + Sidebar**: Create a horizontal split with approximately 70/30 proportions

### Use Cases for Split Panes

Split panes are useful in many scenarios:

1. **Server Monitoring**: One pane shows logs while another allows command input
2. **Development**: Code in one pane, run tests in another
3. **File Operations**: View directory contents in one pane, edit files in another
4. **Database Work**: Run queries in one pane, view schema in another
5. **Documentation**: View reference material in one pane while working in another

### Keyboard Shortcuts

Terminal.app also supports keyboard shortcuts for split pane operations, which you can use as alternatives to this script:

- ⌘⇧D: Split pane horizontally
- ⌘⇧d: Split pane vertically
- ⌘⌥↑: Move focus up
- ⌘⌥↓: Move focus down
- ⌘⌥←: Move focus left
- ⌘⌥→: Move focus right
- ⌘⌥W: Close current pane

### Example Workflow: Development Environment

Here's an example of using this script to set up a development environment:

1. Create a new Terminal window
2. Create a horizontal split (2 panes side by side)
3. In the left pane, navigate to your code directory
4. Create a vertical split in the left pane (creating top and bottom panes)
5. In the top-left pane, start your development server
6. In the bottom-left pane, open your code editor or prepare for git commands
7. In the right pane, set up for testing or log viewing

This creates a three-pane layout optimized for development work, all within a single Terminal window.
