---
title: Video Conversion Utility
category: 10_creative
id: video_conversion_utility
description: >-
  A utility script for converting video files between formats using macOS AVFoundation framework.
language: javascript
keywords:
  - convert
  - video
  - format
  - mp4
  - mov
  - m4v
  - avfoundation
  - quality
  - preset
---

# Video Conversion Utility

This script provides video format conversion capabilities on macOS using the AVFoundation framework through JavaScript for Automation (JXA). It supports common video formats with configurable quality presets.

## Usage

The script can be run standalone with dialogs or via the MCP with parameters.

```javascript
// Video Conversion Utility
// Converts video files between formats using AVFoundation

function run(argv) {
  // Check if we have command line arguments or are running interactively
  if (argv && argv.length > 0) {
    // MCP mode - parse parameters
    return processMCPParameters(argv);
  } else {
    // Interactive mode
    return performVideoConversion();
  }
}

// Handle MCP parameters
function processMCPParameters(argv) {
  // Parse input parameters from argv
  const inputPath = argv[0] || "";
  const outputPath = argv[1] || "";
  const format = argv[2] || "";
  const quality = argv[3] || "medium";
  
  // Validate required parameters
  if (!inputPath) {
    return JSON.stringify({success: false, error: "Input path is required"});
  }
  
  if (!format) {
    return JSON.stringify({success: false, error: "Target format is required"});
  }
  
  // If output path not specified, create one in the same directory
  let finalOutputPath = outputPath;
  if (!finalOutputPath) {
    const inputFile = $.NSString.alloc.initWithUTF8String(inputPath);
    const directory = inputFile.stringByDeletingLastPathComponent;
    const filename = inputFile.lastPathComponent.stringByDeletingPathExtension;
    finalOutputPath = `${directory}/${filename}.${format}`;
  }
  
  // Perform the conversion
  return convertVideo(inputPath, finalOutputPath, format, quality);
}

// Interactive video conversion
function performVideoConversion() {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  try {
    // Select input file
    const inputFile = app.chooseFile({
      withPrompt: "Select a video file to convert:",
      ofType: ["public.movie"]
    });
    const inputPath = inputFile.toString();
    
    // Select output format
    const formats = ["mp4", "mov", "m4v"];
    const selectedFormat = app.chooseFromList(formats, {
      withPrompt: "Convert to which format?",
      defaultItems: ["mp4"]
    });
    
    if (!selectedFormat || selectedFormat.length === 0) {
      return "Conversion cancelled.";
    }
    const format = selectedFormat[0];
    
    // Select quality
    const qualityLevels = ["low", "medium", "high", "maximum"];
    const selectedQuality = app.chooseFromList(qualityLevels, {
      withPrompt: "Select quality level:",
      defaultItems: ["medium"]
    });
    
    if (!selectedQuality || selectedQuality.length === 0) {
      return "Conversion cancelled.";
    }
    const quality = selectedQuality[0];
    
    // Set output location
    const inputNSString = $.NSString.alloc.initWithUTF8String(inputPath);
    const defaultName = inputNSString.lastPathComponent.stringByDeletingPathExtension.js + "." + format;
    
    const outputFile = app.chooseFileName({
      withPrompt: "Save converted video as:",
      defaultName: defaultName
    });
    const outputPath = outputFile.toString();
    
    // Perform conversion
    return convertVideo(inputPath, outputPath, format, quality);
  } catch (error) {
    return "Error: " + error.message;
  }
}

// Video conversion function
function convertVideo(inputPath, outputPath, format, quality) {
  try {
    // Create an AVAsset from the input file
    const inputURL = $.NSURL.fileURLWithPath(inputPath);
    const asset = $.AVURLAsset.alloc.initWithURLOptions(inputURL, null);
    
    // Determine export preset based on quality
    const preset = getPresetForQuality(quality);
    
    // Check if the preset is compatible with the asset
    const compatiblePresets = $.AVAssetExportSession.exportPresetsCompatibleWithAsset(asset);
    let presetAvailable = false;
    
    for (let i = 0; i < compatiblePresets.count; i++) {
      if (compatiblePresets.objectAtIndex(i).js === preset) {
        presetAvailable = true;
        break;
      }
    }
    
    if (!presetAvailable) {
      return "Error: Quality preset '" + quality + "' is not compatible with this video file.";
    }
    
    // Create export session
    const exportSession = $.AVAssetExportSession.alloc.initWithAssetPresetName(asset, preset);
    
    // Set output URL and file type
    exportSession.outputURL = $.NSURL.fileURLWithPath(outputPath);
    exportSession.outputFileType = getOutputFileType(format);
    
    // Set up completion handler using a dispatch group
    const dispatchGroup = $.NSDispatchGroup.alloc.init;
    dispatchGroup.enter;
    
    let exportError = null;
    let exportCompleted = false;
    
    // Export the video
    exportSession.exportAsynchronouslyWithCompletionHandler(function() {
      const status = exportSession.status;
      
      if (status === $.AVAssetExportSessionStatusCompleted) {
        exportCompleted = true;
      } else if (status === $.AVAssetExportSessionStatusFailed) {
        exportError = exportSession.error.localizedDescription.js;
      } else if (status === $.AVAssetExportSessionStatusCancelled) {
        exportError = "Export was cancelled";
      }
      
      dispatchGroup.leave;
    });
    
    // Wait for completion (with timeout)
    const timeout = 60 * 60; // 1 hour in seconds
    const result = dispatchGroup.waitTimeout($.dispatch_time($.DISPATCH_TIME_NOW, timeout * 1000000000));
    
    if (result !== 0) {
      return "Error: Conversion timed out after " + timeout + " seconds";
    }
    
    if (exportError) {
      return "Error during conversion: " + exportError;
    }
    
    if (exportCompleted) {
      return "Video converted to " + format + " format at " + outputPath;
    }
    
    return "Error: Unknown export status";
    
  } catch (error) {
    return "Error converting video: " + error.message;
  }
}

// Helper function to get preset based on quality
function getPresetForQuality(quality) {
  switch (quality) {
    case "low":
      return $.AVAssetExportPresetLowQuality;
    case "medium":
      return $.AVAssetExportPresetMediumQuality;
    case "high":
      return $.AVAssetExportPreset1280x720;
    case "maximum":
      return $.AVAssetExportPresetHighestQuality;
    default:
      return $.AVAssetExportPresetMediumQuality;
  }
}

// Helper function to get output file type
function getOutputFileType(format) {
  switch (format.toLowerCase()) {
    case "mp4":
      return $.AVFileTypeMPEG4;
    case "mov":
      return $.AVFileTypeQuickTimeMovie;
    case "m4v":
      return $.AVFileTypeAppleM4V;
    default:
      return $.AVFileTypeMPEG4;
  }
}
```

## Example Input Parameters

When using with MCP, you can provide these parameters as arguments:

- `inputPath`: POSIX path to the input video file
- `outputPath`: (Optional) POSIX path for the output file
- `format`: Target format ("mp4", "mov", or "m4v")
- `quality`: (Optional) Quality level ("low", "medium", "high", "maximum") - defaults to "medium"

## Example Usage

### Convert MOV to MP4

```json
{
  "args": [
    "/Users/username/Movies/video.mov",
    "",
    "mp4",
    "medium"
  ]
}
```

### Convert to M4V with high quality

```json
{
  "args": [
    "/Users/username/Movies/original.mov",
    "/Users/username/Movies/converted.m4v",
    "m4v",
    "high"
  ]
}
```

### Convert with maximum quality

```json
{
  "args": [
    "/Users/username/Movies/raw_footage.mov",
    "/Users/username/Movies/final_video.mp4",
    "mp4",
    "maximum"
  ]
}
```

## Supported Formats

- **MP4** - MPEG-4 format (most compatible)
- **MOV** - QuickTime format (Apple native)
- **M4V** - Apple's MP4 variant (iTunes compatible)

## Quality Presets

The quality settings use AVFoundation's built-in presets:

- **low**: Uses AVAssetExportPresetLowQuality - Suitable for mobile/web streaming
- **medium**: Uses AVAssetExportPresetMediumQuality - Balanced quality and file size
- **high**: Uses AVAssetExportPreset1280x720 - 720p resolution
- **maximum**: Uses AVAssetExportPresetHighestQuality - Best available quality

Note: The actual output quality depends on the input video's quality and the chosen preset's compatibility with the source material.

## Technical Notes

- The script uses AVFoundation for video processing, which provides hardware acceleration when available
- Export times vary based on video length, resolution, and complexity
- A 1-hour timeout is set for the conversion process
- The script checks preset compatibility before attempting conversion
- File type constants are mapped to the appropriate AVFoundation types