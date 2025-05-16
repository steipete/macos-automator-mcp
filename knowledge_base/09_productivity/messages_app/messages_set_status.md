---
title: "Messages: Set Status Message"
category: "07_productivity_apps"
id: messages_set_status
description: "Sets your status message in the Messages app."
keywords: ["Messages", "status message", "away message", "iMessage status", "presence"]
language: applescript
argumentsPrompt: "Enter the status message to set"
notes: "Sets your status in the Messages app. The status will be visible to your contacts."
---

```applescript
on run {statusMessage}
  tell application "Messages"
    try
      if statusMessage is "" or statusMessage is missing value then
        set statusMessage to "--MCP_INPUT:statusMessage"
      end if
      
      activate
      
      -- Use UI scripting to set the status
      tell application "System Events"
        tell process "Messages"
          -- Open Messages menu
          click menu item "Messages" of menu bar item "Messages" of menu bar 1
          delay 0.3
          
          -- Click on "Status" menu item
          click menu item "Status" of menu "Messages" of menu bar item "Messages" of menu bar 1
          delay 0.3
          
          -- Look for "Custom..." or "Edit Status Menu..." menu item
          if exists menu item "Custom..." of menu "Status" of menu "Messages" of menu bar item "Messages" of menu bar 1 then
            click menu item "Custom..." of menu "Status" of menu "Messages" of menu bar item "Messages" of menu bar 1
          else if exists menu item "Edit Status Menu..." of menu "Status" of menu "Messages" of menu bar item "Messages" of menu bar 1 then
            click menu item "Edit Status Menu..." of menu "Status" of menu "Messages" of menu bar item "Messages" of menu bar 1
          else
            -- If we can't find the right menu item, escape out of the menus and report error
            keystroke (ASCII character 27) -- Escape key
            return "Error: Could not find the option to set a custom status. The Messages menu structure may have changed."
          end if
          
          delay 0.5
          
          -- Enter the custom status in the dialog
          if exists sheet 1 of window 1 then
            if exists text field 1 of sheet 1 of window 1 then
              set value of text field 1 of sheet 1 of window 1 to statusMessage
              
              -- Click OK button
              click button "OK" of sheet 1 of window 1
              
              return "Status message set to: " & statusMessage
            else
              -- If the text field isn't found, try to dismiss the dialog
              if exists button "Cancel" of sheet 1 of window 1 then
                click button "Cancel" of sheet 1 of window 1
              end if
              
              return "Error: Could not set status message. The status dialog interface may have changed."
            end if
          else
            return "Error: Could not set status message. The status dialog did not appear."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to set status message - " & errMsg
    end try
  end tell
end run
```
END_TIP