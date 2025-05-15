---
title: "Finder: Get POSIX Path of Selected Items"
category: "03_file_system_and_finder" # Subdir: file_operations_finder
id: finder_get_selected_items_paths
description: "Retrieves the POSIX paths of all currently selected files and folders in the frontmost Finder window."
keywords: ["Finder", "selection", "selected files", "path", "POSIX"]
language: applescript
notes: |
  - Finder must be the frontmost application with a window open and items selected.
  - Returns a list of POSIX paths, one per line.
---

```applescript
tell application "Finder"
  if not running then return "error: Finder is not running."
  activate -- Ensure Finder is frontmost to get its selection
  delay 0.2
  try
    set selectedItems to selection
    if selectedItems is {} then
      return "No items selected in Finder."
    end if
    
    set itemPathsList to {}
    repeat with anItem in selectedItems
      set end of itemPathsList to POSIX path of (anItem as alias)
    end repeat
    
    set AppleScript's text item delimiters to "\\n"
    set pathsString to itemPathsList as string
    set AppleScript's text item delimiters to "" -- Reset
    return pathsString
    
  on error errMsg
    return "error: Failed to get selected Finder items - " & errMsg
  end try
end tell
```
END_TIP 