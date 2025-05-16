---
title: "Maps: Get Current Location"
category: "07_productivity_apps"
id: maps_get_current_location
description: "Retrieves the current location information from the Maps app."
keywords: ["Maps", "current location", "GPS", "coordinates", "geolocation"]
language: applescript
notes: "Requires location services to be enabled and permission granted to the Maps app."
---

```applescript
tell application "Maps"
  try
    activate
    
    -- Give Maps a moment to show the current location
    delay 2
    
    tell application "System Events"
      tell process "Maps"
        -- Click on the Current Location button in Maps
        click button "Current Location" of group 1 of group 1 of window 1
        delay 1
        
        -- Get the details from the info display that shows current location
        if exists group 2 of window 1 then
          set locationInfo to value of static text 1 of group 2 of window 1
          
          -- Extract coordinates if shown in the status bar
          if exists static text 1 of group 1 of toolbar 1 of window 1 then
            set coordinatesText to value of static text 1 of group 1 of toolbar 1 of window 1
            return "Current Location: " & locationInfo & "\\n" & "Coordinates: " & coordinatesText
          else
            return "Current Location: " & locationInfo
          end if
        else
          return "Unable to retrieve current location information. Make sure location services are enabled."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get current location - " & errMsg
  end try
end tell
```
END_TIP