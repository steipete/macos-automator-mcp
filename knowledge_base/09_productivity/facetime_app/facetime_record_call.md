---
title: 'FaceTime: Record Call'
category: 09_productivity
id: facetime_record_call
description: Records a FaceTime call using the built-in recording feature.
keywords:
  - FaceTime
  - record call
  - video recording
  - call recording
  - screen recording
language: applescript
notes: >-
  Uses the SharePlay screen recording feature to record FaceTime calls.
  Available in macOS Monterey (12) and later.
---

```applescript
tell application "FaceTime"
  try
    activate
    
    -- Check if FaceTime is in an active call
    tell application "System Events"
      tell process "FaceTime"
        -- Look for indicators that we're in an active call
        if exists window 1 then
          -- Check if there's an active call UI
          set inActiveCall to false
          
          -- Look for buttons that appear in active call UI
          if exists button "Mute" of window 1 or exists button "Video" of window 1 or exists button "Effects" of window 1 then
            set inActiveCall to true
          end if
          
          if not inActiveCall then
            return "No active call detected. Please start a FaceTime call first."
          end if
          
          -- Start recording by clicking on SharePlay button and selecting Record
          -- The specific UI elements may vary based on macOS version
          
          -- Try to find and click the SharePlay button
          set sharableFound to false
          
          -- Look for SharePlay button in different locations based on macOS version
          if exists button 3 of group 1 of window 1 then 
            set possibleButton to button 3 of group 1 of window 1
            click possibleButton
            set sharableFound to true
          else if exists button "SharePlay" of window 1 then
            click button "SharePlay" of window 1
            set sharableFound to true
          else
            -- Try to find the button by scanning all buttons
            set allButtons to buttons of window 1
            repeat with currentButton in allButtons
              if exists description of currentButton then
                if description of currentButton contains "share" or description of currentButton contains "SharePlay" then
                  click currentButton
                  set sharableFound to true
                  exit repeat
                end if
              end if
            end repeat
          end if
          
          if not sharableFound then
            return "Could not find SharePlay button. The FaceTime interface may have changed."
          end if
          
          -- Wait for SharePlay menu to appear
          delay 0.5
          
          -- Click on Record option in menu
          if exists menu item "Record" of menu 1 of window 1 then
            click menu item "Record" of menu 1 of window 1
            
            -- Wait a moment for recording dialog to appear
            delay 0.5
            
            -- Click "Record" or "Continue" button to start recording
            if exists sheet 1 of window 1 then
              if exists button "Record" of sheet 1 of window 1 then
                click button "Record" of sheet 1 of window 1
              else if exists button "Continue" of sheet 1 of window 1 then
                click button "Continue" of sheet 1 of window 1
              end if
              
              -- Wait a moment for recording countdown
              delay 3
              
              return "FaceTime call recording started. To stop recording, click the Stop button in the menu bar."
            else
              return "Recording confirmation dialog did not appear."
            end if
          else
            return "Record option not found in SharePlay menu. The FaceTime interface may have changed."
          end if
        else
          return "No FaceTime window found. Please start a FaceTime call first."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to record FaceTime call - " & errMsg
  end try
end tell
```
END_TIP
