---
id: iterm_split_pane
title: iTerm2 Split Pane Management
description: 'Creates, navigates between, and manages split panes in iTerm2'
language: applescript
author: Claude
keywords:
  - terminal
  - panes
  - split-screen
  - workspace
  - multitasking
usage_examples:
  - Create a vertical or horizontal split pane in iTerm2
  - Navigate between panes in a complex layout
  - Close specific panes or organize multi-pane layouts
parameters:
  - name: action
    description: 'Action to perform - create, close, navigate, resize, or maximize'
    required: true
  - name: direction
    description: >-
      Direction for split or navigation - horizontal, vertical, left, right, up,
      down
    required: false
  - name: resizeAmount
    description: 'Amount to resize by (1-10, where 10 is maximum) when using resize action'
    required: false
category: 06_terminal
---

# iTerm2 Split Pane Management

This script provides comprehensive control over iTerm2's split pane functionality, allowing you to create complex terminal layouts and efficiently navigate between panes.

```applescript
on run {input, parameters}
    set action to "--MCP_INPUT:action"
    set direction to "--MCP_INPUT:direction"
    set resizeAmount to "--MCP_INPUT:resizeAmount"
    
    -- Validate and set defaults for parameters
    if action is "" or action is missing value then
        return "Error: Please specify an action (create, close, navigate, resize, or maximize)"
    end if
    
    -- Convert parameters to lowercase for case-insensitive comparison
    set action to my toLowerCase(action)
    
    -- Set defaults and validate direction if needed
    if direction is not "" and direction is not missing value then
        set direction to my toLowerCase(direction)
    else
        if action is "create" then
            set direction to "horizontal"
        else if action is "navigate" then
            set direction to "right"
        else if action is "resize" then
            set direction to "right"
        end if
    end if
    
    -- Set default resize amount if not provided
    if resizeAmount is "" or resizeAmount is missing value then
        if action is "resize" then
            set resizeAmount to 5
        end if
    else
        try
            set resizeAmount to resizeAmount as number
            if resizeAmount < 1 then set resizeAmount to 1
            if resizeAmount > 10 then set resizeAmount to 10
        on error
            set resizeAmount to 5
        end try
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
        activate
        
        if action is "create" then
            return createSplitPane(direction)
        else if action is "close" then
            return closeSplitPane()
        else if action is "navigate" then
            return navigatePanes(direction)
        else if action is "resize" then
            return resizePane(direction, resizeAmount)
        else if action is "maximize" then
            return maximizePane()
        else
            return "Error: Invalid action. Use 'create', 'close', 'navigate', 'resize', or 'maximize'."
        end if
    end tell
end run

-- Create a new split pane
on createSplitPane(direction)
    tell application "iTerm2"
        tell current window
            tell current session
                if direction is "vertical" then
                    -- Split vertically (top/bottom)
                    set newSession to split vertically with default profile
                    return "Created vertical split pane (top/bottom)"
                else
                    -- Split horizontally (left/right)
                    set newSession to split horizontally with default profile
                    return "Created horizontal split pane (left/right)"
                end if
            end tell
        end tell
    end tell
end createSplitPane

-- Close the current pane
on closeSplitPane()
    tell application "iTerm2"
        tell current window
            if (count of sessions) > 1 then
                tell current session
                    close
                    return "Closed current pane"
                end tell
            else
                return "Cannot close the last pane in the window"
            end if
        end tell
    end tell
end closeSplitPane

-- Navigate between panes
on navigatePanes(direction)
    tell application "iTerm2"
        tell current window
            -- Determine the keyboard shortcut based on direction
            if direction is "right" then
                tell application "System Events" to key code 124 using {option down, command down}
                return "Navigated to the right pane"
                
            else if direction is "left" then
                tell application "System Events" to key code 123 using {option down, command down}
                return "Navigated to the left pane"
                
            else if direction is "up" then
                tell application "System Events" to key code 126 using {option down, command down}
                return "Navigated to the upper pane"
                
            else if direction is "down" then
                tell application "System Events" to key code 125 using {option down, command down}
                return "Navigated to the lower pane"
                
            else if direction is "next" then
                tell application "System Events" to key code 48 using {shift down, command down}
                return "Navigated to the next pane"
                
            else if direction is "previous" then
                tell application "System Events" to key code 48 using {shift down, command down, option down}
                return "Navigated to the previous pane"
                
            else
                return "Error: Invalid navigation direction. Use 'right', 'left', 'up', 'down', 'next', or 'previous'."
            end if
        end tell
    end tell
end navigatePanes

-- Resize the current pane
on resizePane(direction, amount)
    -- Scale the amount to a reasonable number of keystrokes (1-3)
    set keyCount to round (amount / 3.5)
    if keyCount < 1 then set keyCount to 1
    if keyCount > 3 then set keyCount to 3
    
    tell application "iTerm2"
        activate
        
        if direction is "right" then
            repeat keyCount times
                tell application "System Events" to key code 124 using {control down, command down}
                delay 0.1
            end repeat
            return "Resized pane to the right"
            
        else if direction is "left" then
            repeat keyCount times
                tell application "System Events" to key code 123 using {control down, command down}
                delay 0.1
            end repeat
            return "Resized pane to the left"
            
        else if direction is "up" then
            repeat keyCount times
                tell application "System Events" to key code 126 using {control down, command down}
                delay 0.1
            end repeat
            return "Resized pane upward"
            
        else if direction is "down" then
            repeat keyCount times
                tell application "System Events" to key code 125 using {control down, command down}
                delay 0.1
            end repeat
            return "Resized pane downward"
            
        else
            return "Error: Invalid resize direction. Use 'right', 'left', 'up', or 'down'."
        end if
    end tell
end resizePane

-- Maximize (zoom) the current pane
on maximizePane()
    tell application "iTerm2"
        activate
        tell application "System Events" to key code 13 using {shift down, command down}
        return "Toggled maximize (zoom) for current pane"
    end tell
end maximizePane

-- Helper function to convert text to lowercase
on toLowerCase(theText)
    return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```

## iTerm2 Split Pane System

iTerm2 offers a powerful and flexible split pane system that allows you to divide your terminal window into multiple sessions, each capable of running different commands or tasks.

### Split Pane Concepts

In iTerm2, terminal windows can be divided into multiple panes:

1. **Window**: The top-level container
2. **Tab**: Each window can contain multiple tabs
3. **Pane**: Each tab can be split into multiple panes (sessions)

Panes can be split:
- **Horizontally**: Creates left and right panes
- **Vertically**: Creates top and bottom panes

Each pane is an independent terminal session that can run its own commands.

### Key Advantages of iTerm2 Split Panes

iTerm2's implementation offers several advantages:

1. **Native AppleScript Support**: Unlike Terminal.app, iTerm2 provides direct AppleScript access to its split pane functionality
2. **Profile Integration**: New panes can inherit or use different profiles (colors, fonts, etc.)
3. **Flexible Layouts**: Supports nested splits for complex arrangements
4. **Session Broadcasting**: Can broadcast input to multiple panes (not included in this script)
5. **Session Restoration**: Layouts can be saved and restored

### Using Split Panes Effectively

#### Development Environments

Create specialized layouts for development:

1. **Three-Panel Layout**:
   - Left pane: Code editor or file navigation
   - Top-right pane: Running server or application
   - Bottom-right pane: Testing, git commands, or logs

2. **Database Work**:
   - Left pane: SQL client
   - Right pane: Documentation or schema information

#### Server Management

For DevOps and server administration:

1. **Monitoring Setup**:
   - Top pane: System monitoring (top, htop)
   - Bottom-left: Log monitoring (tail -f)
   - Bottom-right: Command input

2. **Multi-Server Management**:
   - Create a pane for each server you're managing
   - Use different profiles with unique colors for each environment

### Keyboard Shortcuts

While this script provides programmatic control, it's useful to know iTerm2's built-in shortcuts:

- **⌘⇧D**: Split pane horizontally (left/right)
- **⌘D**: Split pane vertically (top/bottom)
- **⌘⌥←/→/↑/↓**: Navigate between panes
- **⌘⌃←/→/↑/↓**: Resize current pane
- **⌘⇧Enter**: Maximize/restore current pane
- **⌘W**: Close current pane

### Advanced Split Pane Techniques

#### Creating Complex Layouts

To create a grid layout:

```applescript
on createGridLayout()
    tell application "iTerm2"
        tell current window
            set original to current session
            
            -- Create first horizontal split
            tell original
                set rightPane to split horizontally with default profile
            end tell
            
            -- Split the left pane vertically
            tell original
                set bottomLeftPane to split vertically with default profile
            end tell
            
            -- Split the right pane vertically
            tell rightPane
                set bottomRightPane to split vertically with default profile
            end tell
            
            -- Now we have a 2x2 grid
            return "Created a 2x2 grid layout"
        end tell
    end tell
end createGridLayout
```

#### Profile-Based Splits

To create splits with different profiles:

```applescript
on createProfiledSplit()
    tell application "iTerm2"
        tell current window
            tell current session
                -- Use a different profile for the new pane
                split horizontally with profile "Production Server"
                return "Created split with Production Server profile"
            end tell
        end tell
    end tell
end createProfiledSplit
```

#### Session Broadcasting

To set up input broadcasting across panes:

```applescript
-- This requires UI automation since there's no direct AppleScript method
on enableBroadcasting()
    tell application "iTerm2" to activate
    tell application "System Events"
        keystroke "i" using {shift down, command down}
        return "Toggled input broadcasting"
    end tell
end enableBroadcasting
```

### Troubleshooting

If pane operations don't work as expected:

1. **Accessibility Permissions**: For keyboard shortcuts, ensure the script has proper permissions
2. **iTerm2 Focus**: Make sure iTerm2 is active when manipulating panes
3. **Profile Issues**: If splits fail, check that the specified profile exists 
4. **Version Compatibility**: Some features might vary between iTerm2 versions
