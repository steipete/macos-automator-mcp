---
title: 'JXA Folder Operations'
category: 03_jxa_core
id: jxa_folder_operations
description: Creating, managing, and listing folder contents using JXA
keywords:
  - jxa
  - javascript
  - folder operations
  - directory
  - create folder
  - list files
  - file system
language: javascript
---

# JXA Folder Operations

This script demonstrates how to work with folders and directories using JavaScript for Automation.

## Prerequisites

Include the Standard Additions library and import the Foundation framework:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Import Foundation framework for advanced operations
ObjC.import('Foundation');
```

## Folder Operations

```javascript
function folderOperations() {
  const desktopPath = app.pathTo('desktop').toString();
  const newFolderPath = desktopPath + '/JXA Test Folder';
  
  try {
    // Create a new folder using shell script (reliable method)
    app.doShellScript(`mkdir -p '${newFolderPath}'`);
    
    // Create some test files inside
    for (let i = 1; i <= 3; i++) {
      const testFilePath = newFolderPath + `/test_file_${i}.txt`;
      const fileContent = `This is test file ${i}`;
      
      // Write file using ObjC bridge
      ObjC.import('Foundation');
      const nsString = $.NSString.alloc.initWithUTF8String(fileContent);
      nsString.writeToFileAtomicallyEncodingError(
        testFilePath,
        true,
        $.NSUTF8StringEncoding,
        null
      );
    }
    
    // List files in the directory using shell script
    const listResult = app.doShellScript(`ls -la '${newFolderPath}'`);
    app.displayDialog("Folder contents:\n" + listResult);
    
    // Get file information for a specific file
    const firstFilePath = newFolderPath + '/test_file_1.txt';
    const fileInfo = app.doShellScript(`stat -l '${firstFilePath}'`);
    
    app.displayDialog("File info:\n" + fileInfo);
    
  } catch (error) {
    app.displayDialog("Error: " + error);
  }
}
```

## Key Folder Operations

The script demonstrates the following operations:

1. Creating a new folder using shell commands
2. Creating multiple files inside a folder
3. Listing all files in a directory with detailed information
4. Getting file statistics and information

## Alternative Methods for Folder Operations

### Using Objective-C NSFileManager

```javascript
function createFolderWithNSFileManager(folderPath) {
  ObjC.import('Foundation');
  const fileManager = $.NSFileManager.defaultManager;
  
  // Create folder with attributes (permissions)
  const result = fileManager.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(
    folderPath,
    true,  // create intermediate directories
    null,  // default attributes
    null   // error pointer
  );
  
  return result;
}
```

### Listing Files with NSFileManager

```javascript
function listFilesWithNSFileManager(folderPath) {
  ObjC.import('Foundation');
  const fileManager = $.NSFileManager.defaultManager;
  
  // Get array of files in directory
  const nsArray = fileManager.contentsOfDirectoryAtPathError(folderPath, null);
  
  // Convert to JavaScript array
  const fileCount = nsArray.count;
  const files = [];
  
  for (let i = 0; i < fileCount; i++) {
    files.push(ObjC.unwrap(nsArray.objectAtIndex(i)));
  }
  
  return files;
}
```

## Common Shell Commands for Folder Operations

When working with folders in JXA, these shell commands are particularly useful:

- `mkdir -p 'path'` - Create folder with parent directories if needed
- `ls -la 'path'` - List all files including hidden files with details
- `rm -rf 'path'` - Remove folder and contents recursively (use with caution)
- `stat -l 'path'` - Get detailed file information
- `find 'path' -type f -name "*.txt"` - Find files by pattern

Using shell commands via `doShellScript()` is often more straightforward for filesystem operations than the native JXA methods.