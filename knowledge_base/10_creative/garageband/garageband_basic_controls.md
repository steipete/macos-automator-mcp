---
title: "GarageBand: Basic Controls"
category: "08_creative_and_document_apps"
id: garageband_basic_controls
description: "Control basic playback and transport functions in GarageBand including play, stop, record, and navigation."
keywords: ["GarageBand", "DAW", "playback", "transport", "record", "music production", "play", "stop"]
language: applescript
notes: |
  - GarageBand must be running for these commands to work.
  - GarageBand has limited AppleScript support, so this script uses UI automation via System Events.
  - This script requires Accessibility permissions to be granted for the script runner.
  - The script covers the most common transport controls: play, stop, record, and navigation.
  - Keyboard shortcuts are used for most operations as they are more reliable than UI element detection.
---

Control basic transport and playback functions in GarageBand.

```applescript
-- Basic controls for GarageBand
-- Note: GarageBand has very limited AppleScript support, so we use UI scripting via System Events

-- Check if GarageBand is running
tell application "System Events"
  set garageBandRunning to exists process "GarageBand"
end tell

if not garageBandRunning then
  return "Error: GarageBand is not running. Please launch GarageBand first."
end if

-- Get the frontmost application to restore focus later if needed
tell application "System Events"
  set frontApp to name of first process whose frontmost is true
end tell

-- Control GarageBand
tell application "GarageBand"
  -- Activate GarageBand
  activate
  delay 0.5 -- Give time for GarageBand to come to foreground
  
  -- Initialize result
  set resultText to ""
  
  -- Use UI scripting for control
  tell application "System Events"
    tell process "GarageBand"
      -- Check if GarageBand has a window open
      if (count of windows) is 0 then
        set resultText to "GarageBand is running but no project is open."
        
        -- Check if GarageBand has alert dialogs or modals open
        if (count of windows whose role is "AXSheet" or role is "AXDialog") > 0 then
          set resultText to resultText & " There appears to be a dialog box open that requires attention."
        end if
        
        return resultText
      end if
      
      -- Get the main window
      set mainWindow to window 1
      
      -- Control playback using keyboard shortcuts
      try
        -- Return to beginning (Home key or Command+Left Arrow)
        keystroke home
        delay 0.2
        
        -- Add to result
        set resultText to resultText & "Moved playhead to beginning. "
        
        -- Play (Space bar)
        keystroke space
        delay 1 -- Let it play briefly
        
        -- Add to result
        set resultText to resultText & "Started playback. "
        
        -- Pause/Stop (Space bar again)
        keystroke space
        delay 0.2
        
        -- Add to result
        set resultText to resultText & "Stopped playback. "
        
        -- Forward a bit (Right arrow)
        key code 124 -- Right arrow
        delay 0.1
        
        -- Add to result
        set resultText to resultText & "Moved playhead forward. "
        
        -- Backward a bit (Left arrow)
        key code 123 -- Left arrow
        delay 0.1
        
        -- Add to result
        set resultText to resultText & "Moved playhead backward. "
        
        -- Toggle Record Mode (R key or Command+R)
        keystroke "r"
        delay 0.2
        
        -- Add to result
        set resultText to resultText & "Toggled record mode. "
        
        -- Toggle it back off
        keystroke "r"
        delay 0.2
        
        -- Get project info if possible
        try
          -- This is challenging with GarageBand's limited scripting
          set projectInfo to ""
          
          -- Try to get title from window
          set windowTitle to title of mainWindow
          if windowTitle is not "" then
            set projectInfo to "Current project: " & windowTitle
          end if
          
          if projectInfo is not "" then
            set resultText to resultText & projectInfo
          end if
        on error
          -- Ignore errors in getting project info
        end try
        
      on error controlErr
        set resultText to resultText & "Error performing controls: " & controlErr
      end try
    end tell
  end tell
  
  -- Format the final result
  set finalResult to "GarageBand transport controls were triggered." & return
  set finalResult to finalResult & "Note: Due to GarageBand's limited AppleScript support, the exact state cannot be determined." & return
  set finalResult to finalResult & "The following operations were attempted: " & return & return & resultText
  
  -- Return the result
  return finalResult
end tell

-- Restore focus to original application if needed
if frontApp is not "GarageBand" then
  tell application frontApp to activate
end if
```