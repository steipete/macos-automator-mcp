---
id: things_complete_todo
title: Complete To-Dos in Things
description: Use AppleScript to mark to-dos as completed in Things app
author: steipete
language: applescript
tags: things, productivity, task management, complete, done
keywords: [completion, task status, mark done, logbook, task tracking]
version: 1.0.0
updated: 2024-05-16
---

# Complete To-Dos in Things

This script marks to-dos as completed in Things, either by ID or by name.

## Example Usage

```applescript
-- Complete a to-do by ID
tell application "Things3"
    set theToDo to to do id "ABC123XYZ"
    set status of theToDo to completed
end tell

-- Complete a to-do by name (first match)
tell application "Things3"
    set theToDos to to dos where name is "Buy groceries"
    if (count of theToDos) > 0 then
        set status of item 1 of theToDos to completed
    end if
end tell

-- Complete all to-dos with a specific tag
tell application "Things3"
    set taggedToDos to to dos where tag names contains "Today"
    repeat with t in taggedToDos
        set status of t to completed
    end repeat
end tell
```

## Script Details

The script uses Things' AppleScript support to mark to-dos as completed using different identification methods.

```applescript
-- Complete a to-do in Things
on completeThingsToDo(todoIdentifier, identifierType)
    tell application "Things3"
        -- Determine how to find the to-do
        if identifierType is "id" then
            -- Find by ID (most reliable)
            try
                set theToDo to to do id todoIdentifier
                set status of theToDo to completed
                return "Completed to-do with ID: " & todoIdentifier
            on error
                return "Error: To-do with ID " & todoIdentifier & " not found"
            end try
            
        else if identifierType is "name" then
            -- Find by name (first exact match)
            set matchingToDos to to dos where name is todoIdentifier
            if (count of matchingToDos) > 0 then
                set status of item 1 of matchingToDos to completed
                return "Completed to-do: " & todoIdentifier
            else
                return "Error: No to-do found with name: " & todoIdentifier
            end if
            
        else if identifierType is "tag" then
            -- Complete all with tag
            set taggedToDos to to dos where tag names contains todoIdentifier
            set completedCount to 0
            
            repeat with t in taggedToDos
                set status of t to completed
                set completedCount to completedCount + 1
            end repeat
            
            return "Completed " & completedCount & " to-do(s) with tag: " & todoIdentifier
            
        else
            return "Error: Invalid identifier type. Use 'id', 'name', or 'tag'."
        end if
    end tell
end completeThingsToDo

-- Example call
completeThingsToDo("--MCP_ARG_1", "--MCP_ARG_2")
```

## Notes

- Things 3 must be installed on the system.
- For `identifierType`, use:
  - `id` to complete a to-do by its unique ID (most reliable)
  - `name` to complete the first to-do that exactly matches the name
  - `tag` to complete all to-dos with the specified tag
- When using name matching, only the first matching to-do will be completed if multiple have the same name.
- When using tag matching, all to-dos with the specified tag will be completed.
- The script returns a message indicating success or failure.
- Completed to-dos are moved to the Logbook in Things.