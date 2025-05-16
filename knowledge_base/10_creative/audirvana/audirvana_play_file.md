---
title: 'Audirvana: Play Audio File'
category: 10_creative
id: audirvana_play_file
description: >-
  Play high-resolution audio files in Audirvana, supporting formats like FLAC,
  DSD, and other audiophile formats.
keywords:
  - Audirvana
  - high-resolution audio
  - play file
  - FLAC
  - DSD
  - audiophile
  - bit-perfect
  - playback
language: applescript
parameters: >
  - file_path (required): Path to the audio file to play

  - control_mode (optional): Control mode to use - "Master" or "Slave" (default:
  "Master")
notes: >
  - Audirvana must be running for this script to work.

  - Audirvana specializes in high-resolution audio playback of formats like
  FLAC, DSD, and other audiophile formats.

  - The file_path parameter should be a full path to a supported audio file.

  - The control_mode parameter determines how Audirvana handles playback:
    - "Master" (default): Audirvana manages playback itself
    - "Slave": For integration with other applications
  - Supported file formats include FLAC, ALAC, WAV, AIFF, DSD, and more.
---

Play high-resolution audio files in Audirvana.

```applescript
-- Get parameters
set filePathParam to "--MCP_INPUT:file_path"
if filePathParam is "" or filePathParam is "--MCP_INPUT:file_path" then
  return "Error: No file path provided. Please specify the path to an audio file."
end if

set controlModeParam to "--MCP_INPUT:control_mode"
if controlModeParam is "" or controlModeParam is "--MCP_INPUT:control_mode" then
  set controlModeParam to "Master" -- Default control mode
end if

-- Validate control mode parameter
if controlModeParam is not "Master" and controlModeParam is not "Slave" then
  return "Error: control_mode must be either 'Master' or 'Slave'."
end if

-- Check if file exists
tell application "System Events"
  if not (exists POSIX file filePathParam) then
    return "Error: File not found at path: " & filePathParam
  end if
end tell

-- Check if it's a supported audio file (by extension)
set supportedExtensions to {".flac", ".wav", ".aiff", ".alac", ".mp3", ".aac", ".ogg", ".dsf", ".dff", ".dsd"}
set fileExtension to ""
set lastDotPos to offset of "." in filePathParam from -1 -- Search from end of string
if lastDotPos > 0 then
  set fileExtension to text (-(lastDotPos - 1)) thru -1 of filePathParam
  set fileExtension to do shell script "echo " & quoted form of fileExtension & " | tr '[:upper:]' '[:lower:]'"
end if

set isSupported to false
repeat with ext in supportedExtensions
  if fileExtension is ext then
    set isSupported to true
    exit repeat
  end if
end repeat

if not isSupported then
  return "Warning: File extension '" & fileExtension & "' may not be supported by Audirvana. Supported formats include: FLAC, WAV, AIFF, ALAC, MP3, AAC, OGG, DSF, DFF, DSD."
end if

tell application "Audirvana"
  if not running then
    return "Audirvana is not running. Please launch Audirvana first."
  end if
  
  try
    -- Set control mode
    set control type to controlModeParam
    
    -- Convert file path to URL if necessary
    set fileURL to filePathParam
    
    -- If not already a URL, convert it
    if fileURL does not start with "file://" then
      if fileURL starts with "/" then
        -- It's a POSIX path, convert to URL
        set fileURL to "file://" & fileURL
      else
        -- Assume it's a HFS path, convert to POSIX then to URL
        set fileURL to "file://" & POSIX path of (fileURL as text)
      end if
    end if
    
    -- Play the file
    set playing track type AudioFile URL fileURL
    
    -- Start playback
    play
    
    -- Wait for track to load and start playing
    delay 1
    
    -- Get information about what's playing
    set resultText to "Now playing in Audirvana:" & return & return
    
    try
      -- Get basic track info
      set currentTrack to current track
      set trackTitle to title of currentTrack
      set trackArtist to artist of currentTrack
      set trackAlbum to album of currentTrack
      
      set resultText to resultText & "Title: " & trackTitle & return
      set resultText to resultText & "Artist: " & trackArtist & return
      set resultText to resultText & "Album: " & trackAlbum & return
      
      -- Try to get audio format details
      try
        set resultText to resultText & return & "Audio Format Details:" & return
        
        try
          set resultText to resultText & "Format: " & format of currentTrack & return
        on error
          -- Format info not available
        end try
        
        try
          set resultText to resultText & "Bit Depth: " & bit depth of currentTrack & "-bit" & return
        on error
          -- Bit depth not available
        end try
        
        try
          set resultText to resultText & "Sample Rate: " & sample rate of currentTrack & " kHz" & return
        on error
          -- Sample rate not available
        end try
        
        try
          set resultText to resultText & "Channels: " & channel count of currentTrack & return
        on error
          -- Channel count not available
        end try
      on error
        -- Audio format details not available
      end try
      
    on error
      -- Basic track info not available, use file path instead
      set resultText to resultText & "File: " & filePathParam
    end try
    
    -- Add control mode information
    set resultText to resultText & return & return & "Control Mode: " & controlModeParam
    
    return resultText
    
  on error errMsg number errNum
    return "Error playing file (" & errNum & "): " & errMsg
  end try
end tell
```
