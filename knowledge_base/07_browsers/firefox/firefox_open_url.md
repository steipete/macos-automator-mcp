---
title: 'Firefox: Open URL'
category: 07_browsers
id: firefox_open_url
description: Opens Firefox and loads a specified URL.
keywords:
  - Firefox
  - URL
  - open
  - browser
  - navigate
language: applescript
notes: |
  - Firefox must be installed.
  - Will launch Firefox if it's not already running.
---

This script opens a URL in Firefox. It uses the OpenURL command, which is one of the few AppleScript commands supported by Firefox.

```applescript
tell application "Firefox"
  OpenURL "--MCP_INPUT:url"
end tell
```
END_TIP
