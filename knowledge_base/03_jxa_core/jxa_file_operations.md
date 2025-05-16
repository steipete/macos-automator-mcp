---
title: 'JXA: File System Operations'
category: 03_jxa_core
id: jxa_file_operations
description: >-
  Examples of file system operations in JXA, including reading, writing, and
  managing files and folders.
keywords:
  - jxa
  - javascript
  - file operations
  - read file
  - write file
  - file system
  - unicode
language: javascript
notes: >-
  For Unicode support, use the Objective-C bridge approach. Standard JXA file
  operations are limited to ASCII.
---

```javascript
// JXA File Operations

// Initialize application with standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// EXAMPLE 1: Basic file operations using standard JXA
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

// EXAMPLE 2: Unicode file operations using Objective-C bridge
function unicodeFileOperations() {
  // Import Foundation framework
  ObjC.import('Foundation');
  
  const desktopPath = app.pathTo('desktop').toString();
  const filePath = desktopPath + '/jxa_unicode_test.txt';
  
  // Text with Unicode characters
  const unicodeText = 'Unicode Text with special characters: 您好 Olá こんにちは Привет';
  
  try {
    // Convert string to NSString
    const nsString = $.NSString.alloc.initWithUTF8String(unicodeText);
    
    // Write to file using NSString methods with UTF-8 encoding
    const result = nsString.writeToFileAtomicallyEncodingError(
      filePath,
      true,
      $.NSUTF8StringEncoding,
      null
    );
    
    if (result) {
      // Read the file back using NSString for correct Unicode handling
      const fileManager = $.NSFileManager.defaultManager;
      const fileExists = fileManager.fileExistsAtPath(filePath);
      
      if (fileExists) {
        const nsFileContent = $.NSString.stringWithContentsOfFileEncodingError(
          filePath,
          $.NSUTF8StringEncoding,
          null
        );
        
        app.displayDialog("Unicode file contents: " + nsFileContent.js);
      }
    } else {
      app.displayDialog("Failed to write Unicode file");
    }
  } catch (error) {
    app.displayDialog("Error: " + error);
  }
}

// EXAMPLE 3: Working with folders
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

// EXAMPLE 4: Working with file paths and aliases
function workWithPaths() {
  // Different ways to reference paths
  const homeFolder = app.pathTo('home folder');
  const documentsFolder = app.pathTo('documents folder');
  const currentFolder = app.pathTo('startup disk').toString() + 
                       app.doShellScript('pwd');
  
  // Using Path object to handle relative paths and ~
  const relPath = Path('~/Documents');
  const absPath = relPath.toString(); // Converts to absolute path
  
  // Working with file URLs
  ObjC.import('Foundation');
  const fileURL = $.NSURL.fileURLWithPath(absPath);
  const urlString = fileURL.absoluteString.js;
  
  // Display all paths
  const pathInfo = "Home: " + homeFolder + "\n" +
                  "Documents: " + documentsFolder + "\n" + 
                  "Current: " + currentFolder + "\n" +
                  "Path Object: " + relPath + "\n" +
                  "Absolute: " + absPath + "\n" +
                  "URL: " + urlString;
  
  app.displayDialog(pathInfo);
}

// Uncomment one of these to run the examples
// basicFileOperations();
// unicodeFileOperations();
// folderOperations();
// workWithPaths();

"File operations examples completed.";
```
