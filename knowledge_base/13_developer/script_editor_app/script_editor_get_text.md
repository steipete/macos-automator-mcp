---
title: "Script Editor: Get Document Text"
category: "developer"
id: script_editor_get_text
description: "Retrieves the text content of a Script Editor document."
keywords: ["Script Editor", "text", "content", "document", "get text", "script content"]
language: applescript
notes: |
  - Script Editor must be running with at least one document open
  - The returned text is the raw script content, not including compilation results or log output
  - This can be useful for automating script management and modifications
---

This AppleScript retrieves the content of the frontmost (active) Script Editor document.

```applescript
tell application "Script Editor"
  try
    -- Check if Script Editor is running and has documents open
    if not running then
      return "Error: Script Editor is not running."
    end if
    if (count of documents) is 0 then
      return "Error: No documents are open in Script Editor."
    end if
    
    -- Get the frontmost document and its text
    set frontDoc to front document
    set docName to name of frontDoc
    set scriptText to text of frontDoc
    
    -- Optional: Get other properties of the document
    set docPath to "Not saved"
    try
      set docPath to path of frontDoc
    end try
    
    set isModified to modified of frontDoc
    set modStatus to if isModified then "Yes" else "No"
    
    -- Return document information including content
    return "Document: " & docName & return & ¬
           "Path: " & docPath & return & ¬
           "Modified: " & modStatus & return & ¬
           "Length: " & (count of scriptText) & " characters" & return & ¬
           "----------------------------------------" & return & ¬
           scriptText
  on error errMsg
    return "Error getting text from Script Editor document: " & errMsg
  end try
end tell
```

This script:
1. Verifies Script Editor is running with open documents
2. Gets the text content of the frontmost document
3. Retrieves metadata like document name, path, and modification status
4. Returns the document information along with the full script text

You can modify this to get text from a specific document by name or index, rather than just the frontmost document.
END_TIP