---
id: jxa_clipboard_manager
title: JXA Clipboard Manager
description: A simple clipboard history manager using JavaScript for Automation
language: javascript
keywords:
  - clipboard
  - history
  - clipboard manager
  - multiple items
  - clip history
  - clipboard stack
category: 03_jxa_core
---

# JXA Clipboard Manager

This script provides a simple clipboard history manager to store and recall multiple clipboard items using JavaScript for Automation (JXA).

## Prerequisites

First, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## Clipboard Manager Implementation

A class-based implementation for managing multiple clipboard items:

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
```

## Usage Example

Here's how to use the Clipboard Manager:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Create a clipboard manager with capacity for 5 items
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

## Practical Applications

This clipboard manager can be useful for:

1. Temporarily storing multiple text snippets during complex document editing
2. Creating automated workflows that need to process multiple clipboard items
3. Maintaining a small history of recent clipboard operations
4. Implementing a simple text collection mechanism for gathering information

The manager currently focuses on text items but could be extended to handle other types of clipboard data with additional Objective-C bridging code.