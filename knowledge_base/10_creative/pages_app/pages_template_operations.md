---
title: 'Pages: Template Operations'
category: 10_creative
id: pages_template_operations
description: 'Create from template, save as template, and list available templates in Pages.'
keywords:
  - Pages
  - templates
  - document templates
  - new from template
  - save as template
  - list templates
language: applescript
argumentsPrompt: 'Choose operation type (create, save, list) and provide necessary parameters'
notes: >-
  Handles Pages document template operations. For 'create' operation, provide
  template name; for 'save' operation, provide current document and template
  name; 'list' operation shows all available templates.
---

```applescript
on run {operationType, param1, param2}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if operationType is "" or operationType is missing value then
        set operationType to "--MCP_INPUT:operationType"
      end if
      
      if param1 is "" or param1 is missing value then
        set param1 to "--MCP_INPUT:param1"
      end if
      
      if param2 is "" or param2 is missing value then
        set param2 to "--MCP_INPUT:param2"
      end if
      
      -- Validate operation type
      set validOperations to {"create", "save", "list"}
      if validOperations does not contain operationType then
        return "Error: Invalid operation type. Must be one of: " & validOperations
      end if
      
      -- Execute the appropriate operation
      if operationType is "create" then
        return createFromTemplate(param1)
      else if operationType is "save" then
        return saveAsTemplate(param1, param2)
      else if operationType is "list" then
        return listTemplates()
      end if
      
    on error errMsg number errNum
      return "Error (" & errNum & "): " & errMsg
    end try
  end tell
end run

-- Create a new document from a template
on createFromTemplate(templateName)
  try
    tell application "Pages"
      -- Get all available templates
      set templateList to get name of every template
      
      -- Check if the specified template exists
      if templateList does not contain templateName then
        return "Error: Template '" & templateName & "' not found. Available templates: " & templateList
      end if
      
      -- Create a new document from the template
      set newDoc to make new document with properties {template:template templateName}
      
      return "Successfully created new document from template: " & templateName
    end tell
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to create document from template - " & errMsg
  end try
end createFromTemplate

-- Save the current document as a template
on saveAsTemplate(documentPath, templateName)
  try
    tell application "Pages"
      -- Verify document path format
      if documentPath does not start with "/" then
        return "Error: Document path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Open the document if not already open
      if (count of documents) is 0 or documentPath is not "" then
        open POSIX file documentPath
      end if
      
      -- Get the front document
      set currentDoc to front document
      
      -- Save as template using UI scripting
      tell application "System Events"
        tell process "Pages"
          -- Select File > Save as Template...
          click menu item "Save as Template…" of menu "File" of menu bar 1
          
          -- Wait for the dialog to appear
          repeat until exists sheet 1 of window 1
            delay 0.1
          end repeat
          
          tell sheet 1 of window 1
            -- Enter the template name
            set value of text field 1 to templateName
            
            -- Click Save button
            click button "Save"
            
            -- Handle potential "replace existing template" dialog
            delay 0.5
            if exists sheet 1 then
              -- Click Replace button if we're overwriting
              click button "Replace" of sheet 1
            end if
          end tell
        end tell
      end tell
      
      return "Successfully saved document as template: " & templateName
    end tell
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to save as template - " & errMsg
  end try
end saveAsTemplate

-- List all available templates
on listTemplates()
  try
    tell application "Pages"
      -- Get all available templates
      set templateList to get name of every template
      
      if (count of templateList) is 0 then
        return "No templates found."
      end if
      
      -- Format the list for display
      set templateText to "Available Templates:" & return
      
      repeat with i from 1 to count of templateList
        set templateText to templateText & "• " & item i of templateList & return
      end repeat
      
      return templateText
    end tell
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list templates - " & errMsg
  end try
end listTemplates
```
END_TIP
