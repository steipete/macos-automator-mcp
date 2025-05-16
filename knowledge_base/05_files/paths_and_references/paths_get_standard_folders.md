---
title: 'Paths: Get Path to Standard Folders'
category: 05_files
id: paths_get_standard_folders
description: >-
  Uses AppleScript's 'path to' command to reliably get paths to standard macOS
  folders like Desktop, Documents, Application Support, etc., for different
  domains.
keywords:
  - path to
  - standard folders
  - desktop
  - documents
  - application support
  - home folder
  - user domain
language: applescript
notes: >
  - Valid domains: `user domain`, `local domain`, `system domain`, `network
  domain`.

  - Returns an `alias` object, which can be coerced to a POSIX path string.

  - For a list of folder keywords, open Script Editor, then File > Open
  Dictionary... > StandardAdditions.osax > `path to` command.
---

The `path to` command is the most reliable way to get locations of standard folders.

```applescript
-- Get POSIX path to the current user's Desktop folder
set desktopPathAlias to path to desktop folder from user domain
set desktopPOSIX to POSIX path of desktopPathAlias

-- Get POSIX path to the system-wide Application Support folder
set appSupportLocalPathAlias to path to application support from local domain
set appSupportLocalPOSIX to POSIX path of appSupportLocalPathAlias

-- Get path to the frontmost application's bundle (if it's a standard app)
try
  set frontAppPathAlias to path to frontmost application
  set frontAppPOSIX to POSIX path of frontAppPathAlias
on error
  set frontAppPOSIX to "N/A (frontmost app might not have a standard path)"
end try

return "User Desktop: " & desktopPOSIX & "\\nLocal App Support: " & appSupportLocalPOSIX & "\\nFront App: " & frontAppPOSIX
```
END_TIP 
