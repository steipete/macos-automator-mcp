---
title: "Core: Filter Reference Form ('whose' / 'where')"
category: "01_applescript_core" # Subdir: reference_forms
id: core_reference_filter_whose
description: "Selects items from a container based on a boolean condition applied to their properties."
keywords: ["reference form", "filter", "whose", "where", "conditional selection", "query"]
language: applescript
notes: "This is a very powerful way to get specific collections of items."
---

```applescript
-- Example 1: Get all .txt files on the Desktop
tell application "Finder"
  try
    set textFilesOnDesktop to every file of desktop whose name extension is "txt"
    set fileNames to {}
    repeat with aFile in textFilesOnDesktop
      set end of fileNames to name of aFile
    end repeat
    if fileNames is {} then return "No .txt files found on Desktop."
    return fileNames
  on error errMsg
    return "error: " & errMsg
  end try
end tell

-- Example 2: Get all visible application processes
(*
tell application "System Events"
  set visibleApps to every application process where visible is true
  set appNames to {}
  repeat with anApp in visibleApps
    set end of appNames to name of anApp
  end repeat
  return appNames
end tell
*)
```
END_TIP 