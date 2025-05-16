---
id: jxa_clipboard_text
title: JXA Clipboard Text Operations
description: Basic text operations with the clipboard using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - text
  - copy
  - paste
  - read
  - write
category: 03_jxa_core
---

# JXA Clipboard Text Operations

This script provides basic text operations with the clipboard using JavaScript for Automation (JXA).

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

These basic text operations can be used in various automation workflows to read from and write to the system clipboard.