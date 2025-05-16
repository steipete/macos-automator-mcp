---
title: "Messages: Create Group Chat"
category: "07_productivity_apps"
id: messages_create_group_chat
description: "Creates a new group chat with multiple recipients in the Messages app."
keywords: ["Messages", "group chat", "new conversation", "multiple recipients", "group message"]
language: applescript
argumentsPrompt: "Enter comma-separated list of contacts for the group chat"
notes: "Creates a new group conversation with the specified contacts. Contacts can be names, phone numbers, or Apple ID emails."
---

```applescript
on run {recipientList}
  tell application "Messages"
    try
      if recipientList is "" or recipientList is missing value then
        set recipientList to "--MCP_INPUT:recipientList"
      end if
      
      -- Split the comma-separated list into individual recipients
      set AppleScript's text item delimiters to ","
      set recipients to text items of recipientList
      set AppleScript's text item delimiters to ""
      
      -- Trim whitespace from recipient names
      set trimmedRecipients to {}
      repeat with recipient in recipients
        -- Remove leading and trailing whitespace
        set trimmedRecipient to do shell script "echo " & quoted form of recipient & " | sed 's/^[ \t]*//;s/[ \t]*$//'"
        if trimmedRecipient is not "" then
          set end of trimmedRecipients to trimmedRecipient
        end if
      end repeat
      
      -- Check if we have at least 2 recipients for a group chat
      if (count of trimmedRecipients) < 2 then
        return "Error: At least 2 recipients are needed to create a group chat. Please provide a comma-separated list."
      end if
      
      activate
      
      -- Create a new message
      tell application "System Events"
        tell process "Messages"
          -- Click on "New Message" button or use keyboard shortcut
          keystroke "n" using {command down}
          delay 1
          
          -- Enter recipients one by one
          repeat with recipient in trimmedRecipients
            -- Type the recipient
            keystroke recipient
            delay 0.5
            -- Press Tab or Return to confirm recipient
            keystroke tab
            delay 0.5
          end repeat
          
          -- Focus on the message field
          keystroke tab
          
          -- Return info about the created chat
          set AppleScript's text item delimiters to ", "
          set recipientString to trimmedRecipients as string
          set AppleScript's text item delimiters to ""
          
          return "Group chat created with: " & recipientString & "\\n\\nType your message in the Messages app and press Return to send."
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create group chat - " & errMsg
    end try
  end tell
end run
```
END_TIP