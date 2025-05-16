---
id: things_get_todos
title: Get To-Dos from Things
description: Use AppleScript to retrieve to-dos from Things app with filtering options
author: steipete
language: applescript
tags: 'things, productivity, task management, to-do, filters'
keywords:
  - filtering
  - query
  - todo-list
  - properties
  - fetch
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer/things
---

# Get To-Dos from Things

This script retrieves to-dos from Things with various filtering options such as list type, tag, and project.

## Example Usage

```applescript
-- Get all to-dos
tell application "Things3"
    set allToDos to to dos
    log (count of allToDos) & " to-dos found"
end tell

-- Get to-dos from a specific list
tell application "Things3"
    set todayToDos to to dos of list "Today"
    log (count of todayToDos) & " to-dos for today"
end tell

-- Get to-dos with a specific tag
tell application "Things3"
    set workToDos to to dos where tag names contains "Work"
    log (count of workToDos) & " work-related to-dos"
end tell
```

## Script Details

The script uses Things' AppleScript support to retrieve to-dos with various filtering options.

```applescript
-- Get to-dos from Things with filtering options
on getThingsToDos(listName, tagFilter, projectName, statusFilter)
    tell application "Things3"
        -- Start with an empty filter
        set theFilter to {}
        
        -- Build filter based on parameters
        if tagFilter is not equal to "" then
            set theFilter to theFilter & {tag names contains tagFilter}
        end if
        
        if projectName is not equal to "" then
            set theFilter to theFilter & {project is projectName}
        end if
        
        if statusFilter is not equal to "" then
            if statusFilter is "completed" then
                set theFilter to theFilter & {status is completed}
            else if statusFilter is "canceled" then
                set theFilter to theFilter & {status is canceled}
            else if statusFilter is "open" then
                set theFilter to theFilter & {status is open}
            end if
        end if
        
        -- Get to-dos with applied filters
        if listName is not equal to "" then
            -- Get from a specific list with filters
            if (count of theFilter) > 0 then
                set theToDos to to dos of list listName where theFilter
            else
                set theToDos to to dos of list listName
            end if
        else
            -- Get from all lists with filters
            if (count of theFilter) > 0 then
                set theToDos to to dos where theFilter
            else
                set theToDos to to dos
            end if
        end if
        
        -- Build result as a list of records
        set todoList to {}
        repeat with t in theToDos
            set todoProperties to {id:id of t, name:name of t, status:status of t}
            
            -- Add optional properties if they exist
            if notes of t is not "" then
                set todoProperties to todoProperties & {notes:notes of t}
            end if
            
            if due date of t is not missing value then
                set todoProperties to todoProperties & {due_date:due date of t}
            end if
            
            if project of t is not missing value then
                set todoProperties to todoProperties & {project:name of project of t}
            end if
            
            if area of t is not missing value then
                set todoProperties to todoProperties & {area:name of area of t}
            end if
            
            if (count of tags of t) > 0 then
                set tagNames to {}
                repeat with aTag in tags of t
                    set end of tagNames to name of aTag
                end repeat
                set todoProperties to todoProperties & {tags:tagNames}
            end if
            
            set end of todoList to todoProperties
        end repeat
        
        return todoList
    end tell
end getThingsToDos

-- Example call
getThingsToDos("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3", "--MCP_ARG_4")
```

## Notes

- Things 3 must be installed on the system.
- For `listName`, valid options include "Inbox", "Today", "Upcoming", "Anytime", "Someday", or the name of a custom list.
- For `tagFilter`, provide a single tag name to filter by.
- For `projectName`, provide the name of a project to filter by.
- For `statusFilter`, valid options are "completed", "canceled", or "open".
- The script returns a list of to-do objects with their properties.
- You can leave any parameter empty to skip that filter.
- The script will return all matching to-dos based on the applied filters.
