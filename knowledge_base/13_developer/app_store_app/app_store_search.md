---
title: 'App Store: Search for Apps'
category: 13_developer/app_store_app
id: app_store_search
description: Searches for applications in the Mac App Store.
keywords:
  - App Store
  - search apps
  - find applications
  - software search
  - app discovery
language: applescript
argumentsPrompt: Enter the search query for apps
notes: Searches the Mac App Store for applications matching the specified query.
---

```applescript
on run {searchQuery}
  try
    -- Handle placeholder substitution
    if searchQuery is "" or searchQuery is missing value then
      set searchQuery to "--MCP_INPUT:searchQuery"
    end if
    
    tell application "App Store"
      activate
      
      -- Give App Store time to launch
      delay 1
      
      tell application "System Events"
        tell process "App Store"
          -- Click in the search field
          if exists text field 1 of group 1 of toolbar 1 of window 1 then
            click text field 1 of group 1 of toolbar 1 of window 1
            
            -- Clear any existing search
            keystroke "a" using {command down}
            keystroke delete
            
            -- Type the search query
            keystroke searchQuery
            keystroke return
            
            -- Wait for results to load
            delay 3
            
            return "Searching for \"" & searchQuery & "\" in the App Store. Results are displayed in the App Store window."
          else
            return "Unable to access the search field. The App Store interface may have changed."
          end if
        end tell
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to search App Store - " & errMsg
  end try
end run
```
END_TIP
