---
title: 'Firefox: Close Current Tab'
category: 07_browsers
id: firefox_close_current_tab
description: Closes the currently active tab in Firefox.
keywords:
  - Firefox
  - tab
  - close tab
  - browser
  - UI scripting
language: applescript
notes: >
  - Firefox must be running.

  - Uses keyboard shortcut to close the current tab.

  - Requires accessibility permissions for UI scripting.

  - Will close Firefox if only one tab is open (unless configured to keep window
  open).
---

This script closes the currently active tab in Firefox. Since Firefox has limited AppleScript support, this script uses System Events to send the standard keyboard shortcut for closing a tab.

```applescript
on run
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Use the standard shortcut to close a tab (Command+W)
      keystroke "w" using {command down}
    end tell
  end tell
  
  return "Closed the current Firefox tab"
end run
```

### Alternative with Tab Count Check

This alternative script first checks if there's only one tab open, which can be useful if you want to show a warning or take different action when there's only one tab (closing the last tab usually closes the Firefox window).

```applescript
on run
  -- Save current clipboard content
  set oldClipboard to the clipboard
  
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  -- First check how many tabs we have using the tab list
  tell application "System Events"
    tell process "Firefox"
      -- Open tab overview
      keystroke "," using {shift down, command down}
      delay 0.5 -- Allow the overview to open
      
      -- Select all text (tabs list)
      keystroke "a" using {command down}
      delay 0.2
      
      -- Copy to clipboard
      keystroke "c" using {command down}
      delay 0.2
      
      -- Close the overview
      keystroke escape
    end tell
  end tell
  
  -- Process clipboard content to count tabs
  set tabsText to the clipboard
  set AppleScript's text item delimiters to return
  set tabItems to every text item of tabsText
  set AppleScript's text item delimiters to ""
  
  -- Count non-empty items
  set tabCount to 0
  repeat with tabItem in tabItems
    if tabItem is not "" and tabItem does not contain "Tabs" then
      set tabCount to tabCount + 1
    end if
  end repeat
  
  -- Restore original clipboard
  set the clipboard to oldClipboard
  
  -- Close tab, or warn if it's the last tab
  if tabCount > 1 then
    tell application "System Events"
      tell process "Firefox"
        -- Use the standard shortcut to close a tab (Command+W)
        keystroke "w" using {command down}
      end tell
    end tell
    return "Closed the current Firefox tab. " & (tabCount - 1) & " tabs remaining."
  else
    return "Warning: This is the last tab. Closing it would close the Firefox window."
    
    -- If you want to force close the last tab anyway, uncomment these lines:
    -- tell application "System Events"
    --   tell process "Firefox"
    --     keystroke "w" using {command down}
    --   end tell
    -- end tell
  end if
end run
```

This script includes additional logic to check if the tab being closed is the last open tab, which would normally close the Firefox window. You can modify the script to close the tab anyway by uncommenting the final section.
END_TIP
