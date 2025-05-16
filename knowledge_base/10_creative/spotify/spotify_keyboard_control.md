---
title: 'Spotify: Keyboard Shortcut Control'
category: 10_creative
id: spotify_keyboard_control
description: >-
  Control Spotify using keyboard shortcuts via System Events, useful for
  programming media keys or automating controls.
keywords:
  - Spotify
  - keyboard shortcuts
  - media keys
  - hotkeys
  - system events
  - play
  - pause
  - next
  - previous
language: applescript
parameters: >
  - action (required): The action to perform. Options: "playpause", "next",
  "previous", "volumeup", "volumedown", "mute"
notes: >
  - This script uses UI Automation to send keyboard shortcuts to Spotify.

  - Spotify must be running and in focus for the keyboard shortcuts to work.

  - This approach is useful when direct AppleScript commands aren't available or
  working.

  - May require Accessibility permissions for System Events to function
  properly.
---

Control Spotify using keyboard shortcuts via System Events.

```applescript
-- Get the action parameter or use a default value
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "playpause" -- Default action
end if

-- Map of actions to keyboard shortcuts
set validActions to {"playpause", "next", "previous", "volumeup", "volumedown", "mute"}

-- Check if action is valid
set isValidAction to false
repeat with validAction in validActions
  if actionParam is validAction then
    set isValidAction to true
    exit repeat
  end if
end repeat

if not isValidAction then
  return "Error: Invalid action specified. Valid options are: " & validActions
end if

-- Set up keyboard shortcuts for Spotify
set keyboardShortcuts to {¬
  playpause: {key: "p", using: {}}, ¬
  next: {key: "n", using: {}}, ¬
  previous: {key: "p", using: {option down}}, ¬
  volumeup: {key: "up arrow", using: {command down, option down}}, ¬
  volumedown: {key: "down arrow", using: {command down, option down}}, ¬
  mute: {key: "down arrow", using: {command down, option down, shift down}} ¬
}

tell application "Spotify"
  -- Check if Spotify is running
  if not running then
    return "Spotify is not running. Please launch it first."
  end if
  
  -- Make sure Spotify is active before sending keyboard shortcuts
  activate
  delay 0.5 -- Give time for Spotify to come to foreground
  
  -- Get the keyboard shortcut for the chosen action
  set chosenShortcut to item 1 of (get value of keyboardShortcuts's item actionParam)
  set shortcutKey to key of chosenShortcut
  set shortcutModifiers to using of chosenShortcut
  
  -- Send the keyboard shortcut to Spotify
  tell application "System Events"
    tell process "Spotify"
      set frontmost to true
      keystroke shortcutKey using shortcutModifiers
    end tell
  end tell
  
  -- Get current Spotify state for feedback
  delay 0.5 -- Allow time for action to complete
  
  set stateInfo to ""
  
  -- Get player state
  set playerState to player state as text
  set stateInfo to stateInfo & "Player State: " & playerState & "\n"
  
  -- Get track info if available
  if playerState is "playing" or playerState is "paused" then
    try
      set trackName to name of current track
      set artistName to artist of current track
      set stateInfo to stateInfo & "Current Track: " & trackName & "\n"
      set stateInfo to stateInfo & "Artist: " & artistName & "\n"
    on error
      set stateInfo to stateInfo & "Track info unavailable\n"
    end try
  end if
  
  -- Get volume
  try
    set volumeLevel to sound volume
    set stateInfo to stateInfo & "Volume: " & volumeLevel & "%\n"
  on error
    set stateInfo to stateInfo & "Volume info unavailable\n"
  end try
  
  -- Return completed action with state info
  return "Action '" & actionParam & "' sent to Spotify via keyboard shortcut.\n\nCurrent Status:\n" & stateInfo
end tell
```
