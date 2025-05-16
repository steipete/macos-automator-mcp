---
title: "Mail: Flag Messages"
category: "07_productivity_apps"
id: mail_flag_messages
description: "Flags selected messages in Mail.app with specific flag colors"
keywords: ["Mail", "email", "flag", "color", "mark", "highlight"]
language: applescript
isComplex: false
argumentsPrompt: "Provide flag color as 'flagColor' in inputData (optional, defaults to 'red')"
notes: |
  - Flags or unflags currently selected messages in Mail.app
  - Supports all Mail flag colors: red, orange, yellow, green, blue, purple, gray, or none (to unflag)
  - Requires Automation permission for Mail.app
  - Requires Mail.app to be open with message(s) selected
---

```applescript
--MCP_INPUT:flagColor

on setMessageFlags(colorName)
  -- Set default if not provided
  if colorName is missing value or colorName is "" then
    set flagColor to "red"
  else
    set flagColor to lowercase of colorName
  end if
  
  -- Validate color name
  set validColors to {"red", "orange", "yellow", "green", "blue", "purple", "gray", "none"}
  set isValidColor to false
  repeat with validColor in validColors
    if flagColor is validColor then
      set isValidColor to true
      exit repeat
    end if
  end repeat
  
  if not isValidColor then
    return "Error: Invalid flag color. Use red, orange, yellow, green, blue, purple, gray, or none"
  end if
  
  tell application "Mail"
    try
      -- Get selected messages
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No messages selected. Please select messages in Mail.app before running this script."
      end if
      
      -- Convert color name to flag index
      set flagIndex to 0 -- Default for none/unflag
      if flagColor is "red" then
        set flagIndex to 1
      else if flagColor is "orange" then
        set flagIndex to 2
      else if flagColor is "yellow" then
        set flagIndex to 3
      else if flagColor is "green" then
        set flagIndex to 4
      else if flagColor is "blue" then
        set flagIndex to 5
      else if flagColor is "purple" then
        set flagIndex to 6
      else if flagColor is "gray" then
        set flagIndex to 7
      end if
      
      -- Flag or unflag the messages
      set messageCount to count of selectedMessages
      
      repeat with thisMessage in selectedMessages
        if flagColor is "none" then
          -- Unflag the message
          set flagged status of thisMessage to false
          set flag index of thisMessage to 0
        else
          -- Flag the message with specified color
          set flagged status of thisMessage to true
          set flag index of thisMessage to flagIndex
        end if
      end repeat
      
      -- Return result
      if flagColor is "none" then
        set actionText to "Unflagged"
      else
        set actionText to "Flagged with " & flagColor & " flag"
      end if
      
      set resultText to actionText & " " & messageCount & " message"
      if messageCount ≠ 1 then set resultText to resultText & "s"
      
      return resultText
    on error errMsg
      return "Error flagging messages: " & errMsg
    end try
  end tell
end setMessageFlags

return my setMessageFlags("--MCP_INPUT:flagColor")
```

This script:
1. Adds colored flags to currently selected messages in Mail.app
2. Supports all standard Mail.app flag colors: red, orange, yellow, green, blue, purple, gray
3. Can also remove flags by specifying "none" as the flag color
4. Validates input to ensure a valid flag color is provided
5. Reports how many messages were flagged/unflagged
6. Provides helpful error messages if no messages are selected