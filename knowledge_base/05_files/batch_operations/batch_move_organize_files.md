---
title: Batch Move and Organize Files
category: 05_files
id: batch_move_organize_files
description: >-
  Move multiple files to a target folder with optional organization by creation
  date, automatically creating date-based subfolders for better file management.
keywords:
  - batch
  - move
  - organize
  - date
  - folders
  - files
language: applescript
---

# Batch Move and Organize Files

This script moves multiple files to a target folder with optional organization by creation date, creating date-based subfolders automatically.

## Features

- Batch move multiple files
- Optional organization by creation date
- Automatic date-based folder creation
- Preserves original filenames
- Error logging for failed operations

## Usage

```applescript
-- Batch Move and Organize Files
-- Move files with optional date-based organization

on run
	try
		-- Use file selection dialog for interactive mode
		set fileList to chooseFiles()
		set targetFolder to chooseFolder()
		
		-- Ask about date organization
		set organizeByDate to button returned of (display dialog "Organize files by creation date?" buttons {"No", "Yes"} default button "Yes") is "Yes"
		
		return batchMove(fileList, targetFolder, organizeByDate)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set fileList to "--MCP_INPUT:fileList"
	set targetFolder to "--MCP_INPUT:targetFolder"
	set organizeByDate to "--MCP_INPUT:organizeByDate"
	
	-- Default values
	if organizeByDate is "" then
		set organizeByDate to false
	else
		try
			set organizeByDate to organizeByDate as boolean
		on error
			set organizeByDate to false
		end try
	end if
	
	-- Validate parameters
	if fileList is "" or class of fileList is not list then
		return "Error: File list is required and must be a list."
	end if
	
	if targetFolder is "" then
		return "Error: Target folder is required."
	end if
	
	return batchMove(fileList, targetFolder, organizeByDate)
end processMCPParameters

-- Choose multiple files for batch processing
on chooseFiles()
	set theFiles to {}
	set dialogResult to (choose file with prompt "Select files to move:" with multiple selections allowed)
	
	-- Convert results to a list of POSIX paths
	repeat with aFile in dialogResult
		set end of theFiles to POSIX path of aFile
	end repeat
	
	return theFiles
end chooseFiles

-- Choose a folder as target for operations
on chooseFolder()
	set theFolder to choose folder with prompt "Select target folder:"
	return POSIX path of theFolder
end chooseFolder

-- Move files to target folder, optionally organizing by creation date
on batchMove(fileList, targetFolder, organizeByDate)
	set movedFiles to {}
	
	repeat with filePath in fileList
		set fullPath to filePath as string
		set fileName to do shell script "basename " & quoted form of fullPath
		
		-- Determine destination path
		if organizeByDate then
			-- Get file creation date
			set fileDate to do shell script "stat -f '%SB' -t '%Y-%m-%d' " & quoted form of fullPath
			set dateFolder to targetFolder & "/" & fileDate
			
			-- Create date folder if it doesn't exist
			do shell script "mkdir -p " & quoted form of dateFolder
			set destPath to dateFolder & "/" & fileName
		else
			set destPath to targetFolder & "/" & fileName
		end if
		
		-- Move the file
		try
			do shell script "mv " & quoted form of fullPath & " " & quoted form of destPath
			set end of movedFiles to destPath
		on error errMsg
			log "Error moving " & fullPath & ": " & errMsg
		end try
	end repeat
	
	if organizeByDate then
		return "Moved " & (count of movedFiles) & " files, organized by date"
	else
		return "Moved " & (count of movedFiles) & " files to target folder"
	end if
end batchMove
```

## MCP Parameters

- `fileList`: Array of file paths to move (required)
- `targetFolder`: Destination folder path (required)
- `organizeByDate`: Boolean to organize by creation date (default: false)

## Example Usage

### Simple batch move
```json
{
  "fileList": [
    "/Users/john/Downloads/file1.pdf",
    "/Users/john/Downloads/file2.pdf"
  ],
  "targetFolder": "/Users/john/Documents/PDFs",
  "organizeByDate": false
}
```

### Organize photos by date
```json
{
  "fileList": [
    "/Users/john/Downloads/IMG_001.jpg",
    "/Users/john/Downloads/IMG_002.jpg",
    "/Users/john/Downloads/IMG_003.jpg"
  ],
  "targetFolder": "/Users/john/Pictures/Organized",
  "organizeByDate": true
}
```

### Archive project files by date
```json
{
  "fileList": [
    "/Users/john/Desktop/report.doc",
    "/Users/john/Desktop/presentation.ppt",
    "/Users/john/Desktop/data.xlsx"
  ],
  "targetFolder": "/Users/john/Archive/2024",
  "organizeByDate": true
}
```

## Date Organization

When `organizeByDate` is enabled:
- Files are organized into subfolders named by creation date (YYYY-MM-DD)
- Folders are created automatically if they don't exist
- Files created on the same day go into the same folder

### Example folder structure:
```
/Target Folder/
├── 2024-01-15/
│   ├── photo1.jpg
│   └── photo2.jpg
├── 2024-01-16/
│   ├── document.pdf
│   └── spreadsheet.xlsx
└── 2024-01-17/
    └── presentation.ppt
```

## Use Cases

1. **Photo Organization**: Sort photos by date taken
2. **Download Management**: Clean up Downloads folder
3. **Project Archival**: Archive project files by completion date
4. **Document Filing**: Organize documents chronologically
5. **Backup Preparation**: Prepare files for date-based backup

## Features

### Automatic Folder Creation
- Date folders are created automatically
- No need to manually create folder structure
- Uses YYYY-MM-DD format for consistent sorting

### File Preservation
- Original filenames are preserved
- Only the location changes, not the file itself
- File attributes remain unchanged

### Error Handling
- Failed moves are logged but don't stop the process
- Returns count of successfully moved files
- Original files remain if move fails

## Tips

1. **Test First**: Try with a small batch before processing many files
2. **Check Space**: Ensure target drive has sufficient space
3. **Permissions**: Verify write permissions on target folder
4. **Duplicates**: Check for existing files with same names