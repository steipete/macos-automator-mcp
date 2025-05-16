---
title: "Audio Hijack: Recordings Management"
category: "08_creative_and_document_apps"
id: audio_hijack_recordings_management
description: "Manage recordings in Audio Hijack including listing recent recordings, getting recording info, and post-processing actions."
keywords: ["Audio Hijack", "recordings", "management", "list", "info", "post-processing", "audio files"]
language: applescript
parameters: |
  - action (required): Action to perform - "list", "info", "open_folder", "recent"
  - recording_id (optional): ID of the recording to manage (required for 'info' action)
  - limit (optional): Number of recent recordings to list (default: 10, for 'list' and 'recent' actions)
notes: |
  - Audio Hijack must be installed on the system.
  - The "list" action shows all recordings with their details.
  - The "info" action provides detailed information about a specific recording.
  - The "open_folder" action opens the Recordings folder in Finder.
  - The "recent" action lists only the most recent recordings.
  - Audio Hijack's recordings management varies by version; this script is designed for Audio Hijack 3+.
---

Manage recordings in Audio Hijack.

```applescript
-- Get parameters
set actionParam to "--MCP_INPUT:action"
if actionParam is "" or actionParam is "--MCP_INPUT:action" then
  set actionParam to "recent" -- Default action: show recent recordings
end if

set recordingIdParam to "--MCP_INPUT:recording_id"
if recordingIdParam is "" or recordingIdParam is "--MCP_INPUT:recording_id" then
  set recordingIdParam to "" -- Will be validated later if needed
end if

set limitParam to "--MCP_INPUT:limit"
if limitParam is "" or limitParam is "--MCP_INPUT:limit" then
  set limitParam to "10" -- Default: show 10 recent recordings
end if

-- Validate action parameter
set validActions to {"list", "info", "open_folder", "recent"}
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
if actionParam is "info" and recordingIdParam is "" then
  return "Error: The 'info' action requires a recording_id parameter."
end if

-- Validate limit parameter
try
  set limitNumber to limitParam as number
  if limitNumber < 1 then
    set limitNumber to 10
  end if
on error
  set limitNumber to 10
end try

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
if actionParam is "open_folder" then
  -- Open the recordings folder in Finder
  try
    tell application "Audio Hijack"
      -- Get the recordings folder path
      set recordingsFolder to (get recordings folder)
      
      -- Open the folder in Finder
      tell application "Finder"
        open POSIX file recordingsFolder
        activate
      end tell
      
      return "Opened Audio Hijack recordings folder: " & recordingsFolder
    end tell
  on error errMsg number errNum
    return "Error opening recordings folder (" & errNum & "): " & errMsg
  end try
  
else
  tell application "Audio Hijack"
    try
      if actionParam is "list" or actionParam is "recent" then
        -- List all recordings or recent recordings
        set recordingsList to recordings
        
        if (count of recordingsList) is 0 then
          return "No recordings found in Audio Hijack."
        end if
        
        -- For "recent" action, sort by date and limit results
        if actionParam is "recent" then
          -- Sort recordings by date (most recent first)
          -- Note: This assumes recordings can be sorted by date
          try
            set sortedRecordings to {}
            repeat with rec in recordingsList
              set end of sortedRecordings to rec
            end repeat
            
            -- Sort the recordings (most recent first)
            repeat with i from 1 to (count of sortedRecordings)
              repeat with j from 1 to (count of sortedRecordings) - i
                try
                  set rec1 to item j of sortedRecordings
                  set rec2 to item (j + 1) of sortedRecordings
                  set date1 to date of rec1
                  set date2 to date of rec2
                  
                  if date1 < date2 then
                    -- Swap the items
                    set item j of sortedRecordings to rec2
                    set item (j + 1) of sortedRecordings to rec1
                  end if
                on error
                  -- Error comparing dates, skip this comparison
                end try
              end repeat
            end repeat
            
            -- Limit to the requested number of recent recordings
            if (count of sortedRecordings) > limitNumber then
              set recordingsList to items 1 thru limitNumber of sortedRecordings
            else
              set recordingsList to sortedRecordings
            end if
          on error sortErr
            -- If sorting fails, just use the original list
            if (count of recordingsList) > limitNumber then
              set recordingsList to items 1 thru limitNumber of recordingsList
            end if
          end try
        end if
        
        -- Format the recording list
        set resultText to "Audio Hijack Recordings:" & return & return
        
        set recCounter to 1
        repeat with theRecording in recordingsList
          -- Get basic recording information
          set recId to id of theRecording
          set recName to name of theRecording
          
          -- Try to get additional info
          try
            set recDate to date of theRecording
            set formattedDate to my formatDateTime(recDate)
          on error
            set formattedDate to "Unknown date"
          end try
          
          try
            set recPath to path of theRecording
          on error
            set recPath to "Path not available"
          end try
          
          try
            set recSize to size of theRecording
            set formattedSize to my formatFileSize(recSize)
          on error
            set formattedSize to "Size not available"
          end try
          
          -- Add recording info to result
          set resultText to resultText & recCounter & ". " & recName & return
          set resultText to resultText & "   ID: " & recId & return
          set resultText to resultText & "   Date: " & formattedDate & return
          set resultText to resultText & "   Size: " & formattedSize & return
          set resultText to resultText & "   Path: " & recPath & return & return
          
          set recCounter to recCounter + 1
        end repeat
        
        return resultText
        
      else if actionParam is "info" then
        -- Get detailed info for a specific recording
        try
          -- Find the recording by ID
          set theRecording to first recording whose id is recordingIdParam
          
          -- Get all available information
          set recName to name of theRecording
          set recId to id of theRecording
          
          set recInfo to "Recording Information:" & return & return
          set recInfo to recInfo & "Name: " & recName & return
          set recInfo to recInfo & "ID: " & recId & return
          
          -- Try to get additional details
          try
            set recDate to date of theRecording
            set recInfo to recInfo & "Date: " & my formatDateTime(recDate) & return
          on error
            -- Skip if date not available
          end try
          
          try
            set recPath to path of theRecording
            set recInfo to recInfo & "File Path: " & recPath & return
          on error
            -- Skip if path not available
          end try
          
          try
            set recSize to size of theRecording
            set recInfo to recInfo & "File Size: " & my formatFileSize(recSize) & return
          on error
            -- Skip if size not available
          end try
          
          try
            set recDuration to duration of theRecording
            set recInfo to recInfo & "Duration: " & my formatDuration(recDuration) & return
          on error
            -- Skip if duration not available
          end try
          
          try
            set recFormat to format of theRecording
            set recInfo to recInfo & "Format: " & recFormat & return
          on error
            -- Skip if format not available
          end try
          
          try
            set recSession to session of theRecording
            set recInfo to recInfo & "Session: " & recSession & return
          on error
            -- Skip if session not available
          end try
          
          -- Add commands to manage the recording
          set recInfo to recInfo & return & "Commands to manage this recording:" & return
          set recInfo to recInfo & "- To open in Finder: tell application \"Finder\" to open POSIX file \"" & recPath & "\"" & return
          set recInfo to recInfo & "- To play: tell application \"QuickTime Player\" to open POSIX file \"" & recPath & "\"" & return
          
          return recInfo
          
        on error errMsg number errNum
          if errNum is -1728 then
            return "Error: Recording with ID '" & recordingIdParam & "' not found."
          else
            return "Error getting recording info (" & errNum & "): " & errMsg
          end if
        end try
      end if
      
    on error errMsg number errNum
      return "Error managing recordings (" & errNum & "): " & errMsg
    end try
  end tell
end if

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

-- Helper function to pad numbers with leading zero
on padNumber(num)
  set numText to num as text
  if (count numText) < 2 then
    set numText to "0" & numText
  end if
  return numText
end padNumber

-- Helper function to format file size
on formatFileSize(sizeInBytes)
  if sizeInBytes < 1024 then
    return sizeInBytes & " bytes"
  else if sizeInBytes < (1024 * 1024) then
    set sizeInKB to sizeInBytes / 1024
    set sizeInKB to round (sizeInKB * 10) / 10
    return sizeInKB & " KB"
  else if sizeInBytes < (1024 * 1024 * 1024) then
    set sizeInMB to sizeInBytes / (1024 * 1024)
    set sizeInMB to round (sizeInMB * 10) / 10
    return sizeInMB & " MB"
  else
    set sizeInGB to sizeInBytes / (1024 * 1024 * 1024)
    set sizeInGB to round (sizeInGB * 10) / 10
    return sizeInGB & " GB"
  end if
end formatFileSize

-- Helper function to format duration
on formatDuration(durationInSeconds)
  set hours to durationInSeconds div 3600
  set minutes to (durationInSeconds mod 3600) div 60
  set seconds to durationInSeconds mod 60
  
  if hours > 0 then
    return hours & ":" & my padNumber(minutes) & ":" & my padNumber(seconds)
  else
    return minutes & ":" & my padNumber(seconds)
  end if
end formatDuration
```