---
title: "Messages: Get Chat History"
category: "07_productivity_apps"
id: messages_get_chat_history
description: "Retrieves message history from a specific chat in the Messages app."
keywords: ["Messages", "chat history", "message history", "conversation history", "text history"]
language: applescript
argumentsPrompt: "Enter the name of the contact or chat to retrieve history from"
notes: "Retrieves recent messages from a specific chat conversation. Limited to a reasonable number of messages to avoid performance issues."
---

```applescript
on run {chatName}
  tell application "Messages"
    try
      if chatName is "" or chatName is missing value then
        set chatName to "--MCP_INPUT:chatName"
      end if
      
      set targetChat to missing value
      
      -- Find the chat that matches the provided name
      set allChats to every chat
      
      repeat with thisChat in allChats
        -- Check if this is the chat we're looking for
        if name of thisChat is not missing value and name of thisChat contains chatName then
          set targetChat to thisChat
          exit repeat
        else
          -- Check participant names if chat name doesn't match
          set chatParticipants to participants of thisChat
          
          repeat with thisParticipant in chatParticipants
            if name of thisParticipant contains chatName then
              set targetChat to thisChat
              exit repeat
            end if
          end repeat
          
          if targetChat is not missing value then
            exit repeat
          end if
        end if
      end repeat
      
      -- If no matching chat found
      if targetChat is missing value then
        return "No chat found matching: " & chatName
      end if
      
      -- Get chat display name
      set chatDisplayName to ""
      if name of targetChat is not missing value then
        set chatDisplayName to name of targetChat
      else
        -- Construct name from participants
        set participantNames to {}
        repeat with thisParticipant in (participants of targetChat)
          set end of participantNames to name of thisParticipant
        end repeat
        
        set AppleScript's text item delimiters to ", "
        set chatDisplayName to participantNames as string
        set AppleScript's text item delimiters to ""
      end if
      
      -- Get messages (limit to last 25 messages to avoid performance issues)
      set chatMessages to messages of targetChat
      set messageCount to count of chatMessages
      
      if messageCount is 0 then
        return "No messages found in chat with: " & chatDisplayName
      end if
      
      -- Limit to last 25 messages
      set maxMessages to 25
      if messageCount > maxMessages then
        set startIndex to messageCount - maxMessages + 1
      else
        set startIndex to 1
      end if
      
      -- Format message history
      set messageHistory to {}
      
      repeat with i from startIndex to messageCount
        set thisMessage to item i of chatMessages
        set messageSender to sender of thisMessage
        set messageContent to content of thisMessage
        set messageDate to date sent of thisMessage
        
        -- Format sender name (handle Apple's internal format)
        set senderName to ""
        if messageSender is not missing value then
          if name of messageSender is not missing value then
            set senderName to name of messageSender
          else
            set senderName to "Me" -- Assume it's from the user if no name
          end if
        else
          set senderName to "Me" -- Assume it's from the user if sender is missing
        end if
        
        -- Format the message entry
        set messageEntry to senderName & " (" & messageDate & "):\\n" & messageContent
        set end of messageHistory to messageEntry
      end repeat
      
      set AppleScript's text item delimiters to "\\n\\n"
      set outputString to "Chat History with " & chatDisplayName & "\\n(Last " & (messageCount - startIndex + 1) & " messages):\\n\\n" & (messageHistory as string)
      set AppleScript's text item delimiters to ""
      
      return outputString
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to retrieve chat history - " & errMsg
    end try
  end tell
end run
```
END_TIP