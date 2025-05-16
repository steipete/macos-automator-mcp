---
title: Media Conversion Utility
category: 10_creative/image_events_app
id: media_conversion_utility
description: >-
  A utility script for converting media files between formats, including images,
  audio, and video using macOS built-in tools.
language: applescript
keywords:
  - convert
  - media
  - image
  - audio
  - video
  - format
  - png
  - jpg
  - webp
  - gif
  - mp3
  - wav
  - mp4
  - mov
---

# Media Conversion Utility

This script provides a comprehensive utility for converting various media formats on macOS, leveraging built-in system tools. It can handle:

1. Image conversions using Image Events and sips
2. Audio conversions using afconvert
3. Video conversions using AVFoundation via JXA

## Usage

The script can be run standalone with dialogs or via the MCP with parameters.

```applescript
-- Media Conversion Utility
-- Converts media files between formats

on run
	-- Interactive mode when run without parameters
	try
		set conversionTypes to {"Image Conversion", "Audio Conversion", "Video Conversion"}
		set selectedType to choose from list conversionTypes with prompt "Select the type of conversion:" default items {"Image Conversion"}
		
		if selectedType is false then
			return "Conversion cancelled."
		end if
		
		set selectedType to item 1 of selectedType
		
		if selectedType is "Image Conversion" then
			return performImageConversion()
		else if selectedType is "Audio Conversion" then
			return performAudioConversion()
		else if selectedType is "Video Conversion" then
			return performVideoConversion()
		end if
		
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	set conversionType to "--MCP_INPUT:conversionType"
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
	
	-- Perform the appropriate conversion
	if conversionType is equal to "image" then
		return convertImage(inputPath, outputPath, format, quality)
	else if conversionType is equal to "audio" then
		return convertAudio(inputPath, outputPath, format, quality)
	else if conversionType is equal to "video" then
		return convertVideo(inputPath, outputPath, format, quality)
	else
		return "Error: Invalid conversion type. Use 'image', 'audio', or 'video'."
	end if
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

-- Interactive video conversion
on performVideoConversion()
	set videoFormats to {"mp4", "mov", "m4v"}
	
	-- Select input file
	set inputFile to choose file with prompt "Select a video file to convert:" of type {"public.movie"}
	set inputPath to POSIX path of inputFile
	
	-- Select output format
	set selectedFormat to choose from list videoFormats with prompt "Convert to which format?"
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
	set outputFile to choose file name with prompt "Save converted video as:" default name defaultName
	set outputPath to POSIX path of outputFile
	
	-- Perform conversion
	return convertVideo(inputPath, outputPath, format, quality)
end performVideoConversion

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

-- Video conversion function (uses JXA for AVFoundation access)
on convertVideo(inputPath, outputPath, format, quality)
	-- We'll use a JXA script to leverage AVFoundation
	set jxaScript to "
function run(argv) {
  const inputPath = argv[0];
  const outputPath = argv[1];
  const format = argv[2];
  const quality = argv[3];
  
  try {
    // Create an AVAsset from the input file
    const AVURLAsset = $.AVURLAsset.alloc.initWithURLOptions(
      $.NSURL.fileURLWithPath(inputPath),
      null
    );
    
    // Create an export session
    const exporter = $.AVAssetExportSession.alloc.initWithAssetPresetName(
      AVURLAsset,
      getPresetForQuality(quality)
    );
    
    // Set output URL and file type
    exporter.outputURL = $.NSURL.fileURLWithPath(outputPath);
    exporter.outputFileType = getOutputFileType(format);
    
    // Set up completion handler using a semaphore to make it synchronous
    const semaphore = $.dispatch.semaphore(0);
    var exportError = null;
    
    exporter.exportAsynchronouslyWithCompletionHandler(function() {
      if (exporter.status === 2) { // Completed
        $.dispatch.semaphore_signal(semaphore);
      } else if (exporter.status === 3) { // Failed
        exportError = exporter.error.localizedDescription.js;
        $.dispatch.semaphore_signal(semaphore);
      }
    });
    
    // Wait for completion (with timeout)
    const timeout = 60 * 60; // 1 hour in seconds
    const result = $.dispatch.semaphore_wait(semaphore, 
      $.dispatch.time($.dispatch.TIME_NOW, timeout * 1000000000));
    
    if (result !== 0) {
      return 'Error: Conversion timed out after ' + timeout + ' seconds';
    }
    
    if (exportError) {
      return 'Error during conversion: ' + exportError;
    }
    
    return 'Video converted to ' + format + ' format at ' + outputPath;
  } catch (error) {
    return 'Error: ' + error.message;
  }
}

// Helper function to get preset based on quality
function getPresetForQuality(quality) {
  switch (quality) {
    case 'low':
      return 'AVAssetExportPresetLowQuality';
    case 'medium':
      return 'AVAssetExportPresetMediumQuality';
    case 'high':
      return 'AVAssetExportPreset1280x720';
    case 'maximum':
      return 'AVAssetExportPresetHighestQuality';
    default:
      return 'AVAssetExportPresetMediumQuality';
  }
}

// Helper function to get output file type
function getOutputFileType(format) {
  switch (format.toLowerCase()) {
    case 'mp4':
      return 'public.mpeg-4';
    case 'mov':
      return 'com.apple.quicktime-movie';
    case 'm4v':
      return 'com.apple.m4v-video';
    default:
      return 'public.mpeg-4';
  }
}
"
	
	-- Create a temporary file for the JXA script
	set tempFile to (path to temporary items as text) & "videoconvert.js"
	set tempFilePosix to POSIX path of tempFile
	
	try
		-- Write the JXA script to the temp file
		do shell script "cat > " & quoted form of tempFilePosix & " << 'EOF'
" & jxaScript & "
EOF"
		
		-- Set execute permissions
		do shell script "chmod +x " & quoted form of tempFilePosix
		
		-- Run the JXA script
		set result to do shell script "osascript -l JavaScript " & quoted form of tempFilePosix & " " & quoted form of inputPath & " " & quoted form of outputPath & " " & quoted form of format & " " & quoted form of quality
		
		-- Clean up
		do shell script "rm " & quoted form of tempFilePosix
		
		return result
	on error errMsg
		-- Clean up even on error
		try
			do shell script "rm " & quoted form of tempFilePosix
		end try
		return "Error converting video: " & errMsg
	end try
end convertVideo

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

- `conversionType`: Type of conversion to perform ("image", "audio", or "video")
- `inputPath`: POSIX path to the input file
- `outputPath`: (Optional) POSIX path for the output file
- `format`: Target format (e.g., "jpeg", "mp3", "mp4")
- `quality`: (Optional) Quality level ("low", "medium", "high", "maximum") - defaults to "medium"

## Example Usage

### Convert an image to PNG format

```json
{
  "conversionType": "image",
  "inputPath": "/Users/username/Pictures/photo.jpg",
  "format": "png",
  "quality": "high"
}
```

### Convert an audio file to MP3

```json
{
  "conversionType": "audio",
  "inputPath": "/Users/username/Music/song.wav",
  "format": "mp3",
  "quality": "medium"
}
```

### Convert a video to MP4

```json
{
  "conversionType": "video",
  "inputPath": "/Users/username/Movies/video.mov",
  "outputPath": "/Users/username/Movies/converted_video.mp4",
  "format": "mp4",
  "quality": "high"
}
```

## Supported Formats

### Image Formats
- JPEG (jpg, jpeg)
- PNG
- TIFF
- GIF
- BMP
- WebP (requires cwebp or GraphicConverter)
- HEIC (requires macOS 10.13+)

### Audio Formats
- MP3
- AAC/M4A
- WAV
- AIFF
- FLAC

### Video Formats
- MP4
- MOV (QuickTime)
- M4V
