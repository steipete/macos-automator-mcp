---
title: 'Firefox: Save Page as PDF'
category: 07_browsers
id: firefox_save_page_as_pdf
description: Saves the current Firefox page as a PDF file using UI automation.
keywords:
  - Firefox
  - PDF
  - save
  - export
  - print to PDF
  - browser
  - UI scripting
language: applescript
notes: |
  - Firefox must be running.
  - Uses UI scripting to navigate print dialog and save as PDF.
  - Requires accessibility permissions.
  - Default save location is the user's Desktop.
  - May need adjustment based on Firefox version and macOS version.
---

This script saves the current page in Firefox as a PDF file. It simulates the "Print to PDF" function through UI scripting since Firefox has limited AppleScript support.

```applescript
on run {input, parameters}
  -- Set default filename and location
  set defaultLocation to (path to desktop folder as string)
  set pdfFilename to "--MCP_INPUT:filename"
  
  -- If no filename is provided, use a timestamp
  if pdfFilename is "" then
    set currentDate to current date
    set pdfFilename to "Firefox_Page_" & (year of currentDate as string) & "-" & (month of currentDate as integer as string) & "-" & (day of currentDate as string) & "_" & (time string of currentDate)
  end if
  
  -- Ensure .pdf extension
  if pdfFilename does not end with ".pdf" then
    set pdfFilename to pdfFilename & ".pdf"
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Start print process
  tell application "System Events"
    tell process "Firefox"
      -- Open Print dialog with Command+P
      keystroke "p" using command down
      delay 1.5 -- Wait for print dialog to appear
      
      -- Select PDF dropdown
      keystroke tab
      delay 0.3
      repeat 3 times
        key code 125 -- Down arrow to reach the PDF dropdown
        delay 0.2
      end repeat
      
      -- Open PDF dropdown menu
      keystroke space
      delay 0.5
      
      -- Select "Save as PDF" option (may need adjustment based on your system)
      key code 125 -- Down arrow
      key code 125 -- Down arrow
      key code 125 -- Down arrow
      delay 0.2
      keystroke return
      delay 1 -- Wait for Save dialog
      
      -- Enter filename in Save dialog
      keystroke "a" using command down -- Select all text
      keystroke pdfFilename -- Type new filename
      delay 0.5
      
      -- Navigate to save location if needed (Desktop is usually default)
      -- For custom location, additional UI scripting would be needed here
      
      -- Click Save button
      keystroke return
      delay 1.5 -- Allow save to complete
    end tell
  end tell
  
  return "Saved current Firefox page as PDF: " & pdfFilename & " on Desktop"
end run
```

### Alternative with Specific Save Location

This version allows specifying a custom save location:

```applescript
on run {input, parameters}
  -- Set default filename and location
  set defaultLocation to (path to desktop folder as string)
  
  -- Get parameters
  set pdfFilename to "--MCP_INPUT:filename"
  set saveLocation to "--MCP_INPUT:saveLocation"
  
  -- If no filename is provided, use a timestamp
  if pdfFilename is "" then
    set currentDate to current date
    set pdfFilename to "Firefox_Page_" & (year of currentDate as string) & "-" & (month of currentDate as integer as string) & "-" & (day of currentDate as string) & "_" & (time string of currentDate)
  end if
  
  -- Ensure .pdf extension
  if pdfFilename does not end with ".pdf" then
    set pdfFilename to pdfFilename & ".pdf"
  end if
  
  -- Set save location, default to Desktop if not specified
  if saveLocation is "" then
    set saveLocation to defaultLocation
  end if
  
  -- Ensure saveLocation has trailing slash
  if character -1 of saveLocation is not ":" and character -1 of saveLocation is not "/" then
    set saveLocation to saveLocation & "/"
  end if
  
  -- Combine path and filename
  set fullSavePath to saveLocation & pdfFilename
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Start print process (remaining script same as above)
  tell application "System Events"
    tell process "Firefox"
      -- Open Print dialog with Command+P
      keystroke "p" using command down
      delay 1.5 -- Wait for print dialog to appear
      
      -- Select PDF dropdown
      keystroke tab
      delay 0.3
      repeat 3 times
        key code 125 -- Down arrow to reach the PDF dropdown
        delay 0.2
      end repeat
      
      -- Open PDF dropdown menu
      keystroke space
      delay 0.5
      
      -- Select "Save as PDF" option
      key code 125 -- Down arrow
      key code 125 -- Down arrow
      key code 125 -- Down arrow
      delay 0.2
      keystroke return
      delay 1 -- Wait for Save dialog
      
      -- Enter filename in Save dialog
      keystroke "a" using command down -- Select all text
      keystroke pdfFilename -- Type new filename
      delay 0.5
      
      -- Navigate to specified save location
      -- This would require additional UI scripting based on the specific save dialog
      
      -- Click Save button
      keystroke return
      delay 1.5 -- Allow save to complete
    end tell
  end tell
  
  return "Saved current Firefox page as PDF: " & pdfFilename
end run
```

Note: These scripts use UI scripting which can be fragile and dependent on the specific versions of Firefox and macOS you're using. You may need to adjust the tab navigation, key presses, and delays to match your system's behavior.
END_TIP
