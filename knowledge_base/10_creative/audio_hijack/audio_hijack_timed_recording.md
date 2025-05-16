---
title: 'Audio Hijack: Timed Recording'
category: 10_creative/audio_hijack
id: audio_hijack_timed_recording
description: >-
  Start a timed recording in Audio Hijack that will automatically stop after a
  specified duration.
keywords:
  - Audio Hijack
  - recording
  - timed
  - duration
  - automatic
  - audio capture
  - scheduled
language: applescript
parameters: >
  - session_name (required): Name of the Audio Hijack session to use for
  recording

  - duration (required): Duration in minutes for the recording

  - output_name (optional): Name to use for the output file (default:
  timestamp-based)
notes: >
  - Audio Hijack must be installed on the system.

  - The specified session must exist in Audio Hijack.

  - This script starts a recording and then waits for the specified duration
  before stopping it.

  - The script will continue running until the recording completes.

  - For long recordings, consider using Audio Hijack's built-in scheduling
  feature instead.

  - Audio Hijack has extensive automation capabilities, especially for
  post-processing recordings.
---

Create a timed recording in Audio Hijack.

```applescript
-- Get parameters
set sessionNameParam to "--MCP_INPUT:session_name"
if sessionNameParam is "" or sessionNameParam is "--MCP_INPUT:session_name" then
  return "Error: No session name provided. Please specify an Audio Hijack session name."
end if

set durationParam to "--MCP_INPUT:duration"
if durationParam is "" or durationParam is "--MCP_INPUT:duration" then
  return "Error: No duration provided. Please specify a recording duration in minutes."
end if

set outputNameParam to "--MCP_INPUT:output_name"
if outputNameParam is "" or outputNameParam is "--MCP_INPUT:output_name" then
  -- Default to a timestamp-based name if none provided
  set currentDate to current date
  set outputNameParam to "Recording_" & (year of currentDate as text) & "-" & my padNumber(month of currentDate as integer) & "-" & my padNumber(day of currentDate) & "_" & my padNumber(hours of currentDate) & "-" & my padNumber(minutes of currentDate)
end if

-- Validate duration parameter
try
  set durationNumber to durationParam as number
  if durationNumber <= 0 then
    return "Error: Duration must be a positive number of minutes."
  end if
on error
  return "Error: Duration must be a number."
end try

-- Calculate duration in seconds for the wait
set durationSeconds to durationNumber * 60

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

-- Initialize progress reporting variables
set startTime to current date
set endTime to startTime + durationSeconds

tell application "Audio Hijack"
  -- Launch Audio Hijack if it's not running
  if not running then
    activate
    delay 2 -- Give time for the application to launch
  end if
  
  try
    -- Find the session by name
    set targetSession to first session whose name is sessionNameParam
    
    -- Check if the session is already recording
    if recording of targetSession then
      return "Error: Session '" & sessionNameParam & "' is already recording. Please stop it first."
    end if
    
    -- Start the recording
    start targetSession
    
    -- Check if recording started successfully
    delay 1 -- Give time for the status to update
    
    if not running of targetSession then
      return "Error: Failed to start session '" & sessionNameParam & "'. Check the session configuration."
    end if
    
    if not recording of targetSession then
      return "Error: Session started but is not recording. Check the session configuration."
    end if
    
    -- Session is now recording, display initial status
    set initialMessage to "Started recording with session '" & sessionNameParam & "'." & return
    set initialMessage to initialMessage & "Recording will run for " & durationNumber & " minutes." & return
    set initialMessage to initialMessage & "Start time: " & my formatDateTime(startTime) & return
    set initialMessage to initialMessage & "End time: " & my formatDateTime(endTime) & return & return
    set initialMessage to initialMessage & "Recording in progress. This script will automatically stop the recording after the specified duration."
    
    display dialog initialMessage buttons {"Cancel Recording", "Let It Run"} default button "Let It Run" with title "Audio Hijack Timed Recording"
    
    if button returned of result is "Cancel Recording" then
      -- User canceled, stop recording
      stop targetSession
      return "Recording canceled by user."
    end if
    
    -- Wait for the specified duration
    delay durationSeconds
    
    -- Stop the recording
    stop targetSession
    
    -- Verify the recording stopped
    delay 1
    
    if not running of targetSession then
      return "Successfully completed " & durationNumber & " minute recording with session '" & sessionNameParam & "'."
    else
      -- Try stopping one more time
      stop targetSession
      delay 1
      
      if not running of targetSession then
        return "Successfully completed " & durationNumber & " minute recording with session '" & sessionNameParam & "' (after retry)."
      else
        return "Warning: Recording duration completed, but session '" & sessionNameParam & "' appears to still be running. You may need to stop it manually."
      end if
    end if
    
  on error errMsg number errNum
    if errNum is -1728 then
      return "Error: Session '" & sessionNameParam & "' not found."
    else
      return "Error with timed recording (" & errNum & "): " & errMsg
    end if
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

-- Helper function to format date and time
on formatDateTime(theDate)
  set theYear to year of theDate
  set theMonth to my padNumber(month of theDate as integer)
  set theDay to my padNumber(day of theDate)
  set theHour to my padNumber(hours of theDate)
  set theMinute to my padNumber(minutes of theDate)
  set theSecond to my padNumber(seconds of theDate)
  
  return theYear & "-" & theMonth & "-" & theDay & " " & theHour & ":" & theMinute & ":" & theSecond
end formatDateTime
```
