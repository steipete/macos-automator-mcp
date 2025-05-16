---
id: kaleidoscope_dev_tools_integration
title: Integrate Kaleidoscope with Developer Tools
description: Advanced script to integrate Kaleidoscope with various developer tools
author: steipete
language: applescript
tags: 'kaleidoscope, diff, development, git, svn, xcode, debugging'
keywords:
  - kaleidoscope
  - git integration
  - xcode integration
  - database comparison
  - branch comparison
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Integrate Kaleidoscope with Developer Tools

This advanced script provides integration between Kaleidoscope and various developer tools such as Xcode, Git, and more.

## Example Usage

```applescript
-- Compare Xcode project files
compareXcodeProjectFiles("/Users/username/Projects/MyApp.xcodeproj", "/Users/username/Projects/Backup/MyApp.xcodeproj")

-- Setup Kaleidoscope as Git diff tool
setupAsGitDiffTool()

-- Compare latest changes in Git repository
compareLatestGitChanges("/Users/username/Projects/MyRepo")

-- Compare specific branches
compareGitBranches("/Users/username/Projects/MyRepo", "main", "feature/new-ui")
```

## Script Details

This script provides advanced Kaleidoscope integration with developer tools.

```applescript
-- Integrate Kaleidoscope with various developer tools

-- Compare Xcode project files (.xcodeproj)
on compareXcodeProjectFiles(xcodeproj1, xcodeproj2)
    -- Extract project.pbxproj files which contain the actual project structure
    set projectFile1 to xcodeproj1 & "/project.pbxproj"
    set projectFile2 to xcodeproj2 & "/project.pbxproj"
    
    -- Check if files exist
    if not (do shell script "[ -f " & quoted form of projectFile1 & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: First Xcode project file does not exist"
    end if
    
    if not (do shell script "[ -f " & quoted form of projectFile2 & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Second Xcode project file does not exist"
    end if
    
    -- Compare using Kaleidoscope
    set comparisonLabel to "Xcode Project Comparison"
    compareFilesWithKaleidoscope(projectFile1, projectFile2, comparisonLabel)
    
    return "Comparing Xcode project files"
end compareXcodeProjectFiles

-- Setup Kaleidoscope as the diff tool for Git
on setupAsGitDiffTool()
    try
        -- Check if ksdiff is installed
        set ksdiffPath to do shell script "which ksdiff || echo 'not found'"
        
        if ksdiffPath contains "not found" then
            -- Try common installation locations
            if (do shell script "[ -f /usr/local/bin/ksdiff ] && echo 'exists' || echo 'not exists'") contains "exists" then
                set ksdiffPath to "/usr/local/bin/ksdiff"
            else if (do shell script "[ -f /opt/homebrew/bin/ksdiff ] && echo 'exists' || echo 'not exists'") contains "exists" then
                set ksdiffPath to "/opt/homebrew/bin/ksdiff"
            else
                return "Error: ksdiff command-line tool not found. Please install Kaleidoscope and its CLI tools."
            end if
        end if
        
        -- Configure Git to use Kaleidoscope
        do shell script "git config --global diff.tool Kaleidoscope"
        do shell script "git config --global difftool.Kaleidoscope.cmd '" & ksdiffPath & " --diff \"$LOCAL\" \"$REMOTE\"'"
        do shell script "git config --global merge.tool Kaleidoscope"
        do shell script "git config --global mergetool.Kaleidoscope.cmd '" & ksdiffPath & " --merge --output \"$MERGED\" \"$LOCAL\" \"$BASE\" \"$REMOTE\"'"
        do shell script "git config --global mergetool.Kaleidoscope.trustExitCode true"
        
        return "Kaleidoscope has been set up as the default Git diff and merge tool."
    on error errMsg
        return "Error configuring Git: " & errMsg
    end try
end setupAsGitDiffTool

-- Compare latest changes in a Git repository
on compareLatestGitChanges(repoPath)
    -- Ensure path exists and is a Git repository
    if not (do shell script "[ -d " & quoted form of repoPath & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Repository path does not exist"
    end if
    
    if not (do shell script "cd " & quoted form of repoPath & " && [ -d .git ] && echo 'is git repo' || echo 'not git repo'") contains "is git repo" then
        return "Error: Path is not a Git repository"
    end if
    
    try
        -- Get the latest commit ID
        set latestCommit to do shell script "cd " & quoted form of repoPath & " && git rev-parse HEAD"
        
        -- Open the changeset in Kaleidoscope
        set kaleidoscopeURL to "kaleidoscope://changeset?commitId=" & latestCommit & "&repo=" & encodeURLComponent(repoPath)
        open location kaleidoscopeURL
        
        return "Comparing latest changes in repository"
    on error errMsg
        return "Error accessing Git repository: " & errMsg
    end try
end compareLatestGitChanges

-- Compare two Git branches
on compareGitBranches(repoPath, branch1, branch2)
    -- Ensure path exists and is a Git repository
    if not (do shell script "[ -d " & quoted form of repoPath & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Repository path does not exist"
    end if
    
    if not (do shell script "cd " & quoted form of repoPath & " && [ -d .git ] && echo 'is git repo' || echo 'not git repo'") contains "is git repo" then
        return "Error: Path is not a Git repository"
    end if
    
    try
        -- Check if branches exist
        set branch1Exists to do shell script "cd " & quoted form of repoPath & " && git rev-parse --verify " & quoted form of branch1 & " >/dev/null 2>&1 && echo 'exists' || echo 'not exists'"
        set branch2Exists to do shell script "cd " & quoted form of repoPath & " && git rev-parse --verify " & quoted form of branch2 & " >/dev/null 2>&1 && echo 'exists' || echo 'not exists'"
        
        if branch1Exists contains "not exists" then
            return "Error: Branch '" & branch1 & "' does not exist"
        end if
        
        if branch2Exists contains "not exists" then
            return "Error: Branch '" & branch2 & "' does not exist"
        end if
        
        -- Create a temporary directory
        set tempDir to (do shell script "mktemp -d")
        
        -- Use ksdiff to compare branches
        do shell script "cd " & quoted form of repoPath & " && ksdiff --git --name-only " & quoted form of (branch1 & "..." & branch2) & " | xargs -I {} sh -c 'mkdir -p " & quoted form of tempDir & "/$(dirname {}) && git show " & quoted form of branch1 & ":{} > " & quoted form of tempDir & "/{} 2>/dev/null || touch " & quoted form of tempDir & "/{}.deleted'"
        
        do shell script "cd " & quoted form of repoPath & " && ksdiff --git --name-only " & quoted form of (branch1 & "..." & branch2) & " | xargs -I {} sh -c 'mkdir -p " & quoted form of tempDir & "_2/$(dirname {}) && git show " & quoted form of branch2 & ":{} > " & quoted form of tempDir & "_2/{} 2>/dev/null || touch " & quoted form of tempDir & "_2/{}.deleted'"
        
        -- Compare directories
        set comparisonLabel to "Branch: " & branch1 & " vs " & branch2
        compareFilesWithKaleidoscope(tempDir, tempDir & "_2", comparisonLabel)
        
        -- Clean up temp dirs after 1 hour (let Kaleidoscope finish using them)
        do shell script "(sleep 3600 && rm -rf " & quoted form of tempDir & " " & quoted form of tempDir & "_2) &"
        
        return "Comparing branches: " & branch1 & " vs " & branch2
    on error errMsg
        return "Error comparing branches: " & errMsg
    end try
end compareGitBranches

-- Compare database schema changes
on compareDatabaseSchemas(dbDumpFile1, dbDumpFile2)
    -- Check if files exist
    if not (do shell script "[ -f " & quoted form of dbDumpFile1 & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: First database dump file does not exist"
    end if
    
    if not (do shell script "[ -f " & quoted form of dbDumpFile2 & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Second database dump file does not exist"
    end if
    
    -- Create temporary files with just the schema information
    set tempFile1 to (do shell script "mktemp")
    set tempFile2 to (do shell script "mktemp")
    
    -- Extract schema definitions (assuming SQL dumps)
    do shell script "grep -E '^CREATE TABLE|^CREATE INDEX|^ALTER TABLE' " & quoted form of dbDumpFile1 & " > " & quoted form of tempFile1
    do shell script "grep -E '^CREATE TABLE|^CREATE INDEX|^ALTER TABLE' " & quoted form of dbDumpFile2 & " > " & quoted form of tempFile2
    
    -- Compare using Kaleidoscope
    set comparisonLabel to "Database Schema Comparison"
    compareFilesWithKaleidoscope(tempFile1, tempFile2, comparisonLabel)
    
    -- Clean up temp files after 1 hour
    do shell script "(sleep 3600 && rm -f " & quoted form of tempFile1 & " " & quoted form of tempFile2 & ") &"
    
    return "Comparing database schemas"
end compareDatabaseSchemas

-- Helper function to compare files with Kaleidoscope
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
        else if theChar is "(" then
            set encodedString to encodedString & "%28"
        else if theChar is ")" then
            set encodedString to encodedString & "%29"
        else
            set encodedString to encodedString & theChar
        end if
    end repeat
    
    return encodedString
end encodeURLComponent

-- Example call based on which function to run
on run argv
    set functionName to item 1 of argv
    
    if functionName is "compare-xcode" then
        return compareXcodeProjectFiles(item 2 of argv, item 3 of argv)
    else if functionName is "setup-git" then
        return setupAsGitDiffTool()
    else if functionName is "compare-git-latest" then
        return compareLatestGitChanges(item 2 of argv)
    else if functionName is "compare-branches" then
        return compareGitBranches(item 2 of argv, item 3 of argv, item 4 of argv)
    else if functionName is "compare-db" then
        return compareDatabaseSchemas(item 2 of argv, item 3 of argv)
    else
        return "Error: Unknown function. Use 'compare-xcode', 'setup-git', 'compare-git-latest', 'compare-branches', or 'compare-db'."
    end if
end run
```

## Notes

- Kaleidoscope and its command-line tool (`ksdiff`) must be installed on the system.
- This script provides advanced integration between Kaleidoscope and various developer tools.
- Functions:
  - `compareXcodeProjectFiles`: Compare two Xcode project files, focusing on the project structure
  - `setupAsGitDiffTool`: Configure Kaleidoscope as the default diff and merge tool for Git
  - `compareLatestGitChanges`: View changes in the most recent commit of a Git repository
  - `compareGitBranches`: Compare files between two Git branches
  - `compareDatabaseSchemas`: Extract and compare database schema definitions from SQL dumps
- The script creates temporary files when needed and includes cleanup to remove them after use.
- This integration is particularly useful for code reviews, merge conflict resolution, and tracking changes across versions.
- The comparison of Git branches creates temporary directories with snapshots of each branch for more effective comparison.
- Command-line flags and arguments may need adjustment depending on the specific versions of tools being used.
