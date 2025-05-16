---
title: Mail UI Components
category: 09_productivity
id: mail_ui_components
description: User interface components for the Mail Automation system
keywords:
  - email
  - mail
  - UI
  - dialog
  - interface
  - menus
  - automation
language: applescript
---

# Mail UI Components

This script provides user interface components for the Mail Automation system, including dialogs, menus, and interactive interfaces for various email operations.

## Main Mail Automation Menu

```applescript
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
```

## Email Composition Dialog

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

## Template Management Dialog

```applescript
-- Show template management dialog
on showTemplateDialog()
  set templateOptions to {"Create New Template", "Edit Template", "Use Template", "Delete Template", "Cancel"}
  
  set selectedOption to choose from list templateOptions with prompt "Email Template Management:" default items {"Create New Template"}
  
  if selectedOption is false then
    return "Template management cancelled"
  end if
  
  set templateAction to item 1 of selectedOption
  
  -- Implementation continues with template actions...
end showTemplateDialog
```

## Draft Template Dialog

```applescript
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
```

## Search and Organization Dialog

```applescript
-- Show dialog for email search and organization
on showSearchOrganizeDialog()
  -- Criteria dialog
  set criteriaDialog to display dialog "Search/Organize Emails" & return & return & "Enter search criteria (leave blank for any):" & return & "Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of criteriaDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set subjectCriteria to text returned of criteriaDialog
  
  -- Implementation continues with search criteria...
end showSearchOrganizeDialog
```

This script provides user-friendly interface components for the Mail Automation system, offering interactive dialogs and menus for email composition, template management, search, and organization. These UI components make the system more accessible and guide users through complex email operations step by step.