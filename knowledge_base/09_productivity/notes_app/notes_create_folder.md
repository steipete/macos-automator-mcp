---
title: 'Notes: Create New Folder'
category: 09_productivity/notes_app
id: notes_create_folder
description: Creates a new folder in the Notes app.
keywords:
  - Notes
  - create folder
  - note folder
  - organize notes
  - note management
language: applescript
argumentsPrompt: Enter the name for the new folder
notes: Creates a new folder in the Notes app with the specified name.
---

```applescript
on run {folderName}
  tell application "Notes"
    try
      -- Handle placeholder substitution
      if folderName is "" or folderName is missing value then
        set folderName to "--MCP_INPUT:folderName"
      end if
      
      -- Check if folder already exists
      if exists folder folderName then
        return "A folder named \"" & folderName & "\" already exists."
      end if
      
      -- Create the new folder
      make new folder with properties {name:folderName}
      
      return "Successfully created new Notes folder: " & folderName
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create folder - " & errMsg
    end try
  end tell
end run
```
END_TIP
