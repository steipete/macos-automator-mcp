---
title: Terminal Change Permissions
category: 06_terminal
id: terminal_change_permissions
description: >-
  Change file or directory permissions through the terminal using chmod,
  with optional recursive changes for directories.
keywords:
  - terminal
  - permissions
  - chmod
  - access
  - recursive
  - security
language: applescript
---

# Terminal Change Permissions

This script provides an easy way to change file or directory permissions through the terminal using chmod.

## Features

- Uses chmod with octal notation (e.g., 755, 644)
- Optional recursive permission changes for directories
- Validates permission values before applying
- Clear feedback on permission changes

## Usage

```applescript
-- Terminal Change Permissions
-- Modify file or directory permissions

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		set defaultPermissions to ""
		
		return changePermissions(defaultSource, defaultPermissions)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theSource to "--MCP_INPUT:source"
	set thePermissions to "--MCP_INPUT:permissions"
	
	-- Validate parameters
	if theSource is "" then
		return "Error: Source path is required for permission change."
	end if
	
	if thePermissions is "" then
		return "Error: Permissions value is required."
	end if
	
	return changePermissions(theSource, thePermissions)
end processMCPParameters

-- Function to change file permissions
on changePermissions(filePath, permissions)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of filePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Path does not exist: " & filePath
	end if
	
	-- Validate permissions format
	if permissions is "" then
		return "Error: Permissions must be specified (e.g., 755, 644, etc.)."
	end if
	
	-- Basic validation of permission format
	try
		set permValue to permissions as integer
		if permValue < 0 or permValue > 777 then
			return "Error: Permission value must be between 0 and 777."
		end if
	on error
		return "Error: Invalid permission format. Use octal notation (e.g., 755, 644)."
	end try
	
	-- Execute chmod command
	try
		do shell script "chmod " & permissions & " " & quoted form of filePath
		
		-- Check if it's a directory and user wants to apply recursively
		set isDir to do shell script "[ -d " & quoted form of filePath & " ] && echo 'yes' || echo 'no'"
		
		if isDir is "yes" then
			set recursiveResponse to display dialog "Do you want to apply these permissions recursively to all files and subdirectories?" ¬
				buttons {"No", "Yes"} default button "No"
			
			if button returned of recursiveResponse is "Yes" then
				do shell script "chmod -R " & permissions & " " & quoted form of filePath
				return "Successfully changed permissions recursively to " & permissions & " for: " & filePath
			end if
		end if
		
		return "Successfully changed permissions to " & permissions & " for: " & filePath
	on error errMsg
		return "Error changing permissions: " & errMsg
	end try
end changePermissions
```

## MCP Parameters

- `source`: Path to the file or directory (required)
- `permissions`: Octal permission value (required)

## Example Usage

### Make a script executable
```json
{
  "source": "/Users/username/Scripts/myscript.sh",
  "permissions": "755"
}
```

### Set read-only permissions
```json
{
  "source": "/Users/username/Documents/important.txt",
  "permissions": "444"
}
```

### Set directory permissions
```json
{
  "source": "/Users/username/Projects/myproject",
  "permissions": "755"
}
```

### Restrict file access
```json
{
  "source": "/Users/username/.ssh/id_rsa",
  "permissions": "600"
}
```

## Common Permission Values

### For Files
- `644`: Read/write for owner, read for others
- `600`: Read/write for owner only
- `755`: Executable by all, writable by owner
- `700`: Full access for owner only
- `444`: Read-only for everyone

### For Directories
- `755`: Standard directory permissions
- `700`: Private directory
- `775`: Group writable directory
- `777`: Full access for everyone (use with caution)

## Permission Notation

Each digit represents permissions for:
1. Owner (user)
2. Group
3. Others

Permission values:
- `4`: Read (r)
- `2`: Write (w)
- `1`: Execute (x)

Combine values for multiple permissions:
- `7` = 4+2+1 (read, write, execute)
- `6` = 4+2 (read, write)
- `5` = 4+1 (read, execute)
- `4` = read only

## Use Cases

1. **Make Scripts Executable**: Set execute permissions on shell scripts
2. **Secure Private Files**: Restrict access to sensitive files
3. **Web Server Files**: Set appropriate permissions for web content
4. **Shared Directories**: Configure group access permissions
5. **System Files**: Correct permissions after file operations

## Recursive Changes

- For directories, the script offers recursive changes
- Applies permissions to all subdirectories and files
- Use with caution as it affects all nested items

## Error Handling

- Verifies file/directory exists
- Validates permission format
- Checks permission value range (0-777)
- Provides clear error messages
- Handles permission denied errors