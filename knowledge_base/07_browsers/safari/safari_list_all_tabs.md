---
title: "Safari: List All Tabs"
category: "05_web_browsers"
id: safari_list_all_tabs
description: "Retrieves a list of all open tabs in all Safari windows, including their titles and URLs."
keywords: ["Safari", "tabs", "windows", "list", "browser", "web"]
language: applescript
isComplex: false
notes: |
  - Safari must be running for this script to work.
  - Returns a JSON string with window and tab information.
  - Each window includes an index and an array of tabs.
  - Each tab includes a title, URL, and whether it is the active tab.
---

This script retrieves all open tabs in all Safari windows and returns them as a structured JSON string.

```applescript
on run
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    try
      set windowCount to count of windows
      if windowCount is 0 then
        return "error: No windows open in Safari."
      end if
      
      -- Initial JSON structure
      set jsonOutput to "{"
      set jsonOutput to jsonOutput & "\"windows\": ["
      
      set windowIndex to 1
      repeat with currentWindow in windows
        set tabCount to count of tabs of currentWindow
        
        -- Add window info
        set jsonOutput to jsonOutput & "{"
        set jsonOutput to jsonOutput & "\"index\": " & windowIndex & ","
        set jsonOutput to jsonOutput & "\"tabs\": ["
        
        -- Add each tab in the window
        set tabIndex to 1
        repeat with currentTab in tabs of currentWindow
          set tabName to name of currentTab
          set tabURL to URL of currentTab
          
          -- Replace quotes and backslashes for JSON compatibility
          set cleanTabName to my replaceText(tabName, "\"", "\\\"")
          set cleanTabURL to my replaceText(tabURL, "\"", "\\\"")
          
          -- Check if this is the current/active tab
          set isActiveTab to (current tab of currentWindow is currentTab)
          
          -- Add tab info
          set jsonOutput to jsonOutput & "{"
          set jsonOutput to jsonOutput & "\"title\": \"" & cleanTabName & "\","
          set jsonOutput to jsonOutput & "\"url\": \"" & cleanTabURL & "\","
          set jsonOutput to jsonOutput & "\"isActive\": " & isActiveTab
          set jsonOutput to jsonOutput & "}"
          
          -- Add comma if not the last tab
          if tabIndex < tabCount then
            set jsonOutput to jsonOutput & ","
          end if
          
          set tabIndex to tabIndex + 1
        end repeat
        
        set jsonOutput to jsonOutput & "]"
        set jsonOutput to jsonOutput & "}"
        
        -- Add comma if not the last window
        if windowIndex < windowCount then
          set jsonOutput to jsonOutput & ","
        end if
        
        set windowIndex to windowIndex + 1
      end repeat
      
      set jsonOutput to jsonOutput & "]"
      set jsonOutput to jsonOutput & "}"
      
      return jsonOutput
    on error errMsg
      return "error: Failed to list Safari tabs - " & errMsg
    end try
  end tell
end run

-- Helper function to replace text
on replaceText(theText, oldString, newString)
  set AppleScript's text item delimiters to oldString
  set tempList to text items of theText
  set AppleScript's text item delimiters to newString
  set theText to tempList as text
  set AppleScript's text item delimiters to ""
  return theText
end replaceText
```