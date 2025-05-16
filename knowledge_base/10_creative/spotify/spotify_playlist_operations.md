---
title: "Spotify: Playlist Operations"
category: "08_creative_and_document_apps"
id: spotify_playlist_operations
description: "Interact with Spotify playlists including listing available playlists, displaying contents, and playing a specific playlist."
keywords: ["Spotify", "playlist", "playlists", "music", "collection", "playback"]
language: applescript
notes: |
  - Spotify must be running.
  - This script demonstrates how to list playlists, play a specific playlist, and get playlist details.
  - Many playlist operations might require additional permissions or authentication for full API access.
  - The script focuses on basic operations available through AppleScript.
---

Work with Spotify playlists.

```applescript
tell application "Spotify"
  if not running then
    return "Spotify is not running."
  end if
  
  try
    -- Get list of playlists
    -- Note: AppleScript support in Spotify is limited for playlist manipulation
    -- This script demonstrates what's commonly possible without using the Web API
    
    -- Operation 1: List available playlists (limited)
    -- Note: This approach doesn't retrieve all playlists,
    -- only those accessible via basic AppleScript
    
    -- Method 1: Using a simple approach that works in some cases
    set playlistNames to {}
    -- Note: Spotify's AppleScript dictionary doesn't natively expose
    -- a comprehensive list of all playlists. The commands below may work
    -- to a limited extent but won't retrieve all playlists.
    
    -- For demonstration purposes only - this will only get system playlists
    -- It won't retrieve user's actual playlists without using the Web API
    try
      -- Attempt to get playlists (may only get limited system playlists or fail)
      set playlistNames to (get name of playlists)
    on error
      set playlistNames to {"⚠️ Complete playlist access requires Spotify Web API"}
    end try
    
    -- Operation 2: Play a specific playlist by URI
    -- If you know the Spotify URI of a playlist, you can play it:
    -- Format: spotify:playlist:37i9dQZF1DXcBWIGoYBM5M
    
    -- Comment/uncomment to test playing a playlist
    -- set playlistURI to "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M" -- Today's Top Hits
    -- play track playlistURI
    
    -- Operation 3: Play playlist by name (if it's in your library)
    -- Note: This is not reliable and depends on how Spotify exposes playlists
    -- set targetPlaylistName to "Your Playlist Name"
    -- set foundPlaylist to false
    
    -- try
    --   repeat with aPlaylist in playlists
    --     if name of aPlaylist is targetPlaylistName then
    --       play aPlaylist
    --       set foundPlaylist to true
    --       exit repeat
    --     end if
    --   end repeat
    --   
    --   if not foundPlaylist then
    --     set output to output & "\nCouldn't find playlist: " & targetPlaylistName
    --   end if
    -- on error
    --   set output to output & "\nError accessing playlists by name"
    -- end try
    
    -- Report current state and available playlists
    set currentStateText to "Current player state: " & (player state as text)
    
    -- If a track is playing, get its info
    if player state is playing or player state is paused then
      set currentStateText to currentStateText & ¬
        "\nCurrent track: " & name of current track & ¬
        "\nArtist: " & artist of current track
    end if
    
    -- Combine results
    set output to currentStateText & ¬
      "\n\nAvailable Playlist Operations:" & ¬
      "\n- Play playlist by URI (spotify:playlist:ID)" & ¬
      "\n- List available playlists" & ¬
      "\n\nNote: For full playlist access including creating and modifying playlists, " & ¬
      "use the Spotify Web API instead of AppleScript." & ¬
      "\n\nPlaylists detected (" & (count of playlistNames) & "):\n- " & ¬
      (playlistNames as text)
    
    return output
    
  on error errMsg number errNum
    return "Error with playlist operations (" & errNum & "): " & errMsg
  end try
end tell
```