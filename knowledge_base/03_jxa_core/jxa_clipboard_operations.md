---
id: jxa_clipboard_operations
title: Clipboard Operations with JXA
description: Overview of clipboard management capabilities using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - copy
  - paste
  - text manipulation
  - file transfer
category: 03_jxa_core
---

# Clipboard Operations with JXA

JavaScript for Automation (JXA) provides methods to read from and write to the macOS clipboard. This document provides an overview of the clipboard operations capabilities available using JXA.

## Available Scripts

The following scripts provide detailed functionality for working with clipboard data:

1. [Basic Text Operations](clipboard/jxa_clipboard_text.md) - Get and set text in the clipboard
2. [Rich Text Operations](clipboard/jxa_clipboard_rich_text.md) - Work with styled RTF text
3. [Image Operations](clipboard/jxa_clipboard_images.md) - Read and write images to the clipboard
4. [File Operations](clipboard/jxa_clipboard_files.md) - Work with file paths in the clipboard
5. [Clipboard Manager](clipboard/jxa_clipboard_manager.md) - Manage multiple clipboard items

## Prerequisites

For all clipboard operations, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## General Usage

Each script provides specialized functionality and can be used independently or in combination. Refer to the individual script documentation for detailed usage instructions and examples.