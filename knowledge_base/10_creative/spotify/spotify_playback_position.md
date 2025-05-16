---
title: "Spotify: Playback Position Control"
category: "08_creative_and_document_apps"
id: spotify_playback_position
description: "Control the playback position within the current Spotify track, showing time remaining and track progress."
keywords: ["Spotify", "playback", "position", "seek", "skip", "scrub", "time", "track", "progress"]
language: applescript
parameters: |
  - action (required): Action to perform - "set_position", "forward", "backward", "get_position"
  - value (optional): For set_position: time in seconds. For forward/backward: seconds to jump (defaults to 10)
notes: |
  - Spotify must be running with a track playing or paused.
  - The "set_position" action requires a specific position in seconds (e.g., 60 for 1 minute into the track).
  - The "forward" and "backward" actions move relative to the current position by the specified number of seconds.
  - The player position is represented in seconds, while track duration is in milliseconds in Spotify's API.
---

Control playback position within the current Spotify track.

```applescript
-- Get the action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "get_position" -- Default to getting current position
end if

-- Get the value parameter for position operations
set valueParam to "--MCP_INPUT:value"
if valueParam is "" or valueParam is "--MCP_INPUT:value" then
  set valueParam to "10" -- Default jump value for forward/backward
end if

-- Validate action
set validActions to {"set_position", "forward", "backward", "get_position"}
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

-- Convert value parameter to number if possible
try
  set valueNumber to valueParam as number
on error
  return "Error: Value parameter must be a number (seconds)."
end try

tell application "Spotify"
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  try
    -- Check if a track is available
    if player state is stopped then
      return "No track is currently playing or paused in Spotify."
    end if
    
    -- Get the track details for reference
    set trackName to name of current track
    set artistName to artist of current track
    set trackDurationMs to duration of current track -- in milliseconds
    set trackDurationSec to trackDurationMs / 1000 -- convert to seconds
    
    -- Get current position before making changes
    set originalPosition to player position -- in seconds
    
    -- Execute the requested action
    if actionParam is "set_position" then
      -- Validate position is within track bounds
      if valueNumber < 0 then
        set valueNumber to 0
      else if valueNumber > trackDurationSec then
        set valueNumber to trackDurationSec
      end if
      
      -- Set the position
      set player position to valueNumber
      
    else if actionParam is "forward" then
      -- Calculate new position and ensure it's within bounds
      set newPosition to originalPosition + valueNumber
      if newPosition > trackDurationSec then
        set newPosition to trackDurationSec
      end if
      
      -- Set the new position
      set player position to newPosition
      
    else if actionParam is "backward" then
      -- Calculate new position and ensure it's within bounds
      set newPosition to originalPosition - valueNumber
      if newPosition < 0 then
        set newPosition to 0
      end if
      
      -- Set the new position
      set player position to newPosition
    end if
    
    -- Get the current position after any changes
    delay 0.1 -- Brief delay to ensure position update
    set currentPosition to player position
    
    -- Format times for display
    set formattedPosition to my formatTime(currentPosition)
    set formattedDuration to my formatTime(trackDurationSec)
    set formattedRemaining to my formatTime(trackDurationSec - currentPosition)
    
    -- Calculate progress percentage
    set progressPercent to (currentPosition / trackDurationSec) * 100
    set progressPercentRounded to round progressPercent
    
    -- Create a visual progress bar
    set progressBar to my createProgressBar(progressPercentRounded)
    
    -- Build the result message
    set resultMessage to "Track: " & trackName & "\nArtist: " & artistName & "\n\n"
    
    -- Add action info if an action was performed
    if actionParam is not "get_position" then
      set resultMessage to resultMessage & "Action: " & actionParam
      
      if actionParam is "set_position" then
        set resultMessage to resultMessage & " to " & valueNumber & " seconds\n"
      else if actionParam is "forward" then
        set resultMessage to resultMessage & " " & valueNumber & " seconds\n"
      else if actionParam is "backward" then
        set resultMessage to resultMessage & " " & valueNumber & " seconds\n"
      end if
      
      set resultMessage to resultMessage & "\n"
    end if
    
    -- Add position information
    set resultMessage to resultMessage & "Position: " & formattedPosition & " / " & formattedDuration & " (" & formattedRemaining & " remaining)\n"
    set resultMessage to resultMessage & "Progress: " & progressPercentRounded & "%\n" & progressBar
    
    -- Add player state info
    set playerStateText to player state as text
    set resultMessage to resultMessage & "\n\nPlayer State: " & playerStateText
    
    return resultMessage
    
  on error errMsg number errNum
    return "Error controlling playback position (" & errNum & "): " & errMsg
  end try
end tell

-- Helper function to format time in MM:SS format
on formatTime(timeInSeconds)
  set totalSeconds to round timeInSeconds
  set minutes to totalSeconds div 60
  set seconds to totalSeconds mod 60
  
  if seconds < 10 then
    set secondsText to "0" & seconds
  else
    set secondsText to seconds as text
  end if
  
  return minutes & ":" & secondsText
end formatTime

-- Helper function to create a visual progress bar
on createProgressBar(percentComplete)
  set barLength to 20 -- Characters in the progress bar
  set completedSegments to round ((percentComplete / 100) * barLength)
  
  if completedSegments > barLength then
    set completedSegments to barLength
  end if
  
  set remainingSegments to barLength - completedSegments
  
  set progressBar to "[" & text 1 thru completedSegments of "####################" & text 1 thru remainingSegments of "                    " & "]"
  return progressBar
end createProgressBar
```