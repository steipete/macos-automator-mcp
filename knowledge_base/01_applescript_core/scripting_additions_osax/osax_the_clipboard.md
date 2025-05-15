---
title: "StandardAdditions: the clipboard Command"
category: "01_applescript_core" # Subdir: scripting_additions_osax
id: osax_the_clipboard
description: "Gets or sets the contents of the system clipboard."
keywords: ["StandardAdditions", "clipboard", "the clipboard", "get clipboard", "set clipboard", "copy", "paste", "osax"]
language: applescript
notes: |
  - `set the clipboard to value` copies `value` to the clipboard.
  - `get the clipboard` or simply `the clipboard` retrieves the current clipboard content.
  - Can specify data type using `as {type}`: `get the clipboard as text`, `get the clipboard as picture`.
  - `clipboard info` provides information about the types of data currently on the clipboard.
---

`the clipboard` allows interaction with the system clipboard.

```applescript
-- Set the clipboard content
set myText to "Hello from AppleScript! " & (current date as string)
set the clipboard to myText

-- Get the clipboard content (as text by default if it's text)
set clipboardContent to the clipboard

-- Get clipboard content explicitly as text
set clipboardAsText to the clipboard as text

-- Get information about clipboard contents
-- Returns a list of records, e.g., {{«class utf8», 32}, {«class ut16», 66}, ...}
-- where «class utf8» is a type and 32 is its size in bytes.
set clipInfo to clipboard info
set firstDataType to "(Clipboard empty or info error)"
try
  if clipInfo is not {} then
    set firstDataTypeRecord to item 1 of item 1 of clipInfo -- The class type of the first data format
    set firstDataType to firstDataTypeRecord as string
  end if
on error
  set firstDataType to "Could not parse clipboard info."
end try

-- Example: Pasting into TextEdit (if it's open and frontmost)
(*
try
    tell application "TextEdit"
        activate
        tell application "System Events"
            keystroke "v" using command down -- Simulate Cmd-V (Paste)
        end tell
    end tell
    set pasteSimResult to "Pasted to TextEdit (simulated)."
on error
    set pasteSimResult to "Could not simulate paste in TextEdit."
end try
*)
set pasteSimResult to "(Paste simulation example commented out)"


return "Set clipboard to: '" & myText & "'" & ¬
  "\nRetrieved from clipboard: '" & clipboardContent & "'" & ¬
  "\nClipboard Info (first data type): " & firstDataType & ¬
  "\n" & pasteSimResult
```
END_TIP 