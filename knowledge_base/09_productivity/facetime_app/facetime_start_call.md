---
title: 'FaceTime: Start New Call'
category: 09_productivity/facetime_app
id: facetime_start_call
description: Initiates a new FaceTime call to a specified contact or number.
keywords:
  - FaceTime
  - video call
  - audio call
  - start call
  - call contact
language: applescript
argumentsPrompt: 'Enter the contact name, phone number, or email to call'
notes: >-
  Starts a FaceTime call with the specified recipient. The recipient can be a
  contact name, phone number, or email associated with an Apple ID.
---

```applescript
on run {recipient}
  tell application "FaceTime"
    try
      if recipient is "" or recipient is missing value then
        set recipient to "--MCP_INPUT:recipient"
      end if
      
      activate
      
      -- Give FaceTime time to launch
      delay 1
      
      tell application "System Events"
        tell process "FaceTime"
          -- Click in the search field
          if exists text field 1 of group 1 of window 1 then
            click text field 1 of group 1 of window 1
            
            -- Clear any existing text
            keystroke "a" using {command down}
            keystroke delete
            
            -- Type the recipient
            keystroke recipient
            delay 1
            
            -- Press return to initiate search
            keystroke return
            delay 1
            
            -- Try to find and click the video call button for the contact
            if exists button 1 of row 1 of table 1 of scroll area 1 of window 1 then
              click button 1 of row 1 of table 1 of scroll area 1 of window 1
              return "Starting FaceTime call with " & recipient
            else
              -- If we can't find a direct match, try to click on first result
              if exists row 1 of table 1 of scroll area 1 of window 1 then
                click row 1 of table 1 of scroll area 1 of window 1
                delay 0.5
                
                -- Now try to find and click a call button
                if exists button 1 of group 1 of window 1 then
                  click button 1 of group 1 of window 1
                  return "Starting FaceTime call with " & recipient
                else
                  return "Found contact but unable to initiate call. Please try manually."
                end if
              else
                return "No contacts found matching: " & recipient
              end if
            end if
          else
            return "Unable to access the search field. The FaceTime app interface may have changed."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to start FaceTime call - " & errMsg
    end try
  end tell
end run
```
END_TIP
