---
title: 'iOS Simulator: Record Screen Video'
category: 13_developer
id: ios_simulator_record_video
description: Records a video of an iOS simulator screen for a specified duration.
keywords:
  - iOS Simulator
  - Xcode
  - record
  - video
  - screen capture
  - developer
  - iOS
  - iPadOS
  - mp4
language: applescript
isComplex: true
argumentsPrompt: >-
  Output path as 'outputPath' (where to save the MP4 video), record duration in
  seconds as 'recordDuration' (default 10 seconds), and optional device
  identifier as 'deviceIdentifier' (defaults to 'booted').
notes: |
  - Records simulator screen activity to an MP4 video file
  - Can specify recording duration in seconds
  - Uses xcrun simctl io to perform the recording
  - Works with currently booted device or specific device by identifier
  - Useful for creating app demos or screen recordings for documentation
  - The Simulator app must be running with a booted device
---

```applescript
--MCP_INPUT:outputPath
--MCP_INPUT:recordDuration
--MCP_INPUT:deviceIdentifier

on recordSimulatorVideo(outputPath, recordDuration, deviceIdentifier)
  if outputPath is missing value or outputPath is "" then
    return "error: Output path not provided. Specify where to save the MP4 video file."
  end if
  
  -- Default duration to 10 seconds if not specified
  if recordDuration is missing value or recordDuration is "" then
    set recordDuration to 10
  else
    try
      set recordDuration to recordDuration as number
    on error
      set recordDuration to 10
    end try
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  try
    -- Ensure output path ends with .mp4
    if not (outputPath ends with ".mp4") then
      set outputPath to outputPath & ".mp4"
    end if
    
    -- Check if file already exists
    set checkFileCmd to "test -f " & quoted form of outputPath & " && echo 'exists' || echo 'not found'"
    set fileExistsResult to do shell script checkFileCmd
    
    if fileExistsResult is "exists" then
      -- File exists, so we'll add a timestamp to make it unique
      set timeStamp to do shell script "date +%Y%m%d_%H%M%S"
      set outputPathBase to text 1 thru ((offset of ".mp4" in outputPath) - 1) of outputPath
      set outputPath to outputPathBase & "_" & timeStamp & ".mp4"
    end if
    
    -- Create the parent directory if it doesn't exist
    set outputDir to do shell script "dirname " & quoted form of outputPath
    do shell script "mkdir -p " & quoted form of outputDir
    
    -- Start recording - using tee so we can capture output while it's running
    set recordCmd to "xcrun simctl io " & quoted form of deviceIdentifier & " recordVideo --type=mp4 " & quoted form of outputPath & " | tee /dev/fd/1"
    
    -- Start recording in the background
    set recordPidCmd to "bash -c " & quoted form of ("{ " & recordCmd & " & } && echo $!")
    set recordPid to do shell script recordPidCmd
    
    -- Wait for specified duration
    delay recordDuration
    
    -- Stop recording by sending SIGINT to the process
    do shell script "kill -INT " & recordPid
    
    -- Wait a bit for the file to finish writing
    delay 1
    
    -- Check if the file was created successfully
    set checkResultCmd to "test -f " & quoted form of outputPath & " && echo 'success' || echo 'failed'"
    set recordResult to do shell script checkResultCmd
    
    if recordResult is "success" then
      set fileSize to do shell script "stat -f %z " & quoted form of outputPath
      set fileSizeKB to (fileSize as number) / 1024
      set fileSizeMB to fileSizeKB / 1024
      
      if fileSizeMB < 0.01 then
        return "Video recorded, but file size is very small (" & (round (fileSizeKB * 100)) / 100 & " KB).
The recording may be empty or corrupted.
Video saved to: " & outputPath
      else
        return "Successfully recorded " & recordDuration & " seconds of video.
Video saved to: " & outputPath & "
File size: " & (round (fileSizeMB * 100)) / 100 & " MB"
      end if
    else
      return "Failed to create video file at " & outputPath
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") recording simulator video: " & errMsg
  end try
end recordSimulatorVideo

return my recordSimulatorVideo("--MCP_INPUT:outputPath", "--MCP_INPUT:recordDuration", "--MCP_INPUT:deviceIdentifier")
```
