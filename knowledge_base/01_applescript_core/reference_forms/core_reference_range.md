---
title: "Core: Range Reference Form"
category: "01_applescript_core" # Subdir: reference_forms
id: core_reference_range
description: "Accessing a contiguous series of elements by specifying a start and end index."
keywords: ["reference form", "range", "items X thru Y", "characters A to B", "slice", "sublist", "substring"]
language: applescript
notes: |
  - Specifies a sequence of elements from a start index to an end index, inclusive.
  - Can use `items X through Y`, `items X thru Y`, `items from X to Y`, or `characters X to Y`.
  - If the end index is before the start index, an empty list or string may result, or an error depending on context.
---

The Range reference form selects a sequence of elements.

```applescript
-- List example
set myColors to {"red", "green", "blue", "yellow", "purple", "orange"}

set someColors1 to items 2 thru 4 of myColors  -- {"green", "blue", "yellow"}
set someColors2 to items 2 through 4 of myColors -- Same as above
set someColors3 to items from 3 to 5 of myColors -- {"blue", "yellow", "purple"}
set firstThree to items 1 to 3 of myColors      -- {"red", "green", "blue"}
set lastTwo to items -2 thru -1 of myColors    -- {"purple", "orange"}

-- String example
set myMessage to "Hello AppleScript World"

set subString1 to characters 1 thru 5 of myMessage    -- "Hello"
set subString2 to characters 7 to 17 of myMessage   -- "AppleScript"
set subString3 to text 7 thru 17 of myMessage       -- "AppleScript" (using 'text' synonym for characters)
set subString4 to characters -5 thru -1 of myMessage -- "World"

-- Application elements (e.g., Finder files)
-- Note: This can be slow with large numbers of items.
set finderRange to "(Finder example not run by default, requires multiple files on Desktop)"
(*
tell application "Finder"
  try
    set desktopFiles to files of desktop
    if (count desktopFiles) > 3 then
      set firstFewFiles to name of items 1 thru 3 of desktopFiles
      set finderRange to "First 3 files: " & (firstFewFiles as string)
    else
      set finderRange to "Not enough files on desktop for range example."
    end if
  on error errMsg
    set finderRange to "Finder error: " & errMsg
  end try
end tell
*)

-- Invalid or empty range
set emptyRangeList to items 3 thru 1 of myColors -- Usually results in error or empty list depending on context/version
-- AppleScript behavior can be inconsistent with reverse ranges; often errors.

return "Colors 2-4: " & (someColors1 as string) & ¬
  "\nString 1-5: " & subString1 & ¬
  "\nString 7-17: " & subString2 & ¬
  "\nFinder range: " & finderRange & ¬
  "\nEmpty/Invalid range attempt (see notes): " & (emptyRangeList as string)
```
END_TIP 