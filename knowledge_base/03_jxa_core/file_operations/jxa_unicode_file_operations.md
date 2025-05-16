---
title: 'JXA Unicode File Operations'
category: 03_jxa_core
id: jxa_unicode_file_operations
description: Working with Unicode text in files using the Objective-C bridge in JXA
keywords:
  - jxa
  - javascript
  - file operations
  - unicode
  - utf-8
  - objective-c
  - nsstring
language: javascript
---

# JXA Unicode File Operations

This script demonstrates how to work with Unicode text in files using the Objective-C bridge in JavaScript for Automation.

## Prerequisites

Include the Standard Additions library and import the Foundation framework:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Import Foundation framework for NSString operations
ObjC.import('Foundation');
```

## Unicode File Operations

```javascript
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
```

## Key Unicode File Operations

The script demonstrates the following operations:

1. Creating text with Unicode characters from multiple languages
2. Converting JavaScript strings to NSString objects
3. Writing Unicode text to a file with proper encoding
4. Checking if a file exists
5. Reading Unicode text from a file with correct encoding
6. Converting NSString objects back to JavaScript strings

## Common Objective-C Methods for File Operations

- `$.NSString.alloc.initWithUTF8String(text)` - Create NSString from JavaScript string
- `nsString.writeToFileAtomicallyEncodingError(path, atomic, encoding, error)` - Write to file
- `$.NSFileManager.defaultManager.fileExistsAtPath(path)` - Check if file exists
- `$.NSString.stringWithContentsOfFileEncodingError(path, encoding, error)` - Read file
- `nsString.js` - Convert NSString back to JavaScript string

## Available Text Encodings

Common encoding constants for file operations:

- `$.NSUTF8StringEncoding` - UTF-8 encoding (recommended for most cases)
- `$.NSUTF16StringEncoding` - UTF-16 encoding
- `$.NSASCIIStringEncoding` - ASCII encoding (limited character set)
- `$.NSISOLatin1StringEncoding` - Latin-1 encoding

This approach overcomes the limitations of standard JXA file operations and provides full support for international characters and emoji in text files.