---
title: 'Finder: Batch Rename Files'
category: 05_files/file_operations_finder
id: finder_batch_rename_files
description: Renames multiple files in a folder according to a pattern.
keywords:
  - Finder
  - batch rename
  - file renaming
  - filename
  - rename files
language: applescript
argumentsPrompt: Enter the folder path and the base name for renamed files
notes: >-
  Renames all files in a folder using a base name followed by a sequential
  number. Preserves file extensions.
---

```applescript
on run {folderPath, baseName}
  try
    -- Handle placeholder substitution
    if folderPath is "" or folderPath is missing value then
      set folderPath to "--MCP_INPUT:folderPath"
    end if
    
    if baseName is "" or baseName is missing value then
      set baseName to "--MCP_INPUT:baseName"
    end if
    
    -- Verify folder path format
    if folderPath does not start with "/" then
      return "Error: Folder path must be a valid absolute POSIX path starting with /"
    end if
    
    -- Check if folder exists
    tell application "System Events"
      if not (exists folder (POSIX file folderPath as string)) then
        return "Error: Folder does not exist: " & folderPath
      end if
    end tell
    
    -- Begin renaming files
    tell application "Finder"
      -- Convert POSIX path to Finder-friendly path
      set targetFolder to POSIX file folderPath as alias
      
      -- Get all files in the folder (not in subfolders)
      set allFiles to files of folder targetFolder
      
      if (count of allFiles) is 0 then
        return "No files found in the folder to rename."
      end if
      
      -- Track statistics
      set totalFiles to count of allFiles
      set renamedFiles to 0
      
      -- Process each file with a sequential number
      repeat with i from 1 to count of allFiles
        set currentFile to item i of allFiles
        set oldName to name of currentFile
        
        -- Extract file extension
        set fileExtension to ""
        if oldName contains "." then
          set extensionOffset to offset of "." in oldName
          if extensionOffset > 1 then
            set fileExtension to text extensionOffset thru (length of oldName) of oldName
          end if
        end if
        
        -- Create new name with sequential number
        set sequenceNumber to text -2 thru -1 of ("0" & i)
        set newName to baseName & " " & sequenceNumber
        
        -- Add the extension if it exists
        if fileExtension is not "" then
          set newName to newName & fileExtension
        end if
        
        -- Rename the file
        set name of currentFile to newName
        set renamedFiles to renamedFiles + 1
      end repeat
      
      -- Generate report
      set reportText to "Batch Rename Complete!" & return & return
      set reportText to reportText & "Folder: " & folderPath & return
      set reportText to reportText & "Base name used: " & baseName & return
      set reportText to reportText & "Files renamed: " & renamedFiles & " of " & totalFiles & return
      
      return reportText
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to rename files - " & errMsg
  end try
end run
```
END_TIP
