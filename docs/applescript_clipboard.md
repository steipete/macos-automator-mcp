# Clipboard Operations in AppleScript

The clipboard is a fundamental system utility that AppleScript can interact with. This document explains how to access and manipulate clipboard content.

## Getting Clipboard Content

```applescript
-- Get the clipboard content (as text by default if it's text)
set clipboardContent to the clipboard

-- Get clipboard content explicitly as text
set clipboardAsText to the clipboard as text

-- Display the content
return "Current clipboard content: " & clipboardContent
```

## Setting Clipboard Content

```applescript
-- Set the clipboard content
set myText to "Hello from AppleScript! " & (current date as string)
set the clipboard to myText

return "Clipboard set to: " & myText
```

## Getting Clipboard Type Information

```applescript
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

return "Clipboard Info (first data type): " & firstDataType
```

## Complete Example

This script demonstrates getting and setting clipboard content with error handling:

```applescript
-- Store original clipboard to restore later
try
  set originalClip to the clipboard
on error
  set originalClip to ""
end try

-- Set new content
set the clipboard to "Test clipboard content"

-- Get the content back
set retrievedContent to the clipboard

-- Restore original content if we had any
try
  if originalClip is not "" then
    set the clipboard to originalClip
  end if
end try

return "Retrieved from clipboard: " & retrievedContent
```

## Notes

- The clipboard operation happens immediately with no need for delays in most cases
- The `clipboard info` command can be useful for debugging or handling different data types
- Clipboard operations are useful for transferring data between applications
- Consider saving and restoring the clipboard content in scripts that modify it, to avoid disrupting the user's workflow