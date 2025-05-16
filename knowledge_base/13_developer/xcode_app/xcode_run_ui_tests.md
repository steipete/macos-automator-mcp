---
title: "Xcode: Run UI Tests"
category: "09_developer_and_utility_apps"
id: xcode_run_ui_tests
description: "Runs UI tests for an open Xcode project using XCTest UI testing framework."
keywords: ["Xcode", "XCTest", "UI test", "testing", "XCUITest", "developer", "iOS", "macOS"]
language: applescript
isComplex: true
argumentsPrompt: "Optional wait time (in seconds) for tests to complete as 'waitTime' in inputData (default is 120 seconds)"
notes: |
  - Requires Xcode to be already open with a project containing UI tests
  - Uses UI scripting via System Events so requires Accessibility permissions
  - UI tests take longer than unit tests since they run the app in simulator
  - Navigates Test Navigator to find and run UI tests specifically
  - Results are shown in the Test Navigator panel in Xcode
---

```applescript
--MCP_INPUT:waitTime

on runXcodeUITests(waitTime)
  -- Default wait time of 120 seconds if not specified (UI tests take longer)
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
  
  set testResult to "UI Test result unknown"
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- First make sure the Navigator is visible (Command+0)
        keystroke "0" using {command down}
        delay 1
        
        -- Switch to Test Navigator (Command+6)
        keystroke "6" using {command down}
        delay 1
        
        -- Look for the Test Navigator
        try
          -- Find the navigator outline with UI tests
          set uiTestTargets to UI elements of outline 1 of scroll area 1 of group 1 of splitter group 1 of window 1 whose name contains "UITests"
          
          if (count of uiTestTargets) > 0 then
            -- Find the first UI test target and right-click it
            set uiTestTarget to item 1 of uiTestTargets
            click uiTestTarget using {button:2}
            delay 0.5
            
            -- Select "Run X Tests" from context menu
            click menu item "Run" of menu 1
            
            -- Wait for tests to complete
            set startTime to current date
            set timeoutDate to startTime + waitTime
            
            -- Wait for tests to complete
            repeat
              delay 2
              
              -- Check for test status indicators
              set testsSucceeded to false
              set testsFailed to false
              
              -- Look for success indicators (green checkmarks)
              try
                set testsSucceeded to exists (first UI element of outline 1 of scroll area 1 of group 1 of splitter group a of window 1 whose description contains "Test Succeeded")
              end try
              
              -- Look for failure indicators (red X)
              try
                set testsFailed to exists (first UI element of outline 1 of scroll area 1 of group 1 of splitter group a of window 1 whose description contains "Test Failed")
              end try
              
              if testsSucceeded then
                set testResult to "All UI tests succeeded"
                exit repeat
              else if testsFailed then
                set testResult to "One or more UI tests failed"
                exit repeat
              end if
              
              -- Check if we've timed out
              if (current date) > timeoutDate then
                set testResult to "UI Test timeout after " & waitTime & " seconds"
                exit repeat
              end if
            end repeat
          else
            set testResult to "No UI test targets found in the project"
          end if
        on error errMsg
          set testResult to "Error finding or running UI tests: " & errMsg
        end try
      end tell
    end tell
    
    return testResult
  on error errMsg number errNum
    return "error (" & errNum & ") running Xcode UI tests: " & errMsg
  end try
end runXcodeUITests

return my runXcodeUITests("--MCP_INPUT:waitTime")
```