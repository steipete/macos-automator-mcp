---
id: things_create_todo
title: Create To-Do in Things
description: Use AppleScript to create a new to-do in Things app
author: steipete
language: applescript
tags: 'things, productivity, task management, to-do'
keywords:
  - tasks
  - action items
  - inbox
  - scheduling
  - reminders
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer/things
---

# Create To-Do in Things

This script creates a new to-do in Things with various properties such as name, notes, due date, and more.

## Example Usage

```applescript
-- Create a simple to-do
tell application "Things3"
    set newToDo to make new to do with properties {name:"Buy groceries"}
end tell

-- Create a to-do with more properties
tell application "Things3"
    set newToDo to make new to do with properties {name:"Finish report", notes:"Include all quarterly data", due date:date "2024-05-20", tags:{"Work", "Important"}}
end tell
```

## Script Details

The script uses Things' AppleScript support to create a to-do with customizable properties.

```applescript
-- Create a to-do in Things with various properties
on createThingsToDo(todoName, todoNotes, todoDueDate, projectName, areaName, tagNames)
    set todoProperties to {name:todoName}
    
    -- Add optional properties if provided
    if todoNotes is not equal to "" then
        set todoProperties to todoProperties & {notes:todoNotes}
    end if
    
    -- Parse due date if provided
    if todoDueDate is not equal to "" then
        set todoProperties to todoProperties & {due date:date todoDueDate}
    end if
    
    -- Add to project if specified
    if projectName is not equal to "" then
        set todoProperties to todoProperties & {project:projectName}
    end if
    
    -- Add to area if specified
    if areaName is not equal to "" then
        set todoProperties to todoProperties & {area:areaName}
    end if
    
    -- Add tags if provided
    if tagNames is not equal to "" then
        set AppleScript's text item delimiters to ","
        set tagList to text items of tagNames
        set AppleScript's text item delimiters to ""
        set todoProperties to todoProperties & {tags:tagList}
    end if
    
    tell application "Things3"
        set newToDo to make new to do with properties todoProperties
        return id of newToDo
    end tell
end createThingsToDo

-- Example call
createThingsToDo("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3", "--MCP_ARG_4", "--MCP_ARG_5", "--MCP_ARG_6")
```

## Notes

- Things 3 must be installed on the system.
- For `dueDate`, use format "YYYY-MM-DD".
- For `tagNames`, provide comma-separated tags, e.g., "Work,Important,Urgent".
- If a project or area doesn't exist, the to-do will be created in the Inbox.
- If tags don't exist, they will be created automatically.
- The script returns the unique ID of the created to-do.
- The to-do will be created in the specified project if provided, otherwise in the specified area, or in the Inbox if neither is provided.
