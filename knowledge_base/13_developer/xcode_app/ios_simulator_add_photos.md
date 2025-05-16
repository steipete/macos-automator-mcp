---
title: 'iOS Simulator: Add Photos to Library'
category: 13_developer
id: ios_simulator_add_photos
description: Adds photos and videos to an iOS Simulator's Photo Library.
keywords:
  - iOS Simulator
  - Xcode
  - photos
  - images
  - videos
  - media
  - Photos app
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Path to media file or directory as 'mediaPath', optional device identifier as
  'deviceIdentifier' (defaults to 'booted'), and optional boolean to process
  directories recursively as 'recursive' (default is false).
notes: |
  - Adds photos, images, and videos to simulator's Photos app
  - Supports most common image formats (JPEG, PNG, GIF, HEIC)
  - Supports video formats (MP4, MOV, M4V)
  - Can add a single file or entire directory of media
  - Useful for testing apps that use photo picking, camera roll, etc.
  - The simulator must be booted for this to work
---

```applescript
--MCP_INPUT:mediaPath
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:recursive

on addPhotosToSimulatorLibrary(mediaPath, deviceIdentifier, recursive)
  if mediaPath is missing value or mediaPath is "" then
    return "error: Media path not provided. Specify a path to an image/video file or a directory containing media files."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default recursive to false if not specified
  if recursive is missing value or recursive is "" then
    set recursive to false
  else if recursive is "true" then
    set recursive to true
  end if
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Check if the media path exists
    set checkPathCmd to "test -e " & quoted form of mediaPath & " && echo 'exists' || echo 'not found'"
    set pathExistsResult to do shell script checkPathCmd
    
    if pathExistsResult is "not found" then
      return "error: Media path not found: " & mediaPath
    end if
    
    -- Determine if it's a file or directory
    set fileTypeCmd to "test -d " & quoted form of mediaPath & " && echo 'directory' || echo 'file'"
    set fileType to do shell script fileTypeCmd
    
    -- Variable to track successful and failed additions
    set successCount to 0
    set failureCount to 0
    set filesList to {}
    
    if fileType is "file" then
      -- Add a single file
      set filesList to {mediaPath}
    else
      -- It's a directory, get list of files
      set findCmd to "find " & quoted form of mediaPath
      if not recursive then
        set findCmd to findCmd & " -maxdepth 1"
      end if
      
      -- Look for common media file extensions
      set findCmd to findCmd & " -type f \\( -iname \"*.jpg\" -o -iname \"*.jpeg\" -o -iname \"*.png\" -o -iname \"*.gif\" -o -iname \"*.heic\" -o -iname \"*.mp4\" -o -iname \"*.mov\" -o -iname \"*.m4v\" \\) -print"
      
      set findOutput to do shell script findCmd
      
      if findOutput is not "" then
        -- Convert multiline output to AppleScript list
        set AppleScript's text item delimiters to return
        set filesList to text items of findOutput
        set AppleScript's text item delimiters to ""
      else
        return "No media files found in " & mediaPath
      end if
    end if
    
    -- Process each file
    set processedList to ""
    repeat with mediaFile in filesList
      try
        set addMediaCmd to "xcrun simctl addmedia " & quoted form of deviceIdentifier & " " & quoted form of mediaFile
        do shell script addMediaCmd
        set successCount to successCount + 1
        
        -- Add to list of processed files (only include the filename to keep output manageable)
        set fileName to do shell script "basename " & quoted form of mediaFile
        set processedList to processedList & "- " & fileName & " ✓" & return
      on error errMsg
        set failureCount to failureCount + 1
        set fileName to do shell script "basename " & quoted form of mediaFile
        set processedList to processedList & "- " & fileName & " ✗ (" & errMsg & ")" & return
      end try
    end repeat
    
    -- Check if any files were processed
    if (count of filesList) is 0 then
      return "No media files were found to add to the simulator."
    end if
    
    -- Return result
    return "Added media to " & deviceIdentifier & " simulator.
Successfully added: " & successCount & " files
Failed to add: " & failureCount & " files

Processed files:
" & processedList & "

The photos should now be available in the Photos app on the simulator."
  on error errMsg number errNum
    return "error (" & errNum & ") adding photos to simulator: " & errMsg
  end try
end addPhotosToSimulatorLibrary

return my addPhotosToSimulatorLibrary("--MCP_INPUT:mediaPath", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:recursive")
```
