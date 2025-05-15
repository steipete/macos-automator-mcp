# System Sound Notification in AppleScript

AppleScript's `beep` command provides a simple way to create audible notifications. This document explains how to use this feature.

## Basic Beep

```applescript
-- Play one beep (default)
beep

return "Played one beep"
```

## Multiple Beeps

```applescript
-- Play three beeps
beep 3

return "Played 3 beeps"
```

## Beep with Error Handling

```applescript
try
  beep 3
  return "Played 3 beeps (if sound is on)"
on error errMsg
  return "Error beeping: " & errMsg
end try
```

## Notes

- The actual sound played depends on the System Settings > Sound > Sound Effects settings
- The system alert sound might be muted if the user has sound effects turned off
- The `beep` command doesn't return a value
- You can specify the number of beeps (integer parameter)
- Useful for providing simple audible feedback in scripts
- A complementary command is `display notification`, which shows visual notifications