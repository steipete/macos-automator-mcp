---
title: 'Spotify: Save Current Track'
category: 10_creative/spotify
id: spotify_save_current_track
description: >-
  Save the currently playing Spotify track to a file with track details and URI
  for future reference or sharing.
keywords:
  - Spotify
  - save
  - export
  - track
  - info
  - URI
  - library
  - song
language: applescript
parameters: >
  - output_format (optional): Format for output - "text", "json", or "csv"
  (default: "text")

  - save_location (optional): File path for saving output (default: desktop)

  - include_timestamp (optional): Whether to include timestamp - "yes" or "no"
  (default: "yes")
notes: |
  - Spotify must be running with a track playing or paused.
  - This script saves track information to a file for future reference.
  - The output includes track name, artist, album, duration, and Spotify URI.
  - Saved files can be used to quickly access tracks again via Spotify URI.
  - The JSON format is particularly useful for automation workflows.
---

Save currently playing Spotify track information to a file.

```applescript
-- Get parameters or use defaults
set outputFormat to "--MCP_INPUT:output_format"
if outputFormat is "" or outputFormat is "--MCP_INPUT:output_format" then
  set outputFormat to "text" -- Default to text format
end if

set saveLocation to "--MCP_INPUT:save_location"
if saveLocation is "" or saveLocation is "--MCP_INPUT:save_location" then
  set saveLocation to "desktop" -- Default to desktop
end if

set includeTimestamp to "--MCP_INPUT:include_timestamp"
if includeTimestamp is "" or includeTimestamp is "--MCP_INPUT:include_timestamp" then
  set includeTimestamp to "yes" -- Default to including timestamp
end if

-- Validate parameters
set validFormats to {"text", "json", "csv"}
set isValidFormat to false
repeat with validFormat in validFormats
  if outputFormat is validFormat then
    set isValidFormat to true
    exit repeat
  end if
end repeat

if not isValidFormat then
  return "Error: Invalid output format. Valid options are: " & validFormats
end if

tell application "Spotify"
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  try
    -- Check if a track is available
    if player state is stopped then
      return "No track is currently playing or paused in Spotify."
    end if
    
    -- Get the track details
    set trackName to name of current track
    set artistName to artist of current track
    set albumName to album of current track
    set trackDurationMs to duration of current track -- in milliseconds
    set trackDurationSec to trackDurationMs / 1000 -- convert to seconds
    set trackPosition to player position -- in seconds
    set spotifyURI to spotify url of current track
    set playerStateText to player state as text
    
    -- Format duration for display
    set durationMin to trackDurationSec div 60
    set durationSec to trackDurationSec mod 60
    if durationSec < 10 then
      set durationSecText to "0" & durationSec
    else
      set durationSecText to durationSec as text
    end if
    set formattedDuration to durationMin & ":" & durationSecText
    
    -- Get current timestamp if requested
    set timestampText to ""
    if includeTimestamp is "yes" then
      set currentDate to current date
      set dateString to (year of currentDate) & "-" & my padNumber(month of currentDate as integer) & "-" & my padNumber(day of currentDate)
      set timeString to my padNumber(hours of currentDate) & ":" & my padNumber(minutes of currentDate) & ":" & my padNumber(seconds of currentDate)
      set timestampText to dateString & " " & timeString
    end if
    
    -- Create sanitized filename based on track
    set sanitizedTrackName to my sanitizeFileName(trackName)
    set sanitizedArtistName to my sanitizeFileName(artistName)
    set baseFileName to sanitizedArtistName & " - " & sanitizedTrackName
    
    -- Generate file content based on format
    set fileContent to ""
    
    if outputFormat is "text" then
      set fileContent to "Spotify Track Information" & return & return
      set fileContent to fileContent & "Track: " & trackName & return
      set fileContent to fileContent & "Artist: " & artistName & return
      set fileContent to fileContent & "Album: " & albumName & return
      set fileContent to fileContent & "Duration: " & formattedDuration & return
      set fileContent to fileContent & "Spotify URI: " & spotifyURI & return
      
      if includeTimestamp is "yes" then
        set fileContent to fileContent & "Saved on: " & timestampText & return
      end if
      
      set fileContent to fileContent & return & "To play this track again, use the Spotify URI or open:" & return
      set fileContent to fileContent & "https://open.spotify.com/track/" & my extractIDFromURI(spotifyURI)
      
      set fileExtension to "txt"
      
    else if outputFormat is "json" then
      -- Build JSON object
      set fileContent to "{" & return
      set fileContent to fileContent & "  \"track\": \"" & my escapeJSON(trackName) & "\"," & return
      set fileContent to fileContent & "  \"artist\": \"" & my escapeJSON(artistName) & "\"," & return
      set fileContent to fileContent & "  \"album\": \"" & my escapeJSON(albumName) & "\"," & return
      set fileContent to fileContent & "  \"duration_ms\": " & trackDurationMs & "," & return
      set fileContent to fileContent & "  \"duration_formatted\": \"" & formattedDuration & "\"," & return
      set fileContent to fileContent & "  \"spotify_uri\": \"" & spotifyURI & "\"," & return
      set fileContent to fileContent & "  \"player_state\": \"" & playerStateText & "\"," & return
      
      if includeTimestamp is "yes" then
        set fileContent to fileContent & "  \"saved_at\": \"" & timestampText & "\"," & return
      end if
      
      set fileContent to fileContent & "  \"web_url\": \"https://open.spotify.com/track/" & my extractIDFromURI(spotifyURI) & "\"" & return
      set fileContent to fileContent & "}"
      
      set fileExtension to "json"
      
    else if outputFormat is "csv" then
      -- Create CSV header and data rows
      set fileContent to "Track,Artist,Album,Duration,Spotify URI"
      
      if includeTimestamp is "yes" then
        set fileContent to fileContent & ",Saved At"
      end if
      
      set fileContent to fileContent & return
      
      -- Add track data
      set fileContent to fileContent & "\"" & my escapeCSV(trackName) & "\","
      set fileContent to fileContent & "\"" & my escapeCSV(artistName) & "\","
      set fileContent to fileContent & "\"" & my escapeCSV(albumName) & "\","
      set fileContent to fileContent & "\"" & formattedDuration & "\","
      set fileContent to fileContent & "\"" & spotifyURI & "\""
      
      if includeTimestamp is "yes" then
        set fileContent to fileContent & ",\"" & timestampText & "\""
      end if
      
      set fileExtension to "csv"
    end if
    
    -- Determine save path
    set filePath to ""
    
    if saveLocation is "desktop" then
      set filePath to (path to desktop as text) & baseFileName & "." & fileExtension
    else
      set filePath to saveLocation
      
      -- If path doesn't end with extension, append filename and extension
      if filePath does not end with ("." & fileExtension) then
        if filePath ends with "/" then
          set filePath to filePath & baseFileName & "." & fileExtension
        else
          set filePath to filePath & "/" & baseFileName & "." & fileExtension
        end if
      end if
    end if
    
    -- Convert to POSIX path for file operations
    set posixPath to POSIX path of filePath
    
    -- Write the file
    do shell script "cat > " & quoted form of posixPath & " << 'EOF'
" & fileContent & "
EOF"
    
    -- Return success message with file details
    set resultMessage to "Successfully saved " & outputFormat & " information for track:" & return
    set resultMessage to resultMessage & "\"" & trackName & "\" by " & artistName & return & return
    set resultMessage to resultMessage & "Saved to: " & posixPath & return & return
    set resultMessage to resultMessage & "This file contains:" & return
    set resultMessage to resultMessage & "- Basic track information" & return
    set resultMessage to resultMessage & "- Spotify URI for reuse: " & spotifyURI & return
    set resultMessage to resultMessage & "- Track URL: https://open.spotify.com/track/" & my extractIDFromURI(spotifyURI)
    
    return resultMessage
    
  on error errMsg number errNum
    return "Error saving track information (" & errNum & "): " & errMsg
  end try
end tell

-- Helper function to pad numbers with leading zero
on padNumber(num)
  set numText to num as text
  if (count numText) < 2 then
    set numText to "0" & numText
  end if
  return numText
end padNumber

-- Helper function to sanitize file names
on sanitizeFileName(fileName)
  set invalidChars to {":", "/", "\\", "*", "?", "\"", "<", ">", "|"}
  set sanitized to fileName
  
  repeat with invalidChar in invalidChars
    set sanitized to my replaceText(sanitized, invalidChar, "-")
  end repeat
  
  return sanitized
end sanitizeFileName

-- Helper function to replace text
on replaceText(sourceText, findText, replaceText)
  set AppleScript's text item delimiters to findText
  set textItems to text items of sourceText
  set AppleScript's text item delimiters to replaceText
  set resultText to textItems as text
  set AppleScript's text item delimiters to ""
  return resultText
end replaceText

-- Helper function to escape JSON strings
on escapeJSON(theText)
  set escaped to theText
  set escaped to my replaceText(escaped, "\\", "\\\\")
  set escaped to my replaceText(escaped, "\"", "\\\"")
  set escaped to my replaceText(escaped, return, "\\n")
  set escaped to my replaceText(escaped, tab, "\\t")
  return escaped
end escapeJSON

-- Helper function to escape CSV fields
on escapeCSV(theText)
  -- Replace double quotes with two double quotes (CSV standard)
  set escaped to my replaceText(theText, "\"", "\"\"")
  return escaped
end escapeCSV

-- Helper function to extract ID from Spotify URI
on extractIDFromURI(uri)
  -- Expecting format like "spotify:track:1234567890"
  try
    set AppleScript's text item delimiters to ":"
    set idParts to text items of uri
    if (count of idParts) ≥ 3 then
      set trackID to item 3 of idParts
      set AppleScript's text item delimiters to ""
      return trackID
    end if
    
    -- Reset delimiters
    set AppleScript's text item delimiters to ""
    return ""
  on error
    set AppleScript's text item delimiters to ""
    return ""
  end try
end extractIDFromURI
```
