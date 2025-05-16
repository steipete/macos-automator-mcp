---
title: 'VLC: Get Current Media Information'
category: 10_creative
id: vlc_current_media_info
description: >-
  Retrieves detailed information about the currently playing media in VLC Media
  Player.
keywords:
  - VLC
  - current media
  - media info
  - video
  - audio
  - duration
  - position
  - media player
language: applescript
notes: >
  - VLC Media Player must be running.

  - This script works for both audio and video files.

  - VLC's AppleScript support has some limitations, so not all media properties
  may be available.

  - Information retrieved includes name, time position, duration, and path.
---

Get details of the currently playing media in VLC Media Player.

```applescript
tell application "VLC"
  if not running then
    return "VLC is not running. Please launch VLC first."
  end if
  
  try
    -- Check if VLC is actually playing something
    set isPlaying to false
    try
      set isPlaying to playing
    on error
      set isPlaying to false
    end try
    
    if not isPlaying then
      return "VLC is not currently playing any media."
    end if
    
    -- Get basic media information
    set mediaInfo to "VLC Media Information:\n\n"
    
    -- Get media name if available
    try
      set mediaName to name of current item
      set mediaInfo to mediaInfo & "Name: " & mediaName & "\n"
    on error
      set mediaInfo to mediaInfo & "Name: Unknown\n"
    end try
    
    -- Get current time position and duration
    set currentTime to current time
    set totalDuration to duration
    
    -- Format time values for display
    set formattedPosition to my formatTime(currentTime)
    set formattedDuration to my formatTime(totalDuration)
    
    -- Calculate progress percentage
    set progressPercent to round ((currentTime / totalDuration) * 100)
    
    -- Add timing information
    set mediaInfo to mediaInfo & "Position: " & formattedPosition & " / " & formattedDuration & "\n"
    set mediaInfo to mediaInfo & "Progress: " & progressPercent & "%\n"
    
    -- Create a visual progress bar
    set progressBar to my createProgressBar(progressPercent)
    set mediaInfo to mediaInfo & progressBar & "\n\n"
    
    -- Try to get path information
    try
      set mediaPath to path of current item
      set mediaInfo to mediaInfo & "File Path: " & mediaPath & "\n"
    on error
      -- Path may not be available for streams or certain media types
    end try
    
    -- Get audio volume
    try
      set volumeLevel to audio volume
      set mediaInfo to mediaInfo & "Volume: " & volumeLevel & "%\n"
    on error
      -- Volume info unavailable
    end try
    
    -- Get playback state
    set playStateText to "Playing"
    if not playing then
      set playStateText to "Paused"
    end if
    set mediaInfo to mediaInfo & "State: " & playStateText & "\n"
    
    -- Get playback rate
    try
      set playRate to rate
      set mediaInfo to mediaInfo & "Playback Speed: " & playRate & "x\n"
    on error
      -- Rate info unavailable
    end try
    
    -- Get video information if available
    try
      set videoWidth to video width of current item
      set videoHeight to video height of current item
      
      if videoWidth > 0 and videoHeight > 0 then
        set mediaInfo to mediaInfo & "\nVideo Resolution: " & videoWidth & " x " & videoHeight & "\n"
      end if
    on error
      -- This might be an audio file or video info is unavailable
    end try
    
    -- Get audio track information if available
    try
      set audioTracksCount to count of audio tracks
      set mediaInfo to mediaInfo & "Audio Tracks: " & audioTracksCount & "\n"
    on error
      -- Audio track info unavailable
    end try
    
    -- Get subtitle information if available
    try
      set subtitleTracksCount to count of subtitle tracks
      set mediaInfo to mediaInfo & "Subtitle Tracks: " & subtitleTracksCount & "\n"
    on error
      -- Subtitle info unavailable
    end try
    
    return mediaInfo
    
  on error errMsg number errNum
    return "Error retrieving media info (" & errNum & "): " & errMsg
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

-- Helper function to create a visual progress bar
on createProgressBar(percentComplete)
  set barLength to 30 -- Characters in the progress bar
  set completedSegments to round ((percentComplete / 100) * barLength)
  
  if completedSegments > barLength then
    set completedSegments to barLength
  end if
  
  set remainingSegments to barLength - completedSegments
  
  set progressBar to "[" & text 1 thru completedSegments of "==============================" & text 1 thru remainingSegments of "                              " & "]"
  return progressBar
end createProgressBar
```
