---
id: jxa_file_dialogs
title: File Selection Dialogs with JXA
description: Use JavaScript for Automation to create file and folder selection dialogs
language: javascript
keywords:
  - file selection
  - folder selection
  - file picker
  - save dialog
  - finder integration
category: 03_jxa_core
---

# File Selection Dialogs with JXA

JavaScript for Automation (JXA) provides several methods to create file and folder selection dialogs.

## Prerequisites

First, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## Choose File Dialog

To let the user select an existing file:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const filePath = app.chooseFile({
        withPrompt: "Please select a file",
        ofType: ["public.text", "public.image"], // Optional: limit by file types
        defaultLocation: app.pathTo("desktop") // Optional: set starting location
    });
    
    console.log("Selected file: " + filePath);
    // Now you can process the selected file...
} catch (error) {
    // User cancelled the dialog
    console.log("No file was selected");
}
```

## Choose Folder Dialog

To let the user select a folder:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const folderPath = app.chooseFolder({
        withPrompt: "Please select a folder",
        defaultLocation: app.pathTo("home") // Optional: set starting location
    });
    
    console.log("Selected folder: " + folderPath);
    // Now you can process the selected folder...
} catch (error) {
    // User cancelled the dialog
    console.log("No folder was selected");
}
```

## Save File Dialog

To let the user specify a location to save a file:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const savePath = app.chooseFileName({
        withPrompt: "Save file as:",
        defaultName: "Untitled.txt", // Default filename
        defaultLocation: app.pathTo("documents") // Default save location
    });
    
    console.log("Save location: " + savePath);
    // Now you can save to this location...
} catch (error) {
    // User cancelled the dialog
    console.log("Save operation cancelled");
}
```

## Multiple File Selection

To let the user select multiple files:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const files = app.chooseFile({
        withPrompt: "Select files to process",
        multipleSelectionsAllowed: true, // Allow selecting multiple files
        defaultLocation: app.pathTo("documents")
    });
    
    console.log("Selected files: " + files.length);
    
    // Process each selected file
    files.forEach(function(file, index) {
        console.log(`File ${index + 1}: ${file}`);
        // Process this file...
    });
} catch (error) {
    // User cancelled the dialog
    console.log("No files were selected");
}
```

## Working with Finder and Selected Files

Once you have a file path, you can get a Finder reference to it:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;
const finder = Application("Finder");

try {
    const filePath = app.chooseFile({
        withPrompt: "Please select a file"
    });
    
    // Get a Finder reference to work with file attributes
    const fileRef = finder.items[filePath];
    
    // Get file information
    console.log(`Name: ${fileRef.name()}`);
    console.log(`Size: ${fileRef.size()} bytes`);
    console.log(`Created: ${fileRef.creationDate()}`);
    console.log(`Modified: ${fileRef.modificationDate()}`);
    console.log(`Kind: ${fileRef.kind()}`);
    
    // You can also make changes to the file if needed
    // fileRef.comment = "My special file";
    
} catch (error) {
    console.log("Operation cancelled or error occurred: " + error);
}
```

## Helper Function: Get Finder Object from Path

This function helps convert a full path to a Finder file/folder reference:

```javascript
function getFinderItemFromPath(fullPath) {
    const finder = Application("Finder");
    
    // Split the path into components
    const components = fullPath.split('/').slice(1);
    const itemName = components.pop();
    
    // Start with the startup disk
    let container = finder.startupDisk();
    
    // Traverse the folder hierarchy
    components.forEach(dirName => {
        if (dirName && dirName.length > 0) {
            container = container.folders[dirName];
        }
    });
    
    // Get the file or folder object
    try {
        const item = container.files[itemName];
        return item;
    } catch (e) {
        try {
            return container.folders[itemName];
        } catch (e2) {
            throw new Error(`Item not found: ${fullPath}`);
        }
    }
}
```

## Usage Example: Process a Selected Image File

This example shows a complete workflow of selecting an image file and processing it:

```javascript
(() => {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    
    try {
        const imagePath = app.chooseFile({
            withPrompt: "Select an image to process",
            ofType: ["public.image"],
            defaultLocation: app.pathTo("pictures")
        });
        
        // Display notification that processing is starting
        app.displayNotification("Beginning image processing...", {
            withTitle: "Image Processor"
        });
        
        // Get file information using Finder
        const finder = Application("Finder");
        const imageFile = finder.items[imagePath];
        
        // Process the image (this is where you'd add your actual processing logic)
        console.log(`Processing image: ${imageFile.name()}`);
        console.log(`Size: ${imageFile.size() / 1024} KB`);
        
        // Simulate processing time
        delay(2);
        
        // Display completion notification
        app.displayNotification(`Processed ${imageFile.name()} successfully!`, {
            withTitle: "Image Processor",
            soundName: "Purr"
        });
        
    } catch (error) {
        console.log(`Operation cancelled or error occurred: ${error}`);
    }
})();
```

This script demonstrates how to combine file dialogs with notifications and Finder operations to create a complete user workflow.
