---
title: Send Email Directly from Mail App
description: >-
  Creates and sends an email with specified recipients, subject, body, and
  optional attachments
keywords:
  - mail
  - email
  - send email
  - outgoing
  - compose
  - attachment
language: applescript
id: mail_send_email_direct
argumentsPrompt: 'Provide recipient email, subject, body text, and optional attachment path'
category: 09_productivity
---

This script creates and sends an email directly from Apple Mail without user intervention.

```applescript
-- Email details (can be replaced with MCP placeholders)
set recipientEmail to "recipient@example.com" -- --MCP_INPUT:recipientEmail
set emailSubject to "Important Information" -- --MCP_INPUT:subject
set emailBody to "Hello,\n\nThis is an automated email sent via AppleScript.\n\nRegards,\nYour Name" -- --MCP_INPUT:body
set attachmentPath to "" -- --MCP_INPUT:attachmentPath (optional POSIX path to file)

tell application "Mail"
  -- Create a new outgoing message
  set newMessage to make new outgoing message with properties {subject:emailSubject, content:emailBody, visible:false}
  
  -- Add the recipient
  tell newMessage
    make new to recipient with properties {address:recipientEmail}
    
    -- Add CC recipient (optional)
    -- make new cc recipient with properties {address:"cc@example.com"}
    
    -- Add BCC recipient (optional)
    -- make new bcc recipient with properties {address:"bcc@example.com"}
    
    -- Add attachment if path is provided
    if attachmentPath is not "" and attachmentPath is not missing value then
      try
        -- Convert POSIX path to file
        set attachmentFile to POSIX file attachmentPath
        -- Attach the file
        make new attachment with properties {file name:attachmentFile} at after the last paragraph
      on error errMsg
        return "Error adding attachment: " & errMsg
      end try
    end if
    
    -- Send the message
    send
  end tell
  
  return "Email sent to " & recipientEmail & " with subject: " & emailSubject
end tell
```

This script:
1. Creates a new outgoing email message with specified subject and body
2. Adds recipients (to, cc, bcc)
3. Optionally attaches a file if a path is provided
4. Sends the email immediately
5. All parameters can be customized using input placeholders

Note: This script requires Mail to be configured with a valid sending account.
