---
title: 'Terminal: Get Current Tab Content'
id: terminal_get_tab_content
category: 06_terminal
description: >-
  Retrieves the full text content (scrollback history) of the currently active
  tab in the frontmost Terminal.app window.
keywords:
  - Terminal.app
  - content
  - text
  - buffer
  - history
  - scrollback
  - read
  - get
language: applescript
isComplex: false
---

This script fetches all the text currently displayed in the active tab of the frontmost `Terminal.app` window, including its scrollback history.

**Usage:**
- Useful for capturing the state of a terminal session.
- Can be used to read the output of commands that have already been run.

**Important Notes:**
- `Terminal.app` must be running and have an active window.
- The script will target the selected tab of the frontmost window.

```applescript
on runWithInput(inputData, legacyArguments)
    tell application "Terminal"
        activate
        if not (exists window 1) then
            return "Error: Terminal.app has no windows open."
        end if
        
        try
            set frontWindow to window 1
            set currentTab to selected tab of frontWindow
            set tabContent to history of currentTab
            return tabContent
        on error errMsg
            return "Error retrieving tab content: " & errMsg
        end try
    end tell
end runWithInput
```
--- 
