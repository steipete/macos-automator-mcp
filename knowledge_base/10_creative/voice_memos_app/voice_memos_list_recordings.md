---
title: "Voice Memos: List Recordings"
category: "08_creative_and_document_apps"
id: voice_memos_list_recordings
description: "Lists all voice recordings in the Voice Memos app."
keywords: ["Voice Memos", "list recordings", "audio files", "voice notes", "recorded memos"]
language: applescript
notes: "Retrieves a list of all voice recordings with their names and dates. The information available may be limited due to the app's UI accessibility."
---

```applescript
tell application "Voice Memos"
  try
    activate
    
    -- Give Voice Memos time to launch
    delay 1
    
    tell application "System Events"
      tell process "Voice Memos"
        -- Make sure we're viewing the recordings list
        -- We may need to click the back button if we're in a recording detail view
        if exists button "Back" of window 1 then
          click button "Back" of window 1
          delay 0.5
        end if
        
        -- Try to access the recordings list
        if exists table 1 of scroll area 1 of window 1 then
          set recordingsList to {}
          set rows to rows of table 1 of scroll area 1 of window 1
          
          if (count of rows) is 0 then
            return "No voice recordings found."
          end if
          
          -- Iterate through each recording row to get its details
          repeat with i from 1 to count of rows
            set currentRow to item i of rows
            
            -- Try to get recording name and date
            set recordingName to ""
            set recordingDate to ""
            
            if exists static text 1 of currentRow then
              set recordingName to value of static text 1 of currentRow
            end if
            
            if exists static text 2 of currentRow then
              set recordingDate to value of static text 2 of currentRow
            end if
            
            if recordingName is not "" then
              set recordingInfo to "Recording " & i & ": " & recordingName
              
              if recordingDate is not "" then
                set recordingInfo to recordingInfo & " (" & recordingDate & ")"
              end if
              
              set end of recordingsList to recordingInfo
            end if
          end repeat
          
          set AppleScript's text item delimiters to "\\n"
          set outputText to "Voice Recordings (" & (count of recordingsList) & "):\\n" & (recordingsList as string)
          set AppleScript's text item delimiters to ""
          
          return outputText
        else
          return "Unable to access the recordings list. The Voice Memos app interface may have changed."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list voice recordings - " & errMsg
  end try
end tell
```
END_TIP