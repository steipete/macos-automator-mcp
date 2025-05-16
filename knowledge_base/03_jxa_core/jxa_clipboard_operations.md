---
id: jxa_clipboard_operations
title: Clipboard Operations with JXA
description: Manage clipboard contents using JavaScript for Automation
language: javascript
keywords: ["clipboard", "copy", "paste", "text manipulation", "file transfer"]
---

# Clipboard Operations with JXA

JavaScript for Automation (JXA) provides methods to read from and write to the macOS clipboard.

## Prerequisites

First, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## Get Text from Clipboard

To read text content from the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Get text from clipboard
const clipboardText = app.theClipboard();
console.log("Clipboard contains: " + clipboardText);
```

## Set Text to Clipboard

To write text content to the clipboard:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Set text to clipboard
const textToSet = "This text is now in the clipboard";
app.setTheClipboardTo(textToSet);
console.log("Clipboard content set");
```

## Check if Clipboard Contains Text

To verify if the clipboard contains text:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Try to get text from clipboard
try {
    const clipboardText = app.theClipboard();
    if (clipboardText && clipboardText.length > 0) {
        console.log("Clipboard contains text: " + clipboardText);
    } else {
        console.log("Clipboard is empty or doesn't contain text");
    }
} catch (error) {
    console.log("Clipboard doesn't contain text data");
}
```

## Set Rich Text to Clipboard

To set styled (RTF) text to the clipboard, you can use an NSAttributedString:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Use Objective-C bridge
ObjC.import('AppKit');

// Create a mutable attributed string
const string = $.NSMutableAttributedString.alloc.initWithString('Hello, World!');

// Apply some styling
const range = $.NSMakeRange(0, 5); // Range for "Hello"
const boldFont = $.NSFont.boldSystemFontOfSize(16);
string.addAttributeValueRange($.NSFontAttributeName, boldFont, range);

// Red color for "Hello"
const redColor = $.NSColor.redColor;
string.addAttributeValueRange($.NSForegroundColorAttributeName, redColor, range);

// Set to pasteboard
const pasteboard = $.NSPasteboard.generalPasteboard;
pasteboard.clearContents;
pasteboard.writeObjectsForTypes([string], [$.NSPasteboardTypeRTF]);

console.log("Rich text set to clipboard");
```

## Working with Images in Clipboard

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

## Working with Files in Clipboard

To get file paths from the clipboard:

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

To set file paths to the clipboard:

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

## Clipboard Manager for Multiple Items

A simple clipboard manager to store and recall multiple clipboard items:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

class ClipboardManager {
    constructor(maxItems = 10) {
        this.items = [];
        this.maxItems = maxItems;
    }
    
    // Add current clipboard content to history
    saveCurrentClipboard() {
        try {
            const content = app.theClipboard();
            if (content && content.length > 0) {
                // Add to the beginning of the array
                this.items.unshift(content);
                
                // Keep array within maxItems limit
                if (this.items.length > this.maxItems) {
                    this.items.pop();
                }
                
                console.log(`Saved clipboard item: "${this._truncate(content, 30)}"`);
                return true;
            }
        } catch (error) {
            console.log("Could not save clipboard content: " + error);
        }
        return false;
    }
    
    // Restore a specific item to the clipboard
    restoreItem(index) {
        if (index >= 0 && index < this.items.length) {
            try {
                app.setTheClipboardTo(this.items[index]);
                console.log(`Restored clipboard item ${index + 1}: "${this._truncate(this.items[index], 30)}"`);
                return true;
            } catch (error) {
                console.log(`Could not restore clipboard item ${index + 1}: ${error}`);
            }
        } else {
            console.log(`Invalid item index: ${index}`);
        }
        return false;
    }
    
    // Show all stored items
    listItems() {
        if (this.items.length === 0) {
            console.log("No items in clipboard history");
            return [];
        }
        
        console.log("Clipboard History:");
        this.items.forEach((item, index) => {
            console.log(`${index + 1}: "${this._truncate(item, 50)}"`);
        });
        
        return this.items;
    }
    
    // Clear all stored items
    clearHistory() {
        this.items = [];
        console.log("Clipboard history cleared");
    }
    
    // Helper method to truncate long strings
    _truncate(str, maxLength) {
        if (str.length <= maxLength) return str;
        return str.substring(0, maxLength) + "...";
    }
}

// Usage example
const clipManager = new ClipboardManager(5);

// Save current clipboard
clipManager.saveCurrentClipboard();

// Set something new to the clipboard
app.setTheClipboardTo("New clipboard content");
clipManager.saveCurrentClipboard();

// List all saved items
clipManager.listItems();

// Restore the first saved item
clipManager.restoreItem(0);
```

These examples demonstrate the various ways JXA can interact with the clipboard in macOS, providing powerful capabilities for clipboard management and automation.