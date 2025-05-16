---
title: 'Pages: Create New Document'
category: 10_creative/pages_app
id: pages_create_document
description: Creates a new document in Pages with specified content.
keywords:
  - Pages
  - document
  - word processing
  - create document
  - text document
language: applescript
argumentsPrompt: 'Enter the title and content for the new document, and where to save it'
notes: >-
  Creates a new Pages document with title and text content. The file path should
  be a full POSIX path ending with .pages
---

```applescript
on run {documentTitle, documentContent, savePath}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if documentTitle is "" or documentTitle is missing value then
        set documentTitle to "--MCP_INPUT:documentTitle"
      end if
      
      if documentContent is "" or documentContent is missing value then
        set documentContent to "--MCP_INPUT:documentContent"
      end if
      
      if savePath is "" or savePath is missing value then
        set savePath to "--MCP_INPUT:savePath"
      end if
      
      -- Verify save path format
      if savePath does not start with "/" then
        return "Error: Save path must be a valid absolute POSIX path starting with /"
      end if
      
      if savePath does not end with ".pages" then
        set savePath to savePath & ".pages"
      end if
      
      -- Create a new document
      make new document
      
      -- Get the current document
      set currentDocument to front document
      
      -- Set the document title and content
      tell currentDocument
        tell body text
          -- Set the content
          set its text to documentTitle & return & return & documentContent
          
          -- Format the title as heading
          if length of documentTitle > 0 then
            set properties of paragraph 1 to {alignment:center, bold:true, font size:18}
          end if
        end tell
      end tell
      
      -- Save the document
      save currentDocument in POSIX file savePath
      
      return "Successfully created new Pages document: " & savePath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create document - " & errMsg
    end try
  end tell
end run
```
END_TIP
