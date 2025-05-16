---
title: Terminal Move Files
category: 06_terminal
id: terminal_move_files
description: >-
  Move or rename files and directories through the terminal, preserving
  file attributes and handling complex paths with spaces.
keywords:
  - terminal
  - move
  - mv
  - rename
  - file
  - directory
language: applescript
---

# Terminal Move Files

This script provides an easy way to move or rename files and directories through the terminal without having to manually type complex commands.

## Features

- Works with both single files and entire directory structures
- Preserves file attributes during the move operation
- Can be used for both moving and renaming
- Handles spaces and special characters in file paths

## Usage

```applescript
-- Terminal Move Files
-- Move or rename files and directories

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		set defaultDestination to ""
		
		return moveFiles(defaultSource, defaultDestination)
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
		return "Error: Source path is required for move operation."
	end if
	
	if theDestination is "" then
		return "Error: Destination path is required for move operation."
	end if
	
	return moveFiles(theSource, theDestination)
end processMCPParameters

-- Function to move files or directories
on moveFiles(sourcePath, destPath)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Source path does not exist: " & sourcePath
	end if
	
	-- Check if source is a file or directory
	set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
	
	-- Execute the move command
	try
		do shell script "mv " & quoted form of sourcePath & " " & quoted form of destPath
		
		if sourceType is "directory" then
			return "Successfully moved directory from " & sourcePath & " to " & destPath
		else
			return "Successfully moved file from " & sourcePath & " to " & destPath
		end if
	on error errMsg
		return "Error moving: " & errMsg
	end try
end moveFiles
```

## MCP Parameters

- `source`: Path to the file or directory to move (required)
- `destination`: New path or name for the file or directory (required)

## Example Usage

### Move a file to a different directory
```json
{
  "source": "/Users/username/Downloads/document.pdf",
  "destination": "/Users/username/Documents/document.pdf"
}
```

### Rename a file in the same directory
```json
{
  "source": "/Users/username/Desktop/old_name.txt",
  "destination": "/Users/username/Desktop/new_name.txt"
}
```

### Move a directory
```json
{
  "source": "/Users/username/Projects/old_project",
  "destination": "/Users/username/Archive/old_project"
}
```

### Move with spaces in path
```json
{
  "source": "/Users/username/My Documents/Important File.doc",
  "destination": "/Users/username/Desktop/Important File.doc"
}
```

## Use Cases

1. **File Organization**: Move files into appropriate directories
2. **Renaming**: Change file or directory names
3. **Project Archiving**: Move completed projects to archive folders
4. **Clean Downloads**: Move files from Downloads to organized locations

## Tips

- The same command works for both moving and renaming
- Moving to a different name in the same directory effectively renames
- Paths are automatically quoted to handle spaces and special characters
- Use drag-and-drop from Finder to easily get file paths

## Error Handling

- Verifies source exists before attempting move
- Provides clear error messages for missing files
- Reports whether a file or directory was moved
- Handles permission errors appropriately