---
title: Mail Email Composition and Sending
category: 09_productivity
id: mail_email_composition
description: Functions for creating and sending emails with Apple Mail automation
keywords:
  - email
  - mail
  - composition
  - sending
  - attachment
  - cc
  - bcc
  - recipients
language: applescript
---

# Mail Email Composition and Sending

This script provides functionality for creating and sending emails with various options through Apple Mail.

## Creating and Sending Emails

```applescript
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
```

## Creating an Email with a Template

```applescript
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
```

## Interactive Email Composition Dialog

```applescript
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
```

This script provides comprehensive functionality for creating and sending emails through Apple Mail, offering features like CC/BCC recipients, attachments, account and signature selection, and template support. The interactive dialog guides users through the email composition process step by step.