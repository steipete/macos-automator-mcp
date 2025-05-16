---
title: "Script Editor: Open Script File"
category: "developer"
id: script_editor_open_file
description: "Opens an AppleScript file in Script Editor."
keywords: ["Script Editor", "open file", "script file", "AppleScript", "load script", "editor"]
language: applescript
isComplex: true
argumentsPrompt: "Provide the absolute path (POSIX or HFS) to the script file to open in inputData."
notes: |
  - Supports .scpt, .applescript, .scptd (bundle) and text files containing AppleScript
  - Script Editor will be launched if not already running
  - Can be used to programmatically open scripts for editing or execution
---

This script opens a specified AppleScript file in Script Editor.

```applescript
--MCP_INPUT:filePath

on openScriptFile(scriptPath)
  if scriptPath is missing value or scriptPath is "" then
    return "error: Script file path not provided."
  end if
  
  try
    -- Determine path type and convert as needed
    set scriptFileRef to missing value
    
    if scriptPath starts with "/" then
      -- Path is in POSIX format
      set scriptFileRef to POSIX file scriptPath
    else
      -- Assume HFS path or try to use as is
      try
        set scriptFileRef to scriptPath as alias
      on error
        -- If not a valid alias, try as a string path
        set scriptFileRef to scriptPath
      end try
    end if
    
    -- Open the file in Script Editor
    tell application "Script Editor"
      activate
      set scriptDoc to open scriptFileRef
      
      -- Return information about the opened document
      set docName to name of scriptDoc
      set docPath to "Not saved to disk"
      try
        set docPath to path of scriptDoc
      end try
      
      return "Successfully opened script: " & docName & return & "Path: " & docPath
    end tell
  on error errMsg
    return "Error opening script file: " & errMsg
  end try
end openScriptFile

return my openScriptFile("--MCP_INPUT:filePath")
```

This script:
1. Accepts a file path in either POSIX or HFS format
2. Converts the path to a file reference
3. Opens the script in Script Editor
4. Returns information about the opened document

You can use this to:
- Open script files for editing
- Prepare scripts for execution
- Integrate with larger automation workflows
- Work with scripts stored in various locations

Note that Script Editor will be launched if it's not already running, and the document will be opened in a new window.
END_TIP