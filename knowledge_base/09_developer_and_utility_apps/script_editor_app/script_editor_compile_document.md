---
title: "Script Editor: Compile Document"
category: "11_developer_and_utility_apps" # Subdir: script_editor_app
id: script_editor_compile_document
description: "Compiles an AppleScript document in Script Editor to check for syntax errors and prepare it for execution."
keywords: ["Script Editor", "compile", "check syntax", "AppleScript", "document", "validation"]
language: applescript
notes: |
  - Script Editor must be running with at least one document open
  - Compilation validates the script's syntax but doesn't execute it
  - The 'compiled' property indicates whether compilation was successful
  - Error information is available after failed compilation
---

This script demonstrates how to compile an AppleScript document in Script Editor to check its syntax and prepare it for execution.

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
    
    -- Reference to the frontmost document
    set scriptDoc to front document
    set docName to name of scriptDoc
    
    -- Get initial state of the document
    set wasCompiled to compiled of scriptDoc
    
    -- Compile the document
    compile scriptDoc
    
    -- Check if compilation was successful
    set isCompiled to compiled of scriptDoc
    
    -- Get compilation result information
    if isCompiled then
      -- Compilation succeeded
      if wasCompiled then
        set resultMessage to "Document '" & docName & "' was already compiled. No errors found."
      else
        set resultMessage to "Document '" & docName & "' was successfully compiled. No errors found."
      end if
      
      -- Get additional information about the compiled script
      set scriptResult to "Document: " & docName & return
      set scriptResult to scriptResult & "Status: Successfully Compiled" & return
      set scriptResult to scriptResult & "Length: " & (count of text of scriptDoc) & " characters" & return
      
      -- Get language version if available
      try
        set langVersion to AppleScript's version
        set scriptResult to scriptResult & "AppleScript Version: " & langVersion & return
      end try
      
      return scriptResult
    else
      -- Compilation failed - get error information
      set errMessage to "Compilation failed for document '" & docName & "'."
      
      -- Get error information
      try
        set errLine to line number of the first error
        set errText to text of the first error
        set errStart to offset of the first error
        set errEnd to (offset of the first error) + (length of the first error) - 1
        
        set errMessage to errMessage & return & return
        set errMessage to errMessage & "Line: " & errLine & return
        set errMessage to errMessage & "Error: " & errText & return
        set errMessage to errMessage & "Character positions: " & errStart & " to " & errEnd
      end try
      
      return errMessage
    end if
  on error errMsg
    return "Error during compilation process: " & errMsg
  end try
end tell
```

This script:
1. Checks if Script Editor is running with an open document
2. Compiles the frontmost document
3. Verifies if compilation was successful
4. Returns information about the compiled script or error details if compilation failed

When a script is successfully compiled:
- It's ready to be run
- Its syntax is confirmed to be correct
- It can be saved as a compiled script (.scpt) or application

When compilation fails:
- Error information is provided (line number, position, error message)
- The script can't be run until errors are fixed
- The 'compiled' property remains false

Compilation is useful for:
- Validating script syntax without running it
- Finding errors in complex scripts
- Preparing scripts for distribution or execution
- Getting information about a script's structure

Note that compilation only checks for syntax errors, not logical errors or runtime issues. A script might compile successfully but still produce errors when run.
END_TIP