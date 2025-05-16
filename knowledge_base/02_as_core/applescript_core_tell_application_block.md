---
title: 'AppleScript Core: Basic ''tell application'' Block'
category: 02_as_core
id: applescript_core_tell_application_block
description: The fundamental structure for sending commands to a macOS application.
keywords:
  - tell
  - application
  - syntax
  - basic
  - core
language: applescript
---

To control an application or get information from it, you use a `tell application` block.

```applescript
tell application "Finder"
  -- Commands for the Finder go here
  set desktopItems to count of items on desktop
  activate -- Brings Finder to the front
  return "Finder has " & desktopItems & " items on the desktop."
end tell
```

**Note:** Replace `"Finder"` with the exact name of the application you want to script (e.g., `"Safari"`, `"Mail"`, `"System Events"`). The application must be scriptable.
END_TIP
