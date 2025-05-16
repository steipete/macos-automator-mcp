---
title: 'Mail: Smart Reply with Templates'
category: 09_productivity
id: mail_smart_reply
description: >-
  Creates a reply to the selected email using customizable templates based on
  message content
keywords:
  - Mail
  - email
  - reply
  - template
  - auto-respond
  - smart
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide a template folder path as 'templatePath' in inputData (optional,
  defaults to Templates folder in Documents)
notes: |
  - Creates a reply to the selected email with intelligent template selection
  - Can detect keywords in the subject and body to choose appropriate template
  - Falls back to a general template if no specific match is found
  - Substitutes placeholders in templates with sender info and other details
  - Requires Automation permission for Mail.app
  - Requires Mail.app to be open with a message selected
---

```applescript
--MCP_INPUT:templatePath

on setDefaultTemplatePath(pathInput)
  if pathInput is missing value or pathInput is "" then
    -- Default to Documents/Templates
    return POSIX path of (path to documents folder) & "Templates/"
  else
    -- Ensure path ends with slash
    if last character of pathInput is not "/" then
      return pathInput & "/"
    else
      return pathInput
    end if
  end if
end setDefaultTemplatePath

on getTemplatePaths(baseFolder)
  -- Get list of template files
  try
    set templateFiles to paragraphs of (do shell script "ls " & quoted form of baseFolder & "*.txt 2>/dev/null || echo ''")
    if templateFiles is "" then
      return {}
    else
      return templateFiles
    end if
  on error
    return {}
  end try
end getTemplatePaths

on readTemplateFile(templatePath)
  -- Read template content
  try
    set templateContent to do shell script "cat " & quoted form of templatePath
    return templateContent
  on error
    return ""
  end try
end readTemplateFile

on findBestTemplate(templateFolder, messageSubject, messageBody, senderName)
  -- Get list of templates
  set templatePaths to my getTemplatePaths(templateFolder)
  
  if (count of templatePaths) is 0 then
    -- No templates found - create default
    set defaultTemplate to "Dear --NAME--,

Thank you for your email regarding --SUBJECT--.

I've received your message and will respond in detail shortly.

Best regards,
--YOUR-NAME--"
    
    -- Try to save default template
    try
      set defaultPath to templateFolder & "default.txt"
      do shell script "mkdir -p " & quoted form of templateFolder
      do shell script "echo " & quoted form of defaultTemplate & " > " & quoted form of defaultPath
      return {path:defaultPath, content:defaultTemplate}
    on error
      -- Return template without saving
      return {path:"", content:defaultTemplate}
    end try
  end if
  
  -- Convert inputs to lowercase for matching
  set subjectLower to lowercase of messageSubject
  set bodyLower to lowercase of messageBody
  set senderLower to lowercase of senderName
  
  -- Define categories of templates to look for with their keywords
  set templateCategories to {¬
    {name:"urgent", keywords:{"urgent", "asap", "emergency", "immediately", "critical", "deadline", "tomorrow", "today"}}, ¬
    {name:"request", keywords:{"request", "asking", "could you", "would you", "need you to", "please", "help"}}, ¬
    {name:"question", keywords:{"question", "wondering", "curious", "how do", "what is", "clarify", "explain"}}, ¬
    {name:"meeting", keywords:{"meeting", "schedule", "appointment", "calendar", "discuss", "call", "zoom", "teams"}}, ¬
    {name:"feedback", keywords:{"feedback", "review", "thoughts", "opinion", "comment", "suggested", "changes"}}, ¬
    {name:"thank", keywords:{"thank", "appreciate", "grateful", "thanks", "received"}}, ¬
    {name:"complaint", keywords:{"issue", "problem", "complaint", "concerned", "disappointed", "dissatisfied", "failed", "error"}} ¬
  }
  
  -- First try to find template with sender's name or domain
  set senderTemplate to missing value
  set senderScore to 0
  repeat with templatePath in templatePaths
    set templateName to lowercase of (last text item of templatePath delimited by "/")
    
    -- Check if template name contains sender's name or domain
    set senderNameWords to my splitString(senderLower, " ")
    repeat with nameWord in senderNameWords
      if length of nameWord > 3 and templateName contains nameWord then
        set senderTemplate to templatePath
        set senderScore to senderScore + 5
        exit repeat
      end if
    end repeat
    
    -- Check if template is for sender's email domain
    if templateName contains "@" then
      set domainParts to my splitString(senderLower, "@")
      if (count of domainParts) > 1 then
        set domain to item 2 of domainParts
        if templateName contains domain then
          set senderTemplate to templatePath
          set senderScore to senderScore + 10
        end if
      end if
    end if
  end repeat
  
  -- Score templates based on keyword matches
  set bestTemplate to ""
  set bestScore to 0
  set bestContent to ""
  
  repeat with templatePath in templatePaths
    set templateName to lowercase of (last text item of templatePath delimited by "/")
    set matchScore to 0
    
    -- Check category keywords in subject and body
    repeat with category in templateCategories
      set categoryName to name of category
      set categoryKeywords to keywords of category
      
      if templateName contains categoryName then
        -- Check if category keywords appear in subject or body
        repeat with keyword in categoryKeywords
          if subjectLower contains keyword then
            set matchScore to matchScore + 3
          end if
          if bodyLower contains keyword then
            set matchScore to matchScore + 1
          end if
        end repeat
        
        -- Bonus for category name in subject
        if subjectLower contains categoryName then
          set matchScore to matchScore + 5
        end if
      end if
    end repeat
    
    -- If this template scores higher than current best, update
    if matchScore > bestScore then
      set bestTemplate to templatePath
      set bestScore to matchScore
      set bestContent to my readTemplateFile(templatePath)
    end if
  end repeat
  
  -- If sender match is better than keyword match, use that
  if senderTemplate is not missing value and senderScore > bestScore then
    set bestTemplate to senderTemplate
    set bestContent to my readTemplateFile(senderTemplate)
  end if
  
  -- If no good match found, use default template
  if bestTemplate is "" or bestContent is "" then
    -- Look for a default template
    repeat with templatePath in templatePaths
      set templateName to lowercase of (last text item of templatePath delimited by "/")
      if templateName contains "default" then
        set bestTemplate to templatePath
        set bestContent to my readTemplateFile(templatePath)
        exit repeat
      end if
    end repeat
    
    -- If still no template, use the first available
    if bestTemplate is "" or bestContent is "" and (count of templatePaths) > 0 then
      set bestTemplate to item 1 of templatePaths
      set bestContent to my readTemplateFile(bestTemplate)
    end if
  end if
  
  return {path:bestTemplate, content:bestContent}
end findBestTemplate

on processTemplate(templateContent, senderName, senderEmail, subject, body)
  -- Replace template placeholders with actual values
  set processedContent to templateContent
  
  -- Get user's name for signature
  set userName to "Me"
  try
    set userName to do shell script "id -F"
  end try
  
  -- Basic placeholder replacements
  set nameToUse to senderName
  if nameToUse contains "<" then
    -- Extract just the name part from "Name <email>"
    set AppleScript's text item delimiters to "<"
    set nameToUse to text item 1 of nameToUse
    set AppleScript's text item delimiters to ""
    -- Clean up trailing spaces
    repeat while nameToUse ends with " "
      set nameToUse to text 1 thru ((length of nameToUse) - 1) of nameToUse
    end repeat
  end if
  
  -- Get first name only
  set firstNameToUse to nameToUse
  set AppleScript's text item delimiters to " "
  set nameParts to text items of nameToUse
  if (count of nameParts) > 0 then
    set firstNameToUse to item 1 of nameParts
  end if
  set AppleScript's text item delimiters to ""
  
  -- Replace placeholders
  set processedContent to my replaceString(processedContent, "--NAME--", nameToUse)
  set processedContent to my replaceString(processedContent, "--FIRSTNAME--", firstNameToUse)
  set processedContent to my replaceString(processedContent, "--EMAIL--", senderEmail)
  set processedContent to my replaceString(processedContent, "--SUBJECT--", subject)
  set processedContent to my replaceString(processedContent, "--DATE--", (current date) as string)
  set processedContent to my replaceString(processedContent, "--YOUR-NAME--", userName)
  
  -- Advanced replacements - extract quoted text snippets
  if processedContent contains "--QUOTED--" then
    set quotedText to ""
    set bodyLines to paragraphs of body
    set maxLines to 3
    set lineCount to 0
    
    repeat with aLine in bodyLines
      if aLine is not "" and aLine does not start with ">" and lineCount < maxLines then
        if quotedText is not "" then
          set quotedText to quotedText & return
        end if
        set quotedText to quotedText & """ & aLine & """
        set lineCount to lineCount + 1
      end if
    end repeat
    
    set processedContent to my replaceString(processedContent, "--QUOTED--", quotedText)
  end if
  
  return processedContent
end processTemplate

on splitString(theString, theDelimiter)
  set AppleScript's text item delimiters to theDelimiter
  set theItems to text items of theString
  set AppleScript's text item delimiters to ""
  return theItems
end splitString

on replaceString(theText, searchString, replacementString)
  set AppleScript's text item delimiters to searchString
  set theTextItems to text items of theText
  set AppleScript's text item delimiters to replacementString
  set theText to theTextItems as text
  set AppleScript's text item delimiters to ""
  return theText
end replaceString

on extractEmailAddress(fullAddress)
  try
    -- Extract email from formats like "Name <email@example.com>" or just "email@example.com"
    if fullAddress contains "<" and fullAddress contains ">" then
      set AppleScript's text item delimiters to "<"
      set emailParts to text items of fullAddress
      
      if (count of emailParts) > 1 then
        set emailWithBracket to item 2 of emailParts
        set AppleScript's text item delimiters to ">"
        set emailAddress to item 1 of text items of emailWithBracket
        set AppleScript's text item delimiters to ""
        return emailAddress
      end if
    end if
    
    -- If no angle brackets, assume the whole string is an email
    if fullAddress contains "@" then
      return fullAddress
    end if
    
    return ""
  on error
    return ""
  end try
end extractEmailAddress

on smartReply(templateFolder)
  set folderPath to my setDefaultTemplatePath(templateFolder)
  
  tell application "Mail"
    try
      -- Check if a message is selected
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No message selected. Please select a message in Mail.app before running this script."
      end if
      
      -- Get the first selected message
      set theMessage to item 1 of selectedMessages
      set messageSubject to subject of theMessage
      set messageContent to content of theMessage
      set messageSender to sender of theMessage
      set senderEmail to my extractEmailAddress(messageSender)
      
      -- Find best template for this message
      set templateInfo to my findBestTemplate(folderPath, messageSubject, messageContent, messageSender)
      set templatePath to path of templateInfo
      set templateContent to content of templateInfo
      
      if templateContent is "" then
        return "Error: Could not find or read any suitable templates in " & folderPath
      end if
      
      -- Process template
      set replyBody to my processTemplate(templateContent, messageSender, senderEmail, messageSubject, messageContent)
      
      -- Create reply
      set replyMessage to reply theMessage with opening window
      
      -- Set reply content
      delay 0.5 -- Give Mail time to create the reply window
      set content of replyMessage to replyBody
      
      set templateName to "Default"
      if templatePath is not "" then
        set templateName to last text item of templatePath delimited by "/"
        set templateName to text 1 thru ((length of templateName) - 4) of templateName -- Remove .txt
      end if
      
      return "Created reply to " & messageSender & " using template: " & templateName
    on error errMsg
      return "Error creating smart reply: " & errMsg
    end try
  end tell
end smartReply

return my smartReply("--MCP_INPUT:templatePath")
```

This script:
1. Creates a reply to the selected email using customizable text templates
2. Intelligently selects the best template based on:
   - Keywords in the subject and message body
   - Sender's name or email domain
   - Message context and intent (e.g., urgent, thank you, question)
3. Substitutes placeholders like --NAME--, --SUBJECT--, --QUOTED-- with actual message details
4. Falls back to default templates if no specific match is found
5. Supports a template directory with multiple template files
6. Extracts key information from messages to personalize replies
7. Perfect for consistent, time-saving responses while maintaining personalization
8. Creates a default template if none exist in the specified folder
