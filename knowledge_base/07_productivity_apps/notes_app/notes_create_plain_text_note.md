---
title: "Notes: Create Plain Text Note"
category: "07_productivity_apps"
id: notes_create_plain_text_note
description: "Creates a new note in Apple Notes with a specified title and plain text body. Optionally specify a folder."
keywords: ["Notes", "new note", "create note", "text"]
language: applescript
isComplex: true
argumentsPrompt: "Note title as 'noteTitle', body content as 'noteBody'. Optionally, 'folderName' in inputData."
notes: "Requires Automation permission for Notes.app. The body is treated as plain text; for HTML use a different method."
---

```applescript
--MCP_INPUT:noteTitle
--MCP_INPUT:noteBody
--MCP_INPUT:folderName

on createPlainTextNote(theTitle, theBody, theFolderName)
  if theTitle is missing value or theTitle is "" then set theTitle to "New Note " & ((current date) as string)
  if theBody is missing value then set theBody to ""
  
  tell application "Notes"
    activate
    try
      set targetContainer to missing value
      if theFolderName is not missing value and theFolderName is not "" then
        if exists folder theFolderName then
          set targetContainer to folder theFolderName
        else
          -- Optionally create folder if it doesn't exist
          -- make new folder with properties {name:theFolderName}
          -- set targetContainer to folder theFolderName
          log "Warning: Folder '" & theFolderName & "' not found. Note will be created in default location."
        end if
      end if
      
      if targetContainer is missing value then
        -- Create in default location (usually "All iCloud" or first account)
        make new note with properties {name:theTitle, body:theBody}
      else
        tell targetContainer
          make new note with properties {name:theTitle, body:theBody}
        end tell
      end if
      return "Note '" & theTitle & "' created."
    on error errMsg
      return "error: Could not create note - " & errMsg
    end try
  end tell
end createPlainTextNote

return my createPlainTextNote("--MCP_INPUT:noteTitle", "--MCP_INPUT:noteBody", "--MCP_INPUT:folderName")
```
END_TIP 