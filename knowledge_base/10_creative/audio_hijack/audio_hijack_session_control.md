---
title: 'Audio Hijack: Session Control'
category: 10_creative
id: audio_hijack_session_control
description: >-
  Control Audio Hijack sessions including starting, stopping, and checking the
  status of recording sessions.
keywords:
  - Audio Hijack
  - recording
  - session
  - start
  - stop
  - audio capture
  - status
language: applescript
parameters: >
  - action (required): Action to perform - "start", "stop", "status", "list"

  - session_name (optional): Name of the session to control (required for
  start/stop/status actions)
notes: >
  - Audio Hijack must be installed on the system.

  - Sessions must be created in Audio Hijack before they can be controlled via
  AppleScript.

  - The "start" action starts recording for the specified session.

  - The "stop" action stops recording for the specified session.

  - The "status" action returns information about a specific session.

  - The "list" action lists all available sessions and their status.

  - Audio Hijack is a powerful tool for capturing audio from any application or
  input device on macOS.
---

Control Audio Hijack recording sessions.

```applescript
-- Get action parameter
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "list" -- Default action: list sessions
end if

-- Get session name parameter
set sessionNameParam to "--MCP_INPUT:session_name"
if sessionNameParam is "" or sessionNameParam is "--MCP_INPUT:session_name" then
  set sessionNameParam to "" -- Will be validated later if needed
end if

-- Validate action parameter
set validActions to {"start", "stop", "status", "list"}
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
if (actionParam is "start" or actionParam is "stop" or actionParam is "status") and sessionNameParam is "" then
  return "Error: The '" & actionParam & "' action requires a session_name parameter."
end if

-- Check if Audio Hijack is installed
tell application "System Events"
  set isAudioHijackInstalled to exists application process "Audio Hijack"
  
  if not isAudioHijackInstalled then
    try
      -- Check if it's installed but not running
      set appPath to "/Applications/Audio Hijack.app"
      set appExists to exists file (appPath as POSIX file)
      
      if not appExists then
        return "Error: Audio Hijack does not appear to be installed. Please install Audio Hijack before using this script."
      end if
    on error
      return "Error: Could not determine if Audio Hijack is installed."
    end try
  end if
end tell

-- Launch Audio Hijack if it's not running
tell application "Audio Hijack"
  if not running then
    activate
    delay 2 -- Give time for the application to launch
  end if
end tell

-- Execute the requested action
tell application "Audio Hijack"
  if actionParam is "list" then
    -- List all sessions
    try
      set sessionsList to sessions
      
      if (count of sessionsList) is 0 then
        return "No sessions found in Audio Hijack."
      end if
      
      set resultText to "Audio Hijack Sessions:" & return & return
      
      repeat with theSession in sessionsList
        set sessionName to name of theSession
        set isRecording to recording of theSession
        set isRunning to running of theSession
        
        -- Determine session status
        set statusText to "Stopped"
        if isRunning then
          if isRecording then
            set statusText to "Recording"
          else
            set statusText to "Running (not recording)"
          end if
        end if
        
        set resultText to resultText & "- " & sessionName & ": " & statusText & return
      end repeat
      
      return resultText
      
    on error errMsg number errNum
      return "Error listing sessions (" & errNum & "): " & errMsg
    end try
    
  else if actionParam is "start" then
    -- Start a session
    try
      -- Find the session by name
      set targetSession to first session whose name is sessionNameParam
      
      -- Check if the session is already recording
      if recording of targetSession then
        return "Session '" & sessionNameParam & "' is already recording."
      end if
      
      -- Start the session
      start targetSession
      
      -- Check if recording started successfully
      delay 1 -- Give time for the status to update
      
      if running of targetSession then
        if recording of targetSession then
          return "Successfully started recording session '" & sessionNameParam & "'."
        else
          return "Started session '" & sessionNameParam & "' but it is not in recording mode. Check the session configuration."
        end if
      else
        return "Failed to start session '" & sessionNameParam & "'. Check the session configuration."
      end if
      
    on error errMsg number errNum
      if errNum is -1728 then
        return "Error: Session '" & sessionNameParam & "' not found."
      else
        return "Error starting session (" & errNum & "): " & errMsg
      end if
    end try
    
  else if actionParam is "stop" then
    -- Stop a session
    try
      -- Find the session by name
      set targetSession to first session whose name is sessionNameParam
      
      -- Check if the session is running
      if not running of targetSession then
        return "Session '" & sessionNameParam & "' is not currently running."
      end if
      
      -- Stop the session
      stop targetSession
      
      -- Check if the session stopped successfully
      delay 1 -- Give time for the status to update
      
      if not running of targetSession then
        return "Successfully stopped session '" & sessionNameParam & "'."
      else
        return "Failed to stop session '" & sessionNameParam & "'. It may still be running."
      end if
      
    on error errMsg number errNum
      if errNum is -1728 then
        return "Error: Session '" & sessionNameParam & "' not found."
      else
        return "Error stopping session (" & errNum & "): " & errMsg
      end if
    end try
    
  else if actionParam is "status" then
    -- Get status of a session
    try
      -- Find the session by name
      set targetSession to first session whose name is sessionNameParam
      
      -- Get status information
      set isRunning to running of targetSession
      set isRecording to recording of targetSession
      
      -- Determine session status
      set statusText to "Stopped"
      if isRunning then
        if isRecording then
          set statusText to "Recording"
        else
          set statusText to "Running (not recording)"
        end if
      end if
      
      -- Get additional session information if available
      set sessionInfo to "Session: " & sessionNameParam & return
      set sessionInfo to sessionInfo & "Status: " & statusText & return
      
      try
        -- Try to get more detailed information about the session
        set sessionSource to source of targetSession as text
        set sessionInfo to sessionInfo & "Source: " & sessionSource & return
      on error
        -- If we can't get detailed info, just continue
      end try
      
      try
        -- Get recording destination if available
        if isRecording then
          set recordingPath to recording path of targetSession
          set sessionInfo to sessionInfo & "Recording Path: " & recordingPath & return
        end if
      on error
        -- If we can't get recording info, just continue
      end try
      
      return sessionInfo
      
    on error errMsg number errNum
      if errNum is -1728 then
        return "Error: Session '" & sessionNameParam & "' not found."
      else
        return "Error getting session status (" & errNum & "): " & errMsg
      end if
    end try
  end if
end tell
```
