---
title: Mail Automation Script
category: 09_productivity
id: mail_automation_script
description: >-
  Automates various email tasks in Apple Mail including sending, filtering,
  organizing, searching, and template-based responses
keywords:
  - email
  - mail
  - automation
  - templates
  - filter
  - organize
  - search
  - attachment
  - Apple Mail
  - message
language: applescript
notes: >-
  Works with Apple Mail application on macOS. Some operations require Mail to be
  the frontmost application.
---

```applescript
-- Mail Automation Script
-- Provides comprehensive automation capabilities for Apple Mail

-- Configuration properties
property defaultAccount : "" -- Leave empty to use default account
property defaultSignature : "" -- Leave empty to use default account signature
property templateFolder : "~/Library/Application Support/MailTemplates/"
property emailArchiveFolder : "Archive"
property logEnabled : true
property logFile : "~/Library/Logs/MailAutomation.log"

-- Initialize the mail automation script
on initializeMailAutomation()
  -- Check if Mail app is available
  try
    tell application "Mail" to get name
  on error
    display dialog "Error: Cannot access Apple Mail application. Make sure it's installed." buttons {"OK"} default button "OK" with icon stop
    return false
  end try
  
  -- Create template folder if it doesn't exist
  try
    set templateFolderPath to do shell script "echo " & quoted form of templateFolder
    do shell script "mkdir -p " & quoted form of templateFolderPath
  end try
  
  -- Initialize log file
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    do shell script "touch " & quoted form of fullLogPath
    logMessage("Mail automation initialized")
  end if
  
  return true
end initializeMailAutomation

-- Log a message to the log file
on logMessage(message)
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    set logLine to timeStamp & " - " & message
    do shell script "echo " & quoted form of logLine & " >> " & quoted form of fullLogPath
  end if
end logMessage

-- Get list of mail accounts
on getMailAccounts()
  tell application "Mail"
    set accountList to {}
    set allAccounts to accounts
    
    repeat with anAccount in allAccounts
      set accountName to name of anAccount
      set end of accountList to accountName
    end repeat
    
    return accountList
  end tell
end getMailAccounts

-- Get list of signatures
on getMailSignatures()
  tell application "Mail"
    set signatureList to {}
    set allSignatures to signatures
    
    repeat with aSignature in allSignatures
      set signatureName to name of aSignature
      set end of signatureList to signatureName
    end repeat
    
    return signatureList
  end tell
end getMailSignatures

-- Get mail folders for an account
on getMailFolders(accountName)
  tell application "Mail"
    set folderList to {}
    
    if accountName is "" then
      -- Get folders from all accounts
      set allAccounts to accounts
      repeat with anAccount in allAccounts
        set accName to name of anAccount
        set mailboxes of anAccount to mailboxes of anAccount -- Refresh mailboxes
        
        set accountFolders to mail folders of anAccount
        repeat with aFolder in accountFolders
          set folderName to name of aFolder
          set end of folderList to {account:accName, folder:folderName}
        end repeat
      end repeat
    else
      -- Get folders from the specified account
      try
        set targetAccount to account accountName
        set mailboxes of targetAccount to mailboxes of targetAccount -- Refresh mailboxes
        
        set accountFolders to mail folders of targetAccount
        repeat with aFolder in accountFolders
          set folderName to name of aFolder
          set end of folderList to {account:accountName, folder:folderName}
        end repeat
      on error
        -- Account not found
      end try
    end if
    
    return folderList
  end tell
end getMailFolders

-- Create and send a new email
on sendEmail(recipientEmail, emailSubject, emailBody, ccRecipients, bccRecipients, attachmentPath, accountName, signatureName)
  tell application "Mail"
    -- Create a new outgoing message
    set newMessage to make new outgoing message
    
    -- Set the subject
    set subject of newMessage to emailSubject
    
    -- Set the content
    set content of newMessage to emailBody
    
    -- Set the recipient
    tell newMessage
      make new to recipient with properties {address:recipientEmail}
      
      -- Add CC recipients if provided
      if ccRecipients is not {} then
        repeat with ccEmail in ccRecipients
          make new cc recipient with properties {address:ccEmail}
        end repeat
      end if
      
      -- Add BCC recipients if provided
      if bccRecipients is not {} then
        repeat with bccEmail in bccRecipients
          make new bcc recipient with properties {address:bccEmail}
        end repeat
      end if
      
      -- Add attachment if provided
      if attachmentPath is not "" then
        try
          -- Convert to POSIX path if needed
          if attachmentPath starts with "~" then
            set attachmentPath to do shell script "echo " & quoted form of attachmentPath
          end if
          
          -- Check if file exists
          set fileExists to do shell script "test -f " & quoted form of attachmentPath & " && echo 'yes' || echo 'no'"
          
          if fileExists is "yes" then
            tell content
              make new attachment with properties {file name:attachmentPath} at after the last paragraph
            end tell
          end if
        on error errMsg
          logMessage("Error adding attachment: " & errMsg)
        end try
      end if
    end tell
    
    -- Set account if specified
    if accountName is not "" then
      try
        set sender of newMessage to accountName
      on error errMsg
        logMessage("Error setting sender account: " & errMsg)
      end try
    end if
    
    -- Set signature if specified
    if signatureName is not "" then
      try
        set message signature of newMessage to signature signatureName
      on error errMsg
        logMessage("Error setting signature: " & errMsg)
      end try
    end if
    
    -- Send the email
    try
      send newMessage
      logMessage("Email sent to " & recipientEmail & " with subject '" & emailSubject & "'")
      return "Email sent successfully to " & recipientEmail
    on error errMsg
      logMessage("Error sending email: " & errMsg)
      return "Error sending email: " & errMsg
    end try
  end tell
end sendEmail

-- Create a new email from a template
on createEmailFromTemplate(templateName, recipientEmail, emailSubject, customFields, attachmentPath, accountName, signatureName)
  -- Load the template
  set templateContent to loadEmailTemplate(templateName)
  
  if templateContent is not "ERROR" then
    -- Replace placeholders with custom fields
    repeat with fieldName in keys of customFields
      set fieldValue to customFields's fieldName
      set templateContent to replaceText(templateContent, "[[" & fieldName & "]]", fieldValue)
    end repeat
    
    -- Send the email with the processed template
    return sendEmail(recipientEmail, emailSubject, templateContent, {}, {}, attachmentPath, accountName, signatureName)
  else
    return "Error: Template not found or could not be loaded"
  end if
end createEmailFromTemplate

-- Save current draft as a template
on saveDraftAsTemplate(templateName)
  tell application "Mail"
    try
      -- Get the current draft
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No message selected"
      end if
      
      set currentDraft to item 1 of selectedMessages
      
      -- Check if it's a draft
      set isDraft to (message type of currentDraft is draft message)
      if not isDraft then
        return "Error: Selected message is not a draft"
      end if
      
      -- Get the content of the draft
      set draftContent to content of currentDraft
      
      -- Save it as a template
      set templatePath to templateFolder & templateName & ".mailtemplate"
      set templatePath to do shell script "echo " & quoted form of templatePath
      
      do shell script "echo " & quoted form of draftContent & " > " & quoted form of templatePath
      
      logMessage("Template saved: " & templateName)
      return "Template saved as '" & templateName & "'"
    on error errMsg
      logMessage("Error saving template: " & errMsg)
      return "Error saving template: " & errMsg
    end try
  end tell
end saveDraftAsTemplate

-- Create a new template
on createEmailTemplate(templateName, templateContent)
  try
    -- Save the template to the templates folder
    set templatePath to templateFolder & templateName & ".mailtemplate"
    set templatePath to do shell script "echo " & quoted form of templatePath
    
    do shell script "echo " & quoted form of templateContent & " > " & quoted form of templatePath
    
    logMessage("Template created: " & templateName)
    return "Template '" & templateName & "' created successfully"
  on error errMsg
    logMessage("Error creating template: " & errMsg)
    return "Error creating template: " & errMsg
  end try
end createEmailTemplate

-- Load an email template
on loadEmailTemplate(templateName)
  try
    set templatePath to templateFolder & templateName & ".mailtemplate"
    set templatePath to do shell script "echo " & quoted form of templatePath
    
    -- Check if template exists
    set fileExists to do shell script "test -f " & quoted form of templatePath & " && echo 'yes' || echo 'no'"
    
    if fileExists is "yes" then
      set templateContent to do shell script "cat " & quoted form of templatePath
      return templateContent
    else
      logMessage("Template not found: " & templateName)
      return "ERROR"
    end if
  on error errMsg
    logMessage("Error loading template: " & errMsg)
    return "ERROR"
  end try
end loadEmailTemplate

-- List available templates
on listEmailTemplates()
  try
    set templatesFolder to do shell script "echo " & quoted form of templateFolder
    
    -- List .mailtemplate files in the templates folder
    set templateFiles to paragraphs of (do shell script "ls -1 " & quoted form of templatesFolder & "*.mailtemplate 2>/dev/null || echo ''")
    
    set templateNames to {}
    
    repeat with templateFile in templateFiles
      if templateFile is not "" then
        -- Extract template name from filename
        set templateName to do shell script "basename " & quoted form of templateFile & " .mailtemplate"
        set end of templateNames to templateName
      end if
    end repeat
    
    return templateNames
  on error errMsg
    logMessage("Error listing templates: " & errMsg)
    return {}
  end try
end listEmailTemplates

-- Search emails with criteria
on searchEmails(searchCriteria)
  tell application "Mail"
    try
      set searchResults to {}
      
      -- Get the account to search in
      set accountToSearch to missing value
      if searchCriteria's account is not "" then
        set accountToSearch to account searchCriteria's account
      end if
      
      -- Get the mailbox to search in
      set mailboxToSearch to missing value
      if searchCriteria's folder is not "" and accountToSearch is not missing value then
        set mailboxToSearch to mailbox searchCriteria's folder of accountToSearch
      end if
      
      -- Build the search string
      set searchString to ""
      
      if searchCriteria's subject is not "" then
        set searchString to searchString & " subject:" & quoted form of searchCriteria's subject
      end if
      
      if searchCriteria's sender is not "" then
        set searchString to searchString & " from:" & quoted form of searchCriteria's sender
      end if
      
      if searchCriteria's recipient is not "" then
        set searchString to searchString & " to:" & quoted form of searchCriteria's recipient
      end if
      
      if searchCriteria's content is not "" then
        set searchString to searchString & " content:" & quoted form of searchCriteria's content
      end if
      
      -- Perform the search
      if mailboxToSearch is not missing value then
        -- Search in specific mailbox
        set foundMessages to search mailboxToSearch for searchString
      else if accountToSearch is not missing value then
        -- Search in all mailboxes of the account
        set foundMessages to search accountToSearch for searchString
      else
        -- Search in all accounts
        set foundMessages to search for searchString
      end if
      
      -- Filter by date if specified
      if searchCriteria's dateSince is not "" then
        try
          set dateThreshold to date searchCriteria's dateSince
          set filteredMessages to {}
          
          repeat with aMessage in foundMessages
            if date received of aMessage ≥ dateThreshold then
              set end of filteredMessages to aMessage
            end if
          end repeat
          
          set foundMessages to filteredMessages
        end try
      end if
      
      -- Limit results if specified
      if searchCriteria's maxResults is not "" and searchCriteria's maxResults is not 0 then
        set maxCount to searchCriteria's maxResults as integer
        if (count of foundMessages) > maxCount then
          set foundMessages to items 1 thru maxCount of foundMessages
        end if
      end if
      
      -- Extract information from found messages
      repeat with aMessage in foundMessages
        set messageSubject to subject of aMessage
        set messageSender to sender of aMessage
        set messageDate to date received of aMessage
        
        set messageInfo to {subject:messageSubject, sender:messageSender, date:messageDate}
        set end of searchResults to messageInfo
      end repeat
      
      logMessage("Search completed, found " & (count of searchResults) & " messages")
      return searchResults
    on error errMsg
      logMessage("Error during search: " & errMsg)
      return {}
    end try
  end tell
end searchEmails

-- Move messages to a folder
on moveMessages(messageCriteria, destinationFolder, destinationAccount)
  tell application "Mail"
    try
      -- Find messages to move
      set messagesToMove to {}
      
      -- Prepare search criteria
      set searchCriteria to {subject:messageCriteria's subject, sender:messageCriteria's sender, recipient:messageCriteria's recipient, content:messageCriteria's content, account:messageCriteria's account, folder:messageCriteria's folder, dateSince:messageCriteria's dateSince, maxResults:""}
      
      -- Perform search
      set searchResults to my searchEmails(searchCriteria)
      
      -- Get the search results as actual message objects
      if searchResults is not {} then
        set searchString to ""
        
        if messageCriteria's subject is not "" then
          set searchString to searchString & " subject:" & quoted form of messageCriteria's subject
        end if
        
        if messageCriteria's sender is not "" then
          set searchString to searchString & " from:" & quoted form of messageCriteria's sender
        end if
        
        if messageCriteria's recipient is not "" then
          set searchString to searchString & " to:" & quoted form of messageCriteria's recipient
        end if
        
        if messageCriteria's content is not "" then
          set searchString to searchString & " content:" & quoted form of messageCriteria's content
        end if
        
        -- Get account and folder for search
        set accountToSearch to missing value
        set mailboxToSearch to missing value
        
        if messageCriteria's account is not "" then
          set accountToSearch to account messageCriteria's account
          
          if messageCriteria's folder is not "" then
            set mailboxToSearch to mailbox messageCriteria's folder of accountToSearch
          end if
        end if
        
        -- Execute search to get message objects
        if mailboxToSearch is not missing value then
          set messagesToMove to search mailboxToSearch for searchString
        else if accountToSearch is not missing value then
          set messagesToMove to search accountToSearch for searchString
        else
          set messagesToMove to search for searchString
        end if
        
        -- Filter by date if needed
        if messageCriteria's dateSince is not "" then
          try
            set dateThreshold to date messageCriteria's dateSince
            set filteredMessages to {}
            
            repeat with aMessage in messagesToMove
              if date received of aMessage ≥ dateThreshold then
                set end of filteredMessages to aMessage
              end if
            end repeat
            
            set messagesToMove to filteredMessages
          end try
        end if
      end if
      
      -- If we found messages to move
      if (count of messagesToMove) > 0 then
        -- Get destination mailbox
        set targetMailbox to missing value
        
        if destinationAccount is not "" then
          set targetAccount to account destinationAccount
          set targetMailbox to mailbox destinationFolder of targetAccount
        else
          -- Try to find the folder in any account
          set allAccounts to accounts
          repeat with anAccount in allAccounts
            try
              set targetMailbox to mailbox destinationFolder of anAccount
              exit repeat
            end try
          end repeat
        end if
        
        if targetMailbox is missing value then
          return "Error: Destination folder not found"
        end if
        
        -- Move the messages
        repeat with aMessage in messagesToMove
          move aMessage to targetMailbox
        end repeat
        
        logMessage("Moved " & (count of messagesToMove) & " messages to " & destinationFolder)
        return "Moved " & (count of messagesToMove) & " messages to " & destinationFolder
      else
        return "No messages found matching the criteria"
      end if
    on error errMsg
      logMessage("Error moving messages: " & errMsg)
      return "Error moving messages: " & errMsg
    end try
  end tell
end moveMessages

-- Mark messages as read/unread
on markMessages(messageCriteria, markAsRead)
  tell application "Mail"
    try
      -- Find messages to mark
      set messagesToMark to {}
      
      -- Prepare search criteria
      set searchCriteria to {subject:messageCriteria's subject, sender:messageCriteria's sender, recipient:messageCriteria's recipient, content:messageCriteria's content, account:messageCriteria's account, folder:messageCriteria's folder, dateSince:messageCriteria's dateSince, maxResults:""}
      
      -- Perform search to get actual message objects (similar to moveMessages function)
      set searchString to ""
      
      if messageCriteria's subject is not "" then
        set searchString to searchString & " subject:" & quoted form of messageCriteria's subject
      end if
      
      if messageCriteria's sender is not "" then
        set searchString to searchString & " from:" & quoted form of messageCriteria's sender
      end if
      
      if messageCriteria's recipient is not "" then
        set searchString to searchString & " to:" & quoted form of messageCriteria's recipient
      end if
      
      if messageCriteria's content is not "" then
        set searchString to searchString & " content:" & quoted form of messageCriteria's content
      end if
      
      -- Get account and folder for search
      set accountToSearch to missing value
      set mailboxToSearch to missing value
      
      if messageCriteria's account is not "" then
        set accountToSearch to account messageCriteria's account
        
        if messageCriteria's folder is not "" then
          set mailboxToSearch to mailbox messageCriteria's folder of accountToSearch
        end if
      end if
      
      -- Execute search to get message objects
      if mailboxToSearch is not missing value then
        set messagesToMark to search mailboxToSearch for searchString
      else if accountToSearch is not missing value then
        set messagesToMark to search accountToSearch for searchString
      else
        set messagesToMark to search for searchString
      end if
      
      -- Filter by date if needed
      if messageCriteria's dateSince is not "" then
        try
          set dateThreshold to date messageCriteria's dateSince
          set filteredMessages to {}
          
          repeat with aMessage in messagesToMark
            if date received of aMessage ≥ dateThreshold then
              set end of filteredMessages to aMessage
            end if
          end repeat
          
          set messagesToMark to filteredMessages
        end try
      end if
      
      -- If we found messages to mark
      if (count of messagesToMark) > 0 then
        -- Mark the messages
        repeat with aMessage in messagesToMark
          set read status of aMessage to markAsRead
        end repeat
        
        set actionText to "marked as " & (if markAsRead then "read" else "unread")
        logMessage((count of messagesToMark) & " messages " & actionText)
        return (count of messagesToMark) & " messages " & actionText
      else
        return "No messages found matching the criteria"
      end if
    on error errMsg
      logMessage("Error marking messages: " & errMsg)
      return "Error marking messages: " & errMsg
    end try
  end tell
end markMessages

-- Archive messages based on criteria
on archiveMessages(messageCriteria)
  -- Prepare the criteria for move operation
  set moveResult to moveMessages(messageCriteria, emailArchiveFolder, messageCriteria's account)
  return moveResult
end archiveMessages

-- Helper function to parse email addresses
on parseEmailAddresses(emailString)
  -- Split the string by commas
  set AppleScript's text item delimiters to ","
  set emailItems to text items of emailString
  set AppleScript's text item delimiters to ""
  
  set emailList to {}
  
  repeat with anEmail in emailItems
    -- Trim whitespace
    set trimmedEmail to do shell script "echo " & quoted form of anEmail & " | xargs"
    if trimmedEmail is not "" then
      set end of emailList to trimmedEmail
    end if
  end repeat
  
  return emailList
end parseEmailAddresses

-- Helper function to replace text
on replaceText(theText, searchString, replacementString)
  set AppleScript's text item delimiters to searchString
  set textItems to text items of theText
  set AppleScript's text item delimiters to replacementString
  set newText to textItems as text
  set AppleScript's text item delimiters to ""
  return newText
end replaceText

-- Show dialog to create a new email
on showNewEmailDialog()
  tell application "Mail"
    -- Get list of accounts
    set accountList to my getMailAccounts()
    if accountList is {} then
      return "Error: No mail accounts found"
    end if
    
    -- Get list of signatures
    set signatureList to my getMailSignatures()
    
    -- Recipient dialog
    set recipientDialog to display dialog "To: (email address)" default answer "" buttons {"Cancel", "Template", "Next"} default button "Next"
    
    if button returned of recipientDialog is "Cancel" then
      return "Email creation cancelled"
    end if
    
    set recipientEmail to text returned of recipientDialog
    
    if button returned of recipientDialog is "Template" then
      -- Show template dialog
      set templateList to my listEmailTemplates()
      
      if templateList is {} then
        display dialog "No email templates found" buttons {"OK"} default button "OK"
        return "No email templates available"
      end if
      
      set selectedTemplate to choose from list templateList with prompt "Select Email Template:" default items item 1 of templateList
      
      if selectedTemplate is false then
        return "Template selection cancelled"
      end if
      
      set templateName to item 1 of selectedTemplate
      
      -- Ask for subject
      set subjectDialog to display dialog "Email Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
      
      if button returned of subjectDialog is "Cancel" then
        return "Email creation cancelled"
      end if
      
      set emailSubject to text returned of subjectDialog
      
      -- Ask for custom fields
      set customFieldsDialog to display dialog "Custom Fields (format: field1=value1, field2=value2):" default answer "" buttons {"Cancel", "Next"} default button "Next"
      
      if button returned of customFieldsDialog is "Cancel" then
        return "Email creation cancelled"
      end if
      
      -- Parse custom fields
      set customFieldsText to text returned of customFieldsDialog
      set customFields to {}
      
      if customFieldsText is not "" then
        set AppleScript's text item delimiters to ","
        set fieldPairs to text items of customFieldsText
        set AppleScript's text item delimiters to ""
        
        repeat with aPair in fieldPairs
          set AppleScript's text item delimiters to "="
          set pairItems to text items of aPair
          set AppleScript's text item delimiters to ""
          
          if (count of pairItems) ≥ 2 then
            set fieldName to item 1 of pairItems
            set fieldValue to items 2 thru -1 of pairItems as text
            
            -- Trim whitespace
            set fieldName to do shell script "echo " & quoted form of fieldName & " | xargs"
            set fieldValue to do shell script "echo " & quoted form of fieldValue & " | xargs"
            
            if fieldName is not "" then
              set customFields's fieldName to fieldValue
            end if
          end if
        end repeat
      end if
      
      -- Ask for attachment
      set attachmentDialog to display dialog "Attachment Path (optional):" default answer "" buttons {"Cancel", "Skip", "Choose File"} default button "Skip"
      
      set attachmentPath to ""
      
      if button returned of attachmentDialog is "Choose File" then
        set chosenFile to choose file with prompt "Select an attachment:"
        set attachmentPath to POSIX path of chosenFile
      else if button returned of attachmentDialog is "Cancel" then
        return "Email creation cancelled"
      else
        set attachmentPath to text returned of attachmentDialog
      end if
      
      -- Select account if there are multiple
      set accountName to ""
      if (count of accountList) > 1 then
        set selectedAccount to choose from list accountList with prompt "Select Account:" default items item 1 of accountList
        
        if selectedAccount is false then
          set accountName to ""
        else
          set accountName to item 1 of selectedAccount
        end if
      else if (count of accountList) is 1 then
        set accountName to item 1 of accountList
      end if
      
      -- Select signature if available
      set signatureName to ""
      if signatureList is not {} then
        set signatureOptions to {"None"} & signatureList
        set selectedSignature to choose from list signatureOptions with prompt "Select Signature:" default items {"None"}
        
        if selectedSignature is not false and item 1 of selectedSignature is not "None" then
          set signatureName to item 1 of selectedSignature
        end if
      end if
      
      -- Create email from template
      return createEmailFromTemplate(templateName, recipientEmail, emailSubject, customFields, attachmentPath, accountName, signatureName)
    else
      -- Continue with normal email creation
      -- Subject dialog
      set subjectDialog to display dialog "Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
      
      if button returned of subjectDialog is "Cancel" then
        return "Email creation cancelled"
      end if
      
      set emailSubject to text returned of subjectDialog
      
      -- Body dialog
      set bodyDialog to display dialog "Email Body:" default answer "" buttons {"Cancel", "Next"} default button "Next" with multiple line editing
      
      if button returned of bodyDialog is "Cancel" then
        return "Email creation cancelled"
      end if
      
      set emailBody to text returned of bodyDialog
      
      -- CC dialog
      set ccDialog to display dialog "CC: (comma-separated, optional)" default answer "" buttons {"Cancel", "Skip", "Next"} default button "Skip"
      
      set ccList to {}
      
      if button returned of ccDialog is "Cancel" then
        return "Email creation cancelled"
      else if button returned of ccDialog is "Next" then
        set ccString to text returned of ccDialog
        set ccList to parseEmailAddresses(ccString)
      end if
      
      -- BCC dialog
      set bccDialog to display dialog "BCC: (comma-separated, optional)" default answer "" buttons {"Cancel", "Skip", "Next"} default button "Skip"
      
      set bccList to {}
      
      if button returned of bccDialog is "Cancel" then
        return "Email creation cancelled"
      else if button returned of bccDialog is "Next" then
        set bccString to text returned of bccDialog
        set bccList to parseEmailAddresses(bccString)
      end if
      
      -- Attachment dialog
      set attachmentDialog to display dialog "Attachment Path (optional):" default answer "" buttons {"Cancel", "Skip", "Choose File"} default button "Skip"
      
      set attachmentPath to ""
      
      if button returned of attachmentDialog is "Choose File" then
        try
          set chosenFile to choose file with prompt "Select an attachment:"
          set attachmentPath to POSIX path of chosenFile
        on error
          -- User cancelled file selection
          set attachmentPath to ""
        end try
      else if button returned of attachmentDialog is "Cancel" then
        return "Email creation cancelled"
      else if button returned of attachmentDialog is "Next" then
        set attachmentPath to text returned of attachmentDialog
      end if
      
      -- Select account if there are multiple
      set accountName to ""
      if (count of accountList) > 1 then
        set selectedAccount to choose from list accountList with prompt "Select Account:" default items item 1 of accountList
        
        if selectedAccount is false then
          set accountName to ""
        else
          set accountName to item 1 of selectedAccount
        end if
      else if (count of accountList) is 1 then
        set accountName to item 1 of accountList
      end if
      
      -- Select signature if available
      set signatureName to ""
      if signatureList is not {} then
        set signatureOptions to {"None"} & signatureList
        set selectedSignature to choose from list signatureOptions with prompt "Select Signature:" default items {"None"}
        
        if selectedSignature is not false and item 1 of selectedSignature is not "None" then
          set signatureName to item 1 of selectedSignature
        end if
      end if
      
      -- Send the email
      return sendEmail(recipientEmail, emailSubject, emailBody, ccList, bccList, attachmentPath, accountName, signatureName)
    end if
  end tell
end showNewEmailDialog

-- Show dialog for email search and organization
on showSearchOrganizeDialog()
  -- Criteria dialog
  set criteriaDialog to display dialog "Search/Organize Emails" & return & return & "Enter search criteria (leave blank for any):" & return & "Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of criteriaDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set subjectCriteria to text returned of criteriaDialog
  
  -- Sender dialog
  set senderDialog to display dialog "From: (sender)" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of senderDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set senderCriteria to text returned of senderDialog
  
  -- Recipient dialog
  set recipientDialog to display dialog "To: (recipient)" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of recipientDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set recipientCriteria to text returned of recipientDialog
  
  -- Content dialog
  set contentDialog to display dialog "Content contains:" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of contentDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set contentCriteria to text returned of contentDialog
  
  -- Date dialog
  set dateDialog to display dialog "Since date (e.g., 'yesterday', '2023-01-01'):" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of dateDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set dateCriteria to text returned of dateDialog
  
  -- Get list of accounts
  set accountList to getMailAccounts()
  set accountOptions to {"All Accounts"} & accountList
  
  -- Account selection
  set selectedAccount to choose from list accountOptions with prompt "Select Account:" default items {"All Accounts"}
  
  if selectedAccount is false then
    return "Search cancelled"
  end if
  
  set accountCriteria to ""
  if item 1 of selectedAccount is not "All Accounts" then
    set accountCriteria to item 1 of selectedAccount
  end if
  
  -- Folder selection (if account was selected)
  set folderCriteria to ""
  if accountCriteria is not "" then
    set folderList to getMailFolders(accountCriteria)
    
    set folderNames to {"All Folders"}
    repeat with aFolder in folderList
      set folderName to aFolder's folder
      set end of folderNames to folderName
    end repeat
    
    set selectedFolder to choose from list folderNames with prompt "Select Folder:" default items {"All Folders"}
    
    if selectedFolder is false then
      return "Search cancelled"
    end if
    
    if item 1 of selectedFolder is not "All Folders" then
      set folderCriteria to item 1 of selectedFolder
    end if
  end if
  
  -- Action selection
  set actionOptions to {"Search Only", "Mark as Read", "Mark as Unread", "Move to Folder", "Archive"}
  set selectedAction to choose from list actionOptions with prompt "Select Action:" default items {"Search Only"}
  
  if selectedAction is false then
    return "Operation cancelled"
  end if
  
  set actionType to item 1 of selectedAction
  
  -- Prepare criteria
  set messageCriteria to {subject:subjectCriteria, sender:senderCriteria, recipient:recipientCriteria, content:contentCriteria, account:accountCriteria, folder:folderCriteria, dateSince:dateCriteria, maxResults:"100"}
  
  -- Perform the selected action
  if actionType is "Search Only" then
    -- Perform search
    set searchResults to searchEmails(messageCriteria)
    
    if searchResults is {} then
      return "No messages found matching the criteria"
    end if
    
    -- Format search results for display
    set resultText to "Search Results:" & return & return
    
    repeat with i from 1 to count of searchResults
      set messageInfo to item i of searchResults
      set messageSubject to messageInfo's subject
      set messageSender to messageInfo's sender
      set messageDate to messageInfo's date as string
      
      set resultText to resultText & i & ". " & messageSubject & return
      set resultText to resultText & "   From: " & messageSender & return
      set resultText to resultText & "   Date: " & messageDate & return & return
    end repeat
    
    -- Display results
    display dialog resultText buttons {"OK"} default button "OK"
    return "Found " & (count of searchResults) & " messages"
    
  else if actionType is "Mark as Read" then
    -- Mark messages as read
    return markMessages(messageCriteria, true)
    
  else if actionType is "Mark as Unread" then
    -- Mark messages as unread
    return markMessages(messageCriteria, false)
    
  else if actionType is "Move to Folder" then
    -- Get list of all mail folders across accounts
    set allFolders to getMailFolders("")
    
    set folderOptions to {}
    repeat with aFolder in allFolders
      set accountName to aFolder's account
      set folderName to aFolder's folder
      set folderDisplay to folderName & " (" & accountName & ")"
      set end of folderOptions to {display:folderDisplay, account:accountName, folder:folderName}
    end repeat
    
    -- Extract just the display names for the choose from list
    set folderDisplays to {}
    repeat with aFolder in folderOptions
      set end of folderDisplays to aFolder's display
    end repeat
    
    -- Select destination folder
    set selectedDestination to choose from list folderDisplays with prompt "Select Destination Folder:" default items item 1 of folderDisplays
    
    if selectedDestination is false then
      return "Move operation cancelled"
    end if
    
    -- Find the selected folder details
    set destinationAccount to ""
    set destinationFolder to ""
    
    repeat with i from 1 to count of folderOptions
      if (folderOptions's item i)'s display is item 1 of selectedDestination then
        set destinationAccount to (folderOptions's item i)'s account
        set destinationFolder to (folderOptions's item i)'s folder
        exit repeat
      end if
    end repeat
    
    -- Move the messages
    return moveMessages(messageCriteria, destinationFolder, destinationAccount)
    
  else if actionType is "Archive" then
    -- Archive the messages
    return archiveMessages(messageCriteria)
  end if
  
  return "Operation completed"
end showSearchOrganizeDialog

-- Show template management dialog
on showTemplateDialog()
  set templateOptions to {"Create New Template", "Edit Template", "Use Template", "Delete Template", "Cancel"}
  
  set selectedOption to choose from list templateOptions with prompt "Email Template Management:" default items {"Create New Template"}
  
  if selectedOption is false then
    return "Template management cancelled"
  end if
  
  set templateAction to item 1 of selectedOption
  
  if templateAction is "Create New Template" then
    -- Template name dialog
    set nameDialog to display dialog "Template Name:" default answer "" buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of nameDialog is "Cancel" then
      return "Template creation cancelled"
    end if
    
    set templateName to text returned of nameDialog
    if templateName is "" then
      display dialog "Template name cannot be empty" buttons {"OK"} default button "OK" with icon stop
      return "Template creation cancelled: No name provided"
    end if
    
    -- Template content dialog
    set contentDialog to display dialog "Template Content:" & return & return & "Use [[placeholder]] for customizable fields" default answer "" buttons {"Cancel", "Save Template"} default button "Save Template" with multiple line editing
    
    if button returned of contentDialog is "Cancel" then
      return "Template creation cancelled"
    end if
    
    set templateContent to text returned of contentDialog
    
    -- Create the template
    return createEmailTemplate(templateName, templateContent)
    
  else if templateAction is "Edit Template" then
    -- Get list of templates
    set templateList to listEmailTemplates()
    
    if templateList is {} then
      display dialog "No email templates found" buttons {"OK"} default button "OK"
      return "No email templates available"
    end if
    
    -- Select template to edit
    set selectedTemplate to choose from list templateList with prompt "Select Template to Edit:" default items item 1 of templateList
    
    if selectedTemplate is false then
      return "Template editing cancelled"
    end if
    
    set templateName to item 1 of selectedTemplate
    
    -- Load the template
    set templateContent to loadEmailTemplate(templateName)
    
    if templateContent is "ERROR" then
      return "Error loading template"
    end if
    
    -- Edit content dialog
    set editDialog to display dialog "Edit Template Content:" default answer templateContent buttons {"Cancel", "Save Changes"} default button "Save Changes" with multiple line editing
    
    if button returned of editDialog is "Cancel" then
      return "Template editing cancelled"
    end if
    
    set newContent to text returned of editDialog
    
    -- Save the updated template
    return createEmailTemplate(templateName, newContent)
    
  else if templateAction is "Use Template" then
    -- Get list of templates
    set templateList to listEmailTemplates()
    
    if templateList is {} then
      display dialog "No email templates found" buttons {"OK"} default button "OK"
      return "No email templates available"
    end if
    
    -- Select template to use
    set selectedTemplate to choose from list templateList with prompt "Select Template:" default items item 1 of templateList
    
    if selectedTemplate is false then
      return "Template selection cancelled"
    end if
    
    set templateName to item 1 of selectedTemplate
    
    -- Recipient dialog
    set recipientDialog to display dialog "To: (email address)" default answer "" buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of recipientDialog is "Cancel" then
      return "Email creation cancelled"
    end if
    
    set recipientEmail to text returned of recipientDialog
    
    -- Subject dialog
    set subjectDialog to display dialog "Email Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of subjectDialog is "Cancel" then
      return "Email creation cancelled"
    end if
    
    set emailSubject to text returned of subjectDialog
    
    -- Load the template to find placeholders
    set templateContent to loadEmailTemplate(templateName)
    
    if templateContent is "ERROR" then
      return "Error loading template"
    end if
    
    -- Find placeholders in the template
    set placeholders to {}
    set remainingText to templateContent
    set placeholderFormat to "\\[\\[(.*?)\\]\\]"
    
    repeat
      try
        -- Use grep to find placeholders
        set grepCommand to "echo " & quoted form of remainingText & " | grep -o '" & placeholderFormat & "' | head -1"
        set placeholderMatch to do shell script grepCommand
        
        -- Extract the placeholder name
        set placeholderName to do shell script "echo " & quoted form of placeholderMatch & " | sed 's/\\[\\[\\(.*\\)\\]\\]/\\1/'"
        
        -- Add to list if not already present
        if placeholderName is not in placeholders then
          set end of placeholders to placeholderName
        end if
        
        -- Remove the found placeholder to find the next one
        set placeholderEscaped to do shell script "echo " & quoted form of placeholderMatch & " | sed 's/\\[/\\\\[/g' | sed 's/\\]/\\\\]/g'"
        set remainingText to do shell script "echo " & quoted form of remainingText & " | sed 's/" & placeholderEscaped & "//'"
      on error
        -- No more placeholders found
        exit repeat
      end try
    end repeat
    
    -- Create custom fields dialog based on placeholders
    set customFields to {}
    
    repeat with placeholder in placeholders
      set placeholderDialog to display dialog "Enter value for [[" & placeholder & "]]:" default answer "" buttons {"Cancel", "Next"} default button "Next"
      
      if button returned of placeholderDialog is "Cancel" then
        return "Email creation cancelled"
      end if
      
      set placeholderValue to text returned of placeholderDialog
      set customFields's placeholder to placeholderValue
    end repeat
    
    -- Get list of accounts
    set accountList to getMailAccounts()
    
    -- Select account if there are multiple
    set accountName to ""
    if (count of accountList) > 1 then
      set selectedAccount to choose from list accountList with prompt "Select Account:" default items item 1 of accountList
      
      if selectedAccount is false then
        set accountName to ""
      else
        set accountName to item 1 of selectedAccount
      end if
    else if (count of accountList) is 1 then
      set accountName to item 1 of accountList
    end if
    
    -- Get list of signatures
    set signatureList to getMailSignatures()
    
    -- Select signature if available
    set signatureName to ""
    if signatureList is not {} then
      set signatureOptions to {"None"} & signatureList
      set selectedSignature to choose from list signatureOptions with prompt "Select Signature:" default items {"None"}
      
      if selectedSignature is not false and item 1 of selectedSignature is not "None" then
        set signatureName to item 1 of selectedSignature
      end if
    end if
    
    -- Create email from template
    return createEmailFromTemplate(templateName, recipientEmail, emailSubject, customFields, "", accountName, signatureName)
    
  else if templateAction is "Delete Template" then
    -- Get list of templates
    set templateList to listEmailTemplates()
    
    if templateList is {} then
      display dialog "No email templates found" buttons {"OK"} default button "OK"
      return "No email templates available"
    end if
    
    -- Select template to delete
    set selectedTemplate to choose from list templateList with prompt "Select Template to Delete:" default items item 1 of templateList
    
    if selectedTemplate is false then
      return "Template deletion cancelled"
    end if
    
    set templateName to item 1 of selectedTemplate
    
    -- Confirm deletion
    set confirmDialog to display dialog "Are you sure you want to delete template '" & templateName & "'?" buttons {"Cancel", "Delete"} default button "Cancel" with icon caution
    
    if button returned of confirmDialog is "Cancel" then
      return "Template deletion cancelled"
    end if
    
    -- Delete the template
    try
      set templatePath to templateFolder & templateName & ".mailtemplate"
      set templatePath to do shell script "echo " & quoted form of templatePath
      
      do shell script "rm " & quoted form of templatePath
      
      logMessage("Template deleted: " & templateName)
      return "Template '" & templateName & "' deleted successfully"
    on error errMsg
      logMessage("Error deleting template: " & errMsg)
      return "Error deleting template: " & errMsg
    end try
  else
    return "Template management cancelled"
  end if
end showTemplateDialog

-- Show Save Current Draft as Template dialog
on showSaveDraftDialog()
  tell application "Mail"
    -- Check if a draft is selected
    set selectedMessages to selection
    
    if (count of selectedMessages) is 0 then
      return "Error: No message selected"
    end if
    
    set currentMessage to item 1 of selectedMessages
    
    -- Check if it's a draft
    set isDraft to (message type of currentMessage is draft message)
    if not isDraft then
      return "Error: Selected message is not a draft"
    end if
    
    -- Ask for template name
    set nameDialog to display dialog "Save Draft as Template:" & return & return & "Template Name:" default answer "" buttons {"Cancel", "Save"} default button "Save"
    
    if button returned of nameDialog is "Cancel" then
      return "Save as template cancelled"
    end if
    
    set templateName to text returned of nameDialog
    if templateName is "" then
      display dialog "Template name cannot be empty" buttons {"OK"} default button "OK" with icon stop
      return "Save as template cancelled: No name provided"
    end if
    
    -- Save the draft as template
    return saveDraftAsTemplate(templateName)
  end tell
end showSaveDraftDialog

-- Show the main Mail Automation menu
on showMailMenu()
  if not initializeMailAutomation() then
    return "Failed to initialize Mail Automation"
  end if
  
  set menuOptions to {"New Email", "Search/Organize Emails", "Manage Templates", "Save Draft as Template", "Cancel"}
  
  set selectedOption to choose from list menuOptions with prompt "Mail Automation:" default items {"New Email"}
  
  if selectedOption is false then
    return "Mail automation cancelled"
  end if
  
  set menuChoice to item 1 of selectedOption
  
  if menuChoice is "New Email" then
    return showNewEmailDialog()
    
  else if menuChoice is "Search/Organize Emails" then
    return showSearchOrganizeDialog()
    
  else if menuChoice is "Manage Templates" then
    return showTemplateDialog()
    
  else if menuChoice is "Save Draft as Template" then
    return showSaveDraftDialog()
    
  else
    return "Mail automation cancelled"
  end if
end showMailMenu

-- Run the Mail Automation script
on run
  return showMailMenu()
end run
```

This Mail Automation Script provides a comprehensive set of tools for automating and streamlining email tasks in Apple Mail. The script combines powerful email management features with a user-friendly interface to help users handle their email more efficiently.

### Key Features:

1. **Email Composition and Sending**:
   - Create and send emails with full formatting options
   - Support for CC and BCC recipients
   - File attachments
   - Multiple account and signature selection
   - Draft management

2. **Template System**:
   - Create and manage reusable email templates
   - Customizable placeholders for personalization
   - Save drafts as templates for future use
   - Template editing and organization
   - Placeholder auto-detection and filling

3. **Email Search and Organization**:
   - Advanced search with multiple criteria (subject, sender, recipient, content)
   - Date-based filtering
   - Account and folder specific searches
   - Limit search results for performance

4. **Batch Email Operations**:
   - Move messages between folders
   - Mark messages as read/unread
   - Archive messages automatically
   - Apply operations to search results

5. **Account and Folder Management**:
   - Support for multiple mail accounts
   - Folder navigation and selection
   - Signature management
   - Cross-account operations

### Usage Examples:

1. **Using Email Templates**:
   - Create templates with placeholders like `[[name]]` and `[[company]]`
   - When using the template, you'll be prompted to fill in these placeholders
   - Save commonly used email formats as templates for consistent communication

2. **Email Organization**:
   - Find all unread messages from a specific sender
   - Locate emails with attachments matching certain criteria
   - Move old emails to an archive folder based on date

3. **Batch Processing**:
   - Mark all messages matching certain criteria as read
   - Move messages to specific folders based on content or sender
   - Archive old messages while preserving important ones

This script is highly customizable with properties for controlling default behavior, logging, and template storage. It provides a complete email management solution while maintaining a user-friendly interface that guides users through each operation step by step.
