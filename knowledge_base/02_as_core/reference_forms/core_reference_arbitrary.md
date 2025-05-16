---
title: 'Core: Arbitrary Element Reference Form (''some'')'
category: 02_as_core/reference_forms
id: core_reference_arbitrary
description: >-
  Accessing an arbitrary or random element from a collection using 'some
  element'.
keywords:
  - reference form
  - arbitrary
  - some
  - random element
  - any element
language: applescript
notes: >
  - `some element` (e.g., `some file`, `some item`) returns one unspecified
  element from the collection.

  - It's not guaranteed to be cryptographically random, but provides a way to
  pick an item without specifying which one.

  - If the collection is empty, attempting to get `some element` will result in
  an error.
---

The Arbitrary Element form (`some element`) selects an unspecified item from a collection.

```applescript
-- List example
set myOptions to {"Option A", "Option B", "Option C", "Option D"}
if (count of myOptions) > 0 then
  set randomOption to some item of myOptions
else
  set randomOption to "(List is empty)"
end if

-- String example (less common, but works for characters/words/paragraphs)
set mySentence to "Pick any word from this sentence."
if mySentence is not "" then
  set randomWord to some word of mySentence
else
  set randomWord to "(String is empty)"
end if

-- Finder example: Get some file from the Desktop
set randomFileOnDesktop to "(Finder example not run by default or Desktop empty)"
(*
tell application "Finder"
  try
    if (count of files of desktop) > 0 then
      set aFile to some file of desktop
      set randomFileOnDesktop to name of aFile
    else
      set randomFileOnDesktop to "No files on Desktop to pick from."
    end if
  on error errMsg
    set randomFileOnDesktop to "Finder error: " & errMsg
  end try
end tell
*)

-- Error handling for empty collection
set emptyList to {}
set emptyPickError to "No error yet."
try
  set failedPick to some item of emptyList
on error errMsg
  set emptyPickError to "Error picking from empty list: " & errMsg
end try

return "Random option: " & randomOption & ¬
  "\nRandom word: " & randomWord & ¬
  "\nRandom Desktop file: " & randomFileOnDesktop & ¬
  "\nError from empty list: " & emptyPickError
```
END_TIP 
