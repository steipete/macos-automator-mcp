---
title: "Paths: Create Alias Object from HFS Path String"
category: "03_file_system_and_finder" # Subdir: paths_and_references
id: paths_create_alias_from_hfs
description: "Demonstrates how to create an AppleScript 'alias' object from a colon-separated HFS+ path string."
keywords: ["alias", "HFS path", "file reference", "object"]
language: applescript
notes: |
  - The path must exist for an alias to be created successfully, otherwise it will error.
  - An `alias` object maintains its link to the file/folder even if the item is moved (within the same volume).
  - A `file` object created from a path string is just a path specifier and doesn't track moves.
---

```applescript
-- Assuming "Macintosh HD" is your startup disk name. Adjust if different.
set myHFSPath to "Macintosh HD:Applications:TextEdit.app"

try
  set myAppAlias to alias myHFSPath
  return "Successfully created alias: " & (myAppAlias as text) & "\\nPODIX Path: " & (POSIX path of myAppAlias)
on error errMsg
  return "Error creating alias for '" & myHFSPath & "': " & errMsg
end try
```
END_TIP 