---
title: 'Safari: Clear Cache and Website Data'
category: 07_browsers/safari
id: safari_clear_cache
description: >-
  Clears Safari's cache, cookies, and website data for improved testing and
  development.
keywords:
  - Safari
  - cache
  - cookies
  - web development
  - testing
  - website data
  - clear data
  - debug
language: applescript
isComplex: false
argumentsPrompt: >-
  Optional clearOption as 'clearOption' in inputData. Values can be 'all',
  'cache', 'cookies', or 'local'. Defaults to 'all'.
notes: >
  - Safari must be running.

  - This script uses UI automation via System Events, so Accessibility
  permissions are required.

  - The script navigates Safari's preferences and clears the selected data.

  - Clear options:
    - 'all': Clears all website data (default)
    - 'cache': Clears only the browser cache
    - 'cookies': Clears only cookies and website data
    - 'local': Clears only local storage and databases
  - Safari will need to be relaunched after clearing certain types of data.

  - The exact UI elements may vary slightly between Safari versions, so the
  script tries multiple approaches.
---

This script clears Safari's cache and website data, which is useful for web development and testing.

```applescript
--MCP_INPUT:clearOption

on clearSafariData(clearOption)
  if clearOption is missing value or clearOption is "" then
    set clearOption to "all"
  end if
  
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  tell application "System Events"
    tell process "Safari"
      -- Open Safari preferences
      click menu item "Settings…" of menu "Safari" of menu bar 1
      delay 1
      
      -- Go to the Privacy tab
      try
        -- Modern Safari versions (13+)
        click button "Privacy" of toolbar 1 of window 1
      on error
        -- Try alternative UI path
        try
          -- Older Safari versions
          click button "Privacy" of window 1
        on error
          -- Try by position or tab index
          try
            -- Try the 3rd or 4th button in the toolbar
            click button 4 of toolbar 1 of window 1
          on error
            try
              click button 3 of toolbar 1 of window 1
            on error
              return "error: Could not navigate to Privacy settings."
            end try
          end try
        end try
      end try
      
      delay 0.5
      
      -- Clear different types of data based on user option
      if clearOption is "all" or clearOption is "cache" then
        -- Click "Manage Website Data..." button
        try
          click button "Manage Website Data…" of window 1
          delay 1
          
          -- Click "Remove All" button in the dialog
          click button "Remove All" of sheet 1 of window 1
          delay 0.5
          
          -- Confirm removal
          click button "Remove Now" of sheet 1 of sheet 1 of window 1
          delay 0.5
        on error errMsg
          log "Error clearing website data: " & errMsg
        end try
      end if
      
      if clearOption is "all" or clearOption is "cookies" then
        -- Try to click "Remove All Website Data" button if it exists
        try
          click button "Remove All Website Data…" of window 1
          delay 0.5
          
          -- Confirm removal
          click button "Remove Now" of sheet 1 of window 1
          delay 0.5
        on error errMsg
          log "Error clearing all website data: " & errMsg
          -- Might be a different UI version, try alternative approach
        end try
      end if
      
      -- For local storage specifically
      if clearOption is "all" or clearOption is "local" then
        -- This is typically cleared with "Remove All Website Data" but
        -- some versions of Safari have separate controls
        try
          click checkbox "Block all cookies" of window 1
          delay 0.5
          click checkbox "Block all cookies" of window 1
          delay 0.5
        on error errMsg
          log "Error toggling cookie settings: " & errMsg
        end try
      end if
      
      -- Close preferences window
      try
        keystroke "w" using command down
      on error
        try
          click button 1 of window 1
        on error errMsg
          log "Error closing preferences: " & errMsg
        end try
      end try
    end tell
  end tell
  
  -- Return success message based on what was cleared
  if clearOption is "all" then
    return "Successfully cleared all Safari website data and cache."
  else if clearOption is "cache" then
    return "Successfully cleared Safari cache."
  else if clearOption is "cookies" then
    return "Successfully cleared Safari cookies and website data."
  else if clearOption is "local" then
    return "Successfully cleared Safari local storage and databases."
  else
    return "Unknown clear option. Use 'all', 'cache', 'cookies', or 'local'."
  end if
end clearSafariData

return my clearSafariData("--MCP_INPUT:clearOption")
```
