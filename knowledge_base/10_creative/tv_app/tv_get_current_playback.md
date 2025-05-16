---
title: "TV: Get Current Playback Info"
category: "08_creative_and_document_apps"
id: tv_get_current_playback
description: "Retrieves information about the currently playing content in the TV app."
keywords: ["TV app", "current playback", "movie info", "show details", "playback status"]
language: applescript
notes: "Gets information about what's currently playing in the TV app, including title and playback controls."
---

```applescript
tell application "TV"
  try
    activate
    
    -- Give TV app time to launch (or come to foreground)
    delay 1
    
    -- Check if something is playing
    if player state is playing or player state is paused then
      set playerStatus to player state as string
      set currentPosition to player position
      
      -- Format time in minutes:seconds
      set minutes to currentPosition div 60
      set seconds to currentPosition mod 60
      set formattedPosition to minutes & ":" & text -2 thru -1 of ("0" & seconds)
      
      -- Try to get content information using UI scripting
      tell application "System Events"
        tell process "TV"
          set contentTitle to ""
          
          -- Try to get title from window title
          if exists window 1 then
            set windowTitle to name of window 1
            
            -- If window title contains " — TV", remove that part
            if windowTitle contains " — TV" then
              set contentTitle to text 1 thru ((offset of " — TV" in windowTitle) - 1) of windowTitle
            else
              set contentTitle to windowTitle
            end if
          end if
          
          -- Return playback information
          if contentTitle is not "" then
            return "Currently " & playerStatus & ": " & contentTitle & "\\nPosition: " & formattedPosition
          else
            return "Content is " & playerStatus & " at position " & formattedPosition & "\\n(Unable to determine content title)"
          end if
        end tell
      end tell
    else
      return "No content is currently playing in the TV app."
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get playback information - " & errMsg
  end try
end tell
```
END_TIP