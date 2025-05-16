---
title: 'Music: Search and Play'
category: 10_creative/music_app
id: music_search_and_play
description: 'Search Apple Music library for songs, artists, or albums and play the results.'
keywords:
  - Apple Music
  - Music
  - iTunes
  - search
  - find
  - play
  - artist
  - album
  - song
  - track
language: applescript
parameters: >
  - search_term (required): The search term to look for

  - search_type (optional): Type of search: "songs", "albums", "artists",
  "playlists", or "all" (default: "songs")

  - play_results (optional): Whether to play the first search result - "yes" or
  "no" (default: "no")
notes: >
  - Music.app must be running.

  - The search is performed on your local library, not the Apple Music service.

  - To search Apple Music streaming service, you would need to use the Music
  app's interface directly.

  - The search_type parameter determines which type of items to search for.

  - If play_results is "yes", the first matching item will be played
  automatically.

  - The script returns a list of up to 10 results, showing titles, artists, and
  albums where applicable.
---

Search Apple Music library and optionally play results.

```applescript
-- Get search term parameter
set searchTermParam to "--MCP_INPUT:search_term"
if searchTermParam is "" or searchTermParam is "--MCP_INPUT:search_term" then
  return "Error: No search term provided. Please specify a search_term parameter."
end if

-- Get search type parameter
set searchTypeParam to "--MCP_INPUT:search_type"
if searchTypeParam is "" or searchTypeParam is "--MCP_INPUT:search_type" then
  set searchTypeParam to "songs" -- Default search type: songs
end if

-- Get play results parameter
set playResultsParam to "--MCP_INPUT:play_results"
if playResultsParam is "" or playResultsParam is "--MCP_INPUT:play_results" then
  set playResultsParam to "no" -- Default: don't play results automatically
end if

-- Validate search type parameter
set validSearchTypes to {"songs", "albums", "artists", "playlists", "all"}
set isValidSearchType to false
repeat with validType in validSearchTypes
  if searchTypeParam is validType then
    set isValidSearchType to true
    exit repeat
  end if
end repeat

if not isValidSearchType then
  return "Error: Invalid search type. Valid options are: " & validSearchTypes
end if

-- Validate play results parameter
if playResultsParam is not "yes" and playResultsParam is not "no" then
  return "Error: play_results parameter must be either 'yes' or 'no'."
end if

tell application "Music"
  if not running then
    return "Music app is not running. Please launch it first."
  end if
  
  try
    set resultText to "Searching for '" & searchTermParam & "' in " & searchTypeParam & ":" & return & return
    
    -- Perform the search based on search type
    set searchResults to {}
    
    if searchTypeParam is "songs" or searchTypeParam is "all" then
      -- Search for songs
      set songResults to search library playlist 1 for searchTermParam only songs
      
      if (count of songResults) > 0 then
        set resultText to resultText & "Songs:" & return
        
        set maxResults to 10
        if (count of songResults) < maxResults then
          set maxResults to count of songResults
        end if
        
        repeat with i from 1 to maxResults
          set currentTrack to item i of songResults
          set trackName to name of currentTrack
          set artistName to artist of currentTrack
          set albumName to album of currentTrack
          
          set resultText to resultText & i & ". " & trackName & " by " & artistName & " (Album: " & albumName & ")" & return
          
          -- Add to combined results list
          set end of searchResults to currentTrack
        end repeat
        
        if (count of songResults) > maxResults then
          set resultText to resultText & "... and " & ((count of songResults) - maxResults) & " more songs" & return
        end if
        
        set resultText to resultText & return
      else
        set resultText to resultText & "No songs found matching '" & searchTermParam & "'." & return & return
      end if
    end if
    
    if searchTypeParam is "albums" or searchTypeParam is "all" then
      -- Search for albums
      set albumResults to search library playlist 1 for searchTermParam only albums
      
      if (count of albumResults) > 0 then
        set resultText to resultText & "Albums:" & return
        
        set maxResults to 5
        if (count of albumResults) < maxResults then
          set maxResults to count of albumResults
        end if
        
        repeat with i from 1 to maxResults
          set currentAlbum to item i of albumResults
          set albumName to album of currentAlbum
          set artistName to artist of currentAlbum
          
          set resultText to resultText & i & ". " & albumName & " by " & artistName & return
          
          -- Add first track of album to combined results if not already there
          if searchTypeParam is "albums" then
            set end of searchResults to currentAlbum
          end if
        end repeat
        
        if (count of albumResults) > maxResults then
          set resultText to resultText & "... and " & ((count of albumResults) - maxResults) & " more albums" & return
        end if
        
        set resultText to resultText & return
      else
        set resultText to resultText & "No albums found matching '" & searchTermParam & "'." & return & return
      end if
    end if
    
    if searchTypeParam is "artists" or searchTypeParam is "all" then
      -- Search for artists
      set artistResults to search library playlist 1 for searchTermParam only artists
      
      if (count of artistResults) > 0 then
        set resultText to resultText & "Artists:" & return
        
        set maxResults to 5
        if (count of artistResults) < maxResults then
          set maxResults to count of artistResults
        end if
        
        repeat with i from 1 to maxResults
          set currentArtistTrack to item i of artistResults
          set artistName to artist of currentArtistTrack
          
          -- Check if we've already listed this artist (avoid duplicates)
          if i is 1 or artistName is not artist of item (i - 1) of artistResults then
            set resultText to resultText & i & ". " & artistName & return
            
            -- Add to combined results if not already there
            if searchTypeParam is "artists" then
              set end of searchResults to currentArtistTrack
            end if
          end if
        end repeat
        
        if (count of artistResults) > maxResults then
          set resultText to resultText & "... and more artists" & return
        end if
        
        set resultText to resultText & return
      else
        set resultText to resultText & "No artists found matching '" & searchTermParam & "'." & return & return
      end if
    end if
    
    if searchTypeParam is "playlists" or searchTypeParam is "all" then
      -- Search for playlists
      set playlistResults to {}
      
      -- Search in user playlists
      repeat with aPlaylist in user playlists
        if name of aPlaylist contains searchTermParam then
          set end of playlistResults to aPlaylist
        end if
      end repeat
      
      -- Search in library playlists
      repeat with aPlaylist in library playlists
        if name of aPlaylist contains searchTermParam then
          set end of playlistResults to aPlaylist
        end if
      end repeat
      
      if (count of playlistResults) > 0 then
        set resultText to resultText & "Playlists:" & return
        
        set maxResults to 5
        if (count of playlistResults) < maxResults then
          set maxResults to count of playlistResults
        end if
        
        repeat with i from 1 to maxResults
          set currentPlaylist to item i of playlistResults
          set playlistName to name of currentPlaylist
          set trackCount to count of tracks of currentPlaylist
          
          set resultText to resultText & i & ". " & playlistName & " (" & trackCount & " tracks)" & return
          
          -- Add playlist to combined results
          if searchTypeParam is "playlists" then
            set end of searchResults to currentPlaylist
          end if
        end repeat
        
        if (count of playlistResults) > maxResults then
          set resultText to resultText & "... and " & ((count of playlistResults) - maxResults) & " more playlists" & return
        end if
        
        set resultText to resultText & return
      else
        set resultText to resultText & "No playlists found matching '" & searchTermParam & "'." & return & return
      end if
    end if
    
    -- No results found at all
    if (count of searchResults) is 0 then
      set resultText to "No results found for '" & searchTermParam & "' in " & searchTypeParam & "."
      return resultText
    end if
    
    -- Play the first result if requested
    if playResultsParam is "yes" and (count of searchResults) > 0 then
      set itemToPlay to item 1 of searchResults
      
      if searchTypeParam is "songs" or searchTypeParam is "all" then
        -- Play the song
        play itemToPlay
        set resultText to resultText & "▶️ Now playing: " & name of itemToPlay & " by " & artist of itemToPlay & return
        
      else if searchTypeParam is "albums" then
        -- Play the album
        play itemToPlay
        set resultText to resultText & "▶️ Now playing album: " & album of itemToPlay & " by " & artist of itemToPlay & return
        
      else if searchTypeParam is "artists" then
        -- Play the artist
        play itemToPlay
        set resultText to resultText & "▶️ Now playing music by: " & artist of itemToPlay & return
        
      else if searchTypeParam is "playlists" then
        -- Play the playlist
        play itemToPlay
        set resultText to resultText & "▶️ Now playing playlist: " & name of itemToPlay & return
      end if
    else if playResultsParam is "yes" then
      set resultText to resultText & "No items to play." & return
    end if
    
    -- Return the final result
    return resultText
    
  on error errMsg number errNum
    return "Error searching Music library (" & errNum & "): " & errMsg
  end try
end tell
```
