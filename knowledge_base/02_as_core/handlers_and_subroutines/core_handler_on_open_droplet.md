---
title: 'Core: Droplet Handler ''on open'''
category: 02_as_core/handlers_and_subroutines
id: core_handler_on_open_droplet
description: >-
  Defines a handler that executes when files or folders are dropped onto the
  saved script (applet). The input is a list of aliases to the dropped items.
keywords:
  - handler
  - droplet
  - on open
  - drag and drop
  - file processing
  - alias list
language: applescript
notes: >
  - Save the script as an Application to create a droplet.

  - `listOfDroppedItems` will be a list, even if only one item is dropped.

  - Each item in the list is an `alias`. Coerce to `POSIX path` for shell
  commands.
---

```applescript
-- This script, when saved as an application (droplet),
-- will display the POSIX paths of all items dropped onto it.

on open listOfDroppedItems
  set outputPaths to {}
  try
    repeat with anItem in listOfDroppedItems
      set end of outputPaths to POSIX path of anItem
    end repeat
    
    if outputPaths is {} then
      display dialog "No valid items were processed."
    else
      set AppleScript's text item delimiters to "\\n"
      set displayMessage to "Dropped item paths:\\n" & (outputPaths as string)
      set AppleScript's text item delimiters to ""
      display dialog displayMessage
    end if
    
  on error errMsg number errNum
    display dialog "Error processing dropped items (" & errNum & "):\\n" & errMsg
  end try
end open
```
END_TIP 
