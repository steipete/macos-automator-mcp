---
title: "Script Editor: Set Document Text"
category: "developer"
id: script_editor_set_text
description: "Sets the text content of a Script Editor document, allowing programmatic creation or modification of AppleScripts."
keywords: ["Script Editor", "set text", "modify script", "edit", "document", "code generation"]
language: applescript
isComplex: true
argumentsPrompt: "Provide the new text content as 'scriptContent' in inputData."
notes: |
  - Script Editor must be running for this to work
  - Setting text in a document marks it as modified and uncompiled
  - You may need to compile the document after setting text if you intend to run it
  - This allows for dynamic script generation or template-based script creation
---

This script demonstrates how to set the text content of a Script Editor document programmatically.

```applescript
--MCP_INPUT:scriptContent

on setScriptEditorText(scriptContent)
  if scriptContent is missing value or scriptContent is "" then
    return "error: Script content not provided."
  end if
  
  tell application "Script Editor"
    try
      -- Check if Script Editor is running
      if not running then
        -- Launch Script Editor if not running
        run
        delay 0.5 -- Give it a moment to launch
      end if
      
      -- Determine if we need to create a new document or use an existing one
      set targetDoc to missing value
      
      if (count of documents) is 0 then
        -- No documents open, create a new one
        set targetDoc to make new document
      else
        -- Use the front document
        set targetDoc to front document
      end if
      
      -- Get document info before modification for reporting
      set docName to name of targetDoc
      set originalLength to count of (text of targetDoc)
      
      -- Set the text content of the document
      set text of targetDoc to scriptContent
      
      -- Document is now modified and needs to be compiled before running
      set isModified to modified of targetDoc
      set isCompiled to compiled of targetDoc
      
      -- Compile the document if it contains valid content
      set compileResult to "Not compiled"
      if scriptContent is not "" then
        try
          compile targetDoc
          set compileResult to "Successfully compiled"
        on error errMsg
          set compileResult to "Compilation failed: " & errMsg
        end try
      end if
      
      -- Save the document if it's new and has no name
      if docName starts with "untitled" and scriptContent is not "" then
        -- Optional: save document (commented out to avoid unexpected file writes)
        -- save targetDoc -- Would need file name and location to save properly
      end if
      
      -- Activate Script Editor to show the changes
      activate
      
      return "Set text of document '" & docName & "'" & return & ¬
        "Original length: " & originalLength & " characters" & return & ¬
        "New length: " & (count of scriptContent) & " characters" & return & ¬
        "Modified: " & isModified & return & ¬
        "Compilation status: " & compileResult
    on error errMsg
      return "Error setting script text: " & errMsg
    end try
  end tell
end setScriptEditorText

-- Example usage with placeholder script content
return my setScriptEditorText("--MCP_INPUT:scriptContent")
```

This script:
1. Launches Script Editor if it's not already running
2. Uses the frontmost document or creates a new one if none exists
3. Sets the text content of the document to the provided script
4. Attempts to compile the new script if applicable
5. Returns information about the modification

Common use cases:
- Programmatically creating or modifying AppleScripts
- Implementing script templates that get customized at runtime
- Building script generators or tools
- Automating script modifications or updates
- Setting up test scripts

When you set the text of a document:
- The document is marked as modified and needs to be saved
- The 'compiled' property is set to false until you explicitly compile it
- The script won't run until it's been compiled again
- Any previous content is completely replaced

For complex scripts, consider using template strings with placeholder tokens that you can replace with specific values based on your needs.
END_TIP