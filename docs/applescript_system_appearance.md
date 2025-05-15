# AppleScript: System Appearance Controls

This document demonstrates how to toggle between Light and Dark Mode on macOS using AppleScript. You can automate system appearance changes either directly through preferences or via UI scripting.

## Toggling Dark Mode (Direct Method)

```applescript
-- The simple, direct method to toggle Dark Mode
tell application "System Events"
  tell appearance preferences
    set dark mode to not dark mode
    return "Dark Mode toggled. Current state: " & dark mode
  end tell
end tell
```

## Getting Current Dark Mode State

```applescript
tell application "System Events"
  tell appearance preferences
    set currentDarkMode to dark mode
    if currentDarkMode then
      return "System is currently in Dark Mode"
    else
      return "System is currently in Light Mode"
    end if
  end tell
end tell
```

## Setting Specific Mode

```applescript
on setDarkMode(enableDarkMode)
  tell application "System Events"
    tell appearance preferences
      set dark mode to enableDarkMode
      return "Dark Mode set to: " & dark mode
    end tell
  end tell
end setDarkMode

-- Usage:
-- Set to Dark Mode
setDarkMode(true)
-- Set to Light Mode
setDarkMode(false)
```

## Scheduled Mode Changes

```applescript
-- Example: Set Dark Mode at night, Light Mode during the day
set currentHour to hours of (current date)

if currentHour ≥ 18 or currentHour < 7 then
  -- Evening and night hours (6pm to 7am)
  tell application "System Events"
    tell appearance preferences
      if not dark mode then
        set dark mode to true
        return "Switched to Dark Mode for evening hours"
      else
        return "Already in Dark Mode"
      end if
    end tell
  end tell
else
  -- Daytime hours (7am to 6pm)
  tell application "System Events"
    tell appearance preferences
      if dark mode then
        set dark mode to false
        return "Switched to Light Mode for daytime hours"
      else
        return "Already in Light Mode"
      end if
    end tell
  end tell
end if
```

## Checking Compatibility

```applescript
-- Check if the current macOS supports direct Dark Mode toggling
on canToggleDarkMode()
  try
    tell application "System Events"
      tell appearance preferences
        return true
      end tell
    end tell
  on error
    return false
  end try
end canToggleDarkMode
```

## Common Use Cases

- Automating dark/light mode based on time of day
- Creating keyboard shortcuts for quick toggling
- Switching modes based on specific applications being launched
- Synchronizing appearance with external conditions (e.g., ambient light sensors)
- Setting specific modes for different types of work (e.g., coding vs. design)

## Notes and Limitations

- Direct method requires macOS Mojave (10.14) or later
- Some applications may not respond to appearance changes until restarted
- Accessibility permissions may be required for these scripts to work
- UI scripting approach (manipulating System Settings/Preferences) is fragile and should be avoided when possible
- Always prefer the direct "appearance preferences" method as shown in the first example