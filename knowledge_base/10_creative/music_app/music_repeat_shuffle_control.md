---
title: 'Music: Repeat and Shuffle Control'
category: 10_creative
id: music_repeat_shuffle_control
description: Control Apple Music's repeat and shuffle settings via AppleScript.
keywords:
  - Apple Music
  - Music
  - iTunes
  - repeat
  - shuffle
  - repeating
  - shuffling
  - playback
  - settings
language: applescript
parameters: >
  - action (required): Action to perform - "toggle_repeat", "toggle_shuffle",
  "set_repeat", "set_shuffle", "get_status"

  - value (optional): For set_repeat/set_shuffle actions - "off", "one", or
  "all" for repeat; "on" or "off" for shuffle
notes: |
  - Music.app must be running.
  - Toggle actions will cycle through the available states.
  - Repeat has three states: off, one (current track), and all (playlist).
  - Shuffle has two states: on or off.
  - Get_status returns the current repeat and shuffle settings.
  - Some operations may have limitations with Apple Music streaming content.
---

Control Apple Music's repeat and shuffle playback settings.

```applescript
-- Get the action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "get_status" -- Default to checking status
end if

-- Get the value parameter for set operations
set valueParam to "--MCP_INPUT:value"
if valueParam is "" or valueParam is "--MCP_INPUT:value" then
  set valueParam to "" -- Will be validated later if needed
end if

-- Validate action
set validActions to {"toggle_repeat", "toggle_shuffle", "set_repeat", "set_shuffle", "get_status"}
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

-- For set operations, validate the value parameter
if actionParam is "set_repeat" and (valueParam is not "off" and valueParam is not "one" and valueParam is not "all") then
  return "Error: When using set_repeat, value parameter must be either 'off', 'one' (repeat one), or 'all' (repeat all)."
end if

if actionParam is "set_shuffle" and (valueParam is not "on" and valueParam is not "off") then
  return "Error: When using set_shuffle, value parameter must be either 'on' or 'off'."
end if

tell application "Music"
  if not running then
    return "Music app is not running. Please launch it first."
  end if
  
  try
    -- Store initial values for reporting
    set initialSongRepeat to song repeat
    set initialShuffleEnabled to shuffle enabled
    set initialShuffleMode to shuffle mode
    
    -- Execute the requested action
    if actionParam is "toggle_repeat" then
      -- Cycle through off -> one -> all -> off
      if song repeat is off then
        set song repeat to one
      else if song repeat is one then
        set song repeat to all
      else
        set song repeat to off
      end if
      
    else if actionParam is "toggle_shuffle" then
      -- Toggle shuffle on/off
      set shuffle enabled to not shuffle enabled
      
    else if actionParam is "set_repeat" then
      -- Set specific repeat mode
      if valueParam is "off" then
        set song repeat to off
      else if valueParam is "one" then
        set song repeat to one
      else if valueParam is "all" then
        set song repeat to all
      end if
      
    else if actionParam is "set_shuffle" then
      -- Set specific shuffle state
      if valueParam is "on" then
        set shuffle enabled to true
      else if valueParam is "off" then
        set shuffle enabled to false
      end if
    end if
    
    -- Get current states after any changes
    set currentSongRepeat to song repeat
    set currentShuffleEnabled to shuffle enabled
    set currentShuffleMode to shuffle mode
    
    -- Prepare status strings
    if currentSongRepeat is off then
      set repeatStatus to "off"
    else if currentSongRepeat is one then
      set repeatStatus to "one track"
    else if currentSongRepeat is all then
      set repeatStatus to "all tracks"
    else
      set repeatStatus to "unknown"
    end if
    
    if currentShuffleEnabled then
      if currentShuffleMode is songs then
        set shuffleStatus to "on (songs)"
      else if currentShuffleMode is albums then
        set shuffleStatus to "on (albums)"
      else if currentShuffleMode is groupings then
        set shuffleStatus to "on (groupings)"
      else
        set shuffleStatus to "on"
      end if
    else
      set shuffleStatus to "off"
    end if
    
    -- Report on actions taken and current status
    set resultMessage to "Current Apple Music Playback Settings:\n"
    set resultMessage to resultMessage & "- Repeat: " & repeatStatus & "\n"
    set resultMessage to resultMessage & "- Shuffle: " & shuffleStatus
    
    if actionParam is not "get_status" then
      set resultMessage to resultMessage & "\n\nAction Performed: " & actionParam
      
      if actionParam is "set_repeat" or actionParam is "set_shuffle" then
        set resultMessage to resultMessage & " to " & valueParam
      end if
      
      -- For toggle actions, report the state change
      if actionParam is "toggle_repeat" then
        set resultMessage to resultMessage & "\nRepeat changed from "
        
        if initialSongRepeat is off then
          set resultMessage to resultMessage & "off"
        else if initialSongRepeat is one then
          set resultMessage to resultMessage & "one track"
        else if initialSongRepeat is all then
          set resultMessage to resultMessage & "all tracks"
        end if
        
        set resultMessage to resultMessage & " to " & repeatStatus
      else if actionParam is "toggle_shuffle" then
        set resultMessage to resultMessage & "\nShuffle changed from "
        
        if initialShuffleEnabled then
          set resultMessage to resultMessage & "on"
        else
          set resultMessage to resultMessage & "off"
        end if
        
        set resultMessage to resultMessage & " to "
        
        if currentShuffleEnabled then
          set resultMessage to resultMessage & "on"
        else
          set resultMessage to resultMessage & "off"
        end if
      end if
    end if
    
    -- Get current track info if playing
    if player state is playing or player state is paused then
      set trackName to name of current track
      set artistName to artist of current track
      set playerStateText to player state as text
      
      set resultMessage to resultMessage & "\n\nCurrently " & playerStateText & ": " & trackName & " by " & artistName
    end if
    
    return resultMessage
    
  on error errMsg number errNum
    return "Error controlling Music settings (" & errNum & "): " & errMsg
  end try
end tell
```
