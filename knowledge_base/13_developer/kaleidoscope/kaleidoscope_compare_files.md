---
id: kaleidoscope_compare_files
title: Compare Files with Kaleidoscope
description: Use AppleScript to open and compare files in Kaleidoscope
author: steipete
language: applescript
tags: kaleidoscope, diff, compare, files
keywords: ["kaleidoscope", "file comparison", "diff", "url scheme", "file diff"]
version: 1.0.0
updated: 2024-05-16
---

# Compare Files with Kaleidoscope

This script uses Kaleidoscope's URL scheme to open and compare two files.

## Example Usage

```applescript
-- Compare two specific files
open location "kaleidoscope://compare?/path/to/file1.txt&/path/to/file2.txt&label=My Comparison"

-- Compare files using the shell command ksdiff
do shell script "/usr/local/bin/ksdiff /path/to/file1.txt /path/to/file2.txt"
```

## Script Details

Kaleidoscope supports multiple ways to compare files. The URL scheme method is recommended for AppleScript integration.

```applescript
-- Compare two files using Kaleidoscope's URL scheme
on compareFilesWithKaleidoscope(file1Path, file2Path, comparisonLabel)
    set encodedFile1 to encodeURLComponent(file1Path)
    set encodedFile2 to encodeURLComponent(file2Path)
    set encodedLabel to encodeURLComponent(comparisonLabel)
    
    set kaleidoscopeURL to "kaleidoscope://compare?" & encodedFile1 & "&" & encodedFile2
    
    if comparisonLabel is not equal to "" then
        set kaleidoscopeURL to kaleidoscopeURL & "&label=" & encodedLabel
    end if
    
    open location kaleidoscopeURL
end compareFilesWithKaleidoscope

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
compareFilesWithKaleidoscope("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3")
```

## Notes

- Kaleidoscope must be installed on the system.
- For the command-line tool (`ksdiff`), make sure to provide the correct path.
- The URL scheme works with local files, but paths must be properly URL-encoded.
- When using with relative paths, make sure to convert them to absolute paths first.