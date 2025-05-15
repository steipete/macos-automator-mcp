# Get macOS Version with AppleScript

There are two effective ways to get the current macOS version using AppleScript. This document explains both methods.

## Method 1: Using System Events

This is a pure AppleScript approach that uses System Events to retrieve system information:

```applescript
tell application "System Events"
  set osVersion to system version of (get system info)
end tell
return "macOS Version: " & osVersion
```

## Method 2: Using Shell Commands

This approach uses the `sw_vers` command-line tool via `do shell script` to get more detailed version information:

```applescript
set productVersion to do shell script "sw_vers -productVersion"
set buildVersion to do shell script "sw_vers -buildVersion"
return "macOS Product Version: " & productVersion & return & "Build Version: " & buildVersion
```

## Combined Approach

For the most comprehensive version information:

```applescript
-- Get version using System Events
tell application "System Events"
  set osVersion to system version of (get system info)
end tell

-- Get more detailed version info via shell commands
set productVersion to do shell script "sw_vers -productVersion"
set buildVersion to do shell script "sw_vers -buildVersion"
set productName to do shell script "sw_vers -productName"

-- Format the output
set versionInfo to "Product Name: " & productName & return
set versionInfo to versionInfo & "Product Version: " & productVersion & return
set versionInfo to versionInfo & "Build Version: " & buildVersion & return
set versionInfo to versionInfo & "System Events Version: " & osVersion

return versionInfo
```

## Notes

- The System Events method (`system version`) returns a simplified version string (e.g., "13.4.1")
- The `sw_vers` command provides more detailed information, including build number
- `sw_vers` also allows you to get just specific components with flags:
  - `-productName`: Gets macOS product name (e.g., "macOS")
  - `-productVersion`: Gets version number (e.g., "13.4.1")
  - `-buildVersion`: Gets build number (e.g., "22F82")
- This script requires no special permissions to run
- Version information is useful for scripts that need to behave differently based on the macOS version