---
id: kaleidoscope_compare_clipboard
title: Compare Clipboard with File in Kaleidoscope
description: Use AppleScript to compare clipboard contents with a file in Kaleidoscope
author: steipete
language: applescript
tags: 'kaleidoscope, diff, compare, clipboard'
keywords:
  - kaleidoscope
  - clipboard
  - compare
  - url scheme
  - diff tool
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Compare Clipboard with File in Kaleidoscope

This script uses Kaleidoscope's URL scheme to compare the contents of the clipboard with a file.

## Example Usage

```applescript
-- Compare clipboard with a specific file
open location "kaleidoscope://clipboard?/path/to/file.txt&label=Clipboard Comparison"
```

## Script Details

Kaleidoscope can compare the clipboard contents with a file using its URL scheme.

```applescript
-- Compare clipboard with a file using Kaleidoscope's URL scheme
on compareClipboardWithFile(filePath, comparisonLabel)
    set encodedPath to encodeURLComponent(filePath)
    set encodedLabel to encodeURLComponent(comparisonLabel)
    
    set kaleidoscopeURL to "kaleidoscope://clipboard?" & encodedPath
    
    if comparisonLabel is not equal to "" then
        set kaleidoscopeURL to kaleidoscopeURL & "&label=" & encodedLabel
    end if
    
    open location kaleidoscopeURL
end compareClipboardWithFile

-- URL encode a string to make it safe for URL parameters
on encodeURLComponent(input)
    set theChars to the characters of input
    set encodedString to ""
    
    repeat with c in theChars
        set theChar to c as string
        if theChar is " " then
            set encodedString to encodedString & "%20"
        else if theChar is "/" then
            set encodedString to encodedString & "/"
        else if theChar is ":" then
            set encodedString to encodedString & "%3A"
        else
            set encodedString to encodedString & theChar
        end if
    end repeat
    
    return encodedString
end encodeURLComponent

-- Example call
compareClipboardWithFile("--MCP_ARG_1", "--MCP_ARG_2")
```

## Notes

- Kaleidoscope must be installed on the system.
- This is useful for quickly comparing text you've copied with a saved file.
- The clipboard contents should be text for the comparison to work properly.
- Kaleidoscope will display the clipboard contents on one side and the file on the other.
- The label parameter is optional but recommended for better organization.
