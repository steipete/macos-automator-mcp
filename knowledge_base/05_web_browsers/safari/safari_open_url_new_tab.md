---
title: "Safari: Open URL in New Tab"
category: "04_web_browsers" # Subdir: safari
id: safari_open_url_new_tab
description: "Opens a specified URL in a new tab in the frontmost Safari window."
keywords: ["safari", "new tab", "open url", "navigation"]
language: applescript
isComplex: true
argumentsPrompt: "URL to open as 'targetURL' in inputData (e.g., { \"targetURL\": \"https://apple.com\" })."
---

```applescript
--MCP_INPUT:targetURL

on openInSafariNewTab(theURL)
  if theURL is missing value or theURL is "" then return "error: URL not provided."
  tell application "Safari"
    if not running then
      run
      delay 1 -- Give Safari time to launch
    end if
    activate
    
    if (count of windows) is 0 then
      -- No windows open, make a new one which will also create a document/tab
      make new document with properties {URL:theURL}
    else
      tell front window
        set newTab to make new tab with properties {URL:theURL}
        set current tab to newTab -- Make the new tab active
      end tell
    end if
    return "Opened " & theURL & " in Safari."
  on error errMsg
    return "error: Failed to open URL in Safari - " & errMsg
  end try
end openInSafariNewTab

return my openInSafariNewTab("--MCP_INPUT:targetURL")
```
END_TIP 