---
title: Terminal Copy Files
category: 06_terminal
id: terminal_copy_files
description: >-
  Copy files or directories through the terminal, automatically handling
  recursive operations for directories and supporting drag-and-drop paths.
keywords:
  - terminal
  - copy
  - cp
  - file
  - directory
  - recursive
language: applescript
---

# Terminal Copy Files

This script provides an easy way to copy files or directories through the terminal without having to manually type complex commands.

## Features

- Automatically determines if source is a file or directory
- Uses appropriate flags for recursive copying when needed
- Handles spaces and special characters in file paths
- Supports drag-and-drop paths from Finder

## Usage

```applescript
-- Terminal Copy Files
-- Copy files or directories

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		set defaultDestination to ""
		
		return copyFiles(defaultSource, defaultDestination)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theSource to "--MCP_INPUT:source"
	set theDestination to "--MCP_INPUT:destination"
	
	-- Validate parameters
	if theSource is "" then
		return "Error: Source path is required for copy operation."
	end if
	
	if theDestination is "" then
		return "Error: Destination path is required for copy operation."
	end if
	
	return copyFiles(theSource, theDestination)
end processMCPParameters

-- Function to copy files or directories
on copyFiles(sourcePath, destPath)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Source path does not exist: " & sourcePath
	end if
	
	-- Check if source is a file or directory
	set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
	
	-- Construct the appropriate cp command
	set cpCommand to "cp "
	
	if sourceType is "directory" then
		set cpCommand to cpCommand & "-R " -- Recursive for directories
	end if
	
	-- Add source and destination
	set cpCommand to cpCommand & quoted form of sourcePath & " " & quoted form of destPath
	
	-- Execute the command
	try
		do shell script cpCommand
		
		if sourceType is "directory" then
			return "Successfully copied directory from " & sourcePath & " to " & destPath
		else
			return "Successfully copied file from " & sourcePath & " to " & destPath
		end if
	on error errMsg
		return "Error copying: " & errMsg
	end try
end copyFiles
```

## MCP Parameters

- `source`: Path to the file or directory to copy (required)
- `destination`: Path where the file or directory should be copied to (required)

## Example Usage

### Copy a single file
```json
{
  "source": "/Users/username/Documents/file.txt",
  "destination": "/Users/username/Desktop/file.txt"
}
```

### Copy a directory
```json
{
  "source": "/Users/username/Projects/myproject",
  "destination": "/Users/username/Backup/myproject"
}
```

### Copy with spaces in path
```json
{
  "source": "/Users/username/My Documents/Important File.pdf",
  "destination": "/Users/username/Desktop/Important File.pdf"
}
```

## Use Cases

1. **Backup Operations**: Create copies of important files or directories
2. **Project Duplication**: Copy entire project directories for testing
3. **File Distribution**: Copy files to multiple locations
4. **Template Creation**: Copy template files for new projects

## Tips

- Use absolute paths for most reliable operation
- The script automatically handles recursive copying for directories
- Spaces and special characters in paths are automatically escaped
- Use drag-and-drop from Finder to easily get file paths

## Error Handling

- Checks if source exists before attempting copy
- Provides clear error messages for missing files
- Reports success with source and destination paths
- Handles permission errors with appropriate messages