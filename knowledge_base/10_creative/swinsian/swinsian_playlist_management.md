---
title: 'Swinsian: Playlist Management'
category: 10_creative/swinsian
id: swinsian_playlist_management
description: >-
  Manage playlists in Swinsian including listing, creating, modifying, and
  playing playlists.
keywords:
  - Swinsian
  - playlist
  - music
  - collection
  - management
  - FLAC
  - high-quality audio
language: applescript
parameters: >
  - action (required): Action to perform - "list", "create", "add_to", "play",
  "get_tracks"

  - playlist_name (optional): Name of the playlist to create, modify, or play
  (required for some actions)

  - track_location (optional): File path of a track to add to playlist (for
  add_to action)
notes: >
  - Swinsian must be running for these commands to work.

  - The "list" action shows all available playlists.

  - The "create" action creates a new playlist with the specified name.

  - The "add_to" action adds a track (by file path) to the specified playlist.

  - The "play" action plays the specified playlist.

  - The "get_tracks" action lists all tracks in the specified playlist.

  - Swinsian has comprehensive playlist management capabilities through
  AppleScript.
---

Manage playlists in Swinsian music player.

```applescript
-- Get action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "list" -- Default action: list playlists
end if

-- Get playlist name parameter
set playlistNameParam to "--MCP_INPUT:playlist_name"
if playlistNameParam is "" or playlistNameParam is "--MCP_INPUT:playlist_name" then
  set playlistNameParam to "" -- Will be validated later if needed
end if

-- Get track location parameter
set trackLocationParam to "--MCP_INPUT:track_location"
if trackLocationParam is "" or trackLocationParam is "--MCP_INPUT:track_location" then
  set trackLocationParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"list", "create", "add_to", "play", "get_tracks"}
set isValidAction to false
repeat with validAction in validActions
  if actionParam is validAction then
    set isValidAction to true
    exit repeat
  end if
end repeat

if not isValidAction then
  return "Error: Invalid action. Valid options are: " & validActions
end if

-- Validate required parameters for specific actions
if (actionParam is "create" or actionParam is "add_to" or actionParam is "play" or actionParam is "get_tracks") and playlistNameParam is "" then
  return "Error: The '" & actionParam & "' action requires a playlist_name parameter."
end if

if actionParam is "add_to" and trackLocationParam is "" then
  return "Error: The 'add_to' action requires a track_location parameter."
end if

tell application "Swinsian"
  if not running then
    return "Swinsian is not running. Please launch it first."
  end if
  
  -- Execute the requested action
  if actionParam is "list" then
    -- List all playlists
    try
      set playlistsList to playlists
      
      if (count of playlistsList) is 0 then
        return "No playlists found in Swinsian."
      end if
      
      set resultText to "Swinsian Playlists:" & return & return
      
      repeat with aPlaylist in playlistsList
        set playlistName to name of aPlaylist
        
        -- Try to get track count for each playlist
        try
          set trackCount to count of tracks of aPlaylist
          set resultText to resultText & "- " & playlistName & " (" & trackCount & " tracks)" & return
        on error
          set resultText to resultText & "- " & playlistName & return
        end try
      end repeat
      
      return resultText
      
    on error errMsg number errNum
      return "Error listing playlists (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "create" then
    -- Create a new playlist
    try
      -- Check if playlist already exists
      set playlistExists to false
      
      repeat with aPlaylist in playlists
        if name of aPlaylist is playlistNameParam then
          set playlistExists to true
          exit repeat
        end if
      end repeat
      
      if playlistExists then
        return "Playlist '" & playlistNameParam & "' already exists."
      end if
      
      -- Create the playlist
      make new playlist with properties {name:playlistNameParam}
      
      return "Successfully created new playlist: '" & playlistNameParam & "'"
      
    on error errMsg number errNum
      return "Error creating playlist (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "add_to" then
    -- Add a track to a playlist
    try
      -- Find the playlist
      set targetPlaylist to missing value
      
      repeat with aPlaylist in playlists
        if name of aPlaylist is playlistNameParam then
          set targetPlaylist to aPlaylist
          exit repeat
        end if
      end repeat
      
      if targetPlaylist is missing value then
        return "Error: Playlist '" & playlistNameParam & "' not found."
      end if
      
      -- Find or add the track
      set trackFound to false
      set trackAdded to false
      
      -- First, check if the track exists in the library
      try
        set allTracks to tracks
        
        repeat with aTrack in allTracks
          try
            if location of aTrack is trackLocationParam then
              -- Track exists, add it to playlist
              duplicate aTrack to targetPlaylist
              set trackFound to true
              set trackAdded to true
              exit repeat
            end if
          on error
            -- Skip if we can't get location
          end try
        end repeat
      on error
        -- Error accessing all tracks, try a different approach
      end try
      
      -- If track not found in library, try to add it
      if not trackFound then
        try
          -- Check if file exists
          tell application "System Events"
            if not (exists POSIX file trackLocationParam) then
              return "Error: File not found at " & trackLocationParam
            end if
          end tell
          
          -- Add track to library and then to playlist
          set newTrack to add trackLocationParam
          duplicate newTrack to targetPlaylist
          set trackAdded to true
        on error addErr
          return "Error adding track to library: " & addErr
        end try
      end if
      
      if trackAdded then
        return "Successfully added track to playlist '" & playlistNameParam & "'."
      else
        return "Failed to add track to playlist. The track may already be in the playlist."
      end if
      
    on error errMsg number errNum
      return "Error adding track to playlist (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "play" then
    -- Play a playlist
    try
      -- Find the playlist
      set targetPlaylist to missing value
      
      repeat with aPlaylist in playlists
        if name of aPlaylist is playlistNameParam then
          set targetPlaylist to aPlaylist
          exit repeat
        end if
      end repeat
      
      if targetPlaylist is missing value then
        return "Error: Playlist '" & playlistNameParam & "' not found."
      end if
      
      -- Play the playlist
      play targetPlaylist
      
      return "Now playing playlist: '" & playlistNameParam & "'"
      
    on error errMsg number errNum
      return "Error playing playlist (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "get_tracks" then
    -- List tracks in a playlist
    try
      -- Find the playlist
      set targetPlaylist to missing value
      
      repeat with aPlaylist in playlists
        if name of aPlaylist is playlistNameParam then
          set targetPlaylist to aPlaylist
          exit repeat
        end if
      end repeat
      
      if targetPlaylist is missing value then
        return "Error: Playlist '" & playlistNameParam & "' not found."
      end if
      
      -- Get the tracks
      set playlistTracks to tracks of targetPlaylist
      
      if (count of playlistTracks) is 0 then
        return "Playlist '" & playlistNameParam & "' is empty."
      end if
      
      set resultText to "Tracks in playlist '" & playlistNameParam & "':" & return & return
      
      set trackCounter to 1
      repeat with aTrack in playlistTracks
        set trackName to name of aTrack
        set trackArtist to artist of aTrack
        set trackAlbum to album of aTrack
        
        set resultText to resultText & trackCounter & ". " & trackName & " - " & trackArtist & " (" & trackAlbum & ")" & return
        
        set trackCounter to trackCounter + 1
      end repeat
      
      return resultText
      
    on error errMsg number errNum
      return "Error listing tracks in playlist (" & errNum & "): " & errMsg
    end try
  end if
end tell
```
