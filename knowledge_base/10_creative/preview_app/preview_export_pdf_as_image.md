---
title: 'Preview: Export PDF as Image'
category: 10_creative
id: preview_export_pdf_as_image
description: Exports a PDF file as an image using Preview.
keywords:
  - Preview
  - export PDF
  - convert PDF to image
  - PDF to JPEG
language: applescript
argumentsPrompt: Enter the source PDF path and destination image path
notes: >-
  Exports the first page of a PDF as a JPEG image. Both source and destination
  should be absolute POSIX paths.
---

```applescript
on run {sourcePath, destinationPath}
  try
    if sourcePath is "" or sourcePath is missing value then
      set sourcePath to "--MCP_INPUT:sourcePath"
    end if
    
    if destinationPath is "" or destinationPath is missing value then
      set destinationPath to "--MCP_INPUT:destinationPath"
    end if
    
    -- Convert to POSIX file if they're not already
    if sourcePath does not start with "/" then
      return "Error: Source path must be a valid absolute POSIX path starting with /"
    end if
    
    if destinationPath does not start with "/" then
      return "Error: Destination path must be a valid absolute POSIX path starting with /"
    end if
    
    set sourceFile to POSIX file sourcePath
    set destinationFile to POSIX file destinationPath
    
    tell application "Preview"
      activate
      open sourceFile
      
      delay 1 -- Give Preview a moment to open the file
      
      tell application "System Events"
        tell process "Preview"
          -- Access Export menu
          click menu item "Export…" of menu "File" of menu bar 1
          
          delay 0.5
          
          -- Handle export dialog
          tell window 1
            -- Select JPEG format from popup
            click pop up button 1
            click menu item "JPEG" of menu 1 of pop up button 1
            
            -- Enter destination in the save panel
            keystroke "g" using {command down, shift down} -- Go to folder
            delay 0.5
            
            -- Enter the folder path (parent directory of destination)
            set folderPath to do shell script "dirname " & quoted form of destinationPath
            keystroke folderPath
            keystroke return
            delay 0.5
            
            -- Enter the filename
            set fileName to do shell script "basename " & quoted form of destinationPath
            keystroke fileName
            
            -- Click Save button
            click button "Save" of sheet 1
          end tell
        end tell
      end tell
      
      delay 1
      close window 1 saving no
      
      return "PDF exported as image successfully to: " & destinationPath
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to export PDF - " & errMsg
  end try
end run
```
END_TIP
