---
title: 'Xcode: Archive Project for Distribution'
category: 13_developer
id: xcode_archive_project
description: Archives an Xcode project for distribution using the Archive option.
keywords:
  - Xcode
  - archive
  - distribution
  - App Store
  - IPA
  - developer
  - iOS
  - macOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional wait time (in seconds) for archive process to complete as 'waitTime'
  in inputData (default is 300 seconds)
notes: |
  - Requires Xcode to be already open with a project loaded
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Ensure project scheme is set to Release configuration before archiving
  - Archiving can take several minutes depending on project size
  - Once complete, the Organizer window will open with the archive
---

```applescript
--MCP_INPUT:waitTime

on archiveXcodeProject(waitTime)
  -- Default wait time of 300 seconds (5 minutes) if not specified
  if waitTime is missing value or waitTime is "" then
    set waitTime to 300
  else
    try
      set waitTime to waitTime as number
    on error
      set waitTime to 300
    end try
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  set archiveResult to "Archive result unknown"
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Select Product menu
        click menu item "Product" of menu bar 1
        delay 0.5
        
        -- Click Archive menu item
        click menu item "Archive" of menu "Product" of menu bar 1
        
        -- Wait for archive to complete
        set startTime to current date
        set timeoutDate to startTime + waitTime
        
        repeat
          delay 5  -- Check less frequently since archiving takes time
          
          -- Check for archive status (look for Organizer window)
          set archiveSucceeded to false
          set archiveFailed to false
          
          -- Try to detect if organizer window appears (success)
          try
            set archiveSucceeded to exists (window "Organizer")
          end try
          
          -- Try to detect if an error dialog appears (failure)
          try
            set archiveFailed to exists (first window whose name contains "Archive Failed")
          end try
          
          if archiveSucceeded then
            set archiveResult to "Archive succeeded"
            exit repeat
          else if archiveFailed then
            set archiveResult to "Archive failed"
            exit repeat
          end if
          
          -- Check if we've timed out
          if (current date) > timeoutDate then
            set archiveResult to "Archive timeout after " & waitTime & " seconds"
            exit repeat
          end if
        end repeat
      end tell
    end tell
    
    return archiveResult
  on error errMsg number errNum
    return "error (" & errNum & ") archiving Xcode project: " & errMsg
  end try
end archiveXcodeProject

return my archiveXcodeProject("--MCP_INPUT:waitTime")
```
