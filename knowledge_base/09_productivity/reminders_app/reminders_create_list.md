---
title: 'Reminders: Create New List'
category: 09_productivity/reminders_app
id: reminders_create_list
description: Creates a new list in the Reminders app.
keywords:
  - Reminders
  - create list
  - reminder list
  - to-do list
  - task list
language: applescript
argumentsPrompt: Enter the name for the new reminders list
notes: Creates a new list in the Reminders app with the specified name.
---

```applescript
on run {listName}
  tell application "Reminders"
    try
      -- Handle placeholder substitution
      if listName is "" or listName is missing value then
        set listName to "--MCP_INPUT:listName"
      end if
      
      -- Check if list already exists
      set existingLists to name of every list
      
      if existingLists contains listName then
        return "A list named \"" & listName & "\" already exists."
      end if
      
      -- Create the new list
      make new list with properties {name:listName}
      
      return "Successfully created new list: " & listName
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create list - " & errMsg
    end try
  end tell
end run
```
END_TIP
