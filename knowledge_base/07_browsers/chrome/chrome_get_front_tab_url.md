---
title: 'Chrome: Get URL of Front Tab'
category: 07_browsers
id: chrome_get_front_tab_url
description: >-
  Retrieves the web address (URL) of the currently active tab in the frontmost
  Google Chrome window.
keywords:
  - Chrome
  - URL
  - current tab
  - web address
  - browser
language: applescript
notes: |
  - Google Chrome must be running.
  - If no windows or tabs are open, an error message is returned.
---

This script targets Google Chrome to get the URL of its active tab in the front window.

```applescript
tell application "Google Chrome"
  if not running then
    return "error: Google Chrome is not running."
  end if
  
  try
    if (count of windows) is 0 then
      return "error: No Chrome windows open."
    end if
    
    if (count of tabs of front window) is 0 then
      return "error: No tabs in front Chrome window."
    end if
    
    return URL of active tab of front window
  on error errMsg
    return "error: Could not get Chrome URL - " & errMsg
  end try
end tell
```
END_TIP
