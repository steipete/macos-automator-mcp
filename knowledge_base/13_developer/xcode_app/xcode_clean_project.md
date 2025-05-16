---
title: 'Xcode: Clean Project'
category: 13_developer/xcode_app
id: xcode_clean_project
description: Cleans an Xcode project by removing build artifacts and intermediate files.
keywords:
  - Xcode
  - clean
  - build
  - project
  - developer
  - iOS
  - macOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional wait time (in seconds) after clean starts as 'waitTime' in inputData
  (default is 30 seconds)
notes: |
  - Requires Xcode to be already open with a project loaded
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Useful before a fresh build to ensure all cached files are removed
---

```applescript
--MCP_INPUT:waitTime

on cleanXcodeProject(waitTime)
  -- Default wait time of 30 seconds if not specified
  if waitTime is missing value or waitTime is "" then
    set waitTime to 30
  else
    try
      set waitTime to waitTime as number
    on error
      set waitTime to 30
    end try
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  set cleanResult to "Clean result unknown"
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Select Product menu
        click menu item "Product" of menu bar 1
        delay 0.5
        
        -- Click Clean Build Folder menu item (holding option key changes "Clean" to "Clean Build Folder")
        -- First try Clean Build Folder (with option key)
        try
          key down option
          delay 0.2
          click menu item "Clean Build Folder" of menu "Product" of menu bar 1
          delay 0.2
          key up option
        on error
          -- If Clean Build Folder isn't available, try regular Clean
          key up option
          click menu item "Clean" of menu "Product" of menu bar 1
        end try
        
        -- Wait for clean to complete
        set startTime to current date
        set timeoutDate to startTime + waitTime
        
        repeat
          delay 1
          
          -- Check for clean status notifications
          set cleanSucceeded to false
          
          -- Try to find clean success notification (may not always appear)
          try
            set cleanSucceeded to exists (first UI element of UI element 1 of window 1 whose value of attribute "AXDescription" contains "Clean Succeeded")
          end try
          
          if cleanSucceeded then
            set cleanResult to "Clean succeeded"
            exit repeat
          end if
          
          -- Check if we've timed out
          if (current date) > timeoutDate then
            -- If we timeout, assume it completed (Clean rarely fails)
            set cleanResult to "Clean likely completed (timeout after " & waitTime & " seconds)"
            exit repeat
          end if
        end repeat
      end tell
    end tell
    
    return cleanResult
  on error errMsg number errNum
    return "error (" & errNum & ") cleaning Xcode project: " & errMsg
  end try
end cleanXcodeProject

return my cleanXcodeProject("--MCP_INPUT:waitTime")
```
