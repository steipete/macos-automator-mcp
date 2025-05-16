---
title: "VLC: Basic Playback Controls"
category: "08_creative_and_document_apps"
id: vlc_playback_controls
description: "Control basic playback in VLC Media Player including play, pause, stop, and volume."
keywords: ["VLC", "playback", "play", "pause", "stop", "volume", "media", "video", "audio"]
language: applescript
notes: |
  - These commands target the VLC Media Player application.
  - VLC must be running for these commands to work.
  - VLC's AppleScript support is somewhat limited and focuses mainly on controlling the currently playing item.
  - Some operations like playlist management are not well supported through AppleScript.
---

Control basic playback features of VLC Media Player.

```applescript
-- Control basic playback in VLC Media Player
tell application "VLC"
  if not running then
    return "VLC is not running. Please launch VLC first."
  end if
  
  try
    -- Get initial state to report at the end
    set isPlaying to my getPlayerState()
    set initialVolume to audio volume
    
    -- Uncomment the commands you want to use
    
    -- Play (starts playback or unpauses)
    -- play
    -- delay 0.5
    
    -- Pause
    -- pause
    -- delay 0.5
    
    -- Play/Pause toggle
    play
    delay 0.5
    
    -- Stop playback
    -- stop
    -- delay 0.5
    
    -- Set volume (0-200, where 100 is 100%)
    set audio volume to 75 -- Set to 75%
    delay 0.5
    
    -- Mute/Unmute
    -- set mute to true -- Mute
    -- delay 0.5
    -- set mute to false -- Unmute
    -- delay 0.5
    
    -- Get current volume
    set currentVolume to audio volume
    
    -- Time navigation
    -- These commands help with moving within the current media
    
    -- Step forward (small increment forward, in seconds)
    -- step forward 5
    -- delay 0.5
    
    -- Step backward (small increment backward, in seconds)
    -- step backward 5
    -- delay 0.5
    
    -- Jump to specific time (in seconds)
    -- set current time to 60 -- Jump to 1 minute mark
    -- delay 0.5
    
    -- Get current time position
    set currentTime to current time
    set totalTime to duration
    
    -- Format times for display
    set formattedCurrentTime to my formatTime(currentTime)
    set formattedTotalTime to my formatTime(totalTime)
    
    -- Check if anything is playing and get its name
    set mediaName to ""
    set isCurrentlyPlaying to my getPlayerState()
    
    if isCurrentlyPlaying then
      try
        set mediaName to name of current item
      on error
        set mediaName to "Unknown media"
      end try
    end if
    
    -- Return information about current status
    if isCurrentlyPlaying then
      return "VLC Status: Playing" & ¬
        "\nMedia: " & mediaName & ¬
        "\nPosition: " & formattedCurrentTime & " / " & formattedTotalTime & ¬
        "\nVolume: " & currentVolume & "%" & ¬
        "\n\n(Note: Most playback commands are commented out for testing purposes. Uncomment the commands you wish to use.)"
    else
      return "VLC Status: Not playing" & ¬
        "\nVolume: " & currentVolume & "%" & ¬
        "\n\n(Note: Most playback commands are commented out for testing purposes. Uncomment the commands you wish to use.)"
    end if
    
  on error errMsg number errNum
    return "Error controlling VLC playback (" & errNum & "): " & errMsg
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

-- Helper function to check if VLC is playing
on getPlayerState()
  tell application "VLC"
    try
      return playing
    on error
      return false
    end try
  end tell
end getPlayerState
```