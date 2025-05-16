---
title: Image Conversion Utility
category: 10_creative
id: image_conversion_utility
description: >-
  A utility script for converting images between various formats using macOS built-in tools.
language: applescript
keywords:
  - convert
  - image
  - format
  - png
  - jpg
  - webp
  - gif
  - heic
  - tiff
  - bmp
  - sips
  - quality
---

# Image Conversion Utility

This script provides comprehensive image format conversion capabilities on macOS, leveraging built-in system tools like sips and Image Events. It supports a wide range of image formats with configurable quality settings.

## Usage

The script can be run standalone with dialogs or via the MCP with parameters.

```applescript
-- Image Conversion Utility
-- Converts image files between formats

on run
	-- Interactive mode when run without parameters
	try
		return performImageConversion()
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	set inputPath to "--MCP_INPUT:inputPath"
	set outputPath to "--MCP_INPUT:outputPath"
	set format to "--MCP_INPUT:format"
	set quality to "--MCP_INPUT:quality"
	
	-- Default quality if not specified
	if quality is equal to "" then
		set quality to "medium"
	end if
	
	-- Validate required parameters
	if inputPath is equal to "" then
		return "Error: Input path is required"
	end if
	
	if format is equal to "" then
		return "Error: Target format is required"
	end if
	
	-- If output path not specified, create one in the same directory
	if outputPath is equal to "" then
		set inputInfo to my getFileInfo(inputPath)
		set fileName to name of inputInfo
		set containingFolder to POSIX path of (container of inputInfo as text)
		set baseName to my getBaseName(fileName)
		set outputPath to containingFolder & baseName & "." & format
	end if
	
	-- Perform the conversion
	return convertImage(inputPath, outputPath, format, quality)
end processMCPParameters

-- Interactive image conversion
on performImageConversion()
	set imageFormats to {"jpeg", "png", "tiff", "gif", "bmp", "webp", "heic"}
	
	-- Select input file
	set inputFile to choose file with prompt "Select an image file to convert:" of type {"public.image"}
	set inputPath to POSIX path of inputFile
	
	-- Select output format
	set selectedFormat to choose from list imageFormats with prompt "Convert to which format?"
	if selectedFormat is false then
		return "Conversion cancelled."
	end if
	set format to item 1 of selectedFormat
	
	-- Select quality
	set qualityLevels to {"low", "medium", "high", "maximum"}
	set selectedQuality to choose from list qualityLevels with prompt "Select quality level:" default items {"medium"}
	if selectedQuality is false then
		return "Conversion cancelled."
	end if
	set quality to item 1 of selectedQuality
	
	-- Set output location
	set defaultName to my getBaseName(my getFileName(inputPath)) & "." & format
	set outputFile to choose file name with prompt "Save converted image as:" default name defaultName
	set outputPath to POSIX path of outputFile
	
	-- Perform conversion
	return convertImage(inputPath, outputPath, format, quality)
end performImageConversion

-- Image conversion function
on convertImage(inputPath, outputPath, format, quality)
	try
		-- Map quality setting to parameters
		set qualityParam to ""
		if format is in {"jpeg", "jpg"} then
			if quality is "low" then
				set qualityParam to "--setProperty formatOptions 0.5"
			else if quality is "medium" then
				set qualityParam to "--setProperty formatOptions 0.8"
			else if quality is "high" then
				set qualityParam to "--setProperty formatOptions 0.9"
			else if quality is "maximum" then
				set qualityParam to "--setProperty formatOptions 1.0"
			end if
		else if format is "png" then
			if quality is "low" then
				set qualityParam to "--setProperty formatOptions low"
			else if quality is "medium" then
				set qualityParam to "--setProperty formatOptions normal"
			else if quality is "high" or quality is "maximum" then
				set qualityParam to "--setProperty formatOptions best"
			end if
		end if
		
		-- Handle different image conversion methods based on format
		if format is in {"jpeg", "jpg", "png", "tiff", "gif"} then
			-- Use sips for standard formats
			set cmd to "sips -s format " & format & " " & qualityParam & " " & quoted form of inputPath & " --out " & quoted form of outputPath
			do shell script cmd
			return "Image converted to " & format & " format at " & outputPath
		else if format is "webp" then
			-- For WebP, check if cwebp is available, otherwise use Image Events with GraphicConverter if available
			try
				do shell script "which cwebp"
				set qualityNum to "75" -- medium quality default
				if quality is "low" then
					set qualityNum to "50"
				else if quality is "high" then
					set qualityNum to "90"
				else if quality is "maximum" then
					set qualityNum to "100"
				end if
				
				set cmd to "cwebp -q " & qualityNum & " " & quoted form of inputPath & " -o " & quoted form of outputPath
				do shell script cmd
				return "Image converted to WebP format at " & outputPath
			on error
				-- Try using Image Events
				try
					tell application "Image Events"
						launch
						set theImage to open inputPath
						save theImage as format in outputPath
						close theImage
					end tell
					return "Image converted to " & format & " format at " & outputPath
				on error
					return "Error: WebP conversion requires cwebp or GraphicConverter. Please install one of these tools."
				end try
			end try
		else if format is "heic" then
			-- For HEIC, use sips on macOS 10.13+
			try
				set cmd to "sips -s format heic " & qualityParam & " " & quoted form of inputPath & " --out " & quoted form of outputPath
				do shell script cmd
				return "Image converted to HEIC format at " & outputPath
			on error
				return "Error: HEIC conversion requires macOS 10.13 or later."
			end try
		else
			return "Error: Unsupported image format: " & format
		end if
	on error errMsg
		return "Error converting image: " & errMsg
	end try
end convertImage

-- Utility function to get file information
on getFileInfo(filePath)
	tell application "System Events"
		return info for file filePath
	end tell
end getFileInfo

-- Utility function to extract filename from path
on getFileName(filePath)
	return do shell script "basename " & quoted form of filePath
end getFileName

-- Utility function to get base name without extension
on getBaseName(fileName)
	return do shell script "basename " & quoted form of fileName & " $(echo " & quoted form of fileName & " | grep -o '\\.[^\\.]*$')"
end getBaseName
```

## Example Input Parameters

When using with MCP, you can provide these parameters:

- `inputPath`: POSIX path to the input image file
- `outputPath`: (Optional) POSIX path for the output file
- `format`: Target format (e.g., "jpeg", "png", "webp")
- `quality`: (Optional) Quality level ("low", "medium", "high", "maximum") - defaults to "medium"

## Example Usage

### Convert a JPEG to PNG format

```json
{
  "inputPath": "/Users/username/Pictures/photo.jpg",
  "format": "png",
  "quality": "high"
}
```

### Convert an image to WebP with custom output path

```json
{
  "inputPath": "/Users/username/Pictures/original.png",
  "outputPath": "/Users/username/Pictures/converted.webp",
  "format": "webp",
  "quality": "medium"
}
```

### Convert to HEIC format (macOS 10.13+)

```json
{
  "inputPath": "/Users/username/Pictures/large_photo.jpg",
  "format": "heic",
  "quality": "maximum"
}
```

## Supported Formats

- **JPEG** (jpg, jpeg) - Standard lossy compression format
- **PNG** - Lossless compression format with transparency support
- **TIFF** - Professional/archival format
- **GIF** - Animated image format
- **BMP** - Bitmap format
- **WebP** - Modern web format (requires cwebp or GraphicConverter)
- **HEIC** - High Efficiency Image Format (requires macOS 10.13+)

## Quality Settings

- **low**: Smaller file sizes, lower quality
- **medium**: Balanced quality and file size (default)
- **high**: Higher quality, larger files
- **maximum**: Best quality, largest files

The quality setting impacts different formats differently:
- JPEG: Affects compression ratio (0.5 to 1.0)
- PNG: Affects compression level
- WebP: Affects quality level (50 to 100)
- Other formats may have fixed quality based on the format specification