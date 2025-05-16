---
title: System Volume Control
category: 04_system/volume_control
id: system_volume_control_manager
description: Controls system audio output volume with precise increments and mute toggling
keywords:
  - volume
  - audio
  - sound
  - mute
  - unmute
  - speakers
  - output volume
language: applescript
notes: >-
  Volume can be set from 0 to 100. Supports muting/unmuting and incremental
  changes.
---

```applescript
-- Get the current volume settings
set currentSettings to get volume settings

-- Set volume to specified percentage (0-100)
-- Example: 50% volume
set volume output volume 50

-- Mute the output
set volume with output muted

-- Unmute the output (keeping the previous volume level)
set volume without output muted

-- Increase volume by 10%
set currentVolume to output volume of currentSettings
if currentVolume <= 90 then
  set volume output volume (currentVolume + 10)
else
  set volume output volume 100
end if

-- Decrease volume by 10%
set currentVolume to output volume of currentSettings
if currentVolume >= 10 then
  set volume output volume (currentVolume - 10)
else
  set volume output volume 0
end if

-- Toggle mute state
set isMuted to output muted of currentSettings
if isMuted then
  set volume without output muted
else
  set volume with output muted
end if
```

The script demonstrates various ways to control system volume, including:
1. Setting absolute volume level (0-100)
2. Muting and unmuting audio output
3. Incrementally adjusting volume up or down
4. Toggling between muted and unmuted states

For a fade effect, you can create sequences with small adjustments and delays:

```applescript
-- Fade in from 0 to 50 over 2 seconds
set targetVolume to 50
set duration to 2 -- seconds
set steps to 10
set volumeStep to targetVolume / steps
set delayTime to duration / steps

repeat with i from 1 to steps
  set volume output volume (i * volumeStep)
  delay delayTime
end repeat

-- Fade out from current volume to 0 over 2 seconds
set currentVolume to output volume of (get volume settings)
set duration to 2 -- seconds
set steps to 10
set volumeStep to currentVolume / steps
set delayTime to duration / steps

repeat with i from 0 to steps - 1
  set volume output volume (currentVolume - (i * volumeStep))
  delay delayTime
end repeat
set volume output volume 0
```

The fade examples show how to create smooth transitions when changing volume levels.
