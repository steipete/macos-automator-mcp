---
title: 'FaceTime: Enable Live Captions'
category: 09_productivity/facetime_app
id: facetime_live_captions
description: >-
  Enables Live Captions for a FaceTime call to show real-time text
  transcription.
keywords:
  - FaceTime
  - live captions
  - transcription
  - accessibility
  - subtitles
language: applescript
notes: >-
  Enables the Live Captions feature for FaceTime calls. Available in macOS
  Ventura (13) and later.
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
          
          -- Check macOS version to ensure Live Captions is available
          set osVersion to do shell script "sw_vers -productVersion"
          set majorVersion to text 1 thru (offset of "." in osVersion) - 1 of osVersion
          
          if (majorVersion as number) < 13 then
            return "Live Captions requires macOS Ventura (13) or later."
          end if
          
          -- Enable Live Captions
          -- First try to access through Menu Bar
          click menu bar item "FaceTime" of menu bar 1
          delay 0.2
          
          if exists menu item "Live Captions" of menu "FaceTime" of menu bar 1 then
            -- Check if Live Captions is already enabled (has checkmark)
            set menuItem to menu item "Live Captions" of menu "FaceTime" of menu bar 1
            
            -- Get menu item properties to check if it's checked/enabled
            set isEnabled to false
            if exists attribute "AXMenuItemMarkChar" of menuItem then
              if value of attribute "AXMenuItemMarkChar" of menuItem is not missing value then
                set isEnabled to true
              end if
            end if
            
            if isEnabled then
              -- Already enabled, so just dismiss menu
              keystroke escape
              return "Live Captions is already enabled."
            else
              -- Enable Live Captions
              click menu item "Live Captions" of menu "FaceTime" of menu bar 1
              
              -- Wait a moment for captions to initialize
              delay 1
              
              return "Live Captions has been enabled. Captions will appear at the bottom of the call window."
            end if
          else
            -- If not found in main menu, try alternative methods
            -- Dismiss the menu first
            keystroke escape
            delay 0.2
            
            -- Try to find a button or control for Live Captions in the call UI
            -- Locations may vary by macOS version, so try several approaches
            
            -- First try direct button
            set captionsEnabled to false
            
            if exists button "Live Captions" of window 1 then
              click button "Live Captions" of window 1
              set captionsEnabled to true
            else
              -- Try settings or more menu
              if exists button "Settings" of window 1 then
                click button "Settings" of window 1
                delay 0.3
                
                -- Check if Live Captions appears in the settings menu
                if exists menu item "Live Captions" of menu 1 then
                  click menu item "Live Captions" of menu 1
                  set captionsEnabled to true
                else
                  -- Dismiss menu
                  keystroke escape
                end if
              end if
            end if
            
            if captionsEnabled then
              return "Live Captions has been enabled. Captions will appear at the bottom of the call window."
            else
              return "Could not find Live Captions option. The FaceTime interface may have changed, or Live Captions may not be available on this system."
            end if
          end if
        else
          return "No FaceTime window found. Please start a FaceTime call first."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to enable Live Captions - " & errMsg
  end try
end tell
```
END_TIP
