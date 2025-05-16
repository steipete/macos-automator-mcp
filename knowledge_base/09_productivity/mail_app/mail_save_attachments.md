---
title: "Mail: Save Attachments from Selected Email"
category: "07_productivity_apps"
id: mail_save_attachments
description: "Extracts and saves all attachments from selected email messages in Mail.app"
keywords: ["Mail", "email", "attachments", "download", "save", "extract"]
language: applescript
isComplex: true
argumentsPrompt: "Provide a save path as 'savePath' in inputData (optional, defaults to Desktop)"
notes: |
  - Extracts attachments from currently selected emails in Mail.app
  - By default saves to Desktop, but a custom path can be specified
  - Returns information about saved attachments
  - Requires Automation permission for Mail.app
  - Requires Mail.app to be open with message(s) selected
---

```applescript
--MCP_INPUT:savePath

-- Set default save location if not provided
on getDefaultSavePath(pathInput)
  if pathInput is missing value or pathInput is "" then
    -- Default to Desktop folder
    return POSIX path of (path to desktop folder)
  else
    -- Ensure path ends with slash
    if last character of pathInput is not "/" then
      return pathInput & "/"
    else
      return pathInput
    end if
  end if
end getDefaultSavePath

-- Function to sanitize filenames
on sanitizeFilename(filename)
  set invalidChars to {":", "/", "\\", "*", "?", "\"", "<", ">", "|"}
  set sanitized to filename
  
  repeat with invalidChar in invalidChars
    set AppleScript's text item delimiters to invalidChar
    set textItems to text items of sanitized
    set AppleScript's text item delimiters to "_"
    set sanitized to textItems as text
  end repeat
  
  return sanitized
end sanitizeFilename

-- Main function to save attachments
on saveAttachments(targetPath)
  set savePath to my getDefaultSavePath(targetPath)
  
  tell application "Mail"
    try
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No messages selected. Please select one or more messages in Mail.app"
      end if
      
      set savedAttachments to {}
      set totalSaved to 0
      
      -- Process each selected message
      repeat with thisMessage in selectedMessages
        set messageSubject to subject of thisMessage
        set sanitizedSubject to my sanitizeFilename(messageSubject)
        
        -- Get all attachments in this message
        set messageAttachments to mail attachments of content of thisMessage
        if (count of messageAttachments) > 0 then
          -- Process each attachment
          repeat with thisAttachment in messageAttachments
            set attachmentName to name of thisAttachment
            set sanitizedName to my sanitizeFilename(attachmentName)
            
            -- Create a folder with the message subject if multiple messages selected
            if (count of selectedMessages) > 1 then
              -- Create folder for this message
              do shell script "mkdir -p " & quoted form of (savePath & sanitizedSubject)
              set attachmentPath to savePath & sanitizedSubject & "/" & sanitizedName
            else
              set attachmentPath to savePath & sanitizedName
            end if
            
            -- Save the attachment
            save thisAttachment in (POSIX file attachmentPath)
            
            -- Log the saved attachment
            copy attachmentPath to end of savedAttachments
            set totalSaved to totalSaved + 1
          end repeat
        end if
      end repeat
      
      -- Format the result
      if totalSaved is 0 then
        return "No attachments found in the selected message(s)"
      else
        set resultText to "Saved " & totalSaved & " attachment"
        if totalSaved > 1 then set resultText to resultText & "s"
        set resultText to resultText & " to " & savePath
        
        if totalSaved ≤ 5 then
          -- List the files if there aren't too many
          set resultText to resultText & ":" & return
          repeat with i from 1 to count of savedAttachments
            set resultText to resultText & "- " & item i of savedAttachments & return
          end repeat
        end if
        
        return resultText
      end if
    on error errMsg
      return "Error saving attachments: " & errMsg
    end try
  end tell
end saveAttachments

return my saveAttachments("--MCP_INPUT:savePath")
```

This script:
1. Extracts all attachments from currently selected emails in Mail.app
2. Saves them to the specified location (or Desktop by default)
3. Creates subfolders based on email subjects when multiple messages are selected
4. Sanitizes filenames to ensure they're valid for the filesystem
5. Returns detailed information about the saved attachments