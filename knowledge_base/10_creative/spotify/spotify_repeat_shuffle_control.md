---
title: 'Spotify: Repeat and Shuffle Control'
category: 10_creative
id: spotify_repeat_shuffle_control
description: Control Spotify's repeat and shuffle settings via AppleScript.
keywords:
  - Spotify
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

  - value (optional): For set_repeat/set_shuffle actions - "on" or "off"
  (required when using these actions)
notes: >
  - Spotify must be running.

  - Toggle actions will switch between on and off states.

  - Set actions explicitly set the state to on or off.

  - Get_status returns the current repeat and shuffle states.

  - In some Spotify versions, these commands might not perform as expected due
  to API limitations.
---

Control Spotify's repeat and shuffle playback settings.

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
if (actionParam is "set_repeat" or actionParam is "set_shuffle") and (valueParam is not "on" and valueParam is not "off") then
  return "Error: When using set_repeat or set_shuffle, value parameter must be either 'on' or 'off'."
end if

tell application "Spotify"
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  try
    -- Store initial values for reporting
    set initialRepeatState to repeating
    set initialShuffleState to shuffling
    
    -- Execute the requested action
    if actionParam is "toggle_repeat" then
      set repeating to not repeating
    else if actionParam is "toggle_shuffle" then
      set shuffling to not shuffling
    else if actionParam is "set_repeat" then
      if valueParam is "on" then
        set repeating to true
      else
        set repeating to false
      end if
    else if actionParam is "set_shuffle" then
      if valueParam is "on" then
        set shuffling to true
      else
        set shuffling to false
      end if
    end if
    
    -- Get current states after any changes
    set currentRepeatState to repeating
    set currentShuffleState to shuffling
    
    -- Prepare status strings
    if currentRepeatState then
      set repeatStatus to "on"
    else
      set repeatStatus to "off"
    end if
    
    if currentShuffleState then
      set shuffleStatus to "on"
    else
      set shuffleStatus to "off"
    end if
    
    -- Report on actions taken and current status
    set resultMessage to "Current Spotify Playback Settings:\n"
    set resultMessage to resultMessage & "- Repeat: " & repeatStatus & "\n"
    set resultMessage to resultMessage & "- Shuffle: " & shuffleStatus
    
    if actionParam is not "get_status" then
      set resultMessage to resultMessage & "\n\nAction Performed: " & actionParam
      
      if actionParam is "set_repeat" or actionParam is "set_shuffle" then
        set resultMessage to resultMessage & " to " & valueParam
      end if
      
      -- For toggle actions, report the state change
      if actionParam is "toggle_repeat" then
        set resultMessage to resultMessage & "\nRepeat changed from " & (initialRepeatState as text) & " to " & (currentRepeatState as text)
      else if actionParam is "toggle_shuffle" then
        set resultMessage to resultMessage & "\nShuffle changed from " & (initialShuffleState as text) & " to " & (currentShuffleState as text)
      end if
    end if
    
    -- Get current track info if playing
    if player state is playing then
      set trackName to name of current track
      set artistName to artist of current track
      set resultMessage to resultMessage & "\n\nCurrently Playing: " & trackName & " by " & artistName
    end if
    
    return resultMessage
    
  on error errMsg number errNum
    return "Error controlling Spotify settings (" & errNum & "): " & errMsg
  end try
end tell
```
