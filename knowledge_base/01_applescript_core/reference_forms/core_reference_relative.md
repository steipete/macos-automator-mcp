---
title: "Core: Relative Reference Form"
category: "01_applescript_core" # Subdir: reference_forms
id: core_reference_relative
description: "Accessing objects based on their position relative to another known object (e.g., item before/after)."
keywords: ["reference form", "relative", "before", "after", "positional", "object specifier"]
language: applescript
notes: |
  - This form is useful when the exact index or name is not known, but the relationship to another element is.
  - Requires a container context (e.g., items in a folder, paragraphs in text).
  - If the anchor item is the first or last, requesting an item `before` the first or `after` the last will result in an error.
---

Objects can be referenced by their position relative to another object.

```applescript
-- List example
set myNumbers to {10, 20, 30, 40, 50}
set refItem to item 3 of myNumbers -- This is 30

set itemAfterRef to item after refItem    -- 40
set itemBeforeRef to item before refItem  -- 20

-- File example (using Finder)
-- For this to work predictably, create some uniquely named folders on your Desktop
-- e.g., FolderA, FolderB, FolderC in that order.
set finderResult to "(Finder example not run by default/setup required)"
(*
tell application "Finder"
  try
    set desktopPath to path to desktop
    -- Ensure FolderB exists on the desktop relative to other folders
    set folderB to folder "FolderB" of desktopPath 
    
    set folderAfterB to folder after folderB -- e.g., FolderC
    set folderBeforeB to folder before folderB -- e.g., FolderA
    
    set finderResult to "Folder after FolderB: " & (name of folderAfterB) & ¬
      ", Folder before FolderB: " & (name of folderBeforeB)
  on error errMsg
    set finderResult to "Finder error: " & errMsg & " (Ensure FolderA, FolderB, FolderC exist on Desktop)"
  end try
end tell
*)

-- Text example (paragraphs)
set myStory to "Paragraph one.\nParagraph two.\nParagraph three."
set paraTwo to paragraph 2 of myStory

set paraAfterTwo to paragraph after paraTwo    -- "Paragraph three."
set paraBeforeTwo to paragraph before paraTwo  -- "Paragraph one."

-- Error conditions
set errorMsg to "No error yet."
try
  set noItemBeforeFirst to item before item 1 of myNumbers
on error
  set errorMsg to "Error: Cannot get item before first item."
end try

return "Item after 30: " & itemAfterRef & ¬
  "\nItem before 30: " & itemBeforeRef & ¬
  "\nFinder result: " & finderResult & ¬
  "\nParagraph after P2: " & paraAfterTwo & ¬
  "\nError message: " & errorMsg
```
END_TIP 