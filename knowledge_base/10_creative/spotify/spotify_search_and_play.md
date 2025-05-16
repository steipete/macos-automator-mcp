---
title: 'Spotify: Search and Play'
category: 10_creative/spotify
id: spotify_search_and_play
description: 'Search for tracks, albums, or artists in Spotify and play the results.'
keywords:
  - Spotify
  - search
  - play
  - track
  - album
  - artist
  - query
  - music
language: applescript
parameters: >
  - searchQuery (required): The search term to look for in Spotify

  - searchType (optional): Type of search: "track", "album", "artist" or
  "playlist" (default: "track")
notes: >
  - Spotify must be running.

  - Search functionality in AppleScript is limited. For more advanced searches,
  the Spotify Web API is recommended.

  - This script provides a basic search mechanism that works with Spotify's
  AppleScript capabilities.

  - The search may open Spotify's search interface rather than returning results
  directly in some cases.
---

Search for content in Spotify and play the results.

```applescript
-- Get search query from input or use a sample search term
set searchQuery to "--MCP_INPUT:searchQuery"
if searchQuery is "" or searchQuery is "--MCP_INPUT:searchQuery" then
  set searchQuery to "Tiny Dancer" -- Example default value
end if

-- Get search type from input or default to "track"
set searchType to "--MCP_INPUT:searchType"
if searchType is "" or searchType is "--MCP_INPUT:searchType" then
  set searchType to "track" -- Default to track search
end if

-- Validate searchType
set validSearchTypes to {"track", "album", "artist", "playlist"}
set validType to false
repeat with typeName in validSearchTypes
  if searchType is typeName then
    set validType to true
    exit repeat
  end if
end repeat

if not validType then
  return "Error: Invalid search type. Must be one of: " & validSearchTypes
end if

tell application "Spotify"
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  try
    -- Construct search URI
    set encodedQuery to my encodeText(searchQuery)
    set spotifyURI to "spotify:search:" & encodedQuery
    
    -- Open search
    activate
    open location spotifyURI
    
    -- Provide feedback on what's happening
    set resultText to "Searching Spotify for " & searchType & ": \"" & searchQuery & "\""
    set resultText to resultText & "\n\nNote: Due to limitations in Spotify's AppleScript support, search results are shown in the Spotify app."
    set resultText to resultText & "\n\nSearch URI: " & spotifyURI
    
    -- If the user wants to search tracks and immediate play the top result,
    -- this is a more direct approach using the play command:
    -- if searchType is "track" then
    --   play track "spotify:search:" & encodedQuery
    --   
    --   -- Try to get current track info after a short delay
    --   delay 2
    --   set trackInfo to "\n\nNow playing: " & name of current track & " by " & artist of current track
    --   set resultText to resultText & trackInfo
    -- end if
    
    return resultText
    
  on error errMsg number errNum
    return "Error performing search (" & errNum & "): " & errMsg
  end try
end tell

-- Helper function to encode text for URLs
on encodeText(theText)
  set theTextEnc to ""
  set specialChars to "+:%&#/=?$@ ,;\"'\\[]{}|^~`<>"
  repeat with eachChar in every character of theText
    set eachCharNum to ASCII number of eachChar
    if eachCharNum < 32 or eachCharNum > 126 or specialChars contains eachChar then
      set theTextEnc to theTextEnc & "%" & my toHex(eachCharNum)
    else
      set theTextEnc to theTextEnc & eachChar
    end if
  end repeat
  return theTextEnc
end encodeText

-- Helper function to convert number to hex string
on toHex(intNum)
  set hexStr to ""
  set hexChars to "0123456789ABCDEF"
  repeat until intNum < 1
    set remainder to intNum mod 16
    set hexStr to (character (remainder + 1) of hexChars) & hexStr
    set intNum to intNum div 16
  end repeat
  if hexStr is "" then
    set hexStr to "0"
  end if
  if (count hexStr) is 1 then
    set hexStr to "0" & hexStr
  end if
  return hexStr
end toHex
```
