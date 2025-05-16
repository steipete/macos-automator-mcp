---
title: "Podcasts: List Subscriptions"
category: "08_creative_and_document_apps"
id: podcasts_list_subscriptions
description: "Lists all subscribed podcasts in the Podcasts app."
keywords: ["Podcasts", "subscriptions", "podcast list", "subscribed shows", "podcast library"]
language: applescript
notes: "Returns a list of all podcasts you're subscribed to in the Podcasts app. Useful for discovering what podcasts are available for automation."
---

```applescript
tell application "Podcasts"
  try
    activate
    
    -- Give Podcasts app time to launch
    delay 1
    
    tell application "System Events"
      tell process "Podcasts"
        -- Click on "Library" in the sidebar to ensure we see all subscriptions
        if exists row "Library" of outline 1 of scroll area 1 of splitter group 1 of window 1 then
          click row "Library" of outline 1 of scroll area 1 of splitter group 1 of window 1
          delay 0.5
        end if
        
        -- Navigate to "Shows" within Library
        if exists row "Shows" of table 1 of scroll area 1 of splitter group 1 of window 1 then
          click row "Shows" of table 1 of scroll area 1 of splitter group 1 of window 1
          delay 0.5
          
          -- Get all podcast shows
          if exists scroll area 1 of group 1 of splitter group 1 of window 1 then
            set podcastGrid to scroll area 1 of group 1 of splitter group 1 of window 1
            
            -- Get all UI elements (podcast thumbnails) in the grid
            set podcastElements to UI elements of podcastGrid
            
            -- Filter for elements that are actual podcasts
            set podcastList to {}
            
            repeat with element in podcastElements
              if element is not podcastGrid then -- Skip the scroll area itself
                if exists static text 1 of element then
                  set podcastName to value of static text 1 of element
                  set end of podcastList to podcastName
                end if
              end if
            end repeat
            
            -- Generate results
            if (count of podcastList) is 0 then
              return "No podcast subscriptions found. You may need to subscribe to podcasts first."
            else
              set AppleScript's text item delimiters to return
              set resultText to "Your Podcast Subscriptions (" & (count of podcastList) & "):" & return & return & (podcastList as string)
              set AppleScript's text item delimiters to ""
              
              return resultText
            end if
          else
            return "Unable to access the podcast grid view. The Podcasts app interface may have changed."
          end if
        else
          return "Could not find the 'Shows' section in the Library. The Podcasts app interface may have changed."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list podcast subscriptions - " & errMsg
  end try
end tell
```
END_TIP