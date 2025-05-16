---
title: 'Firefox: Open URL in New Tab'
category: 07_browsers/firefox
id: firefox_open_url_new_tab
description: Opens a specified URL in a new tab in Firefox.
keywords:
  - Firefox
  - URL
  - new tab
  - browser
  - tab
language: applescript
notes: |
  - Firefox must be running.
  - This script uses UI scripting via System Events.
  - You may need to enable accessibility permissions for the script to work.
---

This script opens a new tab in Firefox and loads a specified URL. Since Firefox has limited AppleScript support, this script uses UI scripting to simulate keyboard shortcuts for opening a new tab, then uses the OpenURL command.

```applescript
on run {input, parameters}
  set theURL to "--MCP_INPUT:url"
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
    
    -- Open a new tab using keyboard shortcut
    tell application "System Events" to keystroke "t" using command down
    delay 0.5 -- Allow the tab to open
    
    -- Now load the URL
    OpenURL theURL
  end tell
  
  return "Opened " & theURL & " in a new Firefox tab"
end run
```
END_TIP
