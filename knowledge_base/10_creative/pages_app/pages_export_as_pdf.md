---
title: "Pages: Export as PDF"
category: "08_creative_and_document_apps"
id: pages_export_as_pdf
description: "Exports a Pages document as a PDF file."
keywords: ["Pages", "export PDF", "convert document", "PDF export", "document conversion"]
language: applescript
argumentsPrompt: "Enter the path to the Pages file and the PDF export path"
notes: "Exports a Pages document to PDF format. Both paths should be full POSIX paths."
---

```applescript
on run {pagesFilePath, pdfExportPath}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if pagesFilePath is "" or pagesFilePath is missing value then
        set pagesFilePath to "--MCP_INPUT:pagesFilePath"
      end if
      
      if pdfExportPath is "" or pdfExportPath is missing value then
        set pdfExportPath to "--MCP_INPUT:pdfExportPath"
      end if
      
      -- Verify paths format
      if pagesFilePath does not start with "/" then
        return "Error: Pages file path must be a valid absolute POSIX path starting with /"
      end if
      
      if pdfExportPath does not start with "/" then
        return "Error: PDF export path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Ensure PDF export path has .pdf extension
      if pdfExportPath does not end with ".pdf" then
        set pdfExportPath to pdfExportPath & ".pdf"
      end if
      
      -- Open the Pages file
      open POSIX file pagesFilePath
      
      -- Get the current document
      set targetDocument to front document
      
      -- Use UI scripting to export as PDF
      tell application "System Events"
        tell process "Pages"
          -- Select File > Export To > PDF...
          click menu item "Export To" of menu "File" of menu bar 1
          delay 0.5
          click menu item "PDF…" of menu "Export To" of menu "File" of menu bar 1
          
          -- Wait for export dialog
          repeat until exists sheet 1 of window 1
            delay 0.1
          end repeat
          
          tell sheet 1 of window 1
            -- Set PDF options if needed
            if exists pop up button 1 then
              -- Could set quality options here
            end if
            
            -- Click Next button
            click button "Next…"
            delay 0.5
            
            -- Set the export location
            tell sheet 1
              -- Navigate to the destination folder
              keystroke "g" using {command down, shift down} -- Go to folder dialog
              delay 0.5
              
              -- Enter the folder path (parent directory of destination)
              set folderPath to do shell script "dirname " & quoted form of pdfExportPath
              keystroke folderPath
              keystroke return
              delay 0.5
              
              -- Enter the filename
              set fileName to do shell script "basename " & quoted form of pdfExportPath
              set value of text field 1 to fileName
              
              -- Click Export button
              click button "Export"
            end tell
          end tell
        end tell
      end tell
      
      -- Close the document
      close targetDocument
      
      return "Successfully exported Pages document to PDF: " & pdfExportPath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to export to PDF - " & errMsg
    end try
  end tell
end run
```
END_TIP