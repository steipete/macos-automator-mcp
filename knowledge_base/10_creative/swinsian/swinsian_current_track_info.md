---
title: "Swinsian: Get Current Track Information"
category: "08_creative_and_document_apps"
id: swinsian_current_track_info
description: "Retrieves detailed information about the currently playing track in Swinsian music player."
keywords: ["Swinsian", "current track", "track info", "song details", "artist", "album", "duration", "rating", "FLAC", "high-quality audio"]
language: applescript
notes: |
  - Swinsian must be running for this script to work.
  - This script retrieves comprehensive metadata about the current track.
  - Swinsian supports a wide range of audio formats and maintains detailed track metadata.
  - The script will report if no track is currently playing or if Swinsian is not running.
  - Information includes basic metadata plus file format, bitrate, and other technical details.
---

Get detailed information about the currently playing track in Swinsian.

```applescript
tell application "Swinsian"
  if not running then
    return "Swinsian is not running. Please launch it first."
  end if
  
  try
    -- Check if a track is playing or loaded
    if player state is stopped then
      return "No track is currently loaded in Swinsian."
    end if
    
    -- Get the current track
    set currentTrack to current track
    
    -- Build the result with all available information
    set trackInfo to "Swinsian Track Information:\n\n"
    
    -- Basic track information
    set trackInfo to trackInfo & "Title: " & name of currentTrack & "\n"
    set trackInfo to trackInfo & "Artist: " & artist of currentTrack & "\n"
    set trackInfo to trackInfo & "Album: " & album of currentTrack & "\n"
    
    -- Try to get additional metadata
    try
      set trackInfo to trackInfo & "Album Artist: " & album artist of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Composer: " & composer of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Genre: " & genre of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Year: " & year of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Track Number: " & track number of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Disc Number: " & disc number of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    -- Add a separator before technical information
    set trackInfo to trackInfo & "\nTechnical Information:\n"
    
    -- Get duration information
    try
      set durationSeconds to duration of currentTrack
      set durationMinutes to durationSeconds div 60
      set durationRemainingSeconds to durationSeconds mod 60
      if durationRemainingSeconds < 10 then
        set durationText to durationMinutes & ":0" & durationRemainingSeconds
      else
        set durationText to durationMinutes & ":" & durationRemainingSeconds
      end if
      set trackInfo to trackInfo & "Duration: " & durationText & " (" & durationSeconds & " seconds)\n"
    on error
      -- Skip if not available
    end try
    
    -- File information
    try
      set trackInfo to trackInfo & "File Format: " & kind of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Bit Rate: " & bit rate of currentTrack & " kbps\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Sample Rate: " & sample rate of currentTrack & " Hz\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Channels: " & channels of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    -- File path and size information
    try
      set trackInfo to trackInfo & "File Path: " & location of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "File Size: " & (size of currentTrack) & " bytes\n"
    on error
      -- Skip if not available
    end try
    
    -- Playback statistics
    set trackInfo to trackInfo & "\nPlayback Information:\n"
    
    try
      set trackInfo to trackInfo & "Play Count: " & played count of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Skip Count: " & skipped count of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Last Played: " & last played date of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Date Added: " & date added of currentTrack & "\n"
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Rating: " & rating of currentTrack & "/5\n"
    on error
      -- Skip if not available
    end try
    
    -- Playback status
    set trackInfo to trackInfo & "\nCurrent Status:\n"
    
    if player state is playing then
      set trackInfo to trackInfo & "Player State: Playing\n"
    else if player state is paused then
      set trackInfo to trackInfo & "Player State: Paused\n"
    else
      set trackInfo to trackInfo & "Player State: Stopped\n"
    end if
    
    try
      set trackInfo to trackInfo & "Volume: " & player volume & "%\n"
    on error
      -- Skip if not available
    end try
    
    try
      set positionSeconds to player position
      set positionMinutes to positionSeconds div 60
      set positionRemainingSeconds to positionSeconds mod 60
      if positionRemainingSeconds < 10 then
        set positionText to positionMinutes & ":0" & positionRemainingSeconds
      else
        set positionText to positionMinutes & ":" & positionRemainingSeconds
      end if
      set trackInfo to trackInfo & "Position: " & positionText & " (" & positionSeconds & " seconds)\n"
    on error
      -- Skip if not available
    end try
    
    -- Calculate progress percentage if both position and duration are available
    try
      set positionSeconds to player position
      set durationSeconds to duration of currentTrack
      set progressPercent to round ((positionSeconds / durationSeconds) * 100)
      set trackInfo to trackInfo & "Progress: " & progressPercent & "%\n"
    on error
      -- Skip if not available
    end try
    
    return trackInfo
    
  on error errMsg number errNum
    return "Error retrieving track info (" & errNum & "): " & errMsg
  end try
end tell
```