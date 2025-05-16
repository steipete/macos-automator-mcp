---
title: Batch Apply Metadata
category: 05_files
id: batch_apply_metadata
description: >-
  Apply macOS tags and comments to multiple files using Finder, enabling
  better file organization and searchability.
keywords:
  - batch
  - metadata
  - tags
  - comments
  - Finder
  - macOS
language: applescript
---

# Batch Apply Metadata

This script applies macOS tags and comments to multiple files using Finder, making it easy to organize and categorize files for better searchability.

## Features

- Apply multiple tags to files
- Add comments to files
- Batch processing of multiple files
- Uses native macOS file metadata
- Error handling for individual files

## Usage

```applescript
-- Batch Apply Metadata
-- Apply tags and comments to multiple files

on run
	try
		-- Use file selection dialog for interactive mode
		set fileList to chooseFiles()
		
		-- Get tags from user
		set tagsInput to text returned of (display dialog "Enter tags (comma-separated):" default answer "Important, Project X")
		set tagsToApply to my splitString(tagsInput, ",")
		
		-- Trim spaces from tags
		repeat with i from 1 to count of tagsToApply
			set item i of tagsToApply to my trimSpaces(item i of tagsToApply)
		end repeat
		
		-- Get comment from user
		set commentText to text returned of (display dialog "Enter comment (optional):" default answer "Processed on " & (current date) as string)
		
		return batchApplyMetadata(fileList, tagsToApply, commentText)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set fileList to "--MCP_INPUT:fileList"
	set tagsToApply to "--MCP_INPUT:tags"
	set commentText to "--MCP_INPUT:comment"
	
	-- Default values
	if tagsToApply is "" then
		set tagsToApply to {}
	else if class of tagsToApply is text then
		-- Convert comma-separated string to list
		set tagsToApply to my splitString(tagsToApply, ",")
		repeat with i from 1 to count of tagsToApply
			set item i of tagsToApply to my trimSpaces(item i of tagsToApply)
		end repeat
	end if
	
	if commentText is "" then
		set commentText to ""
	end if
	
	-- Validate file list
	if fileList is "" or class of fileList is not list then
		return "Error: File list is required and must be a list."
	end if
	
	return batchApplyMetadata(fileList, tagsToApply, commentText)
end processMCPParameters

-- Choose multiple files for batch processing
on chooseFiles()
	set theFiles to {}
	set dialogResult to (choose file with prompt "Select files for metadata application:" with multiple selections allowed)
	
	-- Convert results to a list of POSIX paths
	repeat with aFile in dialogResult
		set end of theFiles to POSIX path of aFile
	end repeat
	
	return theFiles
end chooseFiles

-- Apply metadata (tags, comments) to multiple files via Finder
on batchApplyMetadata(fileList, tagsToApply, commentText)
	set processedFiles to 0
	set errorFiles to 0
	
	tell application "Finder"
		repeat with filePath in fileList
			try
				set theFile to POSIX file filePath as alias
				
				-- Apply tags if provided
				if tagsToApply is not {} then
					set tags of theFile to tagsToApply
				end if
				
				-- Apply comment if provided
				if commentText is not "" then
					set comment of theFile to commentText
				end if
				
				set processedFiles to processedFiles + 1
			on error errMsg
				log "Error applying metadata to " & filePath & ": " & errMsg
				set errorFiles to errorFiles + 1
			end try
		end repeat
	end tell
	
	set resultMessage to "Metadata applied to " & processedFiles & " files"
	if errorFiles > 0 then
		set resultMessage to resultMessage & " (" & errorFiles & " errors)"
	end if
	
	return resultMessage
end batchApplyMetadata

-- Helper function to split string
on splitString(theString, theDelimiter)
	set tid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theItems to text items of theString
	set AppleScript's text item delimiters to tid
	return theItems
end splitString

-- Helper function to trim spaces
on trimSpaces(theText)
	set theText to theText as string
	-- Remove leading spaces
	repeat while theText starts with " "
		set theText to text 2 thru -1 of theText
	end repeat
	-- Remove trailing spaces
	repeat while theText ends with " "
		set theText to text 1 thru -2 of theText
	end repeat
	return theText
end trimSpaces
```

## MCP Parameters

- `fileList`: Array of file paths to process (required)
- `tags`: Tags to apply (array or comma-separated string)
- `comment`: Comment text to add to files

## Example Usage

### Apply project tags
```json
{
  "fileList": [
    "/Users/john/Documents/report.pdf",
    "/Users/john/Documents/presentation.ppt"
  ],
  "tags": ["Project Alpha", "Q1 2024", "Important"],
  "comment": "Final deliverables for Project Alpha"
}
```

### Tag photos from event
```json
{
  "fileList": [
    "/Users/john/Pictures/IMG_001.jpg",
    "/Users/john/Pictures/IMG_002.jpg"
  ],
  "tags": "Wedding, Family, 2024",
  "comment": "John and Jane's wedding - January 2024"
}
```

### Add processing date
```json
{
  "fileList": [
    "/Users/john/Downloads/data1.csv",
    "/Users/john/Downloads/data2.csv"
  ],
  "tags": ["Processed", "Data"],
  "comment": "Processed on 2024-01-15"
}
```

## macOS Tags

### Benefits of Tags:
- Searchable in Finder and Spotlight
- Visible as colored dots in Finder
- Can apply multiple tags per file
- Synced across iCloud Drive
- Support smart folders

### Common Tag Uses:
- Project names
- Status (Draft, Final, Archived)
- Priority (High, Medium, Low)
- Categories (Work, Personal, Finance)
- Years or dates

## Comments

### Benefits of Comments:
- Searchable in Spotlight
- Visible in Get Info window
- Can contain detailed descriptions
- Support for timestamps
- Useful for version notes

### Common Comment Uses:
- Processing dates
- Version information
- Source details
- Author notes
- Description of contents

## Use Cases

1. **Project Organization**: Tag files by project and status
2. **Photo Management**: Add event details and dates
3. **Document Archival**: Mark archive date and reason
4. **Workflow Tracking**: Indicate processing status
5. **Team Collaboration**: Add reviewer comments

## Features

### Batch Processing
- Process multiple files in one operation
- Individual error handling
- Continues processing if one file fails

### Flexible Input
- Tags can be array or comma-separated string
- Optional comment field
- Automatic space trimming

### Native Integration
- Uses macOS native metadata
- Compatible with Finder and Spotlight
- Preserves existing metadata

## Tips

1. **Consistent Naming**: Use consistent tag names across files
2. **Color Coding**: Assign colors to tags in Finder preferences
3. **Smart Folders**: Create smart folders based on tags
4. **Backup**: Metadata is included in Time Machine backups
5. **Search**: Use Spotlight to find files by tags or comments