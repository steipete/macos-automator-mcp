---
title: "Firefox: List All Tabs"
category: "05_web_browsers"
id: firefox_list_all_tabs
description: "Lists all open tabs in the frontmost Firefox window using UI scripting."
keywords: ["Firefox", "tabs", "list tabs", "window", "browser", "UI scripting"]
language: applescript
notes: |
  - Firefox must be running.
  - This script uses UI scripting via System Events.
  - Requires accessibility permissions.
  - Not as reliable as Safari's native AppleScript support, as it depends on UI elements.
---

This script retrieves a list of all open tabs in the frontmost Firefox window. Since Firefox has limited AppleScript support, this script uses UI scripting to interact with Firefox's Tab Manager.

```applescript
on run
  -- Initialize empty list for tab information
  set tabsList to {}
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate fully
  end tell
  
  -- Open the tab list menu
  tell application "System Events"
    tell process "Firefox"
      -- Click the tab list button
      keystroke "," using {shift down, command down} -- Keyboard shortcut for tab list
      delay 0.5 -- Allow menu to appear
      
      -- Get tab list
      set tabElements to UI elements of group 1 of window 1 whose role is "AXStaticText"
      
      -- Extract tab information
      repeat with tabElement in tabElements
        set tabName to value of tabElement
        if tabName is not "" and tabName is not "Tabs" then
          copy tabName to end of tabsList
        end if
      end repeat
      
      -- Close the tab list
      keystroke escape
    end tell
  end tell
  
  return tabsList
end run
```

### Alternative Method with Clipboard

If the above method doesn't work reliably, this alternative uses the clipboard to get tab information from Firefox's "View All Tabs" dialog:

```applescript
on run
  -- Save current clipboard content
  set oldClipboard to the clipboard
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate fully
  end tell
  
  -- Use Tab Overview feature
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
  
  -- Process clipboard content into a list
  set tabsText to the clipboard
  set AppleScript's text item delimiters to return
  set tabsList to every text item of tabsText
  set AppleScript's text item delimiters to ""
  
  -- Clean up the list
  set cleanList to {}
  repeat with tabItem in tabsList
    if tabItem is not "" and tabItem does not contain "Tabs" then
      copy tabItem to end of cleanList
    end if
  end repeat
  
  -- Restore original clipboard
  set the clipboard to oldClipboard
  
  return cleanList
end run
```

Note: These methods rely on Firefox's UI, which can change between versions. They may need adjustment if Firefox's interface is updated in future releases.
END_TIP