---
title: 'Audirvana: Playback Controls'
category: 10_creative/audirvana
id: audirvana_playback_controls
description: >-
  Control basic playback in Audirvana including play, pause, next, previous, and
  volume adjustment.
keywords:
  - Audirvana
  - playback
  - play
  - pause
  - volume
  - high-quality audio
  - audiophile
  - FLAC
  - DSD
language: applescript
notes: >
  - Audirvana must be running for these commands to work.

  - Audirvana is an audiophile music player that focuses on high-quality audio
  playback.

  - Audirvana has limited but functional AppleScript support for basic playback
  control.

  - The script works with both Audirvana Origin and Audirvana Studio versions.

  - Control type can be set to "Master" (default) or "Slave" to determine how
  library playback is handled.
---

Control basic playback features of Audirvana music player.

```applescript
-- Basic playback controls for Audirvana
tell application "Audirvana"
  if not running then
    return "Audirvana is not running. Please launch Audirvana first."
  end if
  
  -- Get initial state to report at the end
  set initialVolume to 0
  set isPlaying to false
  
  try
    -- Try to get initial volume if available
    set initialVolume to output volume
  on error
    -- Volume might not be accessible
  end try
  
  try
    -- Try to determine if currently playing
    set currentPlayerState to player state as text
    if currentPlayerState is "playing" then
      set isPlaying to true
    end if
  on error
    -- Player state might not be accessible
  end try
  
  -- Optional: Set control type to determine how playback is handled
  -- Audirvana supports "Master" (default) or "Slave" control types
  -- set control type to "Master"
  
  -- Uncomment the commands you want to use
  
  -- Play/Pause toggle
  playpause
  delay 0.5
  
  -- Play (starts playback)
  -- play
  -- delay 0.5
  
  -- Pause playback
  -- pause
  -- delay 0.5
  
  -- Stop playback completely (if supported)
  -- try
  --   stop
  --   delay 0.5
  -- on error
  --   -- Stop command might not be supported in all versions
  -- end try
  
  -- Next track
  -- next track
  -- delay 0.5
  
  -- Previous track
  -- previous track
  -- delay 0.5
  
  -- Set volume (0-100)
  set output volume to 50 -- Set to half volume
  delay 0.5
  
  -- Mute by setting volume to 0
  -- set output volume to 0
  -- delay 0.5
  
  -- Get current state and information
  set resultText to "Audirvana Status:" & return & return
  
  -- Get player state
  try
    set currentPlayerState to player state as text
    set resultText to resultText & "Player State: " & currentPlayerState & return
  on error
    set resultText to resultText & "Player State: Unknown" & return
  end try
  
  -- Get volume
  try
    set currentVolume to output volume
    set resultText to resultText & "Volume: " & currentVolume & "%" & return
  on error
    set resultText to resultText & "Volume: Unknown" & return
  end try
  
  -- Get current track information if available
  try
    set trackInfo to ""
    
    -- Check if we can access track information
    set currentTrack to current track
    set trackTitle to title of currentTrack
    set trackArtist to artist of currentTrack
    set trackAlbum to album of currentTrack
    
    set trackInfo to "Current Track: " & trackTitle & return & "Artist: " & trackArtist & return & "Album: " & trackAlbum
    
    -- Try to get additional information
    try
      set trackFormat to format of currentTrack
      set trackInfo to trackInfo & return & "Format: " & trackFormat
    on error
      -- Format info not available
    end try
    
    -- Add track info to result
    set resultText to resultText & return & trackInfo
  on error
    set resultText to resultText & return & "No track information available."
  end try
  
  -- Add initial state info
  set resultText to resultText & return & return & "Initial State: " & (if isPlaying then "playing" else "not playing") & return & "Initial Volume: " & initialVolume & "%" & return
  
  -- Add note about commented commands
  set resultText to resultText & return & "(Note: Most playback commands are commented out. Uncomment the commands you wish to use.)"
  
  return resultText
end tell
```
