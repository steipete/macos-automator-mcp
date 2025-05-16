---
title: "Podcasts: Play Episode"
category: "08_creative_and_document_apps"
id: podcasts_play_episode
description: "Plays a specific podcast episode in the Podcasts app."
keywords: ["Podcasts", "play episode", "podcast playback", "listen to podcast", "play podcast"]
language: applescript
argumentsPrompt: "Enter the podcast and episode name"
notes: "Searches for and plays a specific podcast episode. Requires the Podcasts app to be set up with subscriptions."
---

```applescript
on run {podcastName, episodeName}
  tell application "Podcasts"
    try
      -- Handle placeholder substitution
      if podcastName is "" or podcastName is missing value then
        set podcastName to "--MCP_INPUT:podcastName"
      end if
      
      if episodeName is "" or episodeName is missing value then
        set episodeName to "--MCP_INPUT:episodeName"
      end if
      
      activate
      
      -- Give Podcasts app time to launch
      delay 1
      
      -- Check for specific episode if both podcast and episode names provided
      if podcastName is not "--MCP_INPUT:podcastName" and episodeName is not "--MCP_INPUT:episodeName" then
        -- Search for matching podcast
        tell application "System Events"
          tell process "Podcasts"
            -- Click in the search field
            if exists text field 1 of group 1 of toolbar 1 of window 1 then
              click text field 1 of group 1 of toolbar 1 of window 1
              
              -- Clear any existing search
              keystroke "a" using {command down}
              keystroke delete
              
              -- Search for the podcast
              keystroke podcastName
              keystroke return
              delay 1
              
              -- Try to find and click on the podcast in search results
              if exists table 1 of scroll area 1 of group 1 of window 1 then
                set resultRows to rows of table 1 of scroll area 1 of group 1 of window 1
                
                set podcastFound to false
                repeat with i from 1 to count of resultRows
                  set currentRow to item i of resultRows
                  
                  -- Try to get the text of each result row
                  if exists text field 1 of currentRow then
                    set rowText to value of text field 1 of currentRow
                    
                    if rowText contains podcastName then
                      -- Click on this podcast
                      click currentRow
                      set podcastFound to true
                      delay 1
                      exit repeat
                    end if
                  end if
                end repeat
                
                if podcastFound then
                  -- Now search for the episode within the podcast
                  if exists text field 1 of group 1 of toolbar 1 of window 1 then
                    click text field 1 of group 1 of toolbar 1 of window 1
                    
                    -- Clear previous search
                    keystroke "a" using {command down}
                    keystroke delete
                    
                    -- Search for episode
                    keystroke episodeName
                    keystroke return
                    delay 1
                    
                    -- Try to find and play the episode
                    if exists table 1 of scroll area 1 of group 1 of window 1 then
                      set episodeRows to rows of table 1 of scroll area 1 of group 1 of window 1
                      
                      set episodeFound to false
                      repeat with j from 1 to count of episodeRows
                        set currentEpisodeRow to item j of episodeRows
                        
                        if exists text field 1 of currentEpisodeRow then
                          set episodeText to value of text field 1 of currentEpisodeRow
                          
                          if episodeText contains episodeName then
                            -- Double-click to play the episode
                            click currentEpisodeRow
                            delay 0.1
                            click currentEpisodeRow
                            set episodeFound to true
                            delay 1
                            exit repeat
                          end if
                        end if
                      end repeat
                      
                      if episodeFound then
                        return "Playing episode \"" & episodeName & "\" from podcast \"" & podcastName & "\""
                      else
                        return "Episode \"" & episodeName & "\" not found in podcast \"" & podcastName & "\""
                      end if
                    end if
                  end if
                else
                  return "Podcast \"" & podcastName & "\" not found."
                end if
              end if
            end if
          end tell
        end tell
      else
        -- Simpler case: just search for and play the podcast if episode not specified
        set searchTerm to podcastName
        if episodeName is not "--MCP_INPUT:episodeName" then
          set searchTerm to podcastName & " " & episodeName
        end if
        
        tell application "System Events"
          tell process "Podcasts"
            -- Click in the search field
            if exists text field 1 of group 1 of toolbar 1 of window 1 then
              click text field 1 of group 1 of toolbar 1 of window 1
              
              -- Clear any existing search
              keystroke "a" using {command down}
              keystroke delete
              
              -- Search for the podcast/episode
              keystroke searchTerm
              keystroke return
              delay 1
              
              -- Try to find and play the first result
              if exists table 1 of scroll area 1 of group 1 of window 1 then
                if exists row 1 of table 1 of scroll area 1 of group 1 of window 1 then
                  -- Double-click to play
                  click row 1 of table 1 of scroll area 1 of group 1 of window 1
                  delay 0.1
                  click row 1 of table 1 of scroll area 1 of group 1 of window 1
                  
                  return "Playing first result for search: \"" & searchTerm & "\""
                else
                  return "No results found for \"" & searchTerm & "\""
                end if
              end if
            end if
          end tell
        end tell
      end if
      
      -- Default return if nothing else triggered
      return "Unable to play podcast. The Podcasts app interface may have changed."
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to play podcast - " & errMsg
    end try
  end tell
end run
```
END_TIP