---
title: "StandardAdditions: path to Command"
category: "01_applescript_core"
id: osax_path_to
description: "Returns an alias to a special system or user folder (e.g., desktop, documents, applications folder, etc.)."
keywords: ["StandardAdditions", "path to", "folder path", "alias", "system folder", "user folder"]
language: applescript
notes: |
  - For a full list of folder keywords, open Script Editor > File > Open Dictionary... > StandardAdditions.osax, and find the 'path to' command.
  - Can specify `from user domain`, `from local domain`, `from system domain`, or `from network domain`.
  - `as string` or `POSIX path of` can convert the returned alias to a string path.
---

The `path to` command provides a reliable way to get locations of standard macOS folders.

```applescript
-- Path to current user's Desktop
set userDesktopAlias to path to desktop folder from user domain
set userDesktopPOSIX to POSIX path of userDesktopAlias

-- Path to the main Applications folder
set localApplicationsAlias to path to applications folder from local domain
set localApplicationsPOSIX to POSIX path of localApplicationsAlias

-- Path to temporary items folder (good for temp files)
set tempFolderAlias to path to temporary items from user domain
set tempFolderPOSIX to POSIX path of tempFolderAlias

return "User Desktop: " & userDesktopPOSIX & "\\nLocal Applications: " & localApplicationsPOSIX & "\\nTemp Folder: " & tempFolderPOSIX
```
END_TIP 