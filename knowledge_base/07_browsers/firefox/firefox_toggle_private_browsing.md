---
title: 'Firefox: Toggle Private Browsing'
category: 07_browsers/firefox
id: firefox_toggle_private_browsing
description: >-
  Opens a new Firefox window in private browsing mode or closes the existing
  private browsing window.
keywords:
  - Firefox
  - private browsing
  - incognito
  - privacy
  - browser
  - UI scripting
language: applescript
notes: |
  - Firefox must be installed.
  - Uses UI scripting to navigate Firefox's menu items.
  - Requires accessibility permissions.
  - This script simulates menu selection in Firefox to toggle private browsing.
---

This script toggles Firefox's private browsing mode by simulating menu selections. It opens a new private browsing window if none exists, or activates an existing one.

```applescript
on run
  -- Check if Firefox is running
  tell application "System Events"
    set firefoxRunning to (exists process "Firefox")
  end tell
  
  if not firefoxRunning then
    tell application "Firefox"
      activate
      delay 1 -- Allow Firefox to launch
    end tell
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Ensure Firefox is active
  end tell
  
  -- Use menu selection to open a new private window
  tell application "System Events"
    tell process "Firefox"
      set frontmost to true
      
      -- Open File menu
      tell menu bar 1
        tell menu bar item "File"
          click
          delay 0.3
          
          -- Click "New Private Window"
          tell menu 1
            set privateWindowMenuItem to menu item "New Private Window"
            if exists privateWindowMenuItem then
              click privateWindowMenuItem
              return "Opened a new Firefox private browsing window"
            end if
          end tell
        end tell
      end tell
    end tell
  end tell
end run
```

### Alternative Implementation with Shortcut Key

This version uses Firefox's keyboard shortcut for opening a private browsing window (Shift+Command+P on macOS):

```applescript
on run
  tell application "Firefox"
    activate
    delay 0.5 -- Ensure Firefox is active
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Use keyboard shortcut for private browsing (Shift+Command+P)
      keystroke "p" using {shift down, command down}
    end tell
  end tell
  
  return "Toggled Firefox private browsing window"
end run
```

### Implementation with Private Browsing Window Detection

This more advanced version attempts to detect if a private browsing window is already open by checking window titles, and closes it if found:

```applescript
on run
  -- Check if Firefox is running
  tell application "System Events"
    set firefoxRunning to (exists process "Firefox")
  end tell
  
  if not firefoxRunning then
    tell application "Firefox"
      activate
      delay 1 -- Allow Firefox to launch
    end tell
  else
    tell application "Firefox"
      activate
      delay 0.5 -- Ensure Firefox is active
    end tell
  end if
  
  -- Try to detect if a private browsing window exists
  set privateWindowExists to false
  tell application "System Events"
    tell process "Firefox"
      -- Check for windows that contain "Private Browsing" in their title
      repeat with theWindow in windows
        if name of theWindow contains "Private Browsing" then
          set privateWindowExists to true
          exit repeat
        end if
      end repeat
    end tell
  end tell
  
  if privateWindowExists then
    -- If private window exists, try to close it
    tell application "System Events"
      tell process "Firefox"
        -- Find and focus a private browsing window
        repeat with theWindow in windows
          if name of theWindow contains "Private Browsing" then
            set focused of theWindow to true
            keystroke "w" using {command down, shift down} -- Close window
            exit repeat
          end if
        end repeat
      end tell
    end tell
    return "Closed Firefox private browsing window"
  else
    -- If no private window exists, open a new one
    tell application "System Events"
      tell process "Firefox"
        keystroke "p" using {shift down, command down} -- Open private window
      end tell
    end tell
    return "Opened a new Firefox private browsing window"
  end if
end run
```

Note: The title detection method may not be reliable across all Firefox versions, as the exact window title for private browsing can change between versions and localizations.
END_TIP
