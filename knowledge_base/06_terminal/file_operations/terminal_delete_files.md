---
title: Terminal Delete Files
category: 06_terminal
id: terminal_delete_files
description: >-
  Safely delete files or directories through the terminal with confirmation
  prompts and special warnings for non-empty directories.
keywords:
  - terminal
  - delete
  - rm
  - remove
  - safety
  - confirmation
language: applescript
---

# Terminal Delete Files

This script provides a safe way to delete files or directories through the terminal with built-in safety confirmations.

## Features

- Confirmation prompt before deletion
- Extra warning for non-empty directories
- Appropriate flags for different deletion types
- Clear error messages and feedback

## Usage

```applescript
-- Terminal Delete Files
-- Safely delete files or directories

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		
		return deleteFiles(defaultSource)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theSource to "--MCP_INPUT:source"
	
	-- Validate parameters
	if theSource is "" then
		return "Error: Source path is required for delete operation."
	end if
	
	return deleteFiles(theSource)
end processMCPParameters

-- Function to delete files or directories
on deleteFiles(sourcePath)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Path does not exist: " & sourcePath
	end if
	
	-- Check if source is a file or directory
	set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
	
	-- Ask for confirmation before deleting
	set confirmMessage to "Are you sure you want to delete this " & sourceType & "?"
	set confirmButton to "Delete"
	
	if sourceType is "directory" then
		-- Check if directory is empty
		set dirEmpty to do shell script "[ \"$(ls -A " & quoted form of sourcePath & ")\" ] && echo 'not empty' || echo 'empty'"
		
		if dirEmpty is "not empty" then
			set confirmMessage to "Warning: The directory is not empty. Are you sure you want to delete it and all its contents?"
			set confirmButton to "Delete All"
		end if
	end if
	
	display dialog confirmMessage buttons {"Cancel", confirmButton} default button "Cancel" with icon caution
	
	-- Construct the appropriate rm command
	set rmCommand to "rm "
	
	if sourceType is "directory" then
		set rmCommand to rmCommand & "-rf " -- Recursive and force for directories
	else
		set rmCommand to rmCommand & "-f " -- Force for files
	end if
	
	-- Add source path
	set rmCommand to rmCommand & quoted form of sourcePath
	
	-- Execute the command
	try
		do shell script rmCommand
		
		if sourceType is "directory" then
			return "Successfully deleted directory: " & sourcePath
		else
			return "Successfully deleted file: " & sourcePath
		end if
	on error errMsg
		return "Error deleting: " & errMsg
	end try
end deleteFiles
```

## MCP Parameters

- `source`: Path to the file or directory to delete (required)

## Example Usage

### Delete a single file
```json
{
  "source": "/Users/username/Desktop/unwanted_file.txt"
}
```

### Delete an empty directory
```json
{
  "source": "/Users/username/Documents/empty_folder"
}
```

### Delete a directory with contents
```json
{
  "source": "/Users/username/Projects/old_project"
}
```

### Delete with spaces in path
```json
{
  "source": "/Users/username/Desktop/Old Document.pdf"
}
```

## Safety Features

1. **Confirmation Prompts**: Always asks for confirmation before deletion
2. **Empty Directory Check**: Warns specifically about non-empty directories
3. **Type Detection**: Different warnings for files vs directories
4. **Cancel Option**: Default button is "Cancel" for safety

## Use Cases

1. **Clean Temporary Files**: Remove temporary or cache files
2. **Project Cleanup**: Delete old project directories
3. **Desktop Organization**: Remove unwanted files from Desktop
4. **Log Cleanup**: Delete old log files

## Warning Messages

- Files: "Are you sure you want to delete this file?"
- Empty directories: "Are you sure you want to delete this directory?"
- Non-empty directories: "Warning: The directory is not empty..."

## Error Handling

- Verifies file/directory exists before deletion
- Provides appropriate error messages
- Handles permission errors
- Reports successful deletion with full path