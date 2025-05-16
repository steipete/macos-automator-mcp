---
title: "Mail: Create Smart Mailbox"
category: "07_productivity_apps"
id: mail_create_smart_mailbox
description: "Creates a new Smart Mailbox in Mail app based on specified criteria."
keywords: ["Mail", "smart mailbox", "email filter", "message filter", "mail organization"]
language: applescript
argumentsPrompt: "Enter smart mailbox name and search criteria"
notes: "Creates a Smart Mailbox that automatically collects messages matching specified criteria."
---

```applescript
on run {mailboxName, criteriaField, criteriaText}
  tell application "Mail"
    try
      -- Handle placeholder substitution
      if mailboxName is "" or mailboxName is missing value then
        set mailboxName to "--MCP_INPUT:mailboxName"
      end if
      
      if criteriaField is "" or criteriaField is missing value then
        set criteriaField to "--MCP_INPUT:criteriaField" -- e.g., "From", "Subject", "To", "Message Content"
      end if
      
      if criteriaText is "" or criteriaText is missing value then
        set criteriaText to "--MCP_INPUT:criteriaText"
      end if
      
      -- Activate Mail
      activate
      
      tell application "System Events"
        tell process "Mail"
          -- Create a new Smart Mailbox
          click menu item "New Smart Mailbox…" of menu "Mailbox" of menu bar 1
          delay 0.5
          
          if exists sheet 1 of window 1 then
            -- Set the Smart Mailbox name
            set value of text field 1 of sheet 1 of window 1 to mailboxName
            
            -- Set criteria
            if exists pop up button 1 of group 1 of sheet 1 of window 1 then
              -- Click the criteria field popup
              click pop up button 1 of group 1 of sheet 1 of window 1
              delay 0.3
              
              -- Select the criteria field
              click menu item criteriaField of menu 1 of pop up button 1 of group 1 of sheet 1 of window 1
              delay 0.3
              
              -- Enter the criteria text
              if exists text field 1 of group 1 of sheet 1 of window 1 then
                set value of text field 1 of group 1 of sheet 1 of window 1 to criteriaText
              end if
            end if
            
            -- Include messages from sub-mailboxes (optional)
            if exists checkbox "Include messages from Smart Mailboxes" of sheet 1 of window 1 then
              click checkbox "Include messages from Smart Mailboxes" of sheet 1 of window 1
            end if
            
            -- Click OK to create the Smart Mailbox
            click button "OK" of sheet 1 of window 1
            
            return "Successfully created Smart Mailbox: " & mailboxName
          else
            return "Failed to create Smart Mailbox. The dialog did not appear."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create Smart Mailbox - " & errMsg
    end try
  end tell
end run
```
END_TIP