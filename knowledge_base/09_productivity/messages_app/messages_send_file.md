---
title: 'Messages: Send File Attachment'
category: 09_productivity/messages_app
id: messages_send_file
description: Sends a file as an attachment in the Messages app.
keywords:
  - Messages
  - send file
  - attachment
  - file sharing
  - send document
language: applescript
argumentsPrompt: Enter the recipient name and the file path to send
notes: >-
  Attaches and sends a file to a specified contact. The file path should be a
  full POSIX path.
---

```applescript
on run {recipient, filePath}
  tell application "Messages"
    try
      if recipient is "" or recipient is missing value then
        set recipient to "--MCP_INPUT:recipient"
      end if
      
      if filePath is "" or filePath is missing value then
        set filePath to "--MCP_INPUT:filePath"
      end if
      
      -- Verify that the file exists
      if filePath does not start with "/" then
        return "Error: Please provide a valid absolute POSIX path starting with /"
      end if
      
      set theFile to POSIX file filePath
      
      -- Check if file exists
      tell application "System Events"
        if not (exists file theFile) then
          return "Error: File not found at path: " & filePath
        end if
      end tell
      
      activate
      
      -- Try to find the recipient's chat
      set targetChat to missing value
      
      -- First try to get the buddy directly
      try
        set targetService to 1st service whose service type = iMessage
        set targetBuddy to buddy recipient of targetService
        
        -- If buddy exists, try to get or create their chat
        set targetChat to chat with targetBuddy
      on error
        -- If that fails, try to find an existing chat with this recipient
        try
          set targetChat to chat recipient
        on error
          -- If that also fails, we'll try a different approach
          set targetChat to missing value
        end try
      end try
      
      -- If we found or created a chat, send the file
      if targetChat is not missing value then
        send theFile to targetChat
        return "File sent to " & recipient & ": " & filePath
      else
        -- If we couldn't get a chat programmatically, use UI scripting
        tell application "System Events"
          tell process "Messages"
            -- Create a new message
            keystroke "n" using {command down}
            delay 1
            
            -- Enter the recipient
            keystroke recipient
            delay 0.5
            keystroke tab
            delay 0.5
            
            -- Focus on the message field and attach the file
            -- Use Command+Shift+A for attachment dialog
            keystroke "a" using {command down, shift down}
            delay 1
            
            -- Navigate to the file in the dialog
            keystroke "g" using {command down, shift down} -- Go to folder
            delay 0.5
            keystroke filePath
            keystroke return
            delay 1
            
            -- Press Choose button
            keystroke return
            delay 1
            
            -- Press send (Return key)
            keystroke return
            
            return "File sent to " & recipient & ": " & filePath
          end tell
        end tell
      end if
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to send file - " & errMsg
    end try
  end tell
end run
```
END_TIP
