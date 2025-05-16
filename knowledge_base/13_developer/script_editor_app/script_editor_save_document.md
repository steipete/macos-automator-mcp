---
title: 'Script Editor: Save Document'
category: 13_developer
id: script_editor_save_document
description: >-
  Saves a Script Editor document to disk as a script file, applet, or other
  format.
keywords:
  - Script Editor
  - save document
  - script file
  - save as
  - applet
  - export
  - SCPT
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide save path as 'savePath', file format as 'saveFormat' (optional), and
  stay open flag as 'stayOpen' (optional, boolean) in inputData.
notes: >
  - Script Editor must be running with at least one document open

  - The script will be compiled before saving if necessary

  - Common file formats include script (.scpt), application (.app), or text
  (.applescript)

  - For applications, you can specify a stay-open behavior
---

This script demonstrates how to save a Script Editor document to disk in various formats.

```applescript
--MCP_INPUT:savePath
--MCP_INPUT:saveFormat
--MCP_INPUT:stayOpen

on saveScriptEditorDocument(savePath, saveFormat, stayOpen)
  -- Validate required parameters
  if savePath is missing value or savePath is "" then
    return "error: Save path is required."
  end if
  
  -- Set default format if not specified
  if saveFormat is missing value or saveFormat is "" then
    set saveFormat to "script"
  end if
  
  -- Convert saveFormat to proper class value
  set formatClass to my getFileFormatClass(saveFormat)
  
  -- Handle stay open flag (for applications) if provided
  if stayOpen is missing value then
    set stayOpen to false
  end if
  
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
      
      -- Make sure the document is compiled before saving
      if not compiled of scriptDoc then
        compile scriptDoc
      end if
      
      -- Ensure we have a proper file path
      -- If path is not absolute, interpret as relative to Desktop
      if character 1 of savePath is not "/" and savePath does not contain ":" then
        set desktopPath to POSIX path of (path to desktop)
        set savePath to desktopPath & "/" & savePath
      end if
      
      -- Create a file reference
      set saveFile to savePath
      
      -- Save the document in the requested format
      if formatClass is application then
        -- Application format with stay-open flag
        save scriptDoc in saveFile as formatClass with stay open stayOpen
      else
        -- Other formats don't use the stay-open flag
        save scriptDoc in saveFile as formatClass
      end if
      
      -- Get the final path of the saved file
      set savedPath to savePath
      if path of scriptDoc is not missing value then
        set savedPath to POSIX path of (path of scriptDoc as text)
      end if
      
      return "Successfully saved document '" & docName & "'" & return & ¬
        "Format: " & saveFormat & return & ¬
        "Path: " & savedPath & return & ¬
        if formatClass is application then ¬
          "Stay open: " & stayOpen & return
    on error errMsg
      return "Error saving script document: " & errMsg
    end try
  end tell
end saveScriptEditorDocument

-- Helper function to convert format name to actual class
on getFileFormatClass(formatName)
  if formatName is "script" or formatName is "compiled script" or formatName is "scpt" then
    return script
  else if formatName is "application" or formatName is "app" then
    return application
  else if formatName is "text" or formatName is "txt" or formatName is "applescript" then
    return text
  else if formatName is "script bundle" or formatName is "scptd" then
    return script bundle
  else if formatName is "application bundle" or formatName is "applet" then
    return application bundle
  else
    -- Default to script format if unknown
    return script
  end if
end getFileFormatClass

-- Example usage with placeholder values
return my saveScriptEditorDocument("--MCP_INPUT:savePath", "--MCP_INPUT:saveFormat", "--MCP_INPUT:stayOpen")
```

This script provides functionality to save Script Editor documents in various formats:

1. **Script Format (.scpt)**
   - A compiled binary script
   - Can be run directly but not edited without Script Editor
   - Example: `my saveScriptEditorDocument("/path/to/save.scpt", "script", false)`

2. **Application Format (.app)**
   - A standalone executable application
   - Can be run by double-clicking in Finder
   - Supports "stay open" option for persistent applications
   - Example: `my saveScriptEditorDocument("/path/to/save.app", "application", true)`

3. **Text Format (.applescript)**
   - Plain text source code that can be edited in any text editor
   - Not compiled or directly executable
   - Example: `my saveScriptEditorDocument("/path/to/save.applescript", "text", false)`

4. **Script Bundle (.scptd)**
   - A bundle (folder) format that can contain resources
   - Example: `my saveScriptEditorDocument("/path/to/save.scptd", "script bundle", false)`

The "stay open" parameter is only relevant for application formats and determines whether the application continues running after executing its initial code.

When creating applications, consider:
- Setting "stay open" to true for scripts that need to respond to ongoing events
- Setting "stay open" to false for scripts that perform a task and then exit
- Adding proper quit and idle handlers for stay-open applications
END_TIP
