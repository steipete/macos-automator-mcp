---
title: 'Safari: Export Page as PDF'
category: 07_browsers/safari
id: safari_export_pdf
description: Exports the current webpage as a PDF document in Safari.
keywords:
  - Safari
  - export PDF
  - save as PDF
  - webpage to PDF
  - PDF export
language: applescript
argumentsPrompt: Enter the file path where the PDF should be saved
notes: >-
  Exports the current Safari webpage as a PDF file. The file path should be a
  full POSIX path ending with .pdf
---

```applescript
on run {savePath}
  tell application "Safari"
    try
      -- Handle placeholder substitution
      if savePath is "" or savePath is missing value then
        set savePath to "--MCP_INPUT:savePath"
      end if
      
      -- Verify save path format
      if savePath does not start with "/" then
        return "Error: Save path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Ensure the path ends with .pdf
      if savePath does not end with ".pdf" then
        set savePath to savePath & ".pdf"
      end if
      
      -- Make sure Safari is active and has at least one window
      activate
      
      if (count of windows) is 0 then
        return "Error: No Safari windows open."
      end if
      
      -- Get info about the current page
      set currentTab to current tab of front window
      set pageTitle to name of currentTab
      set pageURL to URL of currentTab
      
      -- Extract the directory and filename from the save path
      set saveDirectory to do shell script "dirname " & quoted form of savePath
      set saveFilename to do shell script "basename " & quoted form of savePath
      
      -- Use UI scripting to export the page as PDF
      tell application "System Events"
        tell process "Safari"
          -- Select Export as PDF from the File menu
          click menu item "Export as PDF…" of menu "File" of menu bar 1
          delay 0.5
          
          if exists sheet 1 of window 1 then
            -- Navigate to the specified directory
            keystroke "g" using {command down, shift down} -- Go to folder
            delay 0.5
            
            -- Enter the directory path
            keystroke saveDirectory
            keystroke return
            delay 0.5
            
            -- Enter the filename
            set value of text field 1 of sheet 1 of window 1 to saveFilename
            
            -- Click Save button
            click button "Save" of sheet 1 of window 1
            
            return "Webpage \"" & pageTitle & "\" exported as PDF to:\\n" & savePath
          else
            return "Error: Export dialog did not appear."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to export as PDF - " & errMsg
    end try
  end tell
end run
```
END_TIP
