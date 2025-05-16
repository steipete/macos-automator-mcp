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

# File System Operations with JXA

JavaScript for Automation (JXA) provides several methods for working with files and folders on macOS. This document provides an overview of file system operations using JXA.

## Available Scripts

The following scripts provide detailed functionality for working with files and folders:

1. [Basic File Operations](file_operations/jxa_basic_file_operations.md) - Reading and writing files using standard JXA
2. [Unicode File Operations](file_operations/jxa_unicode_file_operations.md) - Working with Unicode text in files using the Objective-C bridge
3. [Folder Operations](file_operations/jxa_folder_operations.md) - Creating, managing, and listing folder contents
4. [File Paths and Aliases](file_operations/jxa_file_paths_and_aliases.md) - Working with different path formats and file references

## Prerequisites

For all file operations, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

For Unicode support and advanced file operations, you'll also need the Objective-C bridge:

```javascript
// Import Foundation framework for file operations
ObjC.import('Foundation');
```

## General Usage

Each script provides specialized functionality and can be used independently or in combination. Refer to the individual script documentation for detailed usage instructions and examples.

## Important Considerations

- Standard JXA file operations are limited to ASCII text
- For Unicode support, use the Objective-C bridge approach
- Consider using shell commands via `doShellScript()` for complex operations
- File paths should be handled carefully, especially with spaces or special characters