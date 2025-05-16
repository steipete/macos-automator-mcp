---
title: 'Screen Time: Get App Usage'
category: 04_system/screen_time
id: screen_time_get_usage
description: Retrieves app usage statistics from Screen Time.
keywords:
  - Screen Time
  - app usage
  - usage statistics
  - screen usage
  - time tracking
language: applescript
notes: >-
  Gets app usage information from Screen Time. This requires Screen Time to be
  enabled on your Mac. May require Full Disk Access permissions.
---

```applescript
tell application "Screen Time"
  try
    activate
    
    -- Give Screen Time time to launch
    delay 1
    
    tell application "System Events"
      tell process "Screen Time"
        -- Make sure we're on the App Usage tab
        if exists tab group 1 of window 1 then
          -- Click on App Usage tab if not already selected
          if exists radio button "App Usage" of tab group 1 of window 1 then
            if not (value of radio button "App Usage" of tab group 1 of window 1 as boolean) then
              click radio button "App Usage" of tab group 1 of window 1
              delay 0.5
            end if
          end if
          
          -- Get app usage data from the list
          set appData to {}
          
          if exists table 1 of scroll area 1 of group 1 of group 1 of window 1 then
            set usageTable to table 1 of scroll area 1 of group 1 of group 1 of window 1
            
            if exists rows of usageTable then
              set appRows to rows of usageTable
              
              repeat with i from 1 to count of appRows
                set currentRow to item i of appRows
                
                -- Get app name
                set appName to ""
                if exists text field 1 of currentRow then
                  set appName to value of text field 1 of currentRow
                end if
                
                -- Get usage time
                set usageTime to ""
                if exists text field 2 of currentRow then
                  set usageTime to value of text field 2 of currentRow
                end if
                
                -- Add to our collection if we got meaningful data
                if appName is not "" and usageTime is not "" then
                  set end of appData to {name:appName, usage:usageTime}
                end if
              end repeat
            end if
          end if
          
          -- Get time period from the view (Today, Yesterday, etc.)
          set timePeriod to "Today" -- Default
          if exists pop up button 1 of group 1 of group 1 of window 1 then
            set timePeriod to value of pop up button 1 of group 1 of group 1 of window 1
          end if
          
          -- Format the output
          if (count of appData) is 0 then
            return "No app usage data available for " & timePeriod & ". Make sure Screen Time is enabled."
          else
            set resultText to "Screen Time App Usage (" & timePeriod & "):" & return & return
            
            repeat with i from 1 to count of appData
              set currentApp to item i of appData
              set resultText to resultText & name of currentApp & ": " & usage of currentApp & return
            end repeat
            
            return resultText
          end if
        else
          return "Could not access app usage data. Make sure Screen Time is enabled in System Settings."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get Screen Time data - " & errMsg
  end try
end tell
```
END_TIP
