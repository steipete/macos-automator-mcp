---
title: 'JXA Basic File Operations'
category: 03_jxa_core
id: jxa_basic_file_operations
description: Reading and writing files using standard JXA methods
keywords:
  - jxa
  - javascript
  - file operations
  - read file
  - write file
  - file system
  - openForAccess
language: javascript
---

# JXA Basic File Operations

This script demonstrates how to perform basic file operations using standard JavaScript for Automation methods.

## Prerequisites

Include the Standard Additions library to access file operation functions:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## Basic File Operations

```javascript
function basicFileOperations() {
  // Get path to desktop folder
  const desktopPath = app.pathTo('desktop').toString();
  
  // Create a sample text file path
  const filePath = desktopPath + '/jxa_test_file.txt';
  
  // Write text to a file (ASCII only with this method)
  const textToWrite = 'Hello from JXA!\nThis is a test file.';
  
  try {
    // Open file for writing (creates if doesn't exist)
    const fileRef = app.openForAccess(Path(filePath), { writePermission: true });
    
    // Write content to file (overwrites any existing content)
    app.setEof(fileRef, 0); // Truncate file if it exists
    app.write(textToWrite, { to: fileRef });
    
    // Close file when done
    app.closeAccess(fileRef);
    
    // Read the file back
    const readFileRef = app.openForAccess(Path(filePath));
    const fileContents = app.read(readFileRef);
    app.closeAccess(readFileRef);
    
    app.displayDialog("File contents: " + fileContents);
    
  } catch (error) {
    app.displayDialog("Error: " + error);
  }
}
```

## Key File Operations

The script demonstrates the following operations:

1. Getting the path to a standard folder (desktop)
2. Creating a file path for a new file
3. Opening a file for writing with permissions
4. Writing content to a file
5. Closing file access to release resources
6. Opening a file for reading
7. Reading content from a file
8. Error handling for file operations

## Common JXA File Methods

- `app.pathTo('desktop')` - Get path to a standard folder
- `app.openForAccess(Path(path), { writePermission: true })` - Open file for writing
- `app.setEof(fileRef, 0)` - Truncate file (set length to 0)
- `app.write(text, { to: fileRef })` - Write text to file
- `app.read(fileRef)` - Read file contents
- `app.closeAccess(fileRef)` - Close file and release resources

## Limitations

This basic approach has some limitations:

- Only supports ASCII text (for Unicode support, see the Unicode File Operations script)
- Limited error handling for specific file errors
- No built-in support for binary file types

For more advanced file operations, consider using the Objective-C bridge or shell commands.