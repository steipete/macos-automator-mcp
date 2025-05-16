---
title: 'Chrome: List All Tabs'
category: 07_browsers/chrome
id: chrome_list_all_tabs
description: >-
  Lists all tabs from all windows in Google Chrome with their URLs and titles,
  formatted as JSON.
keywords:
  - Chrome
  - tabs
  - windows
  - list tabs
  - browser
  - tab management
language: applescript
returnValueType: json
notes: >
  - Google Chrome must be running.

  - Returns a JSON array of tab objects with window index, tab index, URL, and
  title.

  - Each tab is uniquely identifiable by the window and tab indices for
  targeting in other scripts.
---

This script lists all tabs from all Chrome windows with their URLs and titles.

```applescript
tell application "Google Chrome"
  if not running then
    return "error: Google Chrome is not running."
  end if
  
  try
    set windowCount to count of windows
    if windowCount is 0 then
      return "error: No Chrome windows open."
    end if
    
    -- Initialize our results array
    set tabsJSON to "["
    set first_tab to true
    
    -- Loop through each window
    repeat with windowIndex from 1 to windowCount
      set tabCount to count of tabs of window windowIndex
      
      -- Loop through each tab in the window
      repeat with tabIndex from 1 to tabCount
        set tabProperties to properties of tab tabIndex of window windowIndex
        set tabURL to URL of tabProperties
        set tabTitle to title of tabProperties
        
        -- Format the tab info as a JSON object
        if not first_tab then
          set tabsJSON to tabsJSON & ","
        end if
        set first_tab to false
        
        set tabsJSON to tabsJSON & "{"
        set tabsJSON to tabsJSON & "\"window\": " & windowIndex & ","
        set tabsJSON to tabsJSON & "\"tab\": " & tabIndex & ","
        set tabsJSON to tabsJSON & "\"url\": \"" & my jsonEscape(tabURL) & "\","
        set tabsJSON to tabsJSON & "\"title\": \"" & my jsonEscape(tabTitle) & "\""
        set tabsJSON to tabsJSON & "}"
      end repeat
    end repeat
    
    -- Close the JSON array
    set tabsJSON to tabsJSON & "]"
    return tabsJSON
    
  on error errMsg
    return "error: Failed to list Chrome tabs - " & errMsg
  end try
end tell

-- Helper function to escape special characters in JSON strings
on jsonEscape(theString)
  set resultString to ""
  set specialChars to {ASCII character 8, ASCII character 9, ASCII character 10, ASCII character 12, ASCII character 13, "\"", "\\"}
  set replacements to {"\\b", "\\t", "\\n", "\\f", "\\r", "\\\"", "\\\\"}
  
  repeat with i from 1 to length of theString
    set currentChar to character i of theString
    set found to false
    
    repeat with j from 1 to length of specialChars
      if currentChar is item j of specialChars then
        set resultString to resultString & item j of replacements
        set found to true
        exit repeat
      end if
    end repeat
    
    if not found then
      set resultString to resultString & currentChar
    end if
  end repeat
  
  return resultString
end jsonEscape
```
END_TIP
