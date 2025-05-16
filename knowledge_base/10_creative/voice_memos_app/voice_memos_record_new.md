---
title: 'Voice Memos: Record New Memo'
category: 10_creative
id: voice_memos_record_new
description: Starts recording a new voice memo in the Voice Memos app.
keywords:
  - Voice Memos
  - record audio
  - voice recording
  - audio capture
  - sound recording
language: applescript
notes: >-
  Launches the Voice Memos app and starts a new recording. The script does not
  stop the recording automatically; you'll need to do that manually.
---

```applescript
tell application "Voice Memos"
  try
    activate
    
    -- Give Voice Memos time to launch
    delay 1
    
    tell application "System Events"
      tell process "Voice Memos"
        -- Click the Record button to start a new recording
        if exists button 1 of group 1 of window 1 then
          click button 1 of group 1 of window 1
          
          return "Started recording a new voice memo. Click the record button again in the Voice Memos app when you want to stop recording."
        else
          return "Unable to find the record button. The Voice Memos app interface may have changed."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to start voice recording - " & errMsg
  end try
end tell
```
END_TIP
