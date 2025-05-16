---
title: "Firefox: Get URL of Front Tab"
category: "05_web_browsers"
id: firefox_get_front_tab_url
description: "Retrieves the URL of the active tab in the frontmost Firefox window using UI scripting."
keywords: ["Firefox", "URL", "current tab", "web address", "browser", "clipboard"]
language: applescript
notes: |
  - Firefox must be running.
  - This script uses UI scripting via System Events.
  - Temporarily modifies the clipboard content.
  - You may need to enable accessibility permissions for the script to work.
  - For Firefox 87+, enabling VoiceOver support in Firefox can provide more reliable results (see alternate method in script).
---

This script retrieves the URL of the front tab in Firefox using UI scripting to simulate keyboard shortcuts. It works by activating Firefox, using keyboard shortcuts to select and copy the URL, and then retrieving it from the clipboard.

```applescript
use scripting additions

-- Save the current clipboard content
set oldClipboard to the clipboard

tell application "Firefox"
  activate
  -- Allow Firefox to come to the foreground
  delay 0.5
end tell

-- Use keyboard shortcuts to select and copy the URL
tell application "System Events"
  tell process "Firefox"
    keystroke "l" using {command down}
    delay 0.2
    keystroke "c" using {command down}
    delay 0.2
  end tell
end tell

-- Get the URL from the clipboard
set theURL to the clipboard

-- Restore the original clipboard content
set the clipboard to oldClipboard

return theURL
```

### Alternate Method for Firefox 87+

For newer Firefox versions with VoiceOver support enabled, you can use this more reliable method. To enable VoiceOver support in Firefox, go to about:config and set accessibility.force_disabled to -1.

```applescript
tell application "Firefox"
  activate
end tell

tell application "System Events"
  tell process "Firefox"
    set frontmost to true
    -- Get value from the URL bar
    return value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window
  end tell
end tell
```
END_TIP