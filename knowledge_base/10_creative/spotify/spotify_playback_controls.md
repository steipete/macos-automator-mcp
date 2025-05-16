---
title: 'Spotify: Basic Playback Controls'
category: 10_creative/spotify
id: spotify_playback_controls
description: >-
  Control basic playback in Spotify such as play, pause, next, previous, and
  volume.
keywords:
  - Spotify
  - playback
  - play
  - pause
  - stop
  - next track
  - previous track
  - volume
  - music
language: applescript
notes: |
  - These commands target the Spotify application.
  - Ensure Spotify is running before executing commands.
  - Volume is a real number from 0.0 (mute) to 100.0 (full).
  - Some operations might not work if Spotify Free account restrictions apply.
---

Control basic playback features of the Spotify app.

```applescript
-- Basic playback controls for Spotify
tell application "Spotify"
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  -- Get initial state to report at the end
  set initialPlayerState to (player state as text)
  set initialVolume to sound volume
  
  -- Play (starts current track or unpauses)
  -- play
  -- delay 0.5
  
  -- Pause
  -- pause
  -- delay 0.5
  
  -- Play again to ensure something is playing for next/previous
  play
  delay 0.5
  
  -- Set volume (0-100)
  set sound volume to 50 -- Set to half volume
  delay 0.5
  
  -- Next track
  -- next track
  -- delay 1
  
  -- Previous track
  -- previous track
  -- delay 1
  
  -- Play/Pause toggle (alternative to separate play/pause)
  -- playpause
  -- delay 0.5
  
  -- Control playback position
  -- set player position to 60 -- Skip to 60 seconds into track
  -- delay 0.5
  
  -- Mute/Unmute by saving current volume and setting to 0
  -- set savedVolume to sound volume
  -- set sound volume to 0 -- Mute
  -- delay 0.5
  -- set sound volume to savedVolume -- Unmute
  
  -- Get current player state
  set playerStateInfo to "Player state: " & (player state as string)
  if player state is playing then
    try
      set currentTrackName to name of current track
      set currentArtist to artist of current track
      set playerStateInfo to playerStateInfo & ¬
        "\nCurrent Track: " & currentTrackName & ¬
        "\nArtist: " & currentArtist
    on error
      set playerStateInfo to playerStateInfo & "\nCurrent Track: (Could not get track info)"
    end try
  end if
  
  -- For the return value, let's report the volume and state
  return "Sound volume set to: " & (sound volume as string) & ¬
    "\n" & playerStateInfo & ¬
    "\n\nInitial state: " & initialPlayerState & ¬
    "\nInitial volume: " & initialVolume & ¬
    "\n\n(Note: Many commands are commented out for sequential execution in a single run. Uncomment specific commands to test individually.)"
  
end tell
```
