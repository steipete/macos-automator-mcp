---
id: jxa_clipboard_images
title: JXA Clipboard Image Operations
description: Working with images in the clipboard using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - image
  - png
  - nspasteboard
  - copy
  - paste
  - nsimage
category: 03_jxa_core
---

# JXA Clipboard Image Operations

This script provides functionality for working with images in the clipboard using JavaScript for Automation (JXA).

## Prerequisites

First, make sure to include the Standard Additions library and import the necessary Objective-C frameworks:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Import required frameworks
ObjC.import('AppKit');
```

## Get Image from Clipboard

To read an image from the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

function getImageFromClipboard() {
    const pasteboard = $.NSPasteboard.generalPasteboard;
    
    // Check if clipboard contains an image
    if (pasteboard.dataForType($.NSPasteboardTypePNG)) {
        // Create an image from the clipboard data
        const imageData = pasteboard.dataForType($.NSPasteboardTypePNG);
        const image = $.NSImage.alloc.initWithData(imageData);
        
        if (image) {
            // Get image size
            const size = image.size;
            console.log(`Image found in clipboard: ${size.width} x ${size.height}`);
            return image;
        }
    }
    
    console.log("No image found in clipboard");
    return null;
}

// Use the function
const clipboardImage = getImageFromClipboard();
```

## Set Image to Clipboard

To set an image to the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');
ObjC.import('Foundation');

function setImageToClipboard(imagePath) {
    // Create the file URL
    const fileURL = $.NSURL.fileURLWithPath(imagePath);
    
    // Create an NSImage from the file
    const image = $.NSImage.alloc.initWithContentsOfURL(fileURL);
    
    if (image) {
        // Get image representation as PNG
        const imageRep = image.representations.objectAtIndex(0);
        const imageData = imageRep.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, null);
        
        // Set to pasteboard
        const pasteboard = $.NSPasteboard.generalPasteboard;
        pasteboard.clearContents;
        
        // Write the image data to the pasteboard
        const result = pasteboard.setDataForType(imageData, $.NSPasteboardTypePNG);
        
        if (result) {
            console.log("Image set to clipboard successfully");
            return true;
        }
    }
    
    console.log("Failed to set image to clipboard");
    return false;
}

// Example usage
setImageToClipboard("/Users/username/Pictures/example.png");
```

These image operations can be incorporated into various automation workflows to handle image data through the system clipboard.