---
title: 'VOX: Play Audio File'
category: 10_creative/vox
id: vox_play_file
description: >-
  Play a local audio file in VOX Music Player, supporting high-quality formats
  like FLAC, MP3, AAC, and more.
keywords:
  - VOX
  - play file
  - audio
  - FLAC
  - MP3
  - high-quality
  - playback
  - audiophile
language: applescript
parameters: >
  - file_path (required): Path to the audio file to play

  - add_to_playlist (optional): Whether to add to playlist instead of replacing
  - "yes" or "no" (default: "no")
notes: >
  - VOX Music Player must be running or will be launched automatically.

  - File path must be a valid path to an audio file.

  - VOX supports many audio formats including FLAC, ALAC, AIFF, WAV, MP3, AAC,
  etc.

  - The script can either replace the current playlist or add the file to the
  existing playlist.

  - VOX is particularly useful for playing high-resolution audio files that
  Music.app may not support natively.
---

Play an audio file in VOX Music Player.

```applescript
-- Get parameters or use defaults
set filePathParam to "--MCP_INPUT:file_path"
if filePathParam is "" or filePathParam is "--MCP_INPUT:file_path" then
  return "Error: No file path provided. Please specify the path to an audio file."
end if

set addToPlaylistParam to "--MCP_INPUT:add_to_playlist"
if addToPlaylistParam is "" or addToPlaylistParam is "--MCP_INPUT:add_to_playlist" then
  set addToPlaylistParam to "no" -- Default: replace current playlist
end if

-- Validate add_to_playlist parameter
if addToPlaylistParam is not "yes" and addToPlaylistParam is not "no" then
  return "Error: add_to_playlist parameter must be either 'yes' or 'no'."
end if

-- Convert file path to file URL format
set fileURL to ""

-- Check if it's already a URL
if filePathParam starts with "file://" then
  set fileURL to filePathParam
else
  -- Handle both POSIX paths and HFS paths
  if filePathParam starts with "/" then
    -- It's a POSIX path, convert to URL
    set fileURL to "file://" & filePathParam
  else
    -- Assume it's an HFS path or incomplete path, try to convert
    try
      set fileObj to POSIX file filePathParam
      set fileURL to "file://" & POSIX path of fileObj
    on error
      -- If conversion fails, try to use as is
      set fileURL to "file://" & filePathParam
    end try
  end if
end if

-- Check if file exists
try
  set fileExists to false
  
  -- Extract POSIX path from URL for file existence check
  set posixPath to text 8 thru -1 of fileURL
  
  -- Use do shell script to check if file exists
  do shell script "[ -f " & quoted form of posixPath & " ] && echo 'yes' || echo 'no'"
  
  if result is "yes" then
    set fileExists to true
  end if
  
  if not fileExists then
    return "Error: File not found at path: " & filePathParam
  end if
on error errMsg
  return "Error checking file existence: " & errMsg & "\nPlease check that the path is correct and the file exists."
end try

tell application "VOX"
  -- Launch VOX if it's not running
  if not running then
    -- Activate without opening default playlist
    activate
    
    -- Short delay to let VOX launch
    delay 1
  end if
  
  try
    -- Get current state before playing
    set oldState to player state
    set oldTrack to ""
    set oldArtist to ""
    
    -- Try to get current track info if something is loaded
    if oldState is 0 or oldState is 1 then
      try
        set oldTrack to track
        set oldArtist to artist
      end try
    end if
    
    -- Play the file
    if addToPlaylistParam is "yes" then
      -- Add to playlist without interrupting current playback
      addURL fileURL
      
      -- Provide feedback but keep playing current track
      return "Added file to VOX playlist: " & filePathParam
    else
      -- Play the file immediately, replacing current playlist
      playURL fileURL
      
      -- Give time for track to load
      delay 0.5
      
      -- Get information about the track being played
      try
        set trackTitle to track
        set trackArtist to artist
        set trackAlbum to album
        
        -- Get playback state
        set currentState to player state
        set stateText to ""
        
        if currentState is 1 then
          set stateText to "playing"
        else if currentState is 0 then
          set stateText to "paused"
        else if currentState is 2 then
          set stateText to "stopped"
        else
          set stateText to "unknown"
        end if
        
        -- Format result message
        set resultMessage to "Now " & stateText & " in VOX:" & return
        set resultMessage to resultMessage & "Track: " & trackTitle & return
        set resultMessage to resultMessage & "Artist: " & trackArtist & return
        set resultMessage to resultMessage & "Album: " & trackAlbum
        
        return resultMessage
      on error
        -- Fallback if track information is not available
        return "Playing file in VOX: " & filePathParam
      end try
    end if
    
  on error errMsg number errNum
    return "Error playing file (" & errNum & "): " & errMsg
  end try
end tell
```
