---
id: kaleidoscope_view_git_history
title: View Git File History in Kaleidoscope
description: Use AppleScript to open Git file history in Kaleidoscope
author: steipete
language: applescript
tags: kaleidoscope, git, history, version control
keywords: ["file history", "revision tracking", "timeline view", "git file evolution", "version comparison"]
version: 1.0.0
updated: 2024-05-16
---

# View Git File History in Kaleidoscope

This script uses Kaleidoscope's URL scheme to open the history of a Git-tracked file.

## Example Usage

```applescript
-- View Git history for a specific file
open location "kaleidoscope://history?/path/to/repository/file.txt"
```

## Script Details

Kaleidoscope can display the Git history for a file using its URL scheme.

```applescript
-- View Git history for a file using Kaleidoscope's URL scheme
on viewGitHistory(filePath)
    set encodedPath to encodeURLComponent(filePath)
    set kaleidoscopeURL to "kaleidoscope://history?" & encodedPath
    open location kaleidoscopeURL
end viewGitHistory

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
viewGitHistory("--MCP_ARG_1")
```

## Notes

- Kaleidoscope must be installed on the system.
- The file must be tracked in a Git repository.
- The repository must be in Kaleidoscope's Repositories list.
- This command opens Kaleidoscope showing all revisions of the file in timeline view.
- You can navigate through different versions of the file and compare changes between commits.