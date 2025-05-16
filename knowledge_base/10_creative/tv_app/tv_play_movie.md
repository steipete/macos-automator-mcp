---
title: 'TV: Play Movie or Show'
category: 10_creative
id: tv_play_movie
description: Plays a movie or TV show from your library in the TV app.
keywords:
  - TV app
  - play movie
  - watch show
  - video playback
  - Apple TV+
language: applescript
argumentsPrompt: Enter the name of the movie or show to play
notes: >-
  Searches for and plays content from your library. Requires that the content is
  already in your TV app library.
---

```applescript
on run {contentName}
  tell application "TV"
    try
      if contentName is "" or contentName is missing value then
        set contentName to "--MCP_INPUT:contentName"
      end if
      
      activate
      
      -- Give TV app time to launch
      delay 1
      
      tell application "System Events"
        tell process "TV"
          -- Click on Library in the sidebar if it exists
          if exists row "Library" of table 1 of scroll area 1 of group 1 of window 1 then
            click row "Library" of table 1 of scroll area 1 of group 1 of window 1
            delay 0.5
          end if
          
          -- Click in the search field
          if exists text field 1 of group 1 of toolbar 1 of window 1 then
            click text field 1 of group 1 of toolbar 1 of window 1
            
            -- Clear any existing search
            keystroke "a" using {command down}
            keystroke delete
            
            -- Type the content name and search
            keystroke contentName
            keystroke return
            
            -- Wait for search results
            delay 2
            
            -- Try to play the first search result if it exists
            if exists row 1 of table 1 of scroll area 1 of group 1 of window 1 then
              -- Double-click to play
              click row 1 of table 1 of scroll area 1 of group 1 of window 1
              delay 0.1
              click row 1 of table 1 of scroll area 1 of group 1 of window 1
              
              return "Playing: " & contentName
            else
              return "No content found matching: " & contentName
            end if
          else
            return "Unable to access the search field. The TV app interface may have changed."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to play content - " & errMsg
    end try
  end tell
end run
```
END_TIP
