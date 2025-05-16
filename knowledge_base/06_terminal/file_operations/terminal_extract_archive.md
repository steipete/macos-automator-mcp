---
title: Terminal Extract Archive
category: 06_terminal
id: terminal_extract_archive
description: >-
  Extract various archive formats through the terminal, automatically detecting
  the format and using the appropriate extraction tool.
keywords:
  - terminal
  - extract
  - archive
  - zip
  - tar
  - rar
  - 7z
  - unzip
  - decompress
language: applescript
---

# Terminal Extract Archive

This script provides an easy way to extract various archive formats through the terminal.

## Features

- Supports common formats: zip, tar, tar.gz, tar.bz2, tar.xz, rar, 7z
- Automatically determines the appropriate extraction command
- Creates destination directory if it doesn't exist
- Handles complex paths with spaces

## Usage

```applescript
-- Terminal Extract Archive
-- Extract various archive formats

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		set defaultDestination to ""
		
		return extractArchive(defaultSource, defaultDestination)
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
		return "Error: Source archive path is required for extraction."
	end if
	
	return extractArchive(theSource, theDestination)
end processMCPParameters

-- Function to extract various archive formats
on extractArchive(archivePath, extractDir)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of archivePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Archive file does not exist: " & archivePath
	end if
	
	-- Determine archive type based on extension
	set archiveExtension to my getFileExtension(archivePath)
	set archiveExtension to my toLower(archiveExtension)
	
	-- Set default extract directory if not provided
	if extractDir is "" then
		set extractDir to do shell script "dirname " & quoted form of archivePath
	end if
	
	-- Create the extract directory if it doesn't exist
	do shell script "mkdir -p " & quoted form of extractDir
	
	-- Construct and execute the appropriate extract command based on file type
	set extractCommand to ""
	
	if archiveExtension is "zip" then
		set extractCommand to "unzip -o " & quoted form of archivePath & " -d " & quoted form of extractDir
	else if archiveExtension is in {"tar", "tgz", "gz", "bz2", "xz"} then
		set extractCommand to "tar -xf " & quoted form of archivePath & " -C " & quoted form of extractDir
	else if archiveExtension is "rar" then
		-- Check if unrar is installed
		try
			do shell script "which unrar"
			set extractCommand to "unrar x " & quoted form of archivePath & " " & quoted form of extractDir
		on error
			return "Error: Unrar is not installed. Please install it using Homebrew: brew install unrar"
		end try
	else if archiveExtension is "7z" then
		-- Check if 7zip is installed
		try
			do shell script "which 7z"
			set extractCommand to "7z x " & quoted form of archivePath & " -o" & quoted form of extractDir
		on error
			return "Error: 7zip is not installed. Please install it using Homebrew: brew install p7zip"
		end try
	else
		return "Error: Unsupported archive format: " & archiveExtension & ". Supported formats are: zip, tar, tgz, gz, bz2, xz, rar, 7z."
	end if
	
	-- Execute extraction command
	try
		do shell script extractCommand
		return "Successfully extracted " & archivePath & " to " & extractDir
	on error errMsg
		return "Error extracting archive: " & errMsg
	end try
end extractArchive

-- Helper function to get file extension
on getFileExtension(filePath)
	set fileName to do shell script "basename " & quoted form of filePath
	
	-- Check for double extensions like .tar.gz
	if fileName ends with ".tar.gz" then
		return "tar.gz"
	else if fileName ends with ".tar.bz2" then
		return "tar.bz2"
	else if fileName ends with ".tar.xz" then
		return "tar.xz"
	end if
	
	-- Regular extension
	if fileName contains "." then
		set AppleScript's text item delimiters to "."
		set textItems to text items of fileName
		set lastItem to item (count of textItems) of textItems
		set AppleScript's text item delimiters to ""
		return lastItem
	else
		return ""
	end if
end getFileExtension

-- Helper function to convert text to lowercase
on toLower(theText)
	set lowercaseText to ""
	repeat with i from 1 to length of theText
		set currentChar to character i of theText
		if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
			-- Convert uppercase letter to lowercase
			set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
		else
			-- Keep the character as is
			set lowercaseText to lowercaseText & currentChar
		end if
	end repeat
	return lowercaseText
end toLower
```

## MCP Parameters

- `source`: Path to the archive file to extract (required)
- `destination`: Directory to extract files to (optional, defaults to archive directory)

## Example Usage

### Extract ZIP file
```json
{
  "source": "/Users/username/Downloads/archive.zip"
}
```

### Extract to specific directory
```json
{
  "source": "/Users/username/Downloads/project.tar.gz",
  "destination": "/Users/username/Projects/"
}
```

### Extract RAR archive
```json
{
  "source": "/Users/username/Downloads/files.rar",
  "destination": "/Users/username/Documents/extracted/"
}
```

### Extract with spaces in path
```json
{
  "source": "/Users/username/My Downloads/Important Archive.zip",
  "destination": "/Users/username/My Documents/"
}
```

## Supported Formats

1. **ZIP**: Standard zip archives (`.zip`)
2. **TAR**: Uncompressed tar archives (`.tar`)
3. **GZIP**: Gzip compressed files (`.gz`, `.tgz`, `.tar.gz`)
4. **BZIP2**: Bzip2 compressed files (`.bz2`, `.tar.bz2`)
5. **XZ**: XZ compressed files (`.xz`, `.tar.xz`)
6. **RAR**: RAR archives (`.rar`) - requires unrar
7. **7-Zip**: 7z archives (`.7z`) - requires p7zip

## Additional Tools

Some formats require additional tools:

- **RAR**: Install with `brew install unrar`
- **7z**: Install with `brew install p7zip`

## Use Cases

1. **Download Extraction**: Extract downloaded archives
2. **Backup Restoration**: Extract backup archives
3. **Software Installation**: Extract software packages
4. **Data Processing**: Extract compressed data sets
5. **Project Archives**: Unpack archived projects

## Error Handling

- Verifies archive exists before extraction
- Checks for required tools (unrar, 7z)
- Creates destination directory if needed
- Provides clear error messages
- Handles unsupported formats gracefully