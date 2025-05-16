---
id: things_create_project
title: Create Project in Things
description: Use AppleScript to create a new project in Things app
author: steipete
language: applescript
tags: 'things, productivity, task management, project'
keywords:
  - projects
  - planning
  - due dates
  - deadlines
  - task grouping
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Create Project in Things

This script creates a new project in Things with various properties such as name, notes, due date, and more.

## Example Usage

```applescript
-- Create a simple project
tell application "Things3"
    set newProject to make new project with properties {name:"Redesign Website"}
end tell

-- Create a project with more properties
tell application "Things3"
    set newProject to make new project with properties {name:"Q2 Planning", notes:"Strategic planning for Q2", area:"Work", due date:date "2024-06-30", tags:{"Planning", "Q2"}}
end tell
```

## Script Details

The script uses Things' AppleScript support to create a project with customizable properties.

```applescript
-- Create a project in Things with various properties
on createThingsProject(projectName, projectNotes, projectDueDate, areaName, tagNames)
    set projectProperties to {name:projectName}
    
    -- Add optional properties if provided
    if projectNotes is not equal to "" then
        set projectProperties to projectProperties & {notes:projectNotes}
    end if
    
    -- Parse due date if provided
    if projectDueDate is not equal to "" then
        set projectProperties to projectProperties & {due date:date projectDueDate}
    end if
    
    -- Add to area if specified
    if areaName is not equal to "" then
        set projectProperties to projectProperties & {area:areaName}
    end if
    
    -- Add tags if provided
    if tagNames is not equal to "" then
        set AppleScript's text item delimiters to ","
        set tagList to text items of tagNames
        set AppleScript's text item delimiters to ""
        set projectProperties to projectProperties & {tags:tagList}
    end if
    
    tell application "Things3"
        set newProject to make new project with properties projectProperties
        return id of newProject
    end tell
end createThingsProject

-- Example call
createThingsProject("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3", "--MCP_ARG_4", "--MCP_ARG_5")
```

## Notes

- Things 3 must be installed on the system.
- For `dueDate`, use format "YYYY-MM-DD".
- For `tagNames`, provide comma-separated tags, e.g., "Planning,Q2,Important".
- If an area doesn't exist, the project will be created without an area.
- If tags don't exist, they will be created automatically.
- The script returns the unique ID of the created project.
- Projects can contain multiple to-dos and headings for organization.
- Projects can be set with start dates, deadlines, and even be marked as recurring.
