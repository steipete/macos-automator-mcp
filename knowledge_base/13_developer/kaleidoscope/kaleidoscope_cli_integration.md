---
id: kaleidoscope_cli_integration
title: Kaleidoscope Command Line Integration
description: Use AppleScript with Kaleidoscope's command-line tool ksdiff
author: steipete
language: applescript
tags: 'kaleidoscope, ksdiff, command line, terminal, diff'
keywords:
  - kaleidoscope
  - cli
  - command line
  - ksdiff
  - file comparison
version: 1.0.0
updated: 2024-05-16T00:00:00.000Z
category: 13_developer/kaleidoscope
---

# Kaleidoscope Command Line Integration

This script uses Kaleidoscope's command-line tool `ksdiff` to perform file comparisons and merge operations from AppleScript.

## Example Usage

```applescript
-- Compare two files using ksdiff
do shell script "/usr/local/bin/ksdiff /path/to/file1.txt /path/to/file2.txt"

-- Merge two files
do shell script "/usr/local/bin/ksdiff --merge /path/to/base.txt /path/to/mine.txt /path/to/theirs.txt -o /path/to/result.txt"
```

## Script Details

Kaleidoscope comes with a command-line tool called `ksdiff` that can be used for various comparison operations.

```applescript
-- Use ksdiff for file comparison and merge operations
on useKaleidoscopeCLI(operation, filePath1, filePath2, filePath3, outputPath)
    -- Determine if ksdiff is installed
    try
        do shell script "which ksdiff"
        set ksdiffPath to result
    on error
        -- Try common installation locations
        if exists file "/usr/local/bin/ksdiff" then
            set ksdiffPath to "/usr/local/bin/ksdiff"
        else if exists file "/opt/homebrew/bin/ksdiff" then
            set ksdiffPath to "/opt/homebrew/bin/ksdiff"
        else
            return "Error: ksdiff command-line tool not found. Please install Kaleidoscope and its CLI tools."
        end if
    end try
    
    -- Build the command based on the operation
    if operation is "compare" then
        set cmd to quoted form of ksdiffPath & " " & quoted form of filePath1 & " " & quoted form of filePath2
        
    else if operation is "merge" then
        if filePath3 is "" or outputPath is "" then
            return "Error: Merge operation requires base, mine, theirs, and output path parameters."
        end if
        
        set cmd to quoted form of ksdiffPath & " --merge " & quoted form of filePath1 & " " & quoted form of filePath2 & " " & quoted form of filePath3 & " -o " & quoted form of outputPath
        
    else if operation is "git" then
        set cmd to quoted form of ksdiffPath & " --git " & quoted form of filePath1
        
    else if operation is "help" then
        set cmd to quoted form of ksdiffPath & " --help"
        
    else
        return "Error: Unsupported operation. Use 'compare', 'merge', 'git', or 'help'."
    end if
    
    -- Execute the command
    try
        do shell script cmd
        return "Kaleidoscope operation completed successfully."
    on error errMsg
        return "Error executing ksdiff: " & errMsg
    end try
end useKaleidoscopeCLI

-- Example call
useKaleidoscopeCLI("--MCP_ARG_1", "--MCP_ARG_2", "--MCP_ARG_3", "--MCP_ARG_4", "--MCP_ARG_5")
```

## Notes

- Kaleidoscope and its command-line tools must be installed on the system.
- To install the command-line tool, open Kaleidoscope's preferences, go to the Integration tab, and click "Install Command Line Tool".
- The `ksdiff` tool is typically installed in `/usr/local/bin/` or `/opt/homebrew/bin/`.
- The script supports multiple operations:
  - `compare`: Compare two files or folders
  - `merge`: Merge conflicts between files
  - `git`: Open a file within the context of its Git repository
  - `help`: Show ksdiff command help
- For `merge` operations, provide the base file, your version, their version, and the output path.
- The command-line tool provides more advanced options than the URL scheme for integration with version control systems.
