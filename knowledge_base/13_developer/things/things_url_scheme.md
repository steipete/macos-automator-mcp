---
id: things_url_scheme
title: Use Things URL Scheme
description: Use AppleScript with Things URL scheme for quick actions
author: steipete
language: applescript
tags: 'things, productivity, task management, url scheme, automation'
keywords:
  - url-scheme
  - quick-add
  - integration
  - encoding
  - deep-linking
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Use Things URL Scheme

This script demonstrates how to use Things' URL scheme to perform quick actions like adding to-dos, showing specific lists, or searching.

## Example Usage

```applescript
-- Quick add a to-do
open location "things:///add?title=Buy%20milk&notes=From%20the%20grocery%20store&when=today"

-- Open a specific list
open location "things:///show?id=today"

-- Search for to-dos
open location "things:///search?query=important"
```

## Script Details

The script uses Things' URL scheme to perform various actions quickly.

```applescript
-- Use Things URL scheme for various actions
on useThingsURLScheme(action, parameters)
    set baseURL to "things:///"
    
    if action is "add" then
        set thingsURL to baseURL & "add?"
        
        -- Parse parameters for add action
        set paramList to {}
        
        if parameters contains "title" then
            set title to valueForKey(parameters, "title")
            set end of paramList to "title=" & encodeURLComponent(title)
        end if
        
        if parameters contains "notes" then
            set notes to valueForKey(parameters, "notes")
            set end of paramList to "notes=" & encodeURLComponent(notes)
        end if
        
        if parameters contains "when" then
            set whenDate to valueForKey(parameters, "when")
            set end of paramList to "when=" & encodeURLComponent(whenDate)
        end if
        
        if parameters contains "deadline" then
            set deadline to valueForKey(parameters, "deadline")
            set end of paramList to "deadline=" & encodeURLComponent(deadline)
        end if
        
        if parameters contains "tags" then
            set tags to valueForKey(parameters, "tags")
            set end of paramList to "tags=" & encodeURLComponent(tags)
        end if
        
        if parameters contains "list" then
            set listId to valueForKey(parameters, "list")
            set end of paramList to "list=" & encodeURLComponent(listId)
        end if
        
        -- Join parameters with &
        set AppleScript's text item delimiters to "&"
        set paramString to paramList as text
        set AppleScript's text item delimiters to ""
        
        set thingsURL to thingsURL & paramString
        
    else if action is "show" then
        set thingsURL to baseURL & "show?"
        
        if parameters contains "id" then
            set listId to valueForKey(parameters, "id")
            set thingsURL to thingsURL & "id=" & encodeURLComponent(listId)
        else
            return "Error: 'id' parameter is required for show action."
        end if
        
    else if action is "search" then
        set thingsURL to baseURL & "search?"
        
        if parameters contains "query" then
            set query to valueForKey(parameters, "query")
            set thingsURL to thingsURL & "query=" & encodeURLComponent(query)
        else
            return "Error: 'query' parameter is required for search action."
        end if
        
    else
        return "Error: Unsupported action. Use 'add', 'show', or 'search'."
    end if
    
    -- Open the URL
    open location thingsURL
    return "Things URL opened: " & thingsURL
end useThingsURLScheme

-- Helper function to get a value for a key from a record
on valueForKey(rec, key)
    repeat with i from 1 to count of rec
        set currKey to item 1 of item i of rec
        set currValue to item 2 of item i of rec
        if currKey is key then
            return currValue
        end if
    end repeat
    return ""
end valueForKey

-- URL encode a string to make it safe for URL parameters
on encodeURLComponent(input)
    set theChars to the characters of input
    set encodedString to ""
    
    repeat with c in theChars
        set theChar to c as string
        if theChar is " " then
            set encodedString to encodedString & "%20"
        else if theChar is "/" then
            set encodedString to encodedString & "%2F"
        else if theChar is ":" then
            set encodedString to encodedString & "%3A"
        else if theChar is "," then
            set encodedString to encodedString & "%2C"
        else
            set encodedString to encodedString & theChar
        end if
    end repeat
    
    return encodedString
end encodeURLComponent

-- Example call
useThingsURLScheme("--MCP_ARG_1", {{key1, "--MCP_ARG_2"}, {key2, "--MCP_ARG_3"}, {key3, "--MCP_ARG_4"}})
```

## Notes

- Things 3 must be installed on the system.
- The URL scheme is a quick way to perform actions without the full AppleScript dictionary.
- For `add` action, supported parameters include:
  - `title`: The name of the to-do
  - `notes`: Additional details
  - `when`: When to complete (today, tomorrow, evening, anytime, someday)
  - `deadline`: Due date (YYYY-MM-DD)
  - `tags`: Comma-separated list of tags
  - `list`: ID of the list, project, or area
- For `show` action, supported IDs include:
  - `inbox`, `today`, `upcoming`, `anytime`, `someday`, `logbook`
  - Or a specific project, area, or to-do ID
- For `search` action, the `query` parameter defines what to search for.
- The URL scheme is often simpler to use than the full AppleScript interface but has fewer capabilities.
- This is useful for quick actions or integration with other automation tools.
