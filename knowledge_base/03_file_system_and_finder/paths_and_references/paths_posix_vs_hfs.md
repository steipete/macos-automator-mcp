---
title: "Paths: Understanding POSIX and HFS+ Paths"
category: "03_file_system_and_finder" # Subdir: paths_and_references
id: paths_posix_vs_hfs
description: "Explains the difference between POSIX (slash-separated) and HFS+ (colon-separated) paths in AppleScript and how to convert between them."
keywords: ["path", "POSIX", "HFS", "colon", "slash", "file system", "conversion"]
language: applescript
---

macOS uses POSIX paths (e.g., `/Users/yourname/Documents/file.txt`) at the Unix level.
AppleScript traditionally uses HFS+ paths (e.g., `Macintosh HD:Users:yourname:Documents:file.txt`). It's crucial to convert them correctly.

**Conversion:**
- POSIX to AppleScript `file` object: `POSIX file "/path/to/file"`
- AppleScript `file`/`alias` or HFS path string to POSIX path string: `POSIX path of anAppleScriptPathOrFileObject`

```applescript
-- Example: POSIX to AppleScript file object then back to POSIX path
set myPOSIXPath to "/Applications/Calculator.app"
set myASFileObject to POSIX file myPOSIXPath

-- myASFileObject is now something like: file "Macintosh HD:Applications:Calculator.app"
-- or alias "Macintosh HD:Applications:Calculator.app" depending on context

set retrievedPOSIXPath to POSIX path of myASFileObject
-- retrievedPOSIXPath is now "/Applications/Calculator.app"

-- Example: HFS path string to POSIX path
set userName to do shell script "whoami"
set myHFSPathString to "Macintosh HD:Users:" & userName & ":Desktop:"
set desktopPOSIXPath to POSIX path of myHFSPathString

return "AS File Object: " & (myASFileObject as text) & "\\nRetrieved POSIX: " & retrievedPOSIXPath & "\\nDesktop POSIX: " & desktopPOSIXPath
```

**Note:** When providing paths to `do shell script`, always use POSIX paths and ensure they are properly quoted using `quoted form of`.
END_TIP 