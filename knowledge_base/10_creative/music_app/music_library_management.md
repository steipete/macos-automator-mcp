---
title: "Music: Library Management"
category: "08_creative_and_document_apps"
id: music_library_management
description: "Manage Apple Music library, including adding tracks, updating metadata, and organizing content."
keywords: ["Apple Music", "Music", "iTunes", "library", "tracks", "metadata", "rating", "organize", "add tracks"]
language: applescript
parameters: |
  - action (required): Action to perform - "stats", "rate_current", "update_genre", "add_file", "top_rated"
  - rating (optional): Star rating (1-5) for rate_current action
  - genre (optional): Genre name for update_genre action
  - file_path (optional): File path for add_file action
notes: |
  - Music.app must be running.
  - The "stats" action shows library statistics like track count, total time, etc.
  - The "rate_current" action sets the rating for the currently playing track (1-5 stars).
  - The "update_genre" action changes the genre of the currently playing track.
  - The "add_file" action adds a local audio file to the library.
  - The "top_rated" action shows your highest rated tracks.
  - Some operations may not work on Apple Music (streaming) content, only on your local library.
---

Manage your Apple Music library.

```applescript
-- Get action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "stats" -- Default action: show library stats
end if

-- Get rating parameter (for rate_current action)
set ratingParam to "--MCP_INPUT:rating"
if ratingParam is "" or ratingParam is "--MCP_INPUT:rating" then
  set ratingParam to "5" -- Default rating: 5 stars
end if

-- Get genre parameter (for update_genre action)
set genreParam to "--MCP_INPUT:genre"
if genreParam is "" or genreParam is "--MCP_INPUT:genre" then
  set genreParam to "" -- Will be validated later if needed
end if

-- Get file path parameter (for add_file action)
set filePathParam to "--MCP_INPUT:file_path"
if filePathParam is "" or filePathParam is "--MCP_INPUT:file_path" then
  set filePathParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"stats", "rate_current", "update_genre", "add_file", "top_rated"}
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

-- Additional validation for specific actions
if actionParam is "rate_current" then
  try
    set ratingNumber to ratingParam as number
    if ratingNumber < 1 or ratingNumber > 5 then
      return "Error: Rating must be between 1 and 5 stars."
    end if
  on error
    return "Error: Rating must be a number between 1 and 5."
  end try
end if

if actionParam is "update_genre" and genreParam is "" then
  return "Error: The update_genre action requires a genre parameter."
end if

if actionParam is "add_file" and filePathParam is "" then
  return "Error: The add_file action requires a file_path parameter."
end if

tell application "Music"
  if not running then
    return "The Music app is not running. Please launch it first."
  end if
  
  set resultText to ""
  
  -- Execute the requested action
  if actionParam is "stats" then
    -- Show library statistics
    try
      -- Get library playlist (main library)
      set mainLibrary to library playlist 1
      
      -- Get track counts
      set totalTracks to count of tracks of mainLibrary
      
      -- Calculate total time
      set totalTimeSeconds to 0
      repeat with aTrack in tracks of mainLibrary
        try
          set totalTimeSeconds to totalTimeSeconds + (duration of aTrack)
        end try
      end repeat
      
      -- Convert total time to days, hours, minutes
      set totalTimeDays to totalTimeSeconds / 86400 -- 86400 seconds in a day
      set totalTimeHours to (totalTimeSeconds mod 86400) / 3600
      set totalTimeMinutes to (totalTimeSeconds mod 3600) / 60
      
      -- Round to 1 decimal place
      set totalTimeDays to round (totalTimeDays * 10) / 10
      set totalTimeHours to round (totalTimeHours * 10) / 10
      set totalTimeMinutes to round (totalTimeMinutes * 10) / 10
      
      -- Count playlists
      set totalPlaylists to count of user playlists
      
      -- Get genre count
      set allGenres to {}
      repeat with aTrack in tracks of mainLibrary
        try
          set trackGenre to genre of aTrack
          if trackGenre is not in allGenres and trackGenre is not "" and trackGenre is not missing value then
            set end of allGenres to trackGenre
          end if
        end try
      end repeat
      
      set genreCount to count of allGenres
      
      -- Build the result
      set resultText to "Apple Music Library Statistics:" & return & return
      set resultText to resultText & "Total Tracks: " & totalTracks & return
      set resultText to resultText & "Total Time: " & totalTimeDays & " days, " & totalTimeHours & " hours, " & totalTimeMinutes & " minutes" & return
      set resultText to resultText & "Total Playlists: " & totalPlaylists & return
      set resultText to resultText & "Total Genres: " & genreCount & return
      
      -- Show recently added tracks
      try
        set recentTracks to (get tracks of mainLibrary where date added > ((current date) - (7 * days)))
        set recentCount to count of recentTracks
        
        set resultText to resultText & return & "Tracks Added in the Last Week: " & recentCount & return
        
        if recentCount > 0 then
          set maxRecentToShow to 5
          if recentCount < maxRecentToShow then
            set maxRecentToShow to recentCount
          end if
          
          set resultText to resultText & "Recent Additions:" & return
          
          repeat with i from 1 to maxRecentToShow
            set recentTrack to item i of recentTracks
            set trackName to name of recentTrack
            set artistName to artist of recentTrack
            
            set resultText to resultText & "- " & trackName & " by " & artistName & return
          end repeat
          
          if recentCount > maxRecentToShow then
            set resultText to resultText & "... and " & (recentCount - maxRecentToShow) & " more" & return
          end if
        end if
      end try
      
    on error errMsg number errNum
      set resultText to "Error getting library statistics (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "rate_current" then
    -- Rate the currently playing track
    try
      -- Check if a track is playing
      if player state is stopped then
        set resultText to "No track is currently playing. Please play a track first."
      else
        -- Get the current track
        set currentTrack to current track
        
        -- Convert 1-5 star rating to 0-100 scale (20 points per star)
        set ratingNumber to ratingParam as number
        set ratingValue to ratingNumber * 20
        
        -- Set the rating
        set rating of currentTrack to ratingValue
        
        -- Get track info for confirmation
        set trackName to name of currentTrack
        set artistName to artist of currentTrack
        set oldRatingValue to rating of currentTrack
        
        -- Verify the rating was set correctly
        if oldRatingValue is ratingValue then
          set resultText to "Rating updated successfully." & return
        else
          set resultText to "Rating may not have updated correctly." & return
        end if
        
        set resultText to resultText & "Rated '" & trackName & "' by " & artistName & " with " & ratingNumber & " stars."
      end if
    on error errMsg number errNum
      set resultText to "Error setting track rating (" & errNum & "): " & errMsg
      
      if errNum is -1728 then
        set resultText to "Cannot set rating for this track. It may be an Apple Music track rather than a library track."
      end if
    end try
    
  else if actionParam is "update_genre" then
    -- Update genre of current track
    try
      -- Check if a track is playing
      if player state is stopped then
        set resultText to "No track is currently playing. Please play a track first."
      else
        -- Get the current track
        set currentTrack to current track
        
        -- Save old genre for reporting
        set oldGenre to genre of currentTrack
        
        -- Update the genre
        set genre of currentTrack to genreParam
        
        -- Get track info for confirmation
        set trackName to name of currentTrack
        set artistName to artist of currentTrack
        
        set resultText to "Updated genre for '" & trackName & "' by " & artistName & return
        set resultText to resultText & "Old genre: " & oldGenre & return
        set resultText to resultText & "New genre: " & genreParam
      end if
    on error errMsg number errNum
      set resultText to "Error updating track genre (" & errNum & "): " & errMsg
      
      if errNum is -1728 then
        set resultText to "Cannot update genre for this track. It may be an Apple Music track rather than a library track."
      end if
    end try
    
  else if actionParam is "add_file" then
    -- Add file to library
    try
      -- Convert to POSIX path if needed
      if filePathParam starts with "/" then
        set filePath to POSIX file filePathParam
      else
        set filePath to filePathParam
      end if
      
      -- Add the file to the library
      add filePath
      
      set resultText to "File added to library: " & filePathParam & return
      set resultText to resultText & "Note: The file may still be processing. Check the Music app for the added track."
      
    on error errMsg number errNum
      set resultText to "Error adding file to library (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "top_rated" then
    -- Show top rated tracks
    try
      -- Get library playlist (main library)
      set mainLibrary to library playlist 1
      
      -- Get tracks with rating of 4 or 5 stars (80-100)
      set highRatedTracks to (get tracks of mainLibrary where rating > 79)
      set trackCount to count of highRatedTracks
      
      if trackCount is 0 then
        set resultText to "No highly rated tracks found in your library."
      else
        set resultText to "Top Rated Tracks (4-5 stars):" & return & return
        
        -- Sort by rating (highest first)
        set sortedTracks to {}
        
        -- Copy to a list we can modify
        repeat with aTrack in highRatedTracks
          set end of sortedTracks to aTrack
        end repeat
        
        -- Sort the list (bubble sort - not efficient but works for this)
        set n to count of sortedTracks
        repeat with i from 1 to n
          repeat with j from 1 to (n - i)
            if rating of (item j of sortedTracks) < rating of (item (j + 1) of sortedTracks) then
              set temp to item j of sortedTracks
              set item j of sortedTracks to item (j + 1) of sortedTracks
              set item (j + 1) of sortedTracks to temp
            end if
          end repeat
        end repeat
        
        -- Show top 20 tracks
        set maxTracksToShow to 20
        if trackCount < maxTracksToShow then
          set maxTracksToShow to trackCount
        end if
        
        repeat with i from 1 to maxTracksToShow
          set aTrack to item i of sortedTracks
          
          set trackName to name of aTrack
          set artistName to artist of aTrack
          set albumName to album of aTrack
          set trackRating to rating of aTrack
          set starRating to trackRating / 20
          
          set resultText to resultText & i & ". " & trackName & " by " & artistName & return
          set resultText to resultText & "   Album: " & albumName & return
          set resultText to resultText & "   Rating: " & starRating & " stars" & return & return
        end repeat
        
        if trackCount > maxTracksToShow then
          set resultText to resultText & "... and " & (trackCount - maxTracksToShow) & " more highly rated tracks"
        end if
      end if
    on error errMsg number errNum
      set resultText to "Error getting top rated tracks (" & errNum & "): " & errMsg
    end try
  end if
  
  return resultText
end tell
```