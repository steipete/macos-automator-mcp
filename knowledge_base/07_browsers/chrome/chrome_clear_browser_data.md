---
title: 'Chrome: Clear Browser Data'
category: 07_browsers
id: chrome_clear_browser_data
description: >-
  Clears various types of browser data from Chrome including cache, cookies,
  history, and more with options for time ranges.
keywords:
  - Chrome
  - clear data
  - cache
  - cookies
  - history
  - browser data
  - privacy
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Data clearing options in inputData. For example: { "dataTypes": ["cache",
  "cookies"], "timeRange": "last_hour" }. Available dataTypes: cache, cookies,
  history, passwords, formData, localStorage, downloads. Available timeRanges:
  last_hour, last_day, last_week, last_month, all_time.
notes: >
  - Google Chrome must be running.

  - Opens Chrome's Clear Browsing Data dialog and automates the selection
  process.

  - Requires Accessibility permissions for UI scripting via System Events.

  - Can clear multiple data types in a single operation.

  - Supports various time ranges for selective clearing.

  - This script respects Chrome's security model, so it cannot bypass
  confirmation dialogs.
---

This script automates clearing various types of browser data from Chrome with options for time ranges.

```applescript
--MCP_INPUT:dataTypes
--MCP_INPUT:timeRange

on clearChromeData(dataTypes, timeRange)
  -- Validate and set default parameters
  if dataTypes is missing value or dataTypes is "" then
    set dataTypes to {"cache", "cookies", "history"}
  end if
  
  if timeRange is missing value or timeRange is "" then
    set timeRange to "all_time"
  end if
  
  -- Convert string to list if needed (inputData might send as string)
  if class of dataTypes is string then
    -- Convert comma-separated string to list
    set AppleScript's text item delimiters to ","
    set dataTypesList to text items of dataTypes
    set AppleScript's text item delimiters to ""
    
    -- Trim whitespace from items
    set cleanList to {}
    repeat with i from 1 to count of dataTypesList
      set currentItem to item i of dataTypesList
      set trimmedItem to my trimWhitespace(currentItem)
      if trimmedItem is not "" then
        set end of cleanList to trimmedItem
      end if
    end repeat
    
    set dataTypes to cleanList
  end if
  
  -- Make sure Chrome is running
  tell application "Google Chrome"
    if not running then
      return "error: Google Chrome is not running."
    end if
    
    -- Activate Chrome to ensure it's in the foreground
    activate
  end tell
  
  -- Wait for Chrome to become active
  delay 0.5
  
  -- Open the Clear Browsing Data dialog using keyboard shortcut
  tell application "System Events"
    tell process "Google Chrome"
      set frontmost to true
      
      -- Open Clear Browsing Data dialog with Shift+Command+Delete
      key code 51 using {shift down, command down} -- 51 is delete/backspace
      
      -- Wait for dialog to appear
      delay 1.5
      
      -- Try to find the Clear Browsing Data dialog
      set foundDialog to false
      set dialogWindow to missing value
      
      repeat with w in windows
        if description of w contains "Clear Browsing Data" then
          set dialogWindow to w
          set foundDialog to true
          exit repeat
        end if
      end repeat
      
      if not foundDialog then
        -- Alternative: Try to find sheet or dialog by its controls
        repeat with w in windows
          try
            set checkboxes to checkboxes of w
            set timeRangePopup to pop up buttons of w
            
            if (count of checkboxes) > 3 and (count of timeRangePopup) > 0 then
              set dialogWindow to w
              set foundDialog to true
              exit repeat
            end if
          on error
            -- Continue to next window
          end try
        end repeat
      end if
      
      if not foundDialog then
        return "error: Could not find the Clear Browsing Data dialog. Please check if Chrome is in the expected state."
      end if
      
      -- First, set the time range
      try
        set timePopup to pop up button 1 of dialogWindow
        click timePopup
        delay 0.5
        
        -- Map time range to menu item index (1-based)
        set timeRangeIndex to my getTimeRangeIndex(timeRange)
        
        -- Click the appropriate time range menu item
        click menu item timeRangeIndex of menu 1 of timePopup
        delay 0.5
      on error errMsg
        return "error: Failed to set time range - " & errMsg
      end try
      
      -- Configure the data types to clear by toggling checkboxes
      set clearSummary to ""
      
      -- Get all checkboxes in the dialog
      set allCheckboxes to checkboxes of dialogWindow
      
      -- Try to map dataType names to checkbox indexes or titles
      repeat with dataType in dataTypes
        set typeHandled to false
        
        -- First attempt: Look for checkbox with matching description
        repeat with cb in allCheckboxes
          try
            set cbTitle to title of cb
            
            -- Match checkbox by dataType keyword
            if my checkboxMatchesDataType(cbTitle, dataType) then
              -- Set checkbox to checked state
              if value of cb is 0 then
                click cb
                delay 0.2
              end if
              
              set clearSummary to clearSummary & "• " & cbTitle & return
              set typeHandled to true
              exit repeat
            end if
          on error
            -- Some checkboxes might not have titles, continue
          end try
        end repeat
        
        if not typeHandled then
          set clearSummary to clearSummary & "• Failed to find checkbox for: " & dataType & return
        end if
      end repeat
      
      -- Click the Clear Data button (usually the default button)
      try
        -- Find the "Clear data" or "Clear browsing data" button
        set buttonFound to false
        set allButtons to buttons of dialogWindow
        
        repeat with btn in allButtons
          try
            set btnTitle to title of btn
            
            if btnTitle contains "Clear" then
              click btn
              set buttonFound to true
              exit repeat
            end if
          on error
            -- Continue to next button
          end try
        end repeat
        
        if not buttonFound then
          -- Fallback: Try the default button or the last button
          if (count of allButtons) > 0 then
            click item ((count of allButtons)) of allButtons
            set buttonFound to true
          end if
        end if
        
        if not buttonFound then
          return "error: Could not find the Clear Data button in the dialog."
        end if
      on error errMsg
        return "error: Failed to click the Clear Data button - " & errMsg
      end try
      
      -- Wait for confirmation dialog if it appears
      delay 2
      
      -- Check for confirmation dialog and click if found
      set confirmDialogFound to false
      
      repeat with w in windows
        try
          if description of w contains "Confirm" or description of w contains "clear" then
            set confirmButton to button 1 of w
            click confirmButton
            set confirmDialogFound to true
            exit repeat
          end if
        on error
          -- Continue to next window
        end try
      end repeat
      
      -- Provide success message
      set timeRangeText to my getTimeRangeText(timeRange)
      
      if clearSummary is "" then
        set clearSummary to "Requested data types"
      end if
      
      return "Successfully initiated clearing of browser data for time range: " & timeRangeText & return & return & clearSummary & return & "Chrome's clear browsing data process completes in the background."
    end tell
  end tell
end clearChromeData

-- Helper function to trim whitespace from a string
on trimWhitespace(theString)
  set whitespace to {" ", tab, return, linefeed}
  
  -- Trim leading whitespace
  set trimmedString to theString
  repeat while trimmedString begins with whitespace
    set trimmedString to text 2 thru -1 of trimmedString
  end repeat
  
  -- Trim trailing whitespace
  repeat while trimmedString ends with whitespace
    set trimmedString to text 1 thru -2 of trimmedString
  end repeat
  
  return trimmedString
end trimWhitespace

-- Helper function to determine if a checkbox matches a data type
on checkboxMatchesDataType(checkboxTitle, dataType)
  set checkboxLower to my toLowerCase(checkboxTitle)
  set dataTypeLower to my toLowerCase(dataType)
  
  -- Common mappings between data types and checkbox titles
  if dataTypeLower is "cache" and (checkboxLower contains "cache" or checkboxLower contains "temporary" or checkboxLower contains "files") then
    return true
  else if dataTypeLower is "cookies" and (checkboxLower contains "cookie" or checkboxLower contains "site data") then
    return true
  else if dataTypeLower is "history" and (checkboxLower contains "history" or checkboxLower contains "browsing") then
    return true
  else if dataTypeLower is "passwords" and (checkboxLower contains "password" or checkboxLower contains "sign-in") then
    return true
  else if dataTypeLower is "formdata" and (checkboxLower contains "form" or checkboxLower contains "autofill") then
    return true
  else if dataTypeLower is "localstorage" and (checkboxLower contains "local" or checkboxLower contains "storage" or checkboxLower contains "site data") then
    return true
  else if dataTypeLower is "downloads" and checkboxLower contains "download" then
    return true
  end if
  
  -- Direct substring match as fallback
  return checkboxLower contains dataTypeLower
end checkboxMatchesDataType

-- Helper function to convert time range to menu item index
on getTimeRangeIndex(timeRange)
  set timeRangeLower to my toLowerCase(timeRange)
  
  if timeRangeLower is "last_hour" or timeRangeLower is "hour" then
    return 1
  else if timeRangeLower is "last_day" or timeRangeLower is "day" or timeRangeLower is "24_hours" then
    return 2
  else if timeRangeLower is "last_week" or timeRangeLower is "week" or timeRangeLower is "7_days" then
    return 3
  else if timeRangeLower is "last_month" or timeRangeLower is "month" or timeRangeLower is "4_weeks" then
    return 4
  else if timeRangeLower is "all_time" or timeRangeLower is "all" or timeRangeLower is "everything" then
    return 5
  else
    -- Default to "All time" if unrecognized
    return 5
  end if
end getTimeRangeIndex

-- Helper function to get display text for time range
on getTimeRangeText(timeRange)
  set timeRangeLower to my toLowerCase(timeRange)
  
  if timeRangeLower is "last_hour" or timeRangeLower is "hour" then
    return "Last hour"
  else if timeRangeLower is "last_day" or timeRangeLower is "day" or timeRangeLower is "24_hours" then
    return "Last 24 hours"
  else if timeRangeLower is "last_week" or timeRangeLower is "week" or timeRangeLower is "7_days" then
    return "Last 7 days"
  else if timeRangeLower is "last_month" or timeRangeLower is "month" or timeRangeLower is "4_weeks" then
    return "Last 4 weeks"
  else if timeRangeLower is "all_time" or timeRangeLower is "all" or timeRangeLower is "everything" then
    return "All time"
  else
    return timeRange
  end if
end getTimeRangeText

-- Helper function to convert string to lowercase
on toLowerCase(inputString)
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  set outputString to ""
  
  repeat with i from 1 to length of inputString
    set currentChar to character i of inputString
    set charIndex to offset of currentChar in upperChars
    
    if charIndex > 0 then
      set outputString to outputString & character charIndex of lowerChars
    else
      set outputString to outputString & currentChar
    end if
  end repeat
  
  return outputString
end toLowerCase

return my clearChromeData("--MCP_INPUT:dataTypes", "--MCP_INPUT:timeRange")
```
END_TIP
