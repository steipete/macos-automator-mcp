---
title: "VOX: Basic Playback Controls"
category: "08_creative_and_document_apps"
id: vox_playback_controls
description: "Control basic playback in VOX Music Player including play, pause, next, previous, and volume."
keywords: ["VOX", "playback", "play", "pause", "stop", "next track", "previous track", "volume", "music", "FLAC"]
language: applescript
notes: |
  - These commands target the VOX Music Player application.
  - VOX must be running for these commands to work.
  - VOX is a high-quality music player that supports formats like FLAC, MP3, AAC, and more.
  - Player state values: 1 = playing, 0 = paused, 2 = stopped.
---

Control basic playback features of VOX Music Player.

```applescript
-- Control basic playback in VOX Music Player
tell application "VOX"
  if not running then
    return "VOX is not running. Please launch VOX first."
  end if
  
  -- Get initial state to report at the end
  set initialPlayerState to player state
  set initialVolume to player volume
  
  -- Player state values in VOX:
  -- 1 = playing
  -- 0 = paused
  -- 2 = stopped
  
  -- Uncomment the commands you want to use
  
  -- Play (starts playback or unpauses)
  -- play
  -- delay 0.5
  
  -- Pause
  -- pause
  -- delay 0.5
  
  -- Play/Pause toggle (alternative to separate play/pause)
  playpause
  delay 0.5
  
  -- Play a specific file by URL (by default plays from beginning)
  -- You can use file:// URLs for local files
  -- set fileURL to "file:///Users/username/Music/song.mp3"
  -- playURL fileURL
  -- delay 0.5
  
  -- Get and set Volume (0-100)
  set savedVolume to player volume
  set player volume to 50 -- Set to half volume
  delay 0.5
  
  -- Mute by setting volume to 0
  -- set player volume to 0
  -- delay 0.5
  
  -- Restore original volume
  -- set player volume to savedVolume
  -- delay 0.5
  
  -- Next track
  -- next track
  -- delay 0.5
  
  -- Previous track
  -- previous track
  -- delay 0.5
  
  -- Get current player state and format it as text
  set currentState to player state
  set stateText to ""
  if currentState is 1 then
    set stateText to "playing"
  else if currentState is 0 then
    set stateText to "paused"
  else if currentState is 2 then
    set stateText to "stopped"
  else
    set stateText to "unknown (" & currentState & ")"
  end if
  
  -- Get information about what's playing
  set playbackInfo to ""
  
  if currentState is 1 or currentState is 0 then
    try
      set trackArtist to artist
      set trackTitle to track
      set trackAlbum to album
      
      set playbackInfo to "Current Track: " & trackTitle & ¬
        "\nArtist: " & trackArtist & ¬
        "\nAlbum: " & trackAlbum
    on error
      set playbackInfo to "Could not retrieve current track information."
    end try
  else
    set playbackInfo to "No track is currently playing."
  end if
  
  -- Return information about current status
  return "VOX Music Player Status:" & ¬
    "\nPlayer State: " & stateText & ¬
    "\nVolume: " & (player volume as text) & "%" & ¬
    "\n\n" & playbackInfo & ¬
    "\n\n(Note: Most playback commands are commented out for testing purposes. Uncomment the commands you wish to use.)"
  
end tell
```