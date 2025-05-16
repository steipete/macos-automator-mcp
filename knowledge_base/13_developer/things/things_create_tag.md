---
id: things_create_tag
title: Create and Manage Tags in Things
description: Use AppleScript to create and organize tags in Things app
author: steipete
language: applescript
tags: 'things, productivity, task management, tags, organization'
keywords:
  - tagging
  - categorization
  - filtering
  - hierarchy
  - metadata
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Create and Manage Tags in Things

This script creates and manages tags in Things, which are used to categorize and filter to-dos and projects.

## Example Usage

```applescript
-- Create a simple tag
tell application "Things3"
    set newTag to make new tag with properties {name:"Priority"}
end tell

-- Create a tag with a parent tag (hierarchical)
tell application "Things3"
    set parentTag to make new tag with properties {name:"Work"}
    set newTag to make new tag with properties {name:"Meetings", parent tag:parentTag}
end tell

-- Get all tags
tell application "Things3"
    set allTags to tags
    repeat with t in allTags
        log name of t
    end repeat
end tell
```

## Script Details

The script uses Things' AppleScript support to create and manage tags.

```applescript
-- Create and manage tags in Things
on manageThingsTags(operation, tagName, parentTagName)
    tell application "Things3"
        if operation is "create" then
            -- Create a new tag
            set tagProperties to {name:tagName}
            
            -- Add parent tag if specified
            if parentTagName is not equal to "" then
                try
                    set parentTags to tags where name is parentTagName
                    if (count of parentTags) > 0 then
                        set parentTag to item 1 of parentTags
                        set tagProperties to tagProperties & {parent tag:parentTag}
                    else
                        return "Error: Parent tag '" & parentTagName & "' not found."
                    end if
                on error errMsg
                    return "Error finding parent tag: " & errMsg
                end try
            end if
            
            -- Create the tag
            try
                -- Check if tag already exists
                set existingTags to tags where name is tagName
                if (count of existingTags) > 0 then
                    return "Tag '" & tagName & "' already exists."
                else
                    set newTag to make new tag with properties tagProperties
                    return "Created new tag: " & tagName
                end if
            on error errMsg
                return "Error creating tag: " & errMsg
            end try
            
        else if operation is "list" then
            -- List all tags or child tags of a parent
            if parentTagName is not equal to "" then
                try
                    set parentTags to tags where name is parentTagName
                    if (count of parentTags) > 0 then
                        set parentTag to item 1 of parentTags
                        set childTags to tags where parent tag is parentTag
                        
                        set tagList to {}
                        repeat with t in childTags
                            set end of tagList to name of t
                        end repeat
                        
                        return tagList
                    else
                        return "Error: Parent tag '" & parentTagName & "' not found."
                    end if
                on error errMsg
                    return "Error listing tags: " & errMsg
                end try
            else
                -- List all tags
                set tagList to {}
                repeat with t in tags
                    set end of tagList to name of t
                end repeat
                
                return tagList
            end if
            
        else if operation is "delete" then
            -- Delete a tag
            try
                set tagsToDelete to tags where name is tagName
                if (count of tagsToDelete) > 0 then
                    delete item 1 of tagsToDelete
                    return "Deleted tag: " & tagName
                else
                    return "Error: Tag '" & tagName & "' not found."
                end if
            on error errMsg
                return "Error deleting tag: " & errMsg
            end try
            
        else
            return "Error: Unsupported operation. Use 'create', 'list', or 'delete'."
        end if
    end tell
end manageThingsTags

-- Example call
manageThingsTags("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3")
```

## Notes

- Things 3 must be installed on the system.
- For `operation`, valid options are:
  - `create`: Create a new tag
  - `list`: List all tags or child tags of a parent
  - `delete`: Delete a tag
- Tags can be hierarchical, with parent and child relationships.
- When creating a tag with a parent, the parent tag must already exist.
- Tags are useful for categorizing to-dos across different areas and projects.
- Deleting a tag does not delete the to-dos or projects it's applied to.
- Tags appear in the sidebar of the Things app and can be used for filtering.
- The color of tags can only be set in the Things UI, not via AppleScript.
