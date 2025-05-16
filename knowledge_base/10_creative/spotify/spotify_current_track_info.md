---
title: 'Spotify: Get Current Track Information'
category: 10_creative/spotify
id: spotify_current_track_info
description: Retrieves detailed information about the currently playing track in Spotify.
keywords:
  - Spotify
  - current track
  - track info
  - song details
  - artist
  - album
  - duration
  - music
language: applescript
notes: >
  - Spotify must be running.

  - If no track is playing, some properties might return empty or default
  values.

  - The script provides track name, artist, album, duration, artwork URL, and
  track URI.

  - Track URI can be used with Spotify's API or URI schemes for direct access.
---

Get details of the current track in Spotify.

```applescript
tell application "Spotify"
  if not running then
    return "Spotify is not running."
  end if
  
  try
    set playerState to player state as text
    
    if playerState is "stopped" then
      return "Spotify is currently stopped. No track is playing."
    end if
    
    -- Get basic track information
    set trackName to name of current track
    set trackArtist to artist of current track
    set trackAlbum to album of current track
    set trackDuration to duration of current track -- Duration in milliseconds
    
    -- Convert duration from milliseconds to a more readable format
    set durationInSeconds to trackDuration / 1000
    set durationMinutes to (durationInSeconds div 60) as text
    set durationSeconds to (durationInSeconds mod 60) as text
    if length of durationSeconds < 2 then
      set durationSeconds to "0" & durationSeconds
    end if
    set readableDuration to durationMinutes & ":" & durationSeconds
    
    -- Get additional information
    set trackNumber to track number of current track
    set discNumber to disc number of current track
    set spotifyUrl to spotify url of current track -- URI like "spotify:track:1234567890"
    set trackId to id of current track
    set trackPopularity to popularity of current track
    set trackArtworkUrl to artwork url of current track
    set isPlaying to playerState is "playing"
    set currentPosition to player position
    
    -- Convert position to readable format
    set positionMinutes to (currentPosition div 60) as text
    set positionSeconds to (currentPosition mod 60) as text
    if length of positionSeconds < 2 then
      set positionSeconds to "0" & positionSeconds
    end if
    set readablePosition to positionMinutes & ":" & positionSeconds
    
    -- Build and return detailed track information
    set trackInfo to "Now " & playerState & ":\n" & ¬
      "Track: " & trackName & ¬
      "\nArtist: " & trackArtist & ¬
      "\nAlbum: " & trackAlbum & ¬
      "\nDuration: " & readableDuration & " (" & durationInSeconds & "s)" & ¬
      "\nPosition: " & readablePosition & " (" & currentPosition & "s)" & ¬
      "\nTrack #: " & trackNumber & ¬
      "\nDisc #: " & discNumber & ¬
      "\nPopularity: " & trackPopularity & ¬
      "\nSpotify URI: " & spotifyUrl & ¬
      "\nArtwork URL: " & trackArtworkUrl
      
    return trackInfo
    
  on error errMsg number errNum
    return "Error retrieving track info (" & errNum & "): " & errMsg
  end try
end tell
```
