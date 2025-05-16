---
title: 'Core: Index Reference Form'
category: 02_as_core/reference_forms
id: core_reference_index
description: >-
  Accessing elements within containers (lists, strings, application elements) by
  their numerical index.
keywords:
  - reference form
  - index
  - item
  - character
  - word
  - paragraph
  - list access
  - string element
  - 1-indexed
  - negative index
language: applescript
notes: |
  - AppleScript indices are 1-based (the first item is `item 1`).
  - Negative indices count from the end (`item -1` is the last item).
  - Attempting to access an out-of-bounds index will result in an error.
---

The Index reference form allows you to specify elements by their position.

```applescript
-- List examples
set myFruits to {"apple", "banana", "cherry", "date"}
set firstFruit to item 1 of myFruits          -- "apple"
set thirdFruit to item 3 of myFruits          -- "cherry"
set lastFruit to item -1 of myFruits         -- "date"
set secondToLast to item -2 of myFruits    -- "cherry"
-- set specificFruit to third item of myFruits -- same as item 3

-- String examples (characters, words, paragraphs)
set myText to "AppleScript is fun.\nSo very fun!"

set char1 to character 1 of myText          -- "A"
set char5 to character 5 of myText          -- "S"
set lastChar to character -1 of myText      -- "!"

set word1 to word 1 of myText             -- "AppleScript"
set word3 to word 3 of myText             -- "fun"
-- Note: Punctuation can affect word boundaries.

set para1 to paragraph 1 of myText          -- "AppleScript is fun."
set para2 to paragraph 2 of myText          -- "So very fun!"

-- Application examples (illustrative - requires app context)
(*
tell application "Finder"
  try
    set desktopFolder to path to desktop
    set firstItemOnDesktop to item 1 of desktopFolder
    set itemName to name of firstItemOnDesktop
  on error
    set itemName to "(Error accessing Finder item or desktop empty)"
  end try
end tell
*)

-- Error handling for out-of-bounds
set anError to "No error yet."
try
  set nonExistent to item 10 of myFruits
on error errMsg
  set anError to "Error accessing item 10: " & errMsg
end try

return "First fruit: " & firstFruit & ¬
  "\nLast fruit: " & lastFruit & ¬
  "\nCharacter 5: " & char5 & ¬
  "\nWord 1: " & word1 & ¬
  "\nParagraph 1: " & para1 & ¬
  -- "\nFinder item name: " & itemName & ¬
  "\nOut of bounds error: " & anError
```
END_TIP 
