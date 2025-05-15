---
title: "Core: Alias Data Type"
category: "01_applescript_core"
id: core_datatype_alias
description: "Working with aliases in AppleScript, which are dynamic references to file system objects."
keywords: ["alias", "file", "folder", "reference", "path", "HFS path", "data type"]
language: applescript
notes: |
  - An alias tracks a file or folder even if it's moved or renamed (within the same volume).
  - Typically represented as an HFS path string (e.g., "Macintosh HD:Users:username:Desktop:File.txt").
  - Use `POSIX path of` to convert to a more portable POSIX path string.
  - Creating an alias to a non-existent item will result in an error.
---

Aliases provide robust references to files and folders.

```applescript
-- Declaration (using HFS path string)
-- Note: Replace with a valid path on your system for testing
-- set myFileAlias to alias "Macintosh HD:Users:yourusername:Desktop:MyTestFile.txt"
-- For this example, we'll use a common existing folder
set desktopAlias to path to desktop folder

-- Properties
set aliasName to name of desktopAlias -- e.g., "Desktop"
set aliasKind to kind of desktopAlias -- e.g., "Folder"

-- Coercions
set hfsPathString to desktopAlias as string -- "Macintosh HD:Users:yourusername:Desktop:"
set posixPathString to POSIX path of desktopAlias -- "/Users/yourusername/Desktop/"

-- Using an alias with Finder (example)
set itemList to ""
try
  tell application "Finder"
    set itemList to name of every item of desktopAlias
  end tell
on error
  set itemList to "(Could not get Finder items, ensure Finder is running)"
end try

-- Checking if an alias exists (it must, to be an alias, but to check a path string first)
set pathToCheck to "Macintosh HD:Applications:TextEdit.app"
try
  set appAlias to alias pathToCheck
  set appExists to true
on error
  set appExists to false
end try

return "Alias Name: " & aliasName & "\nKind: " & aliasKind & "\nHFS Path: " & hfsPathString & "\nPOSIX Path: " & posixPathString & "\nApp Exists: " & appExists & "\nDesktop Items (first few): " & (items 1 thru (min(5, count of itemList)) of itemList as string)
```
END_TIP 