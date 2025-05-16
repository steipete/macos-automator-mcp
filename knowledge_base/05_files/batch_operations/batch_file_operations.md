---
title: Batch File Operations
category: 05_files
id: batch_file_operations
description: >-
  Performs batch operations on multiple files including renaming, moving,
  copying, and applying metadata
keywords:
  - batch
  - file
  - rename
  - metadata
  - move
  - copy
  - Finder
  - System Events
language: applescript
notes: >-
  Requires Finder access permissions. Can be adapted for specific batch
  processing needs.
---

```applescript
-- Choose multiple files for batch processing
on chooseFiles()
  set theFiles to {}
  set dialogResult to (choose file with prompt "Select files for batch processing:" with multiple selections allowed)
  
  -- Convert results to a list of POSIX paths
  repeat with aFile in dialogResult
    set end of theFiles to POSIX path of aFile
  end repeat
  
  return theFiles
end chooseFiles

-- Choose a folder as target for operations
on chooseFolder()
  set theFolder to choose folder with prompt "Select target folder:"
  return POSIX path of theFolder
end chooseFolder

-- Batch file rename with pattern
-- Pattern can include [N] for sequence number and [NAME] for original name
on batchRename(fileList, pattern, startNumber)
  set renamedFiles to {}
  set counter to startNumber
  
  repeat with filePath in fileList
    -- Get file info
    set fullPath to filePath as string
    set {name:originalName, extension:fileExtension} to getFileInfo(fullPath)
    
    -- Create new name based on pattern
    set newName to pattern
    
    -- Replace [N] with sequence number (padded if needed)
    if newName contains "[N]" then
      set paddedNumber to text -3 thru -1 of ("000" & counter)
      set newName to my replaceText(newName, "[N]", paddedNumber)
    end if
    
    -- Replace [NAME] with original filename
    if newName contains "[NAME]" then
      set newName to my replaceText(newName, "[NAME]", originalName)
    end if
    
    -- Add extension if needed
    if fileExtension is not "" then
      set newName to newName & "." & fileExtension
    end if
    
    -- Get directory path
    set oldFolder to do shell script "dirname " & quoted form of fullPath
    set newPath to oldFolder & "/" & newName
    
    -- Rename file
    try
      do shell script "mv " & quoted form of fullPath & " " & quoted form of newPath
      set end of renamedFiles to newPath
    on error errMsg
      log "Error renaming " & fullPath & ": " & errMsg
    end try
    
    set counter to counter + 1
  end repeat
  
  return renamedFiles
end batchRename

-- Move files to target folder, optionally organizing by creation date
on batchMove(fileList, targetFolder, organizeByDate)
  set movedFiles to {}
  
  repeat with filePath in fileList
    set fullPath to filePath as string
    set fileName to do shell script "basename " & quoted form of fullPath
    
    -- Determine destination path
    if organizeByDate then
      -- Get file creation date
      set fileDate to do shell script "stat -f '%SB' -t '%Y-%m-%d' " & quoted form of fullPath
      set dateFolder to targetFolder & "/" & fileDate
      
      -- Create date folder if it doesn't exist
      do shell script "mkdir -p " & quoted form of dateFolder
      set destPath to dateFolder & "/" & fileName
    else
      set destPath to targetFolder & "/" & fileName
    end if
    
    -- Move the file
    try
      do shell script "mv " & quoted form of fullPath & " " & quoted form of destPath
      set end of movedFiles to destPath
    on error errMsg
      log "Error moving " & fullPath & ": " & errMsg
    end try
  end repeat
  
  return movedFiles
end batchMove

-- Apply metadata (tags, comments) to multiple files via Finder
on batchApplyMetadata(fileList, tagsToApply, commentText)
  tell application "Finder"
    repeat with filePath in fileList
      try
        set theFile to POSIX file filePath as alias
        
        -- Apply tags if provided
        if tagsToApply is not {} then
          set tags of theFile to tagsToApply
        end if
        
        -- Apply comment if provided
        if commentText is not "" then
          set comment of theFile to commentText
        end if
      on error errMsg
        log "Error applying metadata to " & filePath & ": " & errMsg
      end try
    end repeat
  end tell
  
  return "Metadata applied to " & (count of fileList) & " files"
end batchApplyMetadata

-- Convert image files to different format using sips
on batchConvertImages(fileList, targetFormat)
  set convertedFiles to {}
  
  repeat with filePath in fileList
    set fullPath to filePath as string
    
    -- Get file info
    set {name:baseName, extension:fileExtension} to getFileInfo(fullPath)
    set folderPath to do shell script "dirname " & quoted form of fullPath
    
    -- Ensure it's an image file
    set imageFormats to {"jpg", "jpeg", "png", "tiff", "gif", "bmp", "pdf"}
    if imageFormats does not contain fileExtension then
      log "Skipping non-image file: " & fullPath
    else
      -- Create output path
      set outputPath to folderPath & "/" & baseName & "." & targetFormat
      
      -- Convert using sips
      try
        do shell script "sips -s format " & targetFormat & " " & quoted form of fullPath & " --out " & quoted form of outputPath
        set end of convertedFiles to outputPath
      on error errMsg
        log "Error converting " & fullPath & ": " & errMsg
      end try
    end if
  end repeat
  
  return convertedFiles
end batchConvertImages

-- Helper function to get file info
on getFileInfo(filePath)
  set fileName to do shell script "basename " & quoted form of filePath
  
  -- Split filename and extension
  set tid to AppleScript's text item delimiters
  set AppleScript's text item delimiters to "."
  set nameParts to text items of fileName
  
  if (count of nameParts) > 1 then
    set baseName to items 1 thru -2 of nameParts as text
    set fileExtension to item -1 of nameParts
  else
    set baseName to fileName
    set fileExtension to ""
  end if
  
  -- Restore text item delimiters
  set AppleScript's text item delimiters to tid
  
  return {name:baseName, extension:fileExtension}
end getFileInfo

-- Helper function for text replacement
on replaceText(sourceText, searchString, replacementString)
  set tid to AppleScript's text item delimiters
  set AppleScript's text item delimiters to searchString
  set textItems to text items of sourceText
  set AppleScript's text item delimiters to replacementString
  set newText to textItems as text
  set AppleScript's text item delimiters to tid
  return newText
end replaceText

-- Example usage: Rename files with sequential numbering
on exampleBatchRename()
  set fileList to chooseFiles()
  set renamedFiles to batchRename(fileList, "Project_[N]", 1)
  return "Renamed " & (count of renamedFiles) & " files"
end exampleBatchRename

-- Example usage: Move and organize files by date
on exampleOrganizeByDate()
  set fileList to chooseFiles()
  set targetFolder to chooseFolder()
  set movedFiles to batchMove(fileList, targetFolder, true)
  return "Moved " & (count of movedFiles) & " files, organized by date"
end exampleOrganizeByDate

-- Example usage: Apply tags and comments
on exampleApplyMetadata()
  set fileList to chooseFiles()
  set tagsToApply to {"Important", "Project X"}
  set commentText to "Processed on " & (current date) as string
  return batchApplyMetadata(fileList, tagsToApply, commentText)
end exampleApplyMetadata

-- Example usage: Convert images to PNG format
on exampleConvertImages()
  set fileList to chooseFiles()
  set convertedFiles to batchConvertImages(fileList, "png")
  return "Converted " & (count of convertedFiles) & " images to PNG format"
end exampleConvertImages

-- Main menu to choose operation
on main()
  set operationList to {"Batch Rename", "Move and Organize by Date", "Apply Metadata", "Convert Images", "Cancel"}
  set selectedOperation to choose from list operationList with prompt "Select batch operation:" default items {"Batch Rename"}
  
  if selectedOperation is false then
    return "Operation cancelled"
  else
    set operation to item 1 of selectedOperation
    
    if operation is "Batch Rename" then
      return exampleBatchRename()
    else if operation is "Move and Organize by Date" then
      return exampleOrganizeByDate()
    else if operation is "Apply Metadata" then
      return exampleApplyMetadata()
    else if operation is "Convert Images" then
      return exampleConvertImages()
    else
      return "Operation cancelled"
    end if
  end if
end main

-- Run the main menu
main()
```

This script provides a comprehensive set of tools for batch file operations, including:

1. **Batch Renaming**: Rename multiple files using patterns with sequence numbers and original filenames.

2. **Batch Moving**: Move files to a target folder with optional organization by creation date.

3. **Metadata Application**: Apply macOS tags and comments to multiple files using Finder.

4. **Image Conversion**: Convert image files to different formats using the built-in `sips` command.

The script includes these key functions:

- `chooseFiles()`: Displays a file selection dialog allowing multiple file selection
- `chooseFolder()`: Prompts the user to select a target folder
- `batchRename(fileList, pattern, startNumber)`: Renames files using patterns like "Project_[N]" where [N] is replaced with sequence numbers
- `batchMove(fileList, targetFolder, organizeByDate)`: Moves files, optionally creating date-based subfolders
- `batchApplyMetadata(fileList, tagsToApply, commentText)`: Uses Finder to apply tags and comments
- `batchConvertImages(fileList, targetFormat)`: Converts images to a specified format

The script also includes a simple interactive menu to choose which operation to perform.

You can easily modify the individual functions to adapt to specific batch processing needs or extend the script with additional operations.
