---
title: "Choose File Dialog"
description: "Displays a file selection dialog to allow the user to select a file"
keywords:
  - file
  - dialog
  - choose file
  - user selection
  - OSAX
  - scripting addition
language: applescript
---

This script demonstrates the `choose file` scripting addition, which shows a standard file selection dialog.

```applescript
-- Basic file selection
set selectedFile to choose file with prompt "Please select a file"
return "You selected: " & (POSIX path of selectedFile)

-- More options
set selectedFile to choose file with prompt "Please select a file" ¬
    of type {"txt", "md", "rtf"} ¬
    default location (path to desktop folder) ¬
    with invisibles ¬
    with multiple selections allowed

-- Handle the result (may be a list if multiple selections allowed)
if class of selectedFile is list then
    set fileList to {}
    repeat with oneFile in selectedFile
        set end of fileList to POSIX path of oneFile
    end repeat
    return "You selected multiple files: " & fileList
else
    return "You selected: " & (POSIX path of selectedFile)
end if
```

The `choose file` command supports several parameters:
- `with prompt`: Customizes the dialog message
- `of type`: Filters for specific file types
- `default location`: Sets the initial directory
- `with invisibles`: Shows hidden files
- `with multiple selections allowed`: Allows selecting multiple files