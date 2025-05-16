---
id: window_management_rectangle
title: Manage windows with Rectangle
description: Controls window position and size using Rectangle app commands
language: applescript
author: Claude
usage_examples:
  - "Move active window to left half of screen"
  - "Maximize active window"
  - "Center active window"
parameters:
  - name: action
    description: "Window action to perform (left_half, right_half, top_half, bottom_half, maximize, center, restore, next_display, previous_display)"
    required: true
---

# Manage windows with Rectangle

This script controls window position and size using the Rectangle app by simulating its keyboard shortcuts. Rectangle is a free window management tool available at https://rectangleapp.com/.

```applescript
on run {input, parameters}
    set windowAction to "--MCP_INPUT:action"
    
    if windowAction is "" or windowAction is missing value then
        display dialog "Please specify a window action (left_half, right_half, top_half, bottom_half, maximize, center, restore, next_display, previous_display)." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Check if Rectangle is installed
    set isRectangleInstalled to false
    try
        do shell script "osascript -e 'exists application \"Rectangle\"'"
        set isRectangleInstalled to true
    on error
        display dialog "Rectangle app is required but not installed. Please install it from https://rectangleapp.com/" buttons {"OK"} default button "OK" with icon stop
        return
    end try
    
    -- Define keyboard shortcuts based on Rectangle's default configuration
    set shortcutModifiers to {control down, option down}
    set shortcutKey to ""
    
    if windowAction is "left_half" then
        set shortcutKey to "left"
    else if windowAction is "right_half" then
        set shortcutKey to "right"
    else if windowAction is "top_half" then
        set shortcutKey to "up"
    else if windowAction is "bottom_half" then
        set shortcutKey to "down"
    else if windowAction is "maximize" then
        set shortcutKey to "return" -- Option+Control+Enter
    else if windowAction is "center" then
        set shortcutKey to "c"
    else if windowAction is "restore" then
        set shortcutKey to "delete" -- Option+Control+Delete
    else if windowAction is "next_display" then
        set shortcutKey to "right"
        set shortcutModifiers to {control down, option down, command down}
    else if windowAction is "previous_display" then
        set shortcutKey to "left"
        set shortcutModifiers to {control down, option down, command down}
    else
        display dialog "Unsupported window action: " & windowAction buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Execute the shortcut
    tell application "System Events"
        -- Get the frontmost process
        set frontProcess to first process where it is frontmost
        set frontProcessName to name of frontProcess
        
        tell process frontProcessName
            -- Execute the shortcut
            if shortcutKey is "return" or shortcutKey is "delete" then
                key code (case shortcutKey of
                    "return": 36
                    "delete": 51
                end case) using shortcutModifiers
            else
                keystroke shortcutKey using shortcutModifiers
            end if
        end tell
    end tell
    
    return "Performed window action: " & windowAction
end run
```

## Default Rectangle Keyboard Shortcuts

This script uses Rectangle's default keyboard shortcuts:

- Left Half: ⌃⌥←
- Right Half: ⌃⌥→
- Top Half: ⌃⌥↑
- Bottom Half: ⌃⌥↓
- Maximize: ⌃⌥↩
- Center: ⌃⌥C
- Restore: ⌃⌥⌫
- Next Display: ⌃⌥⌘→
- Previous Display: ⌃⌥⌘←

Note: If you've customized Rectangle's shortcuts, you'll need to modify this script accordingly.