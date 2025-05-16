---
id: jxa_clipboard_files
title: JXA Clipboard File Path Operations
description: Working with file paths in the clipboard using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - file paths
  - nspasteboard
  - nsurl
  - file operations
  - file transfer
category: 03_jxa_core
---

# JXA Clipboard File Path Operations

This script provides functionality for working with file paths in the clipboard using JavaScript for Automation (JXA).

## Prerequisites

First, make sure to include the Standard Additions library and import the necessary Objective-C frameworks:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Import required frameworks
ObjC.import('AppKit');
```

## Get File Paths from Clipboard

To retrieve file paths from the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

function getFilePathsFromClipboard() {
    const pasteboard = $.NSPasteboard.generalPasteboard;
    
    // Check if clipboard contains file URLs
    if (pasteboard.containsObjectsWithClassesOptions(
            [$.NSURL.class], 
            $.NSDictionary.dictionaryWithObject_forKey(
                $.NSNumber.numberWithInt(1), 
                $.NSPasteboardURLReadingFileURLsOnlyKey
            )
        )) {
        
        // Get the file URLs
        const fileURLs = pasteboard.readObjectsForClasses_options(
            [$.NSURL.class],
            $.NSDictionary.dictionaryWithObject_forKey(
                $.NSNumber.numberWithInt(1), 
                $.NSPasteboardURLReadingFileURLsOnlyKey
            )
        );
        
        if (fileURLs && fileURLs.count > 0) {
            // Convert NSArray to JavaScript array of paths
            const paths = [];
            for (let i = 0; i < fileURLs.count; i++) {
                paths.push(ObjC.unwrap(fileURLs.objectAtIndex(i).path));
            }
            
            console.log(`Found ${paths.length} files in clipboard`);
            return paths;
        }
    }
    
    console.log("No file paths found in clipboard");
    return [];
}

// Use the function
const filePaths = getFilePathsFromClipboard();
if (filePaths.length > 0) {
    // Process the files
    filePaths.forEach((path, index) => {
        console.log(`File ${index + 1}: ${path}`);
    });
}
```

## Set File Paths to Clipboard

To add file paths to the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');
ObjC.import('Foundation');

function setFilePathsToClipboard(filePaths) {
    if (!filePaths || filePaths.length === 0) {
        console.log("No file paths provided");
        return false;
    }
    
    // Convert paths to NSURLs
    const fileURLs = $.NSMutableArray.alloc.init;
    
    filePaths.forEach(path => {
        const url = $.NSURL.fileURLWithPath(path);
        fileURLs.addObject(url);
    });
    
    // Set to pasteboard
    const pasteboard = $.NSPasteboard.generalPasteboard;
    pasteboard.clearContents;
    
    // Write the file URLs to the pasteboard
    const result = pasteboard.writeObjectsForTypes(fileURLs, [$.NSPasteboardTypeFileURL]);
    
    if (result) {
        console.log(`${filePaths.length} file paths set to clipboard successfully`);
        return true;
    }
    
    console.log("Failed to set file paths to clipboard");
    return false;
}

// Example usage
const paths = [
    "/Users/username/Documents/example.txt",
    "/Users/username/Pictures/image.jpg"
];
setFilePathsToClipboard(paths);
```

These file path operations can be used in various automation workflows to handle files through the system clipboard.