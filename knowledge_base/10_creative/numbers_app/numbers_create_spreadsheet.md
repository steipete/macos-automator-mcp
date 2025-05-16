---
title: 'Numbers: Create New Spreadsheet'
category: 10_creative/numbers_app
id: numbers_create_spreadsheet
description: Creates a new spreadsheet in Numbers with specified content.
keywords:
  - Numbers
  - spreadsheet
  - new document
  - create table
  - spreadsheet creation
language: applescript
argumentsPrompt: Enter the title for the new spreadsheet and where to save it
notes: >-
  Creates a new Numbers spreadsheet with a simple table. The file path should be
  a full POSIX path ending with .numbers
---

```applescript
on run {documentTitle, savePath}
  tell application "Numbers"
    try
      -- Handle placeholder substitution
      if documentTitle is "" or documentTitle is missing value then
        set documentTitle to "--MCP_INPUT:documentTitle"
      end if
      
      if savePath is "" or savePath is missing value then
        set savePath to "--MCP_INPUT:savePath"
      end if
      
      -- Verify save path format
      if savePath does not start with "/" then
        return "Error: Save path must be a valid absolute POSIX path starting with /"
      end if
      
      if savePath does not end with ".numbers" then
        set savePath to savePath & ".numbers"
      end if
      
      -- Create a new document
      set newDocument to make new document with properties {name:documentTitle}
      
      -- Get the first sheet and table
      tell newDocument
        set firstSheet to sheet 1
        
        tell firstSheet
          -- Get the first table
          set firstTable to table 1
          
          -- Set header row values
          tell firstTable
            set value of cell 1 of row 1 to "Item"
            set value of cell 2 of row 1 to "Quantity"
            set value of cell 3 of row 1 to "Price"
            set value of cell 4 of row 1 to "Total"
            
            -- Add a formula for the Total column
            set value of cell 4 of row 2 to "=B2*C2"
          end tell
        end tell
      end tell
      
      -- Save the document
      save newDocument in POSIX file savePath
      
      return "Successfully created new Numbers spreadsheet: " & savePath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create spreadsheet - " & errMsg
    end try
  end tell
end run
```
END_TIP
