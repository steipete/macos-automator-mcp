---
title: Mail Template System
category: 09_productivity
id: mail_template_system
description: Email template management for Apple Mail automation
keywords:
  - email
  - mail
  - templates
  - placeholders
  - customization
  - personalization
  - drafts
language: applescript
---

# Mail Template System

This script provides functionality for creating, managing, and using email templates with customizable placeholders.

## Template Management Functions

### Creating Templates

```applescript
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
```

### Loading Templates

```applescript
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
```

### Listing Templates

```applescript
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
```

### Saving Drafts as Templates

```applescript
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

## Template Management Interface

```applescript
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
```

This script provides comprehensive functionality for working with email templates in Apple Mail, including creating, editing, using, and deleting templates. It also supports saving draft emails as templates and using placeholders for customized content.