---
title: "VOX: Get Current Track Information"
category: "08_creative_and_document_apps"
id: vox_current_track_info
description: "Retrieves detailed information about the currently playing track in VOX Music Player."
keywords: ["VOX", "current track", "track info", "song details", "artist", "album", "duration", "FLAC", "music"]
language: applescript
notes: |
  - VOX Music Player must be running.
  - If no track is playing or paused, the script will report this.
  - VOX can provide information like track title, artist, album, current position, and more.
  - VOX is often used for playing high-quality audio formats that iTunes/Music may not support natively.
---

Get details of the current track in VOX Music Player.

```applescript
tell application "VOX"
  if not running then
    return "VOX is not running. Please launch VOX first."
  end if
  
  try
    -- Get player state (1 = playing, 0 = paused, 2 = stopped)
    set currentState to player state
    
    -- Define state as text for display
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
    
    -- If no track is active (stopped state), return early
    if currentState is 2 then
      return "VOX is currently stopped. No track information available."
    end if
    
    -- Get basic track information
    set trackTitle to track
    set trackArtist to artist
    set trackAlbum to album
    
    -- Get additional information if available
    set trackInfo to "Now " & stateText & ":\n"
    
    -- Build the basic track info
    set trackInfo to trackInfo & "Track: " & trackTitle & "\n"
    set trackInfo to trackInfo & "Artist: " & trackArtist & "\n"
    set trackInfo to trackInfo & "Album: " & trackAlbum
    
    -- Try to get additional metadata
    try
      -- Get current playback position and duration
      set currentPosition to player position -- in seconds
      set trackDuration to track duration -- in seconds
      
      -- Format position and duration for display
      set positionMinutes to (currentPosition div 60) as integer
      set positionSeconds to (currentPosition mod 60) as integer
      if positionSeconds < 10 then
        set positionSecondsText to "0" & positionSeconds
      else
        set positionSecondsText to positionSeconds as text
      end if
      
      set durationMinutes to (trackDuration div 60) as integer
      set durationSeconds to (trackDuration mod 60) as integer
      if durationSeconds < 10 then
        set durationSecondsText to "0" & durationSeconds
      else
        set durationSecondsText to durationSeconds as text
      end if
      
      -- Calculate progress percentage
      set progressPercent to round ((currentPosition / trackDuration) * 100)
      
      -- Add timing information to the output
      set trackInfo to trackInfo & "\n\nPosition: " & positionMinutes & ":" & positionSecondsText
      set trackInfo to trackInfo & " / " & durationMinutes & ":" & durationSecondsText
      set trackInfo to trackInfo & " (" & progressPercent & "% complete)"
    on error
      set trackInfo to trackInfo & "\n\nPlayback timing information not available."
    end try
    
    -- Try to get additional metadata
    try
      -- Get file format information if available
      set trackBitrate to bitrate -- may not be available for all tracks
      set trackSampleRate to samplerate -- may not be available for all tracks
      
      -- Add format information if available
      set trackInfo to trackInfo & "\n\nTechnical Information:"
      
      if trackBitrate is not missing value then
        set trackInfo to trackInfo & "\nBitrate: " & trackBitrate & " kbps"
      end if
      
      if trackSampleRate is not missing value then
        set trackInfo to trackInfo & "\nSample Rate: " & trackSampleRate & " Hz"
      end if
    on error
      -- Format information may not be available for all tracks
    end try
    
    -- Get volume information
    set volumeLevel to player volume
    set trackInfo to trackInfo & "\n\nPlayer Volume: " & volumeLevel & "%"
    
    -- Return the complete track information
    return trackInfo
    
  on error errMsg number errNum
    return "Error retrieving track info (" & errNum & "): " & errMsg
  end try
end tell
```