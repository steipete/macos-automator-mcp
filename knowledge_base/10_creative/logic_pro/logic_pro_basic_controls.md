---
title: 'Logic Pro: Basic Controls'
category: 10_creative/logic_pro
id: logic_pro_basic_controls
description: >-
  Control basic playback and transport functions in Logic Pro including play,
  stop, record, and navigation.
keywords:
  - Logic Pro
  - DAW
  - playback
  - transport
  - record
  - music production
  - play
  - stop
language: applescript
notes: >
  - Logic Pro must be running for these commands to work.

  - Logic Pro has limited AppleScript support compared to some other Apple
  applications.

  - This script uses a combination of direct AppleScript commands and UI
  automation through System Events.

  - Some commands may require Accessibility permissions to be granted for the
  script runner.

  - The script covers the most common transport controls: play, stop, record,
  and navigation.
---

Control basic transport and playback functions in Logic Pro.

```applescript
-- Basic controls for Logic Pro
-- Note: Logic Pro has limited AppleScript support, so we use a combination of approaches
-- Some operations require UI scripting via System Events

-- Check if Logic Pro is running
tell application "System Events"
  set logicRunning to exists process "Logic Pro"
end tell

if not logicRunning then
  return "Error: Logic Pro is not running. Please launch Logic Pro first."
end if

-- Initialize result
set resultText to ""

-- Get the frontmost application to restore focus later if needed
tell application "System Events"
  set frontApp to name of first process whose frontmost is true
end tell

-- Try to interact with Logic Pro using available AppleScript commands
tell application "Logic Pro"
  -- Activate Logic Pro
  activate
  delay 0.5 -- Give time for Logic Pro to come to foreground
  
  -- Basic controls using System Events (UI scripting)
  tell application "System Events"
    tell process "Logic Pro"
      -- Check if Logic Pro has a window open
      if (count of windows) is 0 then
        set resultText to "Logic Pro is running but no project is open."
        
        -- Check if Logic Pro has alert dialogs or modals open
        if (count of windows whose role is "AXSheet" or role is "AXDialog") > 0 then
          set resultText to resultText & " There appears to be a dialog box open that requires attention."
        end if
        
        return resultText
      end if
      
      -- Get the main window
      set mainWindow to window 1
      
      -- Check if we can access transport controls
      try
        -- Try to perform common transport operations
        -- Play/Stop
        keystroke space
        delay 0.2
        
        -- Add to result
        set resultText to resultText & "Sent play/stop command (spacebar). "
        
        -- Return to beginning
        -- This uses the 'Return to Zero' command (typical shortcut is comma ',')
        keystroke "," using {command down}
        delay 0.2
        
        set resultText to resultText & "Returned to beginning. "
        
        -- Forward a bit
        -- This uses right arrow to move forward
        key code 124 -- Right arrow
        delay 0.1
        
        set resultText to resultText & "Moved playhead forward. "
        
        -- Backward a bit
        -- This uses left arrow to move backward
        key code 123 -- Left arrow
        delay 0.1
        
        set resultText to resultText & "Moved playhead backward. "
        
        -- Toggle Record
        -- Typical shortcut for Record is Command+R
        keystroke "r" using {command down}
        delay 0.2
        keystroke "r" using {command down} -- Toggle it back off
        
        set resultText to resultText & "Toggled record mode on and off. "
        
        -- Try to get status from transport display
        try
          -- Look for transport display elements
          set transportInfo to ""
          
          -- Attempt to get info from transport bar
          -- Note: This is highly dependent on UI elements and may not work reliably
          try
            set transportGroups to groups of mainWindow whose description contains "Transport"
            if (count of transportGroups) > 0 then
              set transportGroup to item 1 of transportGroups
              set transportElements to UI elements of transportGroup
              repeat with elem in transportElements
                set elemDesc to description of elem
                if elemDesc contains "Position" or elemDesc contains "Time" then
                  set transportInfo to transportInfo & elemDesc & " "
                end if
              end repeat
            end if
          on error
            -- Transport element detection failed
          end try
          
          if transportInfo is not "" then
            set resultText to resultText & "Transport info: " & transportInfo
          end if
        on error
          -- Ignore errors in trying to get transport info
        end try
        
      on error
        set resultText to resultText & "Error performing transport operations. "
      end try
    end tell
  end tell
  
  -- Add overall status
  set resultText to "Logic Pro transport controls were triggered." & return
  set resultText to resultText & "Note: Due to Logic Pro's limited AppleScript support, the exact state cannot be determined." & return
  set resultText to resultText & "The following operations were attempted: " & return & return & resultText
  
  -- Return result
  return resultText
end tell

-- Restore focus to original application if needed
if frontApp is not "Logic Pro" then
  tell application frontApp to activate
end if
```
