---
id: kaleidoscope_file_version_tracker
title: Track File Versions with Kaleidoscope
description: Advanced script to track file versions and compare changes using Kaleidoscope
author: steipete
language: applescript
tags: 'kaleidoscope, versioning, diff, compare, backup'
keywords:
  - version control
  - file history
  - file comparison
  - backup management
  - document versioning
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer
---

# Track File Versions with Kaleidoscope

This advanced script creates a simple version control system for any file, automatically creating backups before changes and using Kaleidoscope to compare versions.

## Example Usage

```applescript
-- Initialize tracking for a file
initializeVersionTracking("/Users/username/Documents/important.txt")

-- Save a new version and compare with previous
saveNewVersion("/Users/username/Documents/important.txt", "Added new section")

-- Compare specific versions
compareVersions("/Users/username/Documents/important.txt", 2, 3)

-- List all versions of a file
listVersions("/Users/username/Documents/important.txt")
```

## Script Details

This script creates a version tracking system using Kaleidoscope for comparisons.

```applescript
-- Track and compare file versions using Kaleidoscope
property versionsFolderPath : (path to home folder as text) & "Documents/FileVersions/" as text

-- Initialize version tracking for a file
on initializeVersionTracking(filePath)
    -- Get file name from path
    set fileName to do shell script "basename " & quoted form of filePath
    
    -- Create versions folder if it doesn't exist
    set fileVersionsFolder to versionsFolderPath & fileName
    do shell script "mkdir -p " & quoted form of fileVersionsFolder
    
    -- Create metadata file
    set metadataPath to fileVersionsFolder & "/.metadata"
    do shell script "echo '{\"currentVersion\": 0, \"latestTimestamp\": \"" & (current date) & "\", \"originalPath\": \"" & filePath & "\"}' > " & quoted form of metadataPath
    
    -- Create initial version
    saveNewVersion(filePath, "Initial version")
    
    return "Version tracking initialized for " & fileName
end initializeVersionTracking

-- Save a new version of a file
on saveNewVersion(filePath, commitMessage)
    -- Get file name from path
    set fileName to do shell script "basename " & quoted form of filePath
    
    -- Ensure file exists
    if not (do shell script "[ -f " & quoted form of filePath & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: File does not exist"
    end if
    
    -- Get versions folder path
    set fileVersionsFolder to versionsFolderPath & fileName
    
    -- Create folder if it doesn't exist (auto-initialize)
    if not (do shell script "[ -d " & quoted form of fileVersionsFolder & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        initializeVersionTracking(filePath)
    end if
    
    -- Read metadata
    set metadataPath to fileVersionsFolder & "/.metadata"
    set metadataJSON to do shell script "cat " & quoted form of metadataPath
    
    -- Parse current version (simple parsing, would use JSON tools in production)
    set currentVersionText to do shell script "echo " & quoted form of metadataJSON & " | grep -o '\"currentVersion\": [0-9]*' | grep -o '[0-9]*'"
    set currentVersion to currentVersionText as integer
    
    -- Increment version
    set newVersion to currentVersion + 1
    
    -- Save new version
    set newVersionPath to fileVersionsFolder & "/v" & newVersion
    do shell script "cp " & quoted form of filePath & " " & quoted form of newVersionPath
    
    -- Update metadata
    set timestamp to current date
    do shell script "echo '{\"currentVersion\": " & newVersion & ", \"latestTimestamp\": \"" & timestamp & "\", \"originalPath\": \"" & filePath & "\"}' > " & quoted form of metadataPath
    
    -- Save commit message
    set commitPath to fileVersionsFolder & "/v" & newVersion & ".commit"
    do shell script "echo " & quoted form of commitMessage & " > " & quoted form of commitPath
    
    -- Compare with previous version if exists
    if currentVersion > 0 then
        set previousVersionPath to fileVersionsFolder & "/v" & currentVersion
        compareFilesWithKaleidoscope(previousVersionPath, newVersionPath, "v" & currentVersion & " vs v" & newVersion)
    end if
    
    return "Created version " & newVersion & " of " & fileName
end saveNewVersion

-- Compare specific versions
on compareVersions(filePath, version1, version2)
    -- Get file name from path
    set fileName to do shell script "basename " & quoted form of filePath
    
    -- Get versions folder path
    set fileVersionsFolder to versionsFolderPath & fileName
    
    -- Ensure folder exists
    if not (do shell script "[ -d " & quoted form of fileVersionsFolder & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: No version history found for this file"
    end if
    
    -- Check versions exist
    set v1Path to fileVersionsFolder & "/v" & version1
    set v2Path to fileVersionsFolder & "/v" & version2
    
    if not (do shell script "[ -f " & quoted form of v1Path & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Version " & version1 & " does not exist"
    end if
    
    if not (do shell script "[ -f " & quoted form of v2Path & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: Version " & version2 & " does not exist"
    end if
    
    -- Get commit messages if available
    set commit1 to ""
    set commit2 to ""
    
    if (do shell script "[ -f " & quoted form of (v1Path & ".commit") & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        set commit1 to do shell script "cat " & quoted form of (v1Path & ".commit")
    end if
    
    if (do shell script "[ -f " & quoted form of (v2Path & ".commit") & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        set commit2 to do shell script "cat " & quoted form of (v2Path & ".commit")
    end if
    
    -- Compare with Kaleidoscope
    set comparisonLabel to fileName & ": v" & version1
    if commit1 is not "" then
        set comparisonLabel to comparisonLabel & " (" & commit1 & ")"
    end if
    set comparisonLabel to comparisonLabel & " vs v" & version2
    if commit2 is not "" then
        set comparisonLabel to comparisonLabel & " (" & commit2 & ")"
    end if
    
    compareFilesWithKaleidoscope(v1Path, v2Path, comparisonLabel)
    
    return "Comparing version " & version1 & " with version " & version2 & " of " & fileName
end compareVersions

-- List all versions of a file
on listVersions(filePath)
    -- Get file name from path
    set fileName to do shell script "basename " & quoted form of filePath
    
    -- Get versions folder path
    set fileVersionsFolder to versionsFolderPath & fileName
    
    -- Ensure folder exists
    if not (do shell script "[ -d " & quoted form of fileVersionsFolder & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
        return "Error: No version history found for this file"
    end if
    
    -- List all versions
    set versions to do shell script "ls -1 " & quoted form of fileVersionsFolder & " | grep -E '^v[0-9]+$' | sort -V"
    
    -- Format result
    set result to "Versions of " & fileName & ":" & return
    
    repeat with versionFile in paragraphs of versions
        set versionNum to text 2 through end of versionFile
        set commitMsg to ""
        
        -- Get commit message if available
        set commitPath to fileVersionsFolder & "/" & versionFile & ".commit"
        if (do shell script "[ -f " & quoted form of commitPath & " ] && echo 'exists' || echo 'not exists'") contains "exists" then
            set commitMsg to do shell script "cat " & quoted form of commitPath
        end if
        
        -- Get file info
        set fileInfo to do shell script "ls -la " & quoted form of (fileVersionsFolder & "/" & versionFile) & " | awk '{print $6, $7, $8}'"
        
        set result to result & versionNum & " (" & fileInfo & "): " & commitMsg & return
    end repeat
    
    return result
end listVersions

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
    
    if functionName is "initialize" then
        return initializeVersionTracking(item 2 of argv)
    else if functionName is "save" then
        return saveNewVersion(item 2 of argv, item 3 of argv)
    else if functionName is "compare" then
        return compareVersions(item 2 of argv, item 3 of argv as integer, item 4 of argv as integer)
    else if functionName is "list" then
        return listVersions(item 2 of argv)
    else
        return "Error: Unknown function. Use 'initialize', 'save', 'compare', or 'list'."
    end if
end run
```

## Notes

- Kaleidoscope must be installed on the system.
- This script creates a simple version control system for tracking file changes.
- Versions are stored in `~/Documents/FileVersions/[filename]/`.
- Each version includes a commit message for documentation.
- The script uses Kaleidoscope to visually compare versions.
- This is useful for files that aren't in a proper version control system.
- Functions:
  - `initializeVersionTracking`: Start tracking a file
  - `saveNewVersion`: Save a new version and compare with previous
  - `compareVersions`: Compare any two specific versions
  - `listVersions`: List all versions with timestamps and messages
- For production use, consider using JSON libraries for better metadata handling.
- This script provides lightweight version control for documents, code snippets, or any text file.
