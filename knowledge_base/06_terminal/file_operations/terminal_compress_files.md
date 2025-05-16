---
title: Terminal Compress Files
category: 06_terminal
id: terminal_compress_files
description: >-
  Compress files or directories into various archive formats through the terminal,
  automatically adjusting compression commands based on the source type.
keywords:
  - terminal
  - compress
  - archive
  - zip
  - tar
  - gzip
  - 7z
language: applescript
---

# Terminal Compress Files

This script provides an easy way to compress files or directories into various archive formats through the terminal.

## Features

- Supports creating zip, tar, tar.gz, tar.bz2, tar.xz, and 7z archives
- Automatically adjusts compression commands based on source type
- Uses efficient compression methods for different formats
- Handles complex paths with spaces

## Usage

```applescript
-- Terminal Compress Files
-- Compress files or directories into archives

on run
	try
		-- Default values for interactive mode
		set defaultSource to ""
		set defaultDestination to ""
		
		return compressFiles(defaultSource, defaultDestination)
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
		return "Error: Source path is required for compression."
	end if
	
	if theDestination is "" then
		return "Error: Destination archive path is required for compression."
	end if
	
	return compressFiles(theSource, theDestination)
end processMCPParameters

-- Function to compress files or directories
on compressFiles(sourcePath, destArchive)
	-- Check if source exists
	set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
	
	if sourceExists is "not exists" then
		return "Error: Source path does not exist: " & sourcePath
	end if
	
	-- Determine archive type based on destination extension
	set archiveExtension to my getFileExtension(destArchive)
	set archiveExtension to my toLower(archiveExtension)
	
	-- Get source basename for archive creation
	set sourceBasename to do shell script "basename " & quoted form of sourcePath
	
	-- Construct and execute the appropriate compress command based on file type
	set compressCommand to ""
	
	if archiveExtension is "zip" then
		-- Check if source is a directory
		set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
		
		if sourceType is "directory" then
			-- For directories, we need to change to the parent dir and zip from there
			set parentDir to do shell script "dirname " & quoted form of sourcePath
			set compressCommand to "cd " & quoted form of parentDir & " && zip -r " & ¬
				quoted form of destArchive & " " & quoted form of sourceBasename
		else
			-- For files, we can zip directly
			set compressCommand to "zip -j " & quoted form of destArchive & " " & quoted form of sourcePath
		end if
	else if archiveExtension is "tar" then
		set compressCommand to "tar -cf " & quoted form of destArchive & " -C " & ¬
			quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & ¬
			quoted form of sourceBasename
	else if archiveExtension is in {"tgz", "tar.gz"} then
		set compressCommand to "tar -czf " & quoted form of destArchive & " -C " & ¬
			quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & ¬
			quoted form of sourceBasename
	else if archiveExtension is in {"tbz2", "tar.bz2"} then
		set compressCommand to "tar -cjf " & quoted form of destArchive & " -C " & ¬
			quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & ¬
			quoted form of sourceBasename
	else if archiveExtension is in {"txz", "tar.xz"} then
		set compressCommand to "tar -cJf " & quoted form of destArchive & " -C " & ¬
			quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & ¬
			quoted form of sourceBasename
	else if archiveExtension is "7z" then
		-- Check if 7zip is installed
		try
			do shell script "which 7z"
			set compressCommand to "7z a " & quoted form of destArchive & " " & quoted form of sourcePath
		on error
			return "Error: 7zip is not installed. Please install it using Homebrew: brew install p7zip"
		end try
	else
		return "Error: Unsupported archive format: " & archiveExtension & ¬
			". Supported formats are: zip, tar, tgz, tar.gz, tbz2, tar.bz2, txz, tar.xz, 7z."
	end if
	
	-- Execute compression command
	try
		do shell script compressCommand
		return "Successfully compressed " & sourcePath & " to " & destArchive
	on error errMsg
		return "Error compressing: " & errMsg
	end try
end compressFiles

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

- `source`: Path to the file or directory to compress (required)
- `destination`: Path for the output archive file (required)

## Example Usage

### Create a ZIP archive
```json
{
  "source": "/Users/username/Documents/project",
  "destination": "/Users/username/Desktop/project.zip"
}
```

### Create a compressed TAR archive
```json
{
  "source": "/Users/username/Documents/data",
  "destination": "/Users/username/Backup/data.tar.gz"
}
```

### Compress a single file
```json
{
  "source": "/Users/username/Documents/report.pdf",
  "destination": "/Users/username/Desktop/report.zip"
}
```

### Create 7z archive
```json
{
  "source": "/Users/username/Projects/code",
  "destination": "/Users/username/Archive/code.7z"
}
```

## Supported Formats

1. **ZIP**: Standard zip compression (`.zip`)
2. **TAR**: Uncompressed tar archive (`.tar`)
3. **GZIP**: Gzip compressed tar (`.tgz`, `.tar.gz`)
4. **BZIP2**: Bzip2 compressed tar (`.tbz2`, `.tar.bz2`)
5. **XZ**: XZ compressed tar (`.txz`, `.tar.xz`)
6. **7-Zip**: 7z archive (`.7z`) - requires p7zip

## Format Characteristics

- **ZIP**: Universal format, good for general use
- **TAR**: Groups files without compression
- **GZIP**: Fast compression, widely supported
- **BZIP2**: Better compression than gzip, slower
- **XZ**: Best compression ratio, slowest
- **7z**: Excellent compression, many features

## Use Cases

1. **Backup Creation**: Compress directories for backup
2. **File Transfer**: Reduce file sizes for transfer
3. **Distribution**: Package software or documents
4. **Archival**: Long-term storage with compression
5. **Email Attachments**: Compress files for emailing

## Tips

- Choose format based on your needs:
  - ZIP for compatibility
  - TAR.GZ for Unix/Linux systems
  - 7Z for maximum compression
- Larger files benefit more from compression
- Already compressed files (JPG, MP3) won't compress much

## Error Handling

- Verifies source exists before compression
- Checks for required tools (7z)
- Validates archive format
- Provides clear error messages
- Handles paths with spaces correctly