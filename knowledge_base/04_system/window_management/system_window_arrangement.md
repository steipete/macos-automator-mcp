---
title: System Window Arrangement
category: 04_system
id: system_window_arrangement
description: 'Controls window positions, sizes, and arrangements for multiple applications'
keywords:
  - window
  - arrange
  - position
  - size
  - resize
  - System Events
  - workspace
  - layout
language: applescript
notes: >-
  Requires accessibility permissions for System Events. Works best with
  applications that follow standard window management APIs.
---

```applescript
-- Position a specific application's window at precise coordinates and size
on positionWindow(appName, x, y, width, height)
  tell application "System Events"
    tell process appName
      try
        set frontWindow to first window
        set position of frontWindow to {x, y}
        set size of frontWindow to {width, height}
      on error errMsg
        log "Error positioning window for " & appName & ": " & errMsg
      end try
    end tell
  end tell
end positionWindow

-- Example: Position Safari in top-left quadrant
positionWindow("Safari", 0, 0, 800, 600)

-- Center a window on the main screen
on centerWindow(appName)
  tell application "Finder"
    set screenWidth to word 3 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
    set screenHeight to word 4 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
  end tell
  
  tell application "System Events"
    tell process appName
      try
        set frontWindow to first window
        set windowWidth to item 3 of (get size of frontWindow)
        set windowHeight to item 4 of (get size of frontWindow)
        
        set newX to (screenWidth - windowWidth) / 2
        set newY to (screenHeight - windowHeight) / 2
        
        set position of frontWindow to {newX, newY}
      on error errMsg
        log "Error centering window for " & appName & ": " & errMsg
      end try
    end tell
  end tell
end centerWindow

-- Example: Center Terminal window
centerWindow("Terminal")

-- Arrange windows in a specific pattern (e.g., side by side)
on arrangeWindowsSideBySide(leftAppName, rightAppName)
  tell application "Finder"
    set screenWidth to word 3 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
    set screenHeight to word 4 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
  end tell
  
  -- First make sure both apps are running and visible
  tell application leftAppName to activate
  tell application rightAppName to activate
  
  -- Position left app
  positionWindow(leftAppName, 0, 0, screenWidth / 2, screenHeight)
  
  -- Position right app
  positionWindow(rightAppName, screenWidth / 2, 0, screenWidth / 2, screenHeight)
end arrangeWindowsSideBySide

-- Example: Arrange Safari and Notes side by side
arrangeWindowsSideBySide("Safari", "Notes")

-- Create a full workspace setup with multiple applications
on setupWorkspace()
  tell application "Finder"
    set screenWidth to word 3 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
    set screenHeight to word 4 of (do shell script "system_profiler SPDisplaysDataType | grep Resolution | awk '{print $2,$3,$4}'")
  end tell
  
  -- Launch applications
  tell application "Safari" to activate
  tell application "Mail" to activate
  tell application "Calendar" to activate
  tell application "Notes" to activate
  
  -- Arrange windows (example layout dividing screen into quadrants)
  -- Top left: Safari
  positionWindow("Safari", 0, 0, screenWidth / 2, screenHeight / 2)
  
  -- Top right: Mail
  positionWindow("Mail", screenWidth / 2, 0, screenWidth / 2, screenHeight / 2)
  
  -- Bottom left: Calendar
  positionWindow("Calendar", 0, screenHeight / 2, screenWidth / 2, screenHeight / 2)
  
  -- Bottom right: Notes
  positionWindow("Notes", screenWidth / 2, screenHeight / 2, screenWidth / 2, screenHeight / 2)
  
  -- Bring Safari to the front as the primary app
  tell application "Safari" to activate
end setupWorkspace

-- Example: Set up a complete workspace
setupWorkspace()
```

This script provides utilities for managing window arrangements:

1. Position individual windows at specific coordinates and sizes
2. Center windows on the main screen
3. Arrange two applications side by side (split screen)
4. Create a complete workspace setup with multiple applications

You can customize the `setupWorkspace` handler to create your preferred window arrangement, including:
- Different applications
- Different layouts (beyond the simple quadrants shown)
- Multiple displays
- Specific window sizes optimized for your workflow

Note: Some applications may have custom window management that doesn't fully respond to these commands. Results may vary by application.
