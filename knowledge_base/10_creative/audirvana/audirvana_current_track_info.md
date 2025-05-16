---
title: "Audirvana: Current Track Information"
category: "08_creative_and_document_apps"
id: audirvana_current_track_info
description: "Retrieve detailed information about the currently playing track in Audirvana, including high-resolution audio details."
keywords: ["Audirvana", "current track", "track info", "high-resolution audio", "audiophile", "bit depth", "sample rate", "FLAC", "DSD"]
language: applescript
notes: |
  - Audirvana must be running for this script to work.
  - Audirvana specializes in high-resolution audio playback and provides detailed technical information.
  - This script retrieves comprehensive metadata about the current track, including audio format details.
  - Information includes basic metadata plus bit depth, sample rate, and other technical characteristics.
  - The information available may vary between Audirvana versions and track types.
---

Get detailed information about the currently playing track in Audirvana.

```applescript
tell application "Audirvana"
  if not running then
    return "Audirvana is not running. Please launch Audirvana first."
  end if
  
  try
    -- Check if a track is playing or loaded
    set currentPlayerState to player state as text
    
    if currentPlayerState is "stopped" then
      return "No track is currently loaded in Audirvana."
    end if
    
    -- Get the current track
    set currentTrack to current track
    
    -- Build the result with all available information
    set trackInfo to "Audirvana Track Information:" & return & return
    
    -- Basic track information
    set trackInfo to trackInfo & "Title: " & title of currentTrack & return
    set trackInfo to trackInfo & "Artist: " & artist of currentTrack & return
    set trackInfo to trackInfo & "Album: " & album of currentTrack & return
    
    -- Try to get additional metadata
    try
      set trackInfo to trackInfo & "Album Artist: " & album artist of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Composer: " & composer of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Genre: " & genre of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Year: " & year of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Track Number: " & track number of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Disc Number: " & disc number of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    -- Add a separator before technical information
    set trackInfo to trackInfo & return & "Technical Information:" & return
    
    -- Get duration information
    try
      set trackDuration to duration of currentTrack
      set minutes to trackDuration div 60
      set seconds to trackDuration mod 60
      
      if seconds < 10 then
        set secondsStr to "0" & seconds
      else
        set secondsStr to seconds as text
      end if
      
      set trackInfo to trackInfo & "Duration: " & minutes & ":" & secondsStr & " (" & trackDuration & " seconds)" & return
    on error
      -- Skip if not available
    end try
    
    -- High-resolution audio specific information
    try
      set trackInfo to trackInfo & "Format: " & format of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Bit Depth: " & bit depth of currentTrack & "-bit" & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Sample Rate: " & sample rate of currentTrack & " kHz" & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Channels: " & channel count of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Bit Rate: " & bit rate of currentTrack & " kbps" & return
    on error
      -- Skip if not available
    end try
    
    -- Special formats like DSD may have additional properties
    try
      set trackInfo to trackInfo & "DSD Rate: " & dsd rate of currentTrack & return
    on error
      -- Skip if not DSD or property not available
    end try
    
    -- File information
    try
      set trackInfo to trackInfo & return & "File Information:" & return
      set trackInfo to trackInfo & "File Path: " & file URL of currentTrack & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "File Size: " & file size of currentTrack & " bytes" & return
    on error
      -- Skip if not available
    end try
    
    -- Playback information
    set trackInfo to trackInfo & return & "Playback Information:" & return
    set trackInfo to trackInfo & "Player State: " & currentPlayerState & return
    
    try
      set trackInfo to trackInfo & "Current Position: " & player position & " seconds" & return
      
      -- Calculate percentage through track
      set positionPercent to round ((player position / duration of currentTrack) * 100)
      set trackInfo to trackInfo & "Progress: " & positionPercent & "%" & return
    on error
      -- Skip if not available
    end try
    
    try
      set trackInfo to trackInfo & "Volume: " & output volume & "%" & return
    on error
      -- Skip if not available
    end try
    
    -- Output device information
    try
      set trackInfo to trackInfo & return & "Audio Output:" & return
      set trackInfo to trackInfo & "Output Device: " & output device & return
    on error
      -- Skip if not available
    end try
    
    -- Return the consolidated track information
    return trackInfo
    
  on error errMsg number errNum
    return "Error retrieving track info (" & errNum & "): " & errMsg
  end try
end tell
```