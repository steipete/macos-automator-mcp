---
title: System Screen Lock
category: 04_system/screen_lock
id: system_screen_lock
description: >-
  Locks the screen on macOS using keyboard shortcut simulation or login window
  accessibility
keywords:
  - screen lock
  - security
  - login window
  - keyboard shortcut
  - System Events
language: applescript
notes: >-
  Works on macOS High Sierra (10.13) and newer. Requires accessibility
  permissions for System Events.
---

```applescript
tell application "System Events" to keystroke "q" using {control down, command down}
```

This script locks your Mac's screen immediately by simulating the standard keyboard shortcut Control+Command+Q that Apple introduced in macOS High Sierra.

For older macOS versions, you can use this alternative approach that accesses the Lock Screen option through menu navigation:

```applescript
tell application "System Events" to tell process "SystemUIServer"
  try
    tell (menu bar item 1 of menu bar 1 where description is "Keychain menu extra")
      click
      click menu item "Lock Screen" of menu 1
    end tell
  on error
    -- Fallback to user account menu (macOS Catalina and newer)
    tell (menu bar item 1 of menu bar 1 where description contains "User")
      click
      click menu item "Lock Screen" of menu 1
    end tell
  end try
end tell
```

This script locks the screen without suspending the machine or killing any network connections.
