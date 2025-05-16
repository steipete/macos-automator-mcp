---
title: 'Screen Time: Configure App Limits'
category: 04_system/screen_time
id: screen_time_app_limits
description: Sets up app time limits in Screen Time.
keywords:
  - Screen Time
  - app limits
  - time limits
  - usage control
  - app restrictions
language: applescript
argumentsPrompt: Enter the app name and the daily time limit in hours and minutes
notes: >-
  Configures time limits for specific apps. Requires Screen Time to be enabled
  and may require authentication.
---

```applescript
on run {appName, limitHours, limitMinutes}
  try
    -- Handle placeholder substitution
    if appName is "" or appName is missing value then
      set appName to "--MCP_INPUT:appName"
    end if
    
    if limitHours is "" or limitHours is missing value then
      set limitHours to "--MCP_INPUT:limitHours"
    end if
    
    if limitMinutes is "" or limitMinutes is missing value then
      set limitMinutes to "--MCP_INPUT:limitMinutes"
    end if
    
    -- Validate and convert time inputs to numbers
    if limitHours is not "--MCP_INPUT:limitHours" then
      try
        set limitHours to limitHours as number
      on error
        return "Error: Hours must be a number."
      end try
    else
      set limitHours to 1 -- Default to 1 hour
    end if
    
    if limitMinutes is not "--MCP_INPUT:limitMinutes" then
      try
        set limitMinutes to limitMinutes as number
        if limitMinutes < 0 or limitMinutes > 59 then
          return "Error: Minutes must be between 0 and 59."
        end if
      on error
        return "Error: Minutes must be a number between 0 and 59."
      end try
    else
      set limitMinutes to 0 -- Default to 0 minutes
    end if
    
    -- Format the time strings for display in UI
    set hoursStr to limitHours as string
    set minutesStr to limitMinutes as string
    if limitMinutes < 10 then set minutesStr to "0" & minutesStr
    
    tell application "Screen Time"
      activate
      
      -- Give Screen Time time to launch
      delay 1
      
      tell application "System Events"
        tell process "Screen Time"
          -- Navigate to App Limits tab
          if exists tab group 1 of window 1 then
            -- Click on App Limits tab
            if exists radio button "App Limits" of tab group 1 of window 1 then
              click radio button "App Limits" of tab group 1 of window 1
              delay 0.5
              
              -- Click the "+" button to add a new limit
              if exists button 1 of group 1 of group 1 of window 1 then
                click button 1 of group 1 of group 1 of window 1
                delay 0.5
                
                -- Wait for the app selection dialog
                repeat until exists sheet 1 of window 1
                  delay 0.1
                end repeat
                
                -- Search for the app
                if exists text field 1 of sheet 1 of window 1 then
                  set value of text field 1 of sheet 1 of window 1 to appName
                  delay 1
                  
                  -- Try to find and select the app in the results
                  set appFound to false
                  
                  if exists table 1 of scroll area 1 of sheet 1 of window 1 then
                    set resultRows to rows of table 1 of scroll area 1 of sheet 1 of window 1
                    
                    repeat with i from 1 to count of resultRows
                      set currentRow to item i of resultRows
                      
                      if exists text field 1 of currentRow then
                        set rowText to value of text field 1 of currentRow
                        
                        if rowText contains appName then
                          -- Select this app (check the checkbox)
                          if exists checkbox 1 of currentRow then
                            if not (value of checkbox 1 of currentRow as boolean) then
                              click checkbox 1 of currentRow
                            end if
                            set appFound to true
                            exit repeat
                          end if
                        end if
                      end if
                    end repeat
                  end if
                  
                  if not appFound then
                    -- Cancel the operation
                    if exists button "Cancel" of sheet 1 of window 1 then
                      click button "Cancel" of sheet 1 of window 1
                    end if
                    return "Could not find the app \"" & appName & "\" in Screen Time. Please check the app name and try again."
                  end if
                  
                  -- Click "Done" to continue
                  if exists button "Done" of sheet 1 of window 1 then
                    click button "Done" of sheet 1 of window 1
                    delay 0.5
                  end if
                  
                  -- Set the time limit
                  if exists sheet 1 of window 1 then -- Should now be on the time limit sheet
                    -- Set hours
                    if exists text field 1 of sheet 1 of window 1 then
                      set value of text field 1 of sheet 1 of window 1 to hoursStr
                    end if
                    
                    -- Set minutes
                    if exists text field 2 of sheet 1 of window 1 then
                      set value of text field 2 of sheet 1 of window 1 to minutesStr
                    end if
                    
                    -- Click "Done" to save the limit
                    if exists button "Done" of sheet 1 of window 1 then
                      click button "Done" of sheet 1 of window 1
                      
                      return "App limit for \"" & appName & "\" set to " & hoursStr & ":" & minutesStr & " (hours:minutes)."
                    else
                      return "Could not find the 'Done' button to save the app limit."
                    end if
                  else
                    return "Could not access the time limit settings sheet."
                  end if
                else
                  return "Could not find the search field in the app selection dialog."
                end if
              else
                return "Could not find the '+' button to add a new app limit."
              end if
            else
              return "Could not find the 'App Limits' tab in Screen Time."
            end if
          else
            return "Could not access Screen Time tabs. Make sure Screen Time is enabled."
          end if
        end tell
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to set app limit - " & errMsg
  end try
end run
```
END_TIP
