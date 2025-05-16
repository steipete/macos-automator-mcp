---
title: 'Swinsian: Basic Playback Controls'
category: 10_creative/swinsian
id: swinsian_playback_controls
description: >-
  Control basic playback in Swinsian including play, pause, stop, next,
  previous, and volume adjustment.
keywords:
  - Swinsian
  - playback
  - play
  - pause
  - stop
  - next track
  - previous track
  - volume
  - music
  - FLAC
language: applescript
notes: >
  - Swinsian must be running for these commands to work.

  - Swinsian is an advanced music player for macOS that supports FLAC, MP3, and
  other formats.

  - The play/pause commands toggle playback state.

  - Swinsian has robust AppleScript support for controlling all aspects of
  playback.

  - Volume is set as a percentage from 0-100.
---

Control basic playback features of Swinsian music player.

```applescript
-- Basic playback controls for Swinsian
tell application "Swinsian"
  if not running then
    return "Swinsian is not running. Please launch it first."
  end if
  
  -- Get initial state to report at the end
  set isPlaying to player state is playing
  set initialVolume to player volume
  
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
  
  -- Stop playback completely
  -- stop
  -- delay 0.5
  
  -- Next track
  -- next track
  -- delay 0.5
  
  -- Previous track
  -- previous track
  -- delay 0.5
  
  -- Set volume (0-100)
  set player volume to 50 -- Set to half volume
  delay 0.5
  
  -- Mute by setting volume to 0
  -- set player volume to 0
  -- delay 0.5
  
  -- Get current player state and volume
  set isCurrentlyPlaying to player state is playing
  set currentVolume to player volume
  
  -- Get current track information if available
  set trackInfo to ""
  
  if isCurrentlyPlaying then
    try
      -- Get current track
      set currentTrack to current track
      
      -- Extract track info
      set trackName to name of currentTrack
      set trackArtist to artist of currentTrack
      set trackAlbum to album of currentTrack
      
      -- Build track info string
      set trackInfo to "Current Track: " & trackName & ¬
        "\nArtist: " & trackArtist & ¬
        "\nAlbum: " & trackAlbum
    on error
      set trackInfo to "Could not retrieve current track information."
    end try
  else
    set trackInfo to "No track is currently playing."
  end if
  
  -- Return status information
  set playStateText to "playing"
  if not isCurrentlyPlaying then
    set playStateText to "paused"
  end if
  
  set resultText to "Swinsian Status:" & ¬
    "\nPlayer State: " & playStateText & ¬
    "\nVolume: " & currentVolume & "%" & ¬
    "\n\n" & trackInfo & ¬
    "\n\nInitial State: " & (if isPlaying then "playing" else "paused") & ¬
    "\nInitial Volume: " & initialVolume & "%" & ¬
    "\n\n(Note: Most playback commands are commented out. Uncomment the commands you wish to use.)"
  
  return resultText
end tell
```
