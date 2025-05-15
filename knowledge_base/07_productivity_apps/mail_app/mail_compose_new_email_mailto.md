---
title: "Mail: Compose New Email (via mailto URL)"
category: "09_productivity_apps" # Subdir: mail_app
id: mail_compose_new_email_mailto
description: "Creates a new email in Mail.app with specified recipient, subject, and body using a 'mailto' URL. Mail.app will open with the draft."
keywords: ["Mail", "email", "compose", "new message", "mailto"]
language: applescript
isComplex: true
argumentsPrompt: "Recipient email as 'recipient', subject as 'subject', and body as 'body' in inputData."
notes: |
  - This method opens Mail.app with a pre-filled draft; it does not send the email automatically.
  - Subject and body are URL-encoded by the script.
  - Requires Automation permission for Mail.app.
---

```applescript
--MCP_INPUT:recipient
--MCP_INPUT:subject
--MCP_INPUT:body

on createMailToURL(toAddress, mailSubject, mailBody)
  if toAddress is missing value or toAddress is "" then return "error: Recipient email address is required."
  set theSubject to mailSubject
  if mailSubject is missing value then set theSubject to ""
  set theBody to mailBody
  if mailBody is missing value then set theBody to ""

  set encodedSubject to my urlEncode(theSubject)
  set encodedBody to my urlEncode(theBody)
  
  -- Construct the mailto URL
  set mailtoURL to "mailto:" & toAddress & "?subject=" & encodedSubject & "&body=" & encodedBody
  
  try
    -- Use Mail's 'open location' (which handles mailto) or 'mailto' command
    tell application "Mail"
      activate
      open location mailtoURL -- 'mailto mailtoURL' also works for some versions
    end tell
    return "New email draft opened in Mail for: " & toAddress
  on error errMsg
    return "error: Failed to create email draft - " & errMsg
  end try
end createMailToURL

on urlEncode(theText)
  set StoredDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to {""}
  set newText to ""
  repeat with aChar in characters of theText
    set charCode to ASCII number of aChar
    if (charCode ? 48 and charCode ? 57) or ¬
      (charCode ? 65 and charCode ? 90) or ¬
      (charCode ? 97 and charCode ? 122) or ¬
      aChar is in "-_.~" then
      set newText to newText & aChar
    else if aChar is " " then
      set newText to newText & "%20" -- Use %20 for space for mailto body
    else
      -- Percent-encode other characters
      set L to charCode div 16
      set R to charCode mod 16
      repeat with C in {L, R}
        if C < 10 then
          set newText to newText & C
        else
          set newText to newText & character (C - 10 + (ASCII number of "A"))
        end if
      end repeat
    end if
  end repeat
  set AppleScript's text item delimiters to StoredDelimiters
  return newText
end urlEncode


return my createMailToURL("--MCP_INPUT:recipient", "--MCP_INPUT:subject", "--MCP_INPUT:body")
```
END_TIP 