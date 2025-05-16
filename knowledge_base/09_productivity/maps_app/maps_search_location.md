---
title: "Maps: Search for Location"
category: "07_productivity_apps"
id: maps_search_location
description: "Searches for a specific location in the Maps app."
keywords: ["Maps", "search location", "find place", "directions", "address search"]
language: applescript
argumentsPrompt: "Enter the location or address to search for"
notes: "Opens the Maps app and performs a search for the specified location."
---

```applescript
on run {searchQuery}
  tell application "Maps"
    try
      if searchQuery is "" or searchQuery is missing value then
        set searchQuery to "--MCP_INPUT:searchQuery"
      end if
      
      activate
      
      -- Give Maps a moment to launch
      delay 1
      
      tell application "System Events"
        tell process "Maps"
          -- Click in the search field
          click text field 1 of group 1 of toolbar 1 of window 1
          
          -- Clear any existing text
          keystroke "a" using {command down}
          keystroke delete
          
          -- Enter the search query
          keystroke searchQuery
          keystroke return
          
          -- Wait for results
          delay 2
          
          -- Get search result information if available
          if exists group 2 of window 1 then
            if exists static text 1 of group 2 of window 1 then
              set resultName to value of static text 1 of group 2 of window 1
              
              if exists static text 2 of group 2 of window 1 then
                set resultAddress to value of static text 2 of group 2 of window 1
                return "Found location: " & resultName & "\\nAddress: " & resultAddress
              else
                return "Found location: " & resultName
              end if
            else
              return "Search completed for: " & searchQuery
            end if
          else
            return "Search completed for: " & searchQuery & "\\nUnable to retrieve result details."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search location - " & errMsg
    end try
  end tell
end run
```
END_TIP