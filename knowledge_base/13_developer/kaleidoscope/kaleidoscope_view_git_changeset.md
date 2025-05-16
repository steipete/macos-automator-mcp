---
id: kaleidoscope_view_git_changeset
title: View Git Changeset in Kaleidoscope
description: Use AppleScript to open Git commit changesets in Kaleidoscope
author: steipete
language: applescript
tags: 'kaleidoscope, git, diff, commit, changeset'
keywords:
  - code review
  - commit visualization
  - git integration
  - change comparison
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer/kaleidoscope
---

# View Git Changeset in Kaleidoscope

This script uses Kaleidoscope's URL scheme to open and view a Git commit changeset.

## Example Usage

```applescript
-- View Git changeset for a specific commit
open location "kaleidoscope://changeset?commitId=a1b2c3d4&repo=/path/to/repository"
```

## Script Details

Kaleidoscope can display the changes made in a specific Git commit.

```applescript
-- View Git changeset for a commit using Kaleidoscope's URL scheme
on viewGitChangeset(commitId, repoPath)
    set encodedRepo to encodeURLComponent(repoPath)
    set kaleidoscopeURL to "kaleidoscope://changeset?commitId=" & commitId & "&repo=" & encodedRepo
    open location kaleidoscopeURL
end viewGitChangeset

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
viewGitChangeset("--MCP_ARG_1", "--MCP_ARG_2")
```

## Notes

- Kaleidoscope must be installed on the system.
- The repository must be in Kaleidoscope's Repositories list.
- The commit ID should be a valid Git commit hash (full or abbreviated).
- This command opens Kaleidoscope showing all files changed in that specific commit.
- You can navigate through different files to see the specific changes in each.
- This is useful for code review and understanding what changes were made in a commit.
