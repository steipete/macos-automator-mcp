---
title: 'Finder: Organize Files by Type'
category: 05_files/file_operations_finder
id: finder_organize_files_by_type
description: >-
  Organizes files in a folder by their file type, moving them into type-specific
  subfolders.
keywords:
  - Finder
  - organize files
  - file sorting
  - file management
  - categorize files
language: applescript
argumentsPrompt: Enter the folder path to organize
notes: >-
  Organizes files by type (images, documents, audio, video, etc.) into
  subfolders. The source folder must exist.
---

```applescript
on run {sourcePath}
  try
    -- Handle placeholder substitution
    if sourcePath is "" or sourcePath is missing value then
      set sourcePath to "--MCP_INPUT:sourcePath"
    end if
    
    -- Verify source path format
    if sourcePath does not start with "/" then
      return "Error: Source path must be a valid absolute POSIX path starting with /"
    end if
    
    -- Check if source directory exists
    tell application "System Events"
      if not (exists folder (POSIX file sourcePath as string)) then
        return "Error: Source directory does not exist: " & sourcePath
      end if
    end tell
    
    -- Begin organizing files
    tell application "Finder"
      -- Convert POSIX path to Finder-friendly path
      set sourceFolder to POSIX file sourcePath as alias
      
      -- Get all files in the source folder (not in subfolders)
      set allFiles to files of folder sourceFolder
      
      -- Define category folders
      set categories to {¬
        {name:"Images", extensions:{"jpg", "jpeg", "png", "gif", "tiff", "bmp", "webp", "heic"}}, ¬
        {name:"Documents", extensions:{"pdf", "doc", "docx", "txt", "rtf", "pages", "key", "numbers", "csv", "xls", "xlsx", "ppt", "pptx"}}, ¬
        {name:"Audio", extensions:{"mp3", "aac", "wav", "flac", "m4a", "ogg", "aiff", "wma"}}, ¬
        {name:"Video", extensions:{"mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"}}, ¬
        {name:"Archives", extensions:{"zip", "rar", "7z", "tar", "gz", "bz2", "dmg", "iso"}}, ¬
        {name:"Code", extensions:{"html", "css", "js", "php", "py", "java", "c", "cpp", "h", "swift", "rb", "pl", "sh", "json", "xml"}}¬
      }
      
      -- Create category folders if they don't exist
      repeat with category in categories
        set categoryName to name of category
        
        if not (exists folder categoryName of folder sourceFolder) then
          make new folder at sourceFolder with properties {name:categoryName}
        end if
      end repeat
      
      -- Create an "Other" folder for uncategorized files
      if not (exists folder "Other" of folder sourceFolder) then
        make new folder at sourceFolder with properties {name:"Other"}
      end if
      
      -- Track statistics
      set totalFiles to count of allFiles
      set movedFiles to 0
      set categoryStats to {}
      
      -- Process each file
      repeat with currentFile in allFiles
        set fileName to name of currentFile
        set fileExtension to ""
        
        -- Extract file extension
        if fileName contains "." then
          set fileExtension to text ((offset of "." in fileName) + 1) thru (length of fileName) of fileName
          set fileExtension to (do shell script "echo " & quoted form of fileExtension & " | tr '[:upper:]' '[:lower:]'") -- Convert to lowercase
        end if
        
        -- Determine category for this file
        set targetFolder to folder "Other" of folder sourceFolder
        
        repeat with category in categories
          set categoryName to name of category
          set categoryExtensions to extensions of category
          
          if categoryExtensions contains fileExtension then
            set targetFolder to folder categoryName of folder sourceFolder
            
            -- Update category stats
            set categoryCounter to 0
            set categoryFound to false
            
            repeat with statItem in categoryStats
              if item 1 of statItem is categoryName then
                set categoryCounter to item 2 of statItem
                set item 2 of statItem to categoryCounter + 1
                set categoryFound to true
                exit repeat
              end if
            end repeat
            
            if not categoryFound then
              set end of categoryStats to {categoryName, 1}
            end if
            
            exit repeat
          end if
        end repeat
        
        -- Move the file
        move currentFile to targetFolder
        set movedFiles to movedFiles + 1
      end repeat
      
      -- Generate report
      set reportText to "File Organization Complete!" & return & return
      set reportText to reportText & "Source folder: " & sourcePath & return
      set reportText to reportText & "Files processed: " & totalFiles & return & return
      
      if (count of categoryStats) > 0 then
        set reportText to reportText & "Files by category:" & return
        
        repeat with statItem in categoryStats
          set reportText to reportText & "- " & item 1 of statItem & ": " & item 2 of statItem & " files" & return
        end repeat
      end if
      
      return reportText
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to organize files - " & errMsg
  end try
end run
```
END_TIP
