---
title: "Finder: Create New Folder"
category: "03_file_system_and_finder"
id: finder_create_new_folder
description: "Creates a new folder in a specified location using Finder."
keywords: ["Finder", "new folder", "create folder", "directory", "file management"]
language: applescript
argumentsPrompt: "Enter the folder path and name for the new folder"
notes: "Creates a new folder at the specified location. The parent directory must already exist."
---

```applescript
on run {parentPath, folderName}
  try
    -- Handle placeholder substitution
    if parentPath is "" or parentPath is missing value then
      set parentPath to "--MCP_INPUT:parentPath"
    end if
    
    if folderName is "" or folderName is missing value then
      set folderName to "--MCP_INPUT:folderName"
    end if
    
    -- Verify parent path format
    if parentPath does not start with "/" then
      return "Error: Parent path must be a valid absolute POSIX path starting with /"
    end if
    
    -- Check if parent directory exists
    tell application "System Events"
      if not (exists folder (POSIX file parentPath as string)) then
        return "Error: Parent directory does not exist: " & parentPath
      end if
    end tell
    
    -- Create the new folder using Finder
    tell application "Finder"
      -- Navigate to the parent directory
      set parentFolder to POSIX file parentPath as alias
      
      -- Check if folder already exists
      if exists folder folderName of folder parentFolder then
        return "A folder with this name already exists: " & folderName
      end if
      
      -- Create the new folder
      set newFolder to make new folder at parentFolder with properties {name:folderName}
      
      -- Get the full path of the new folder
      set newFolderPath to POSIX path of (newFolder as alias)
      
      return "Successfully created new folder: " & newFolderPath
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to create folder - " & errMsg
  end try
end run
```
END_TIP