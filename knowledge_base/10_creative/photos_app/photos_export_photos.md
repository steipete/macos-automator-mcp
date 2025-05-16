---
title: 'Photos: Export Selected Photos'
category: 10_creative
id: photos_export_photos
description: Exports selected photos from the Photos app to a specified location.
keywords:
  - Photos
  - export photos
  - save images
  - photo export
  - backup photos
language: applescript
argumentsPrompt: Enter the destination folder where photos should be exported
notes: >-
  Exports selected photos to the specified folder. Make sure to select the
  photos in Photos app before running this script.
---

```applescript
on run {exportFolder}
  tell application "Photos"
    try
      -- Handle placeholder substitution
      if exportFolder is "" or exportFolder is missing value then
        set exportFolder to "--MCP_INPUT:exportFolder"
      end if
      
      -- Verify export folder format
      if exportFolder does not start with "/" then
        return "Error: Export folder path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Convert to POSIX file
      set exportFolderPath to POSIX file exportFolder
      
      -- Check if folder exists, create it if necessary
      tell application "System Events"
        if not (exists folder exportFolderPath) then
          do shell script "mkdir -p " & quoted form of exportFolder
          delay 0.5
        end if
      end tell
      
      activate
      
      -- Get selected photos
      set selectedItems to selection
      
      -- Check if any photos are selected
      if (count of selectedItems) is 0 then
        return "No photos selected. Please select photos in the Photos app before running this script."
      end if
      
      -- Export the selected photos
      export selectedItems to exportFolderPath
      
      -- Get filenames of exported photos for the report
      set photoInfo to {}
      repeat with i from 1 to count of selectedItems
        set currentPhoto to item i of selectedItems
        
        -- Get photo info
        set photoFilename to filename of currentPhoto
        set photoDate to date of currentPhoto as string
        
        set end of photoInfo to "Photo " & i & ": " & photoFilename & " (Date: " & photoDate & ")"
      end repeat
      
      -- Format output
      set AppleScript's text item delimiters to return
      set photoList to photoInfo as string
      set AppleScript's text item delimiters to ""
      
      return (count of selectedItems) & " photos exported to " & exportFolder & ":" & return & return & photoList
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to export photos - " & errMsg
    end try
  end tell
end run
```
END_TIP
