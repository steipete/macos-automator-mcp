---
title: "Music: Basic Playback Controls"
category: "08_creative_and_document_apps"
id: music_playback_controls
description: "Control basic playback in Music.app (or iTunes) such as play, pause, stop, next, previous, and volume."
keywords: ["Music", "iTunes", "playback", "play", "pause", "stop", "next track", "previous track", "volume", "Apple Music"]
language: applescript
notes: |
  - These commands target the Music application (or iTunes on older macOS versions).
  - Ensure Music.app is running.
  - Volume is an integer from 0 (mute) to 100 (full).
---

Control basic playback features of the Music app.

```applescript
-- Ensure Music app is targeted
tell application "Music" -- or "iTunes" on older systems
  
  -- Play (starts current track or unpauses)
  -- play
  -- delay 1 -- Let it play for a moment
  
  -- Pause
  -- pause
  -- delay 1
  
  -- Play again to ensure something is playing for next/previous
  play
  delay 0.5
  
  set initialVolume to sound volume
  
  -- Set volume (0-100)
  set sound volume to 50 -- Set to half volume
  delay 0.5
  
  -- Next track
  -- next track
  -- delay 1
  
  -- Previous track
  -- previous track
  -- delay 1
  
  -- Stop playback
  -- stop
  
  -- Restore initial volume (optional)
  -- set sound volume to initialVolume
  
  -- Get current player state
  set playerStateInfo to "Player state: " & (player state as string)
  if player state is playing then
    try
      set currentTrackName to name of current track
      set playerStateInfo to playerStateInfo & "\nCurrent Track: " & currentTrackName
    on error
      set playerStateInfo to playerStateInfo & "\nCurrent Track: (Could not get track name)"
    end try
  end if
  
  -- For the return value, let's report the volume and state.
  return "Sound volume set to: " & (sound volume as string) & "\n" & playerStateInfo & "\n(Note: Play/Pause/Next/Previous commands are commented out for sequential execution in a single run. Uncomment to test each.)"
  
end tell
```
END_TIP 