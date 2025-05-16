---
title: 'Messages: Get Recent Chats'
category: 09_productivity
id: messages_get_recent_chats
description: Retrieves a list of recent chat conversations from the Messages app.
keywords:
  - Messages
  - conversations
  - chats
  - recent messages
language: applescript
notes: >-
  Lists recent chats with the recipient name and most recent message. Limited to
  the visible chats in the Messages app.
---

```applescript
tell application "Messages"
  try
    set allChats to every chat
    
    if (count of allChats) is 0 then
      return "No recent chats found."
    end if
    
    set chatsList to {}
    
    repeat with thisChat in allChats
      set chatParticipants to participants of thisChat
      set chatName to ""
      
      -- Get chat name or participant names
      if name of thisChat is not missing value then
        set chatName to name of thisChat
      else
        set participantNames to {}
        repeat with thisParticipant in chatParticipants
          set end of participantNames to name of thisParticipant
        end repeat
        
        set AppleScript's text item delimiters to ", "
        set chatName to participantNames as string
        set AppleScript's text item delimiters to ""
      end if
      
      -- Get most recent message if available
      set lastMessage to ""
      if (count of (messages of thisChat)) > 0 then
        set recentMessage to last message of thisChat
        set lastMessage to content of recentMessage
        if length of lastMessage > 50 then
          set lastMessage to (text 1 thru 50 of lastMessage) & "..."
        end if
      end if
      
      set chatInfo to "Chat: " & chatName
      if lastMessage is not "" then
        set chatInfo to chatInfo & "\\n  Recent message: " & lastMessage
      end if
      
      set end of chatsList to chatInfo
    end repeat
    
    set AppleScript's text item delimiters to "\\n\\n"
    set outputString to "Recent Chats (" & (count of allChats) & "):\\n\\n" & (chatsList as string)
    set AppleScript's text item delimiters to ""
    
    return outputString
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to retrieve recent chats - " & errMsg
  end try
end tell
```
END_TIP
