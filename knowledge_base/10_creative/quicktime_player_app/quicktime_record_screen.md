---
title: 'QuickTime Player: Record Screen'
category: 10_creative
id: quicktime_record_screen
description: Starts a screen recording using QuickTime Player.
keywords:
  - QuickTime Player
  - screen recording
  - capture screen
  - screencast
  - video capture
language: applescript
notes: >-
  Initiates a new screen recording. You'll need to manually select the recording
  area and stop the recording when finished.
---

```applescript
tell application "QuickTime Player"
  try
    activate
    
    -- Create a new screen recording
    tell application "System Events"
      tell process "QuickTime Player"
        -- Open the File menu
        click menu "File" of menu bar 1
        
        -- Click on "New Screen Recording" menu item
        click menu item "New Screen Recording" of menu "File" of menu bar 1
        
        -- Wait for the recording interface to appear
        delay 1
        
        return "Screen recording interface launched. Please select the area to record and click the record button."
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to start screen recording - " & errMsg
  end try
end tell
```
END_TIP
