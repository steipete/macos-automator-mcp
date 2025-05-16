---
title: "Firefox: Refresh Current Page"
category: "05_web_browsers"
id: firefox_refresh_page
description: "Refreshes (reloads) the current page in Firefox."
keywords: ["Firefox", "refresh", "reload", "current page", "browser", "UI scripting"]
language: applescript
notes: |
  - Firefox must be running.
  - Uses keyboard shortcut to refresh the current page.
  - Requires accessibility permissions for UI scripting.
  - Provides options for normal refresh and force refresh (bypass cache).
---

This script refreshes the current page in Firefox. It uses System Events to send the standard keyboard shortcut, as Firefox has limited native AppleScript support.

```applescript
on run {input, parameters}
  -- Default to standard refresh
  set forceRefresh to false
  
  -- Check if input parameter requests force refresh
  if input is not {} then
    if input as string is "force" then
      set forceRefresh to true
    end if
  end if
  
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      if forceRefresh then
        -- Force refresh (Command+Shift+R)
        keystroke "r" using {command down, shift down}
      else
        -- Standard refresh (Command+R)
        keystroke "r" using {command down}
      end if
    end tell
  end tell
  
  if forceRefresh then
    return "Force refreshed the current Firefox page (bypassing cache)"
  else
    return "Refreshed the current Firefox page"
  end if
end run
```

### Script with Parameter for Force Refresh

This version includes a parameter that can be used to specify whether to perform a standard refresh or a force refresh (bypass cache).

```applescript
on run {input, parameters}
  -- Get the refresh type (normal/force)
  set refreshType to "--MCP_INPUT:refreshType"
  
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      if refreshType is "force" then
        -- Force refresh (Command+Shift+R)
        keystroke "r" using {command down, shift down}
        return "Force refreshed the current Firefox page (bypassing cache)"
      else
        -- Standard refresh (Command+R)
        keystroke "r" using {command down}
        return "Refreshed the current Firefox page"
      end if
    end tell
  end tell
end run
```

The script can be invoked with a parameter to determine whether to do a standard refresh (which may use cached content) or a force refresh (which bypasses the cache and reloads all elements). For a force refresh, pass "force" as the input parameter.
END_TIP