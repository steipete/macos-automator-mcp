---
title: "Xcode: Build Project via UI Scripting"
category: "09_developer_and_utility_apps"
id: xcode_build_project_ui
description: "Builds an Xcode project by simulating menu selections in the Xcode UI."
keywords: ["Xcode", "build", "compile", "UI scripting", "menu", "developer"]
language: applescript
isComplex: true
argumentsPrompt: "Optional wait time (in seconds) after build starts as 'waitTime' in inputData (default is 120 seconds)"
notes: |
  - Requires Xcode to be already open with a project loaded
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Waits for a configurable amount of time for build to complete
  - Alternative to xcodebuild when direct UI interaction is preferred
---

```applescript
--MCP_INPUT:waitTime

on buildXcodeProjectUI(waitTime)
  -- Default wait time of 120 seconds if not specified
  if waitTime is missing value or waitTime is "" then
    set waitTime to 120
  else
    try
      set waitTime to waitTime as number
    on error
      set waitTime to 120
    end try
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  set buildResult to "Build result unknown"
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Select Product menu
        click menu item "Product" of menu bar 1
        delay 0.5
        
        -- Click Build menu item
        click menu item "Build" of menu "Product" of menu bar 1
        
        -- Wait for build to complete (observe if build succeeded or failed)
        set startTime to current date
        set timeoutDate to startTime + waitTime
        
        repeat
          delay 1
          
          -- Check for build status notifications
          set buildSucceeded to false
          set buildFailed to false
          
          -- Try to find build success notification
          try
            set buildSucceeded to exists (first UI element of UI element 1 of window 1 whose value of attribute "AXDescription" contains "Build Succeeded")
          end try
          
          -- Try to find build failure notification
          try
            set buildFailed to exists (first UI element of UI element 1 of window 1 whose value of attribute "AXDescription" contains "Build Failed")
          end try
          
          if buildSucceeded then
            set buildResult to "Build succeeded"
            exit repeat
          else if buildFailed then
            set buildResult to "Build failed"
            exit repeat
          end if
          
          -- Check if we've timed out
          if (current date) > timeoutDate then
            set buildResult to "Build timeout after " & waitTime & " seconds"
            exit repeat
          end if
        end repeat
      end tell
    end tell
    
    return buildResult
  on error errMsg number errNum
    return "error (" & errNum & ") building Xcode project via UI: " & errMsg
  end try
end buildXcodeProjectUI

return my buildXcodeProjectUI("--MCP_INPUT:waitTime")
```