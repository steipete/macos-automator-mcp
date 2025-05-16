---
id: things_create_area
title: Create Area in Things
description: Use AppleScript to create a new area in Things app
author: steipete
language: applescript
tags: 'things, productivity, task management, area, organization'
keywords:
  - areas
  - categories
  - organization
  - containers
  - hierarchy
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer/things
---

# Create Area in Things

This script creates a new area in Things, which is a top-level organizational unit for grouping related projects and to-dos.

## Example Usage

```applescript
-- Create a simple area
tell application "Things3"
    set newArea to make new area with properties {name:"Personal"}
end tell

-- Create an area with additional properties
tell application "Things3"
    set newArea to make new area with properties {name:"Work", tags:{"Job", "Priority"}}
end tell
```

## Script Details

The script uses Things' AppleScript support to create an area with customizable properties.

```applescript
-- Create an area in Things with optional properties
on createThingsArea(areaName, tagNames)
    set areaProperties to {name:areaName}
    
    -- Add tags if provided
    if tagNames is not equal to "" then
        set AppleScript's text item delimiters to ","
        set tagList to text items of tagNames
        set AppleScript's text item delimiters to ""
        set areaProperties to areaProperties & {tags:tagList}
    end if
    
    tell application "Things3"
        try
            -- Check if area already exists
            set existingAreas to areas where name is areaName
            if (count of existingAreas) > 0 then
                return "Area '" & areaName & "' already exists."
            else
                set newArea to make new area with properties areaProperties
                return "Created new area: " & areaName
            end if
        on error errMsg
            return "Error creating area: " & errMsg
        end try
    end tell
end createThingsArea

-- Example call
createThingsArea("--MCP_ARG_1", "--MCP_ARG_2")
```

## Notes

- Things 3 must be installed on the system.
- Areas are top-level containers in Things that can hold both projects and to-dos.
- For `tagNames`, provide comma-separated tags, e.g., "Personal,Home,Priority".
- If tags don't exist, they will be created automatically.
- The script checks if an area with the same name already exists to avoid duplicates.
- Areas cannot be nested within other areas - they are always at the top level.
- Areas are useful for broad categories like "Work", "Personal", "Health", etc.
- You can view areas in the sidebar of the Things app.
