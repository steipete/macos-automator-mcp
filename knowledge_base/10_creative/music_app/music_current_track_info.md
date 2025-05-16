---
title: "Music: Get Current Track Information"
category: "08_creative_and_document_apps"
id: music_current_track_info
description: "Retrieves detailed information about the currently playing or selected track in Music.app."
keywords: ["Music", "iTunes", "current track", "track info", "song details", "artist", "album", "duration", "rating", "Apple Music"]
language: applescript
notes: |
  - Music.app must be running.
  - If no track is playing or selected, an error may occur or properties might return `missing value`.
---

Get details of the current track in the Music app.

```applescript
tell application "Music" -- or "iTunes"
  if not running then
    return "Music app is not running."
  end if
  
  try
    set currentTr to current track
    if currentTr is missing value then
      return "No current track selected or playing."
    end if
    
    set trackName to name of currentTr
    set trackArtist to artist of currentTr
    set trackAlbum to album of currentTr
    set trackDuration to time of currentTr -- Duration in format MM:SS
    set trackTimeInSeconds to duration of currentTr -- Duration in seconds (real)
    set trackRating to rating of currentTr -- Scale of 0-100 (20 per star)
    set trackKind to kind of currentTr
    set trackYear to year of currentTr
    set trackPlayedCount to played count of currentTr
    set trackGenre to genre of currentTr
    
    set trackInfo to "Track: " & trackName & ¬
      "\nArtist: " & trackArtist & ¬
      "\nAlbum: " & trackAlbum & ¬
      "\nDuration: " & trackDuration & " (" & trackTimeInSeconds & "s)" & ¬
      "\nRating: " & (trackRating / 20) & " stars (" & trackRating & ")" & ¬
      "\nKind: " & trackKind & ¬
      "\nYear: " & trackYear & ¬
      "\nPlayed Count: " & trackPlayedCount & ¬
      "\nGenre: " & trackGenre
      
    return trackInfo
    
  on error errMsg number errNum
    return "Error retrieving track info (" & errNum & "): " & errMsg
  end try
end tell
```
END_TIP 