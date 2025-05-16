---
title: 'Safari: Open URL'
category: 07_browsers/safari
id: safari_open_url
description: >-
  Opens a specified URL in Safari (in the current window or a new window if
  Safari is not already running).
keywords:
  - Safari
  - URL
  - open
  - browser
  - web
  - navigate
language: applescript
isComplex: false
argumentsPrompt: URL to open as 'url' in inputData.
notes: >
  - The script will launch Safari if it's not already running.

  - If Safari is already running, the URL will open in the current window.

  - The URL should be properly formatted (including the http:// or https://
  prefix).
---

This script opens a specified URL in Safari.

```applescript
--MCP_INPUT:url

on openUrlInSafari(theUrl)
  if theUrl is missing value or theUrl is "" then
    return "error: URL not provided."
  end if
  
  -- Check if URL has a proper prefix
  if theUrl does not start with "http://" and theUrl does not start with "https://" then
    set theUrl to "https://" & theUrl
  end if
  
  tell application "Safari"
    activate
    try
      open location theUrl
      return "Successfully opened URL in Safari: " & theUrl
    on error errMsg
      return "error: Failed to open URL - " & errMsg
    end try
  end tell
end openUrlInSafari

return my openUrlInSafari("--MCP_INPUT:url")
```
