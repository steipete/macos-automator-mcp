---
title: "Safari: Get URL of Front Tab"
category: "04_web_browsers" # This will be nested, e.g., knowledge_base/04_web_browsers/safari/
id: safari_get_front_tab_url
description: "Retrieves the web address (URL) of the currently active tab in the frontmost Safari window."
keywords: ["Safari", "URL", "current tab", "web address", "browser"]
language: applescript
notes: |
  - Safari must be running.
  - If no windows or documents are open, an error message is returned.
---

This script targets Safari to get the URL of its front document (active tab).

```applescript
tell application "Safari"
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  try
    if (count of documents) > 0 then
      return URL of front document
    else
      return "error: No documents open in Safari."
    end if
  on error errMsg
    return "error: Could not get Safari URL - " & errMsg
  end try
end tell
```
END_TIP