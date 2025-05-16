---
title: 'VLC: Open Media File or URL'
category: 10_creative/vlc
id: vlc_open_media
description: Open a local media file or streaming URL in VLC Media Player.
keywords:
  - VLC
  - open file
  - play file
  - open URL
  - stream
  - video
  - audio
  - media player
language: applescript
parameters: >
  - media_path (required): Path to the local media file or streaming URL to open

  - start_time (optional): Position in seconds where playback should start
  (default: 0)

  - fullscreen (optional): Whether to start in fullscreen mode - "yes" or "no"
  (default: "no")
notes: >
  - VLC Media Player must be running or will be launched automatically.

  - This script works with local files, DVDs, network streams, and other media
  sources.

  - For local files, either full paths or file:// URLs can be used.

  - For streaming, use a valid URL (http://, rtsp://, etc.).

  - The script can optionally start playback at a specific time position and in
  fullscreen mode.
---

Open and play a media file or URL in VLC Media Player.

```applescript
-- Get parameters or use defaults
set mediaPathParam to "--MCP_INPUT:media_path"
if mediaPathParam is "" or mediaPathParam is "--MCP_INPUT:media_path" then
  return "Error: No media path or URL provided. Please specify a file path or streaming URL."
end if

set startTimeParam to "--MCP_INPUT:start_time"
if startTimeParam is "" or startTimeParam is "--MCP_INPUT:start_time" then
  set startTimeParam to "0" -- Default: start at beginning
end if

set fullscreenParam to "--MCP_INPUT:fullscreen"
if fullscreenParam is "" or fullscreenParam is "--MCP_INPUT:fullscreen" then
  set fullscreenParam to "no" -- Default: don't start in fullscreen
end if

-- Validate start_time parameter
try
  set startTimeNumber to startTimeParam as number
  if startTimeNumber < 0 then
    set startTimeNumber to 0
  end if
on error
  return "Error: start_time parameter must be a positive number."
end try

-- Validate fullscreen parameter
if fullscreenParam is not "yes" and fullscreenParam is not "no" then
  return "Error: fullscreen parameter must be either 'yes' or 'no'."
end if

-- Determine if we're dealing with a URL or local file
set isURL to false
if mediaPathParam starts with "http://" or mediaPathParam starts with "https://" or mediaPathParam starts with "rtsp://" or mediaPathParam starts with "rtmp://" or mediaPathParam starts with "mms://" or mediaPathParam starts with "ftp://" then
  set isURL to true
end if

-- Handle local file paths
if not isURL then
  -- If it's already a file:// URL, use it as is
  if mediaPathParam starts with "file://" then
    set mediaURL to mediaPathParam
  else
    -- Convert local path to a file URL
    if mediaPathParam starts with "/" then
      -- It's a POSIX path
      set mediaURL to "file://" & mediaPathParam
    else
      -- Try to interpret as HFS path or a partial path
      try
        set fileObj to POSIX file mediaPathParam
        set mediaURL to "file://" & POSIX path of fileObj
      on error
        -- If conversion fails, try to use as is
        set mediaURL to "file://" & mediaPathParam
      end try
    end if
    
    -- For local files, check if they exist (not applicable for URLs)
    try
      -- Extract POSIX path from URL for file existence check
      set posixPath to text 8 thru -1 of mediaURL
      
      -- Use do shell script to check if file exists
      do shell script "[ -f " & quoted form of posixPath & " ] && echo 'yes' || echo 'no'"
      
      if result is "no" then
        return "Error: File not found at path: " & mediaPathParam
      end if
    on error
      -- Skip file check if there's an error (might be a special path like a DVD)
    end try
  end if
else
  -- For URLs, just use as is
  set mediaURL to mediaPathParam
end if

tell application "VLC"
  -- Launch VLC if it's not running
  if not running then
    activate
    
    -- Short delay to let VLC launch
    delay 1
  end if
  
  try
    -- Open the media file or URL
    OpenURL mediaURL
    
    -- Start playback
    play
    
    -- If a start time was specified, jump to that position
    if startTimeNumber > 0 then
      -- Wait briefly for the media to load
      delay 0.5
      
      -- Set the position
      set current time to startTimeNumber
    end if
    
    -- Set fullscreen mode if requested
    if fullscreenParam is "yes" then
      -- Wait briefly before toggling fullscreen
      delay 0.5
      fullscreen
    end if
    
    -- Wait briefly for media to start playing
    delay 1
    
    -- Get information about what's playing
    set mediaInfo to ""
    
    -- Check if playback actually started
    if playing then
      -- Try to get media info
      try
        set mediaName to name of current item
        set mediaDuration to duration
        set mediaPosition to current time
        
        -- Format duration for display
        set formattedDuration to my formatTime(mediaDuration)
        
        -- Build info message
        set mediaInfo to "Now playing in VLC:" & return
        set mediaInfo to mediaInfo & "Media: " & mediaName & return
        set mediaInfo to mediaInfo & "Duration: " & formattedDuration
        
        -- Add start position info if applicable
        if startTimeNumber > 0 then
          set formattedStartTime to my formatTime(startTimeNumber)
          set mediaInfo to mediaInfo & return & "Starting at position: " & formattedStartTime
        end if
        
        -- Add fullscreen info if applicable
        if fullscreenParam is "yes" then
          set mediaInfo to mediaInfo & return & "Mode: Fullscreen"
        end if
      on error
        -- Basic fallback if media info is not available
        set mediaInfo to "Playing media in VLC: " & mediaPathParam
      end try
    else
      -- Playback didn't start
      set mediaInfo to "Media loaded in VLC but playback didn't start: " & mediaPathParam
    end if
    
    return mediaInfo
    
  on error errMsg number errNum
    return "Error opening media (" & errNum & "): " & errMsg
  end try
end tell

-- Helper function to format time in HH:MM:SS format
on formatTime(seconds)
  set hours to seconds div 3600
  set mins to (seconds mod 3600) div 60
  set secs to seconds mod 60
  
  if hours > 0 then
    set hoursText to hours as text
    if hours < 10 then set hoursText to "0" & hoursText
    
    set minsText to mins as text
    if mins < 10 then set minsText to "0" & minsText
    
    set secsText to round secs as text
    if secs < 10 then set secsText to "0" & secsText
    
    return hoursText & ":" & minsText & ":" & secsText
  else
    set minsText to mins as text
    if mins < 10 then set minsText to "0" & minsText
    
    set secsText to round secs as text
    if secs < 10 then set secsText to "0" & secsText
    
    return minsText & ":" & secsText
  end if
end formatTime
```
