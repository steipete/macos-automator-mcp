---
title: Create New Folder on Desktop
description: Creates a new folder on the desktop with a specified name
keywords:
  - Finder
  - folder
  - create
  - new folder
  - desktop
  - make directory
language: applescript
id: finder_create_new_folder_desktop
argumentsPrompt: Provide a name for the new folder
category: 05_files
---

This script creates a new folder on the desktop with a specified name.

```applescript
-- Define folder name (can be replaced with --MCP_INPUT:folderName placeholder)
set folderName to "--MCP_INPUT:folderName" 

if folderName is missing value or folderName is "" then
  set folderName to "New Folder"
end if

tell application "Finder"
  -- Get reference to the desktop
  set desktopPath to path to desktop folder
  
  -- Create a new folder on the desktop
  try
    -- Check if folder already exists
    if exists folder folderName of desktopPath then
      return "Error: A folder named '" & folderName & "' already exists on the desktop."
    end if
    
    -- Create the new folder
    set newFolder to make new folder at desktopPath with properties {name:folderName}
    
    -- Return the path of the new folder
    return "Created folder: " & (POSIX path of (newFolder as alias))
  on error errMsg
    return "Error creating folder: " & errMsg
  end try
end tell
```

The script:
1. Takes a folder name as input (can be customized via `--MCP_INPUT:folderName`)
2. Checks if a folder with that name already exists
3. Creates the new folder on the desktop if it doesn't exist
4. Returns the path to the newly created folder or an error message

END_TIP
