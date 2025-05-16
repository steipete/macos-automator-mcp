---
title: 'Numbers: Export as CSV'
category: 10_creative
id: numbers_export_as_csv
description: Exports a Numbers spreadsheet as a CSV file.
keywords:
  - Numbers
  - export
  - CSV
  - convert spreadsheet
  - export table
language: applescript
argumentsPrompt: Enter the path to the Numbers file and the CSV export path
notes: >-
  Exports a Numbers spreadsheet to CSV format. Both paths should be full POSIX
  paths.
---

```applescript
on run {numbersFilePath, csvExportPath}
  tell application "Numbers"
    try
      -- Handle placeholder substitution
      if numbersFilePath is "" or numbersFilePath is missing value then
        set numbersFilePath to "--MCP_INPUT:numbersFilePath"
      end if
      
      if csvExportPath is "" or csvExportPath is missing value then
        set csvExportPath to "--MCP_INPUT:csvExportPath"
      end if
      
      -- Verify paths format
      if numbersFilePath does not start with "/" then
        return "Error: Numbers file path must be a valid absolute POSIX path starting with /"
      end if
      
      if csvExportPath does not start with "/" then
        return "Error: CSV export path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Ensure CSV export path has .csv extension
      if csvExportPath does not end with ".csv" then
        set csvExportPath to csvExportPath & ".csv"
      end if
      
      -- Open the Numbers file
      set targetDocument to open POSIX file numbersFilePath
      
      -- Use UI scripting to export as CSV
      tell application "System Events"
        tell process "Numbers"
          -- Select File > Export To > CSV...
          click menu item "Export To" of menu "File" of menu bar 1
          delay 0.5
          click menu item "CSV…" of menu "Export To" of menu "File" of menu bar 1
          
          -- Wait for export dialog
          repeat until exists sheet 1 of window 1
            delay 0.1
          end repeat
          
          tell sheet 1 of window 1
            -- Set advanced options if needed
            if exists button "Advanced Options" then
              click button "Advanced Options"
              delay 0.5
              
              -- Here you could set CSV options like delimiter in the advanced dialog
              -- For now, just use defaults and close the advanced options
              if exists sheet 1 then
                click button "OK" of sheet 1
                delay 0.5
              end if
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
              set folderPath to do shell script "dirname " & quoted form of csvExportPath
              keystroke folderPath
              keystroke return
              delay 0.5
              
              -- Enter the filename
              set fileName to do shell script "basename " & quoted form of csvExportPath
              set value of text field 1 to fileName
              
              -- Click Export button
              click button "Export"
            end tell
          end tell
        end tell
      end tell
      
      -- Close the document
      close targetDocument
      
      return "Successfully exported Numbers file to CSV: " & csvExportPath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to export to CSV - " & errMsg
    end try
  end tell
end run
```
END_TIP
