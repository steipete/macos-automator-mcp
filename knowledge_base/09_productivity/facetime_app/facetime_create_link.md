---
title: 'FaceTime: Create FaceTime Link'
category: 09_productivity
id: facetime_create_link
description: Creates a FaceTime link that can be shared with others.
keywords:
  - FaceTime
  - create link
  - FaceTime link
  - share FaceTime
  - video call link
language: applescript
notes: >-
  Creates a shareable FaceTime link and copies it to the clipboard. This feature
  is available in macOS Monterey (12) and later.
---

```applescript
tell application "FaceTime"
  try
    activate
    
    -- Give FaceTime time to launch
    delay 1
    
    tell application "System Events"
      tell process "FaceTime"
        -- Click on "Create Link" button
        if exists button "Create Link" of window 1 then
          click button "Create Link" of window 1
          delay 1
          
          -- If a popup menu appears, click "Copy Link"
          if exists menu 1 of window 1 then
            if exists menu item "Copy Link" of menu 1 of window 1 then
              click menu item "Copy Link" of menu 1 of window 1
              return "FaceTime link created and copied to clipboard."
            end if
          end if
          
          -- Alternative approach if the Copy Link menu item isn't found
          -- Try to click on any button that might say "Copy Link"
          if exists button "Copy Link" of window 1 then
            click button "Copy Link" of window 1
            return "FaceTime link created and copied to clipboard."
          end if
          
          return "FaceTime link created but couldn't copy to clipboard automatically. Please copy it manually."
        else
          -- Try alternative UI approach for newer versions
          if exists menu bar item "File" of menu bar 1 then
            click menu bar item "File" of menu bar 1
            delay 0.5
            
            if exists menu item "Create Link" of menu "File" of menu bar 1 then
              click menu item "Create Link" of menu "File" of menu bar 1
              delay 1
              
              -- Try to find and click "Copy Link" button
              if exists button "Copy Link" of sheet 1 of window 1 then
                click button "Copy Link" of sheet 1 of window 1
                return "FaceTime link created and copied to clipboard."
              end if
              
              return "FaceTime link created but couldn't copy to clipboard automatically. Please copy it manually."
            end if
          end if
          
          return "Couldn't find the Create Link option. This feature requires macOS Monterey (12) or later."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to create FaceTime link - " & errMsg
  end try
end tell
```
END_TIP
