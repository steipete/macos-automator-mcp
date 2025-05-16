---
title: 'Core: List Data Type'
category: 02_as_core
id: core_datatype_list
description: >-
  Working with lists (arrays) in AppleScript. Lists are 1-indexed and can
  contain mixed data types.
keywords:
  - list
  - array
  - data type
  - item
  - index
  - count
  - concatenation
  - repeat
language: applescript
---

Lists are ordered collections of items.

```applescript
set myList to {"apple", 123, true, {nestedList: "yes"}}

-- Get count (length)
set listCount to count of myList -- or length of myList

-- Access items (1-indexed)
set firstItem to item 1 of myList
set lastItem to item -1 of myList
set nestedValue to nestedList of item 4 of myList

-- Add items
set myList to myList & "new item" -- Concatenates, creating a new list
set end of myList to "another new item" -- Modifies list in place

-- Check if item exists
set hasApple to "apple" is in myList

-- Iterate
set output to ""
repeat with anItem in myList
  set output to output & (anItem as string) & ", "
end repeat

return "Count: " & listCount & "\\nFirst: " & firstItem & "\\nLast: " & lastItem & "\\nNested: " & nestedValue & "\\nHas Apple: " & hasApple & "\\nIterated: " & output
```
END_TIP 
