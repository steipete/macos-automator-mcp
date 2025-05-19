---
title: Batch Convert Images
category: 05_files
id: batch_convert_images
description: >-
  Convert multiple image files to different formats using the built-in macOS
  sips command, supporting common image formats.
keywords:
  - batch
  - convert
  - images
  - sips
  - format
  - resize
language: applescript
---

# Batch Convert Images

This script converts multiple image files to different formats using the built-in macOS `sips` (Scriptable Image Processing System) command.

## Features

- Convert between common image formats
- Batch process multiple images
- Preserve original files
- Automatic format detection
- Error handling for non-image files

## Usage

```applescript
-- Batch Convert Images
-- Convert images to different formats using sips

on run
	try
		-- Use file selection dialog for interactive mode
		set fileList to chooseFiles()
		
		-- Get target format from user
		set formatList to {"jpeg", "png", "tiff", "gif", "bmp", "pdf"}
		set targetFormat to choose from list formatList with prompt "Select target format:" default items {"png"}
		
		if targetFormat is false then
			return "Operation cancelled"
		end if
		
		set targetFormat to item 1 of targetFormat
		
		return batchConvertImages(fileList, targetFormat)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set fileList to "--MCP_INPUT:fileList"
	set targetFormat to "--MCP_INPUT:targetFormat"
	
	-- Validate parameters
	if fileList is "" or class of fileList is not list then
		return "Error: File list is required and must be a list."
	end if
	
	if targetFormat is "" then
		return "Error: Target format is required."
	end if
	
	-- Validate format
	set validFormats to {"jpeg", "jpg", "png", "tiff", "gif", "bmp", "pdf"}
	if targetFormat is not in validFormats then
		return "Error: Invalid format. Valid formats are: " & my joinList(validFormats, ", ")
	end if
	
	return batchConvertImages(fileList, targetFormat)
end processMCPParameters

-- Choose multiple files for batch processing
on chooseFiles()
	set theFiles to {}
	set dialogResult to (choose file with prompt "Select image files to convert:" with multiple selections allowed)
	
	-- Convert results to a list of POSIX paths
	repeat with aFile in dialogResult
		set end of theFiles to POSIX path of aFile
	end repeat
	
	return theFiles
end chooseFiles

-- Convert image files to different format using sips
on batchConvertImages(fileList, targetFormat)
	set convertedFiles to {}
	set skippedFiles to 0
	
	repeat with filePath in fileList
		set fullPath to filePath as string
		
		-- Get file info
		set {name:baseName, extension:fileExtension} to getFileInfo(fullPath)
		set folderPath to do shell script "dirname " & quoted form of fullPath
		
		-- Ensure it's an image file
		set imageFormats to {"jpg", "jpeg", "png", "tiff", "gif", "bmp", "pdf"}
		if imageFormats does not contain fileExtension then
			log "Skipping non-image file: " & fullPath
			set skippedFiles to skippedFiles + 1
		else
			-- Create output path
			set outputPath to folderPath & "/" & baseName & "." & targetFormat
			
			-- Check if output file already exists
			set fileExists to do shell script "[ -e " & quoted form of outputPath & " ] && echo 'yes' || echo 'no'"
			
			if fileExists is "yes" then
				-- Add timestamp to filename to avoid overwriting
				set currentDate to do shell script "date '+%Y%m%d_%H%M%S'"
				set outputPath to folderPath & "/" & baseName & "_" & currentDate & "." & targetFormat
			end if
			
			-- Convert using sips
			try
				do shell script "sips -s format " & targetFormat & " " & quoted form of fullPath & " --out " & quoted form of outputPath
				set end of convertedFiles to outputPath
			on error errMsg
				log "Error converting " & fullPath & ": " & errMsg
			end try
		end if
	end repeat
	
	set resultMessage to "Converted " & (count of convertedFiles) & " images to " & targetFormat & " format"
	if skippedFiles > 0 then
		set resultMessage to resultMessage & " (skipped " & skippedFiles & " non-image files)"
	end if
	
	return resultMessage
end batchConvertImages

-- Helper function to get file info
on getFileInfo(filePath)
	set fileName to do shell script "basename " & quoted form of filePath
	
	-- Split filename and extension
	set tid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."
	set nameParts to text items of fileName
	
	if (count of nameParts) > 1 then
		set baseName to items 1 thru -2 of nameParts as text
		set fileExtension to item -1 of nameParts
	else
		set baseName to fileName
		set fileExtension to ""
	end if
	
	-- Restore text item delimiters
	set AppleScript's text item delimiters to tid
	
	return {name:baseName, extension:fileExtension}
end getFileInfo

-- Helper function to join list items
on joinList(theList, delimiter)
	set tid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiter
	set theString to theList as text
	set AppleScript's text item delimiters to tid
	return theString
end joinList
```

## MCP Parameters

- `fileList`: Array of image file paths to convert (required)
- `targetFormat`: Target image format (required)

## Supported Formats

- **jpeg/jpg**: JPEG format (lossy compression)
- **png**: PNG format (lossless compression)
- **tiff**: TIFF format (lossless)
- **gif**: GIF format (limited colors)
- **bmp**: Bitmap format
- **pdf**: PDF format

## Example Usage

### Convert photos to PNG
```json
{
  "fileList": [
    "/Users/john/Pictures/photo1.jpg",
    "/Users/john/Pictures/photo2.jpg"
  ],
  "targetFormat": "png"
}
```

### Convert screenshots to JPEG
```json
{
  "fileList": [
    "/Users/john/Desktop/screenshot1.png",
    "/Users/john/Desktop/screenshot2.png"
  ],
  "targetFormat": "jpeg"
}
```

### Convert images to PDF
```json
{
  "fileList": [
    "/Users/john/Documents/scan1.tiff",
    "/Users/john/Documents/scan2.tiff"
  ],
  "targetFormat": "pdf"
}
```

## Use Cases

1. **Web Optimization**: Convert images to JPEG for smaller file sizes
2. **Print Preparation**: Convert to TIFF for high-quality printing
3. **Document Creation**: Convert images to PDF
4. **Transparency Support**: Convert to PNG for transparency
5. **Compatibility**: Convert to widely supported formats

## Features

### Automatic Naming
- Preserves original filename
- Changes only the extension
- Adds timestamp if file exists
- Prevents accidental overwrites

### Format Detection
- Automatically identifies image files
- Skips non-image files
- Logs skipped files
- Continues processing valid images

### Sips Advantages
- Built into macOS (no installation needed)
- Fast and efficient
- Supports many formats
- Command-line based

## Tips

1. **Quality Settings**: JPEG compression can be adjusted with sips
2. **Batch Processing**: Process entire folders of images
3. **Format Choice**:
   - Use JPEG for photos (smaller size)
   - Use PNG for screenshots (lossless)
   - Use TIFF for archival (highest quality)
4. **Original Files**: Original files are preserved

## Advanced Options

The sips command supports additional options:
- Resize images: `--resampleWidth` or `--resampleHeight`
- Adjust quality: `--setProperty formatOptions`
- Rotate images: `--rotate`
- Crop images: `--cropToHeightWidth`

These can be added to the script for more functionality.