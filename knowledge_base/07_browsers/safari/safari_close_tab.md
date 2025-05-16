---
title: 'Safari: Close Tab'
category: 07_browsers
id: safari_close_tab
description: Closes the current tab or a tab with a specific index in Safari.
keywords:
  - Safari
  - close tab
  - browser
  - tab management
language: applescript
isComplex: false
argumentsPrompt: >-
  Optional tab index to close as 'tabIndex' in inputData. If not provided,
  closes the current tab.
notes: >
  - Safari must be running for this script to work.

  - If no tabIndex is provided, the currently active tab will be closed.

  - If tabIndex is provided, the tab at that index in the front window will be
  closed (1-based index).

  - If the last tab is closed, Safari's behavior is to close the window as well.
---

This script closes a tab in Safari, either the current tab or a tab with a specific index.

```applescript
--MCP_INPUT:tabIndex

on closeTab(tabIndex)
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    try
      if (count of windows) is 0 then
        return "error: No windows open in Safari."
      end if
      
      tell front window
        if (count of tabs) is 0 then
          return "error: No tabs open in Safari."
        end if
        
        -- If tabIndex is provided and valid, close that specific tab
        if tabIndex is not missing value and tabIndex is not "" then
          try
            set tabIndexNum to tabIndex as number
            if tabIndexNum < 1 or tabIndexNum > (count of tabs) then
              return "error: Invalid tab index. Must be between 1 and " & (count of tabs) & "."
            end if
            
            close tab tabIndexNum
            return "Successfully closed tab at index " & tabIndexNum & "."
          on error
            return "error: Invalid tab index. Please provide a number."
          end try
        else
          -- No index provided, close the current tab
          close current tab
          return "Successfully closed the current tab."
        end if
      end tell
    on error errMsg
      return "error: Failed to close tab - " & errMsg
    end try
  end tell
end closeTab

return my closeTab("--MCP_INPUT:tabIndex")
```
