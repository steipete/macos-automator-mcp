---
title: Audio Conversion Utility
category: 10_creative
id: audio_conversion_utility
description: >-
  A utility script for converting audio files between formats using macOS afconvert tool.
language: applescript
keywords:
  - convert
  - audio
  - format
  - mp3
  - aac
  - wav
  - aiff
  - flac
  - m4a
  - afconvert
  - bitrate
---

# Audio Conversion Utility

This script provides comprehensive audio format conversion capabilities on macOS, leveraging the built-in `afconvert` command-line tool. It supports various audio formats with configurable quality/bitrate settings.

## Usage

The script can be run standalone with dialogs or via the MCP with parameters.

```applescript
-- Audio Conversion Utility
-- Converts audio files between formats

on run
	-- Interactive mode when run without parameters
	try
		return performAudioConversion()
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
	return convertAudio(inputPath, outputPath, format, quality)
end processMCPParameters

-- Interactive audio conversion
on performAudioConversion()
	set audioFormats to {"mp3", "aac", "wav", "aiff", "flac", "m4a"}
	
	-- Select input file
	set inputFile to choose file with prompt "Select an audio file to convert:" of type {"public.audio"}
	set inputPath to POSIX path of inputFile
	
	-- Select output format
	set selectedFormat to choose from list audioFormats with prompt "Convert to which format?"
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
	set outputFile to choose file name with prompt "Save converted audio as:" default name defaultName
	set outputPath to POSIX path of outputFile
	
	-- Perform conversion
	return convertAudio(inputPath, outputPath, format, quality)
end performAudioConversion

-- Audio conversion function
on convertAudio(inputPath, outputPath, format, quality)
	try
		-- Map format to afconvert format
		set afFormat to ""
		set bitrateFlag to ""
		
		if format is "mp3" then
			set afFormat to "mp3"
			if quality is "low" then
				set bitrateFlag to "-b 128000"
			else if quality is "medium" then
				set bitrateFlag to "-b 192000"
			else if quality is "high" then
				set bitrateFlag to "-b 256000"
			else if quality is "maximum" then
				set bitrateFlag to "-b 320000"
			end if
		else if format is "aac" or format is "m4a" then
			set afFormat to "m4af"
			if quality is "low" then
				set bitrateFlag to "-b 128000"
			else if quality is "medium" then
				set bitrateFlag to "-b 192000"
			else if quality is "high" then
				set bitrateFlag to "-b 256000"
			else if quality is "maximum" then
				set bitrateFlag to "-b 320000"
			end if
		else if format is "wav" then
			set afFormat to "wav"
			-- For WAV, we use different quality settings
			if quality is "low" then
				set bitrateFlag to "-d ui16@44100"
			else if quality is "medium" then
				set bitrateFlag to "-d ui16@48000"
			else if quality is "high" then
				set bitrateFlag to "-d ui24@48000"
			else if quality is "maximum" then
				set bitrateFlag to "-d ui24@96000"
			end if
		else if format is "aiff" then
			set afFormat to "aiff"
			-- Same quality settings as WAV
			if quality is "low" then
				set bitrateFlag to "-d ui16@44100"
			else if quality is "medium" then
				set bitrateFlag to "-d ui16@48000"
			else if quality is "high" then
				set bitrateFlag to "-d ui24@48000"
			else if quality is "maximum" then
				set bitrateFlag to "-d ui24@96000"
			end if
		else if format is "flac" then
			set afFormat to "flac"
			-- For FLAC, we use compression level instead of bitrate
			if quality is "low" then
				set bitrateFlag to "-q 0"
			else if quality is "medium" then
				set bitrateFlag to "-q 5"
			else if quality is "high" then
				set bitrateFlag to "-q 8"
			else if quality is "maximum" then
				set bitrateFlag to "-q 12"
			end if
		else
			return "Error: Unsupported audio format: " & format
		end if
		
		-- Construct the conversion command
		set cmd to "afconvert -f " & afFormat & " " & bitrateFlag & " " & quoted form of inputPath & " " & quoted form of outputPath
		do shell script cmd
		
		return "Audio converted to " & format & " format at " & outputPath
	on error errMsg
		return "Error converting audio: " & errMsg
	end try
end convertAudio

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

- `inputPath`: POSIX path to the input audio file
- `outputPath`: (Optional) POSIX path for the output file
- `format`: Target format (e.g., "mp3", "aac", "wav")
- `quality`: (Optional) Quality level ("low", "medium", "high", "maximum") - defaults to "medium"

## Example Usage

### Convert WAV to MP3

```json
{
  "inputPath": "/Users/username/Music/song.wav",
  "format": "mp3",
  "quality": "medium"
}
```

### Convert to AAC with high quality

```json
{
  "inputPath": "/Users/username/Music/original.mp3",
  "outputPath": "/Users/username/Music/converted.m4a",
  "format": "aac",
  "quality": "high"
}
```

### Convert to FLAC for archival

```json
{
  "inputPath": "/Users/username/Music/master.wav",
  "format": "flac",
  "quality": "maximum"
}
```

## Supported Formats

- **MP3** - Standard compressed format (128-320 kbps)
- **AAC/M4A** - Advanced Audio Coding (128-320 kbps)
- **WAV** - Uncompressed format (16/24-bit, 44.1-96 kHz)
- **AIFF** - Apple's uncompressed format
- **FLAC** - Lossless compression format

## Quality Settings

Quality settings affect different formats differently:

### MP3 and AAC/M4A
- **low**: 128 kbps
- **medium**: 192 kbps  
- **high**: 256 kbps
- **maximum**: 320 kbps

### WAV and AIFF
- **low**: 16-bit, 44.1 kHz
- **medium**: 16-bit, 48 kHz
- **high**: 24-bit, 48 kHz
- **maximum**: 24-bit, 96 kHz

### FLAC
- **low**: Compression level 0 (fastest)
- **medium**: Compression level 5
- **high**: Compression level 8
- **maximum**: Compression level 12 (smallest file)