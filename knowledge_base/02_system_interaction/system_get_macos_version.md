---
title: "System Interaction: Get macOS Version"
category: "02_system_interaction"
id: system_get_macos_version
description: "Retrieves the current macOS version string."
keywords: ["system", "macos", "version", "os version", "system events", "sw_vers"]
language: applescript
notes: |
  - Method 1 uses System Events and is pure AppleScript.
  - Method 2 uses `do shell script` with the `sw_vers` command, which can provide more detailed build info.
---

**Method 1: Using System Events**

```applescript
tell application "System Events"
  set osVersion to system version of (get system info)
end tell
return "macOS Version (System Events): " & osVersion
```

**Method 2: Using `do shell script` (sw_vers)**

```applescript
set productVersion to do shell script "sw_vers -productVersion"
set buildVersion to do shell script "sw_vers -buildVersion"
return "macOS Product Version (sw_vers): " & productVersion & "\\nBuild Version: " & buildVersion
```
END_TIP