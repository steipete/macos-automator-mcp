---
title: "Music: Playlist Operations"
category: "08_creative_and_document_apps"
id: music_playlist_operations
description: "Manage Apple Music playlists including creating, listing, modifying, and playing playlists."
keywords: ["Apple Music", "Music", "iTunes", "playlist", "playlists", "create playlist", "add tracks", "library"]
language: applescript
parameters: |
  - action (required): Action to perform - "list", "create", "add_current", "play", "search"
  - playlist_name (optional): Name of the playlist to create, modify, or play
  - search_term (optional): Term to search for when using the search action
notes: |
  - Music.app must be running.
  - The "list" action shows all available playlists.
  - The "create" action creates a new playlist (playlist_name required).
  - The "add_current" action adds the currently playing track to the specified playlist.
  - The "play" action plays the specified playlist.
  - The "search" action searches for tracks and can optionally add them to a playlist.
  - Apple Music may have limitations on what operations can be performed on certain types of playlists.
---

Manage Apple Music playlists.

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

-- Get search term parameter
set searchTermParam to "--MCP_INPUT:search_term"
if searchTermParam is "" or searchTermParam is "--MCP_INPUT:search_term" then
  set searchTermParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"list", "create", "add_current", "play", "search"}
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
if (actionParam is "create" or actionParam is "add_current" or actionParam is "play") and playlistNameParam is "" then
  return "Error: The '" & actionParam & "' action requires a playlist_name parameter."
end if

if actionParam is "search" and searchTermParam is "" then
  return "Error: The 'search' action requires a search_term parameter."
end if

tell application "Music"
  if not running then
    return "The Music app is not running. Please launch it first."
  end if
  
  set resultText to ""
  
  -- Execute the requested action
  if actionParam is "list" then
    -- List all playlists
    set allPlaylists to {}
    
    -- System playlists (Library, Music, etc.)
    try
      set systemPlaylists to (get name of library playlists)
      set resultText to resultText & "System Playlists:\n"
      repeat with playlistName in systemPlaylists
        set resultText to resultText & "- " & (playlistName as text) & "\n"
      end repeat
    on error
      set resultText to resultText & "No system playlists found.\n"
    end try
    
    -- User playlists
    try
      set userPlaylists to (get name of user playlists)
      set resultText to resultText & "\nUser Playlists:\n"
      repeat with playlistName in userPlaylists
        set resultText to resultText & "- " & (playlistName as text) & "\n"
      end repeat
    on error
      set resultText to resultText & "\nNo user playlists found.\n"
    end try
    
    -- Smart playlists
    try
      set smartPlaylists to (get name of smart playlists)
      set resultText to resultText & "\nSmart Playlists:\n"
      repeat with playlistName in smartPlaylists
        set resultText to resultText & "- " & (playlistName as text) & "\n"
      end repeat
    on error
      set resultText to resultText & "\nNo smart playlists found.\n"
    end try
    
    -- Subscribed/Apple Music playlists
    try
      set subscribedPlaylists to (get name of subscription playlists)
      set resultText to resultText & "\nSubscribed Playlists (Apple Music):\n"
      repeat with playlistName in subscribedPlaylists
        set resultText to resultText & "- " & (playlistName as text) & "\n"
      end repeat
    on error
      set resultText to resultText & "\nNo subscribed playlists found.\n"
    end try
    
    set resultText to resultText & "\nTotal playlists: " & ((count of playlists) as text)
    
  else if actionParam is "create" then
    -- Create a new playlist
    try
      -- Check if playlist already exists
      if user playlist playlistNameParam exists then
        set resultText to "Playlist '" & playlistNameParam & "' already exists. No new playlist created."
      else
        -- Create the playlist
        make new user playlist with properties {name:playlistNameParam}
        set resultText to "Successfully created new playlist: '" & playlistNameParam & "'"
      end if
    on error errMsg number errNum
      set resultText to "Error creating playlist (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "add_current" then
    -- Add currently playing track to specified playlist
    try
      -- Check if playlist exists
      if not (user playlist playlistNameParam exists) then
        -- Create the playlist if it doesn't exist
        make new user playlist with properties {name:playlistNameParam}
        set resultText to "Created new playlist '" & playlistNameParam & "'.\n"
      end if
      
      -- Check if there's a current track
      if player state is stopped then
        set resultText to resultText & "No track is currently playing. Please play a track first."
      else
        -- Get the current track
        set currentTrack to current track
        
        -- Add to playlist
        duplicate currentTrack to user playlist playlistNameParam
        
        -- Get track info for confirmation
        set trackName to name of currentTrack
        set artistName to artist of currentTrack
        
        set resultText to resultText & "Added track '" & trackName & "' by " & artistName & " to playlist '" & playlistNameParam & "'"
      end if
    on error errMsg number errNum
      set resultText to "Error adding current track to playlist (" & errNum & "): " & errMsg
      
      if errNum is -1728 then
        -- Common error: track is already in playlist
        set resultText to "This track is already in the playlist '" & playlistNameParam & "'"
      end if
    end try
    
  else if actionParam is "play" then
    -- Play specified playlist
    try
      -- First try as user playlist
      if user playlist playlistNameParam exists then
        play user playlist playlistNameParam
        set playlistType to "user"
      -- Then try as system playlist
      else if library playlist playlistNameParam exists then
        play library playlist playlistNameParam
        set playlistType to "library"
      -- Then try as smart playlist
      else if smart playlist playlistNameParam exists then
        play smart playlist playlistNameParam
        set playlistType to "smart"
      -- Then try as any playlist type
      else if playlist playlistNameParam exists then
        play playlist playlistNameParam
        set playlistType to "general"
      else
        set resultText to "Playlist '" & playlistNameParam & "' not found."
        return resultText
      end if
      
      -- Get information about what's playing
      delay 1 -- Give time for playback to start
      
      if player state is playing then
        set currentTrackName to name of current track
        set currentArtistName to artist of current track
        
        set resultText to "Now playing from " & playlistType & " playlist '" & playlistNameParam & "'\n"
        set resultText to resultText & "Current track: '" & currentTrackName & "' by " & currentArtistName
      else
        set resultText to "Playlist '" & playlistNameParam & "' loaded but playback did not start."
      end if
    on error errMsg number errNum
      set resultText to "Error playing playlist (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "search" then
    -- Search for tracks
    try
      -- Perform search
      set searchResults to search library playlist 1 for searchTermParam
      
      set resultCount to count of searchResults
      
      if resultCount is 0 then
        set resultText to "No results found for search term '" & searchTermParam & "'"
      else
        set resultText to "Found " & resultCount & " results for '" & searchTermParam & "':\n\n"
        
        -- List first 10 results (to avoid extremely long responses)
        set maxResults to 10
        if resultCount < maxResults then
          set maxResults to resultCount
        end if
        
        repeat with i from 1 to maxResults
          set currentTrack to item i of searchResults
          
          set trackName to name of currentTrack
          set artistName to artist of currentTrack
          set albumName to album of currentTrack
          
          set resultText to resultText & i & ". '" & trackName & "' by " & artistName & " (Album: " & albumName & ")\n"
        end repeat
        
        -- Note if there are more results
        if resultCount > maxResults then
          set resultText to resultText & "\n... and " & (resultCount - maxResults) & " more results"
        end if
        
        -- Add option to add results to a playlist if playlist name was provided
        if playlistNameParam is not "" then
          set resultText to resultText & "\n\nTo add these results to the playlist '" & playlistNameParam & "', run this script again with action='add_search_results'"
        end if
      end if
    on error errMsg number errNum
      set resultText to "Error searching for tracks (" & errNum & "): " & errMsg
    end try
  end if
  
  return resultText
end tell
```