---
title: 'Safari: Reload Page'
category: 07_browsers
id: safari_reload_page
description: Reloads (refreshes) the current page in the active Safari tab.
keywords:
  - Safari
  - reload
  - refresh
  - browser
  - web
  - page
language: applescript
isComplex: false
notes: >
  - Safari must be running for this script to work.

  - The script reloads the currently active tab in the frontmost Safari window.

  - If Safari is not running or no documents are open, an error message is
  returned.
---

This script reloads the current page in Safari's active tab.

```applescript
on run
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    try
      if (count of documents) is 0 then
        return "error: No documents open in Safari."
      end if
      
      tell front document
        set currentURL to URL
        reload
        return "Successfully reloaded page: " & currentURL
      end tell
    on error errMsg
      return "error: Failed to reload page - " & errMsg
    end try
  end tell
end run
```
