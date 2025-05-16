---
title: 'QuickTime Player: Open Video File'
category: 10_creative
id: quicktime_open_video
description: Opens a video file in QuickTime Player.
keywords:
  - QuickTime Player
  - open video
  - play video
  - media player
  - movie file
language: applescript
argumentsPrompt: Enter the path to the video file to open
notes: >-
  Opens a video file for playback. Supports common video formats like MP4, MOV,
  M4V, etc.
---

```applescript
on run {filePath}
  try
    if filePath is "" or filePath is missing value then
      set filePath to "--MCP_INPUT:filePath"
    end if
    
    -- Convert to POSIX file if it's not already
    if filePath does not start with "/" then
      return "Error: Please provide a valid absolute POSIX path starting with /"
    end if
    
    set videoFile to POSIX file filePath
    
    tell application "QuickTime Player"
      activate
      open videoFile
      
      -- Wait for the file to open
      delay 1
      
      -- Start playback
      play document 1
      
      -- Get video information if available
      set videoName to name of document 1
      set videoDuration to duration of document 1
      
      -- Format duration in minutes:seconds
      set minutes to videoDuration div 60
      set seconds to videoDuration mod 60
      set formattedDuration to minutes & ":" & text -2 thru -1 of ("0" & seconds)
      
      return "Opened video: " & videoName & "\\nDuration: " & formattedDuration
    end tell
    
  on error errMsg number errNum
    if errNum is -43 then
      return "Error: File not found at path: " & filePath
    else if errNum is -1728 then
      return "Error: The file format is not supported by QuickTime Player."
    else
      return "Error (" & errNum & "): Failed to open video - " & errMsg
    end if
  end try
end run
```
END_TIP
