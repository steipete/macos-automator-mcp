---
title: 'Photos: Get Selected Items'
category: 10_creative/photos_app
id: photos_get_selected_items
description: Retrieves information about currently selected photos in the Photos app.
keywords:
  - Photos
  - selected photos
  - photo information
  - image selection
language: applescript
notes: 'Returns a list of selected photos with their names, IDs, and creation dates.'
---

```applescript
tell application "Photos"
  activate
  try
    set selectedItems to selection
    
    if (count of selectedItems) is 0 then
      return "No photos selected. Please select one or more photos in the Photos app."
    end if
    
    set photoInfoList to {}
    
    repeat with i from 1 to count of selectedItems
      set thisItem to item i of selectedItems
      set photoName to filename of thisItem
      set photoID to id of thisItem
      set photoDate to date of thisItem
      
      set photoInfo to "Photo " & i & ":\\n" & ¬
                      "  Name: " & photoName & "\\n" & ¬
                      "  ID: " & photoID & "\\n" & ¬
                      "  Date: " & photoDate & "\\n"
      
      set end of photoInfoList to photoInfo
    end repeat
    
    set AppleScript's text item delimiters to "\\n"
    set outputString to "Selected Photos (" & (count of selectedItems) & "):\\n" & (photoInfoList as string)
    set AppleScript's text item delimiters to ""
    
    return outputString
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get selected photos - " & errMsg
  end try
end tell
```
END_TIP
