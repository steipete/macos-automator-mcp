---
title: 'Xcode: Open Instruments for Profiling'
category: 13_developer
id: xcode_open_instruments
description: Opens Xcode Instruments for app profiling with a selected template.
keywords:
  - Xcode
  - Instruments
  - profiling
  - performance
  - Time Profiler
  - Leaks
  - developer
  - iOS
  - macOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Profile template to use (e.g., 'Time Profiler', 'Leaks', 'Energy Log',
  'Allocations') as 'profileTemplate' in inputData
notes: >
  - Requires Xcode to be already open with a project loaded

  - Uses UI scripting via System Events so requires Accessibility permissions

  - Launches the selected Instruments template for profiling

  - Common templates include: Time Profiler, Leaks, Energy Log, Allocations,
  etc.

  - Instruments is a powerful tool for analyzing app performance and memory
  usage
---

```applescript
--MCP_INPUT:profileTemplate

on openXcodeInstruments(profileTemplate)
  -- Default to Time Profiler if no template specified
  if profileTemplate is missing value or profileTemplate is "" then
    set profileTemplate to "Time Profiler"
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  set profilerResult to "Instruments result unknown"
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Select Product menu
        click menu item "Product" of menu bar 1
        delay 0.5
        
        -- Click Profile menu item
        click menu item "Profile" of menu "Product" of menu bar 1
        
        -- Wait for Instruments template chooser to appear
        delay 3
        
        -- Select the template
        try
          tell application process "Instruments"
            -- Look for the template in the template browser
            set foundTemplate to false
            
            -- Wait for Instruments to fully load
            delay 2
            
            -- Try to find and click the template
            tell window 1
              set templateElements to (UI elements whose name contains profileTemplate)
              if (count of templateElements) > 0 then
                click item 1 of templateElements
                delay 1
                
                -- Click Choose button
                click button "Choose" of window 1
                
                set foundTemplate to true
                set profilerResult to "Successfully opened Instruments with template: " & profileTemplate
              else
                set profilerResult to "Could not find template: " & profileTemplate
              end if
            end tell
          end tell
        on error errMsg
          set profilerResult to "Error selecting Instruments template: " & errMsg
        end try
      end tell
    end tell
    
    return profilerResult
  on error errMsg number errNum
    return "error (" & errNum & ") opening Xcode Instruments: " & errMsg
  end try
end openXcodeInstruments

return my openXcodeInstruments("--MCP_INPUT:profileTemplate")
```
