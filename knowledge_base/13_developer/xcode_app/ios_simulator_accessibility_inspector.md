---
title: 'iOS Simulator: Analyze Accessibility Elements'
category: 13_developer
id: ios_simulator_accessibility_inspector
description: >-
  Launches Accessibility Inspector to analyze accessibility elements in iOS
  Simulator apps.
keywords:
  - iOS Simulator
  - Xcode
  - accessibility
  - inspector
  - VoiceOver
  - analysis
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional app bundle ID as 'bundleID' (to launch before inspection), optional
  device identifier as 'deviceIdentifier' (defaults to 'booted'), and optional
  boolean to generate report as 'generateReport' (default is false).
notes: |
  - Launches Accessibility Inspector tool for detailed accessibility testing
  - Can automatically launch target app for inspection
  - Helps verify proper accessibility labels and traits
  - Crucial for building accessible apps for all users
  - Can generate accessibility audit reports
  - Shows accessibility hierarchy and potential issues
---

```applescript
--MCP_INPUT:bundleID
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:generateReport

on analyzeAccessibilityElements(bundleID, deviceIdentifier, generateReport)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default generate report to false if not specified
  if generateReport is missing value or generateReport is "" then
    set generateReport to false
  else if generateReport is "true" then
    set generateReport to true
  end if
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- If bundleID is provided, launch the app
    if bundleID is not missing value and bundleID is not "" then
      -- Check if the app is installed
      set checkAppCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " 2>/dev/null || echo 'not installed'"
      set appContainer to do shell script checkAppCmd
      
      if appContainer is "not installed" then
        return "error: App with bundle ID '" & bundleID & "' not installed on " & deviceIdentifier & " simulator."
      end if
      
      -- Launch the app
      try
        do shell script "xcrun simctl launch " & quoted form of deviceIdentifier & " " & quoted form of bundleID
        delay 2 -- Give the app time to launch
      on error launchErr
        return "error: Failed to launch app " & bundleID & ". Error: " & launchErr
      end try
    end if
    
    -- Create timestamp for report
    set timeStamp to do shell script "date +%Y%m%d_%H%M%S"
    
    -- Create directory for reports if generating
    set reportDir to ""
    if generateReport then
      set reportDir to "/tmp/accessibility_report_" & timeStamp
      do shell script "mkdir -p " & quoted form of reportDir
    end if
    
    -- Launch Accessibility Inspector
    tell application "Accessibility Inspector" to activate
    delay 1
    
    -- Use UI scripting to configure Accessibility Inspector
    tell application "System Events"
      tell process "Accessibility Inspector"
        -- First check if we need to connect to the simulator
        try
          -- Look for the Target picker popup button
          set targetButton to first pop up button of window "Accessibility Inspector"
          
          -- Click it to show available targets
          click targetButton
          delay 0.5
          
          -- Look for simulator in the menu
          set foundTarget to false
          set targetMenus to menu 1 of targetButton
          
          repeat with menuItem in menu items of targetMenus
            if name of menuItem contains "Simulator" then
              click menuItem
              set foundTarget to true
              exit repeat
            end if
          end repeat
          
          if not foundTarget then
            -- Close menu by clicking elsewhere
            key code 53 -- Escape key
          end if
        end try
        
        -- Wait a moment for connection to establish
        delay 1
        
        -- If generating report, start the audit process
        if generateReport then
          -- Look for Audit tab
          try
            click radio button "Audit" of radio group 1 of window "Accessibility Inspector"
            delay 0.5
            
            -- Click Run Audit button
            click button "Run Audit" of window "Accessibility Inspector"
            delay 5 -- Give time for audit to complete
            
            -- Try to save the audit results
            try
              -- Look for save button
              set saveButton to first button of window "Accessibility Inspector" whose description contains "Save"
              click saveButton
              delay 0.5
              
              -- Set filename in save dialog
              set saveFilename to reportDir & "/accessibility_audit_" & timeStamp & ".txt"
              
              tell sheet 1 of window "Accessibility Inspector"
                set value of text field 1 to saveFilename
                delay 0.5
                click button "Save"
              end tell
              
              set reportGenerated to true
            on error
              set reportGenerated to false
            end try
          on error
            -- Audit tab might not be available
            set reportGenerated to false
          end try
        end if
      end tell
    end tell
    
    set resultMessage to "Launched Accessibility Inspector for " & deviceIdentifier & " simulator"
    
    if bundleID is not missing value and bundleID is not "" then
      set resultMessage to resultMessage & " and launched app " & bundleID
    end if
    
    set resultMessage to resultMessage & ".

The Accessibility Inspector provides:
1. Element inspection - Shows accessibility properties of UI elements
2. Hierarchy view - Displays accessibility element hierarchy
3. Audit tool - Checks for common accessibility issues"
    
    if generateReport and reportGenerated then
      set resultMessage to resultMessage & "

Generated accessibility audit report saved to:
" & reportDir & "/accessibility_audit_" & timeStamp & ".txt"
    else if generateReport then
      set resultMessage to resultMessage & "

Failed to automatically generate audit report. 
To manually generate a report:
1. Click the 'Audit' tab in Accessibility Inspector
2. Click 'Run Audit'
3. Click the save button to save audit results"
    end if
    
    set resultMessage to resultMessage & "

To use Accessibility Inspector effectively:
- Use the pointing tool to inspect specific UI elements
- Check accessibility labels, traits, and values
- Review hierarchy to ensure logical navigation flow
- Fix any issues found in the audit report
- Test with VoiceOver enabled to verify user experience

Most accessibility issues fall into these categories:
- Missing labels or descriptions
- Incorrect traits (button vs static text)
- Poor navigation order
- Elements that can't be activated by assistive technologies"
    
    return resultMessage
  on error errMsg number errNum
    return "error (" & errNum & ") analyzing accessibility elements: " & errMsg
  end try
end analyzeAccessibilityElements

return my analyzeAccessibilityElements("--MCP_INPUT:bundleID", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:generateReport")
```
