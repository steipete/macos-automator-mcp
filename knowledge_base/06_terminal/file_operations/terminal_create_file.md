---
title: Terminal Create File
category: 06_terminal
id: terminal_create_file
description: >-
  Create new files with optional content through the terminal, automatically
  creating parent directories if needed.
keywords:
  - terminal
  - create
  - touch
  - file
  - content
  - mkdir
language: applescript
---

# Terminal Create File

This script provides an easy way to create new files with optional content through the terminal.

## Features

- Creates parent directories if they don't exist
- Allows specifying initial file content
- Prompts for confirmation if file already exists
- Handles complex paths with spaces

## Usage

```applescript
-- Terminal Create File
-- Create new files with optional content

on run
	try
		-- Default values for interactive mode
		set defaultDestination to ""
		set defaultContent to ""
		
		return createFile(defaultDestination, defaultContent)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theDestination to "--MCP_INPUT:destination"
	set theContent to "--MCP_INPUT:content"
	
	-- Validate parameters
	if theDestination is "" then
		return "Error: Destination path is required for file creation."
	end if
	
	return createFile(theDestination, theContent)
end processMCPParameters

-- Function to create a new file with optional content
on createFile(filePath, fileContent)
	if filePath is "" then
		return "Error: Destination path is required for file creation."
	end if
	
	-- Check if file already exists
	set fileExists to do shell script "[ -e " & quoted form of filePath & " ] && echo 'exists' || echo 'not exists'"
	
	if fileExists is "exists" then
		set overwriteResponse to display dialog "File already exists. Do you want to overwrite it?" ¬
			buttons {"Cancel", "Overwrite"} default button "Cancel" with icon caution
		
		if button returned of overwriteResponse is "Cancel" then
			return "File creation cancelled."
		end if
	end if
	
	-- Create the parent directory if it doesn't exist
	set parentDir to do shell script "dirname " & quoted form of filePath
	do shell script "mkdir -p " & quoted form of parentDir
	
	-- Create the file with content
	try
		if fileContent is not "" then
			-- Write content to the file
			do shell script "cat > " & quoted form of filePath & " << 'EOFMARKER'
" & fileContent & "
EOFMARKER"
		else
			-- Create an empty file
			do shell script "touch " & quoted form of filePath
		end if
		
		return "Successfully created file: " & filePath
	on error errMsg
		return "Error creating file: " & errMsg
	end try
end createFile
```

## MCP Parameters

- `destination`: Path where the file should be created (required)
- `content`: Initial content for the file (optional)

## Example Usage

### Create an empty file
```json
{
  "destination": "/Users/username/Documents/newfile.txt"
}
```

### Create a file with content
```json
{
  "destination": "/Users/username/Documents/config.json",
  "content": "{\n  \"name\": \"My App\",\n  \"version\": \"1.0.0\"\n}"
}
```

### Create file in new directory
```json
{
  "destination": "/Users/username/NewProject/src/index.js",
  "content": "console.log('Hello, World!');"
}
```

### Create file with spaces in path
```json
{
  "destination": "/Users/username/My Documents/Important Notes.txt",
  "content": "Important notes go here..."
}
```

## Use Cases

1. **Configuration Files**: Create config files with default content
2. **Project Templates**: Create template files for new projects
3. **Documentation**: Create README or documentation files
4. **Log Files**: Initialize empty log files
5. **Scripts**: Create script files with boilerplate code

## Features

### Automatic Directory Creation
- Parent directories are created automatically if they don't exist
- No need to manually create the directory structure first

### Content Handling
- Supports empty files or files with initial content
- Preserves formatting and special characters in content
- Uses HERE document for reliable content writing

### Overwrite Protection
- Warns if file already exists
- Requires confirmation to overwrite existing files
- Default action is to cancel, preventing accidental overwrites

## Error Handling

- Validates destination path is provided
- Checks for existing files before creation
- Creates parent directories automatically
- Provides clear error messages
- Handles permission errors appropriately