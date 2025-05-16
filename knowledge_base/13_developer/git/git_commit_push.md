---
id: git_commit_push
title: Git Commit and Push
description: Automates the Git commit and push process for a repository
language: applescript
author: Claude
keywords:
  - git automation
  - version control
  - commit workflow
  - repository management
  - code versioning
usage_examples:
  - Commit and push changes in a git repository
  - Automate routine code commits
parameters:
  - name: repoPath
    description: Path to the Git repository (POSIX path)
    required: true
  - name: commitMessage
    description: Message for the commit
    required: true
category: 13_developer
---

# Git Commit and Push

This script automates the process of committing and pushing changes to a Git repository.

```applescript
on run {input, parameters}
    set repoPath to "--MCP_INPUT:repoPath"
    set commitMessage to "--MCP_INPUT:commitMessage"
    
    if repoPath is "" or repoPath is missing value then
        tell application "Finder"
            if exists Finder window 1 then
                set currentFolder to target of Finder window 1 as alias
                set repoPath to POSIX path of currentFolder
            else
                display dialog "No Finder window open and no repository path provided." buttons {"OK"} default button "OK" with icon stop
                return
            end if
        end tell
    end if
    
    if commitMessage is "" or commitMessage is missing value then
        set commitMessage to "Update from AppleScript"
    end if
    
    -- Properly escape the commit message for the shell
    set quotedMessage to quoted form of commitMessage
    
    -- Build the command with proper chaining
    set gitCommand to "cd " & quoted form of repoPath & " && git add -A && git commit -m " & quotedMessage & " && git push"
    
    try
        set result to do shell script gitCommand
        return "Successfully committed and pushed changes to repository at " & repoPath & "." & return & return & result
    on error errMsg
        return "Error performing Git operations: " & errMsg
    end try
end run
```

## Customization Options

The script can be extended to support:

1. Specifying which branch to push to
2. Adding specific files instead of all changes
3. Pulling before pushing to avoid conflicts
4. Interactive confirmation before pushing

To modify this script for a specific branch, change the push command:

```applescript
-- For pushing to a specific branch
set gitCommand to "cd " & quoted form of repoPath & " && git add -A && git commit -m " & quotedMessage & " && git push origin main"
```

To add pull before push:

```applescript
-- For pulling before pushing
set gitCommand to "cd " & quoted form of repoPath & " && git add -A && git commit -m " & quotedMessage & " && git pull --rebase && git push"
```

## Note on Git Configuration

This script assumes that Git is properly configured on your system and that you have the necessary credentials to push to the repository (SSH keys or credential helper configured).
