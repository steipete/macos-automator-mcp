---
title: 'JXA Safari Basic Operations'
category: 03_jxa_core
id: jxa_safari_basic_operations
description: Control Safari windows, tabs, and navigation using JavaScript for Automation
keywords:
  - jxa
  - javascript
  - safari
  - browser automation
  - tabs
  - url
  - windows
language: javascript
---

# JXA Safari Basic Operations

This script demonstrates how to control Safari windows, tabs, and navigation using JavaScript for Automation.

## Prerequisites

Safari must have Automation permissions enabled in System Settings → Privacy & Security → Automation.

## Basic Operations

```javascript
function safariBasicOperations() {
  // Get the Safari application object
  const safari = Application('Safari');
  safari.includeStandardAdditions = true;
  
  // Activate Safari (bring to front)
  safari.activate();
  
  // Open a new window if none exists
  if (safari.windows.length === 0) {
    safari.Document().make();
  }
  
  // Get the first window
  const window = safari.windows[0];
  
  // Get current URL
  const currentURL = window.currentTab.url();
  
  // Navigate to a URL
  window.currentTab.url = 'https://apple.com';
  
  // Create a new tab
  const newTab = safari.Tab({url: 'https://developer.apple.com'});
  window.tabs.push(newTab);
  
  // Switch to the new tab
  window.currentTab = newTab;
  
  // Wait a moment for the page to load
  delay(2);
  
  // Get properties of current tab
  const tabName = window.currentTab.name();
  const tabURL = window.currentTab.url();
  
  // List all tabs in the window
  let tabsList = "All tabs in Safari:\n";
  for (let i = 0; i < window.tabs.length; i++) {
    tabsList += `${i+1}. ${window.tabs[i].name()} - ${window.tabs[i].url()}\n`;
  }
  
  // Display information
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  app.displayDialog(tabsList);
  
  return "Safari operations completed.";
}
```

## Window and Tab Operations

The script demonstrates the following operations:

1. Activating the Safari application
2. Creating a new window if none exists
3. Accessing the current URL
4. Navigating to a specific URL
5. Creating and opening a new tab
6. Switching between tabs
7. Getting tab properties like name and URL
8. Listing all open tabs

## Common Safari JXA Properties and Methods

- `safari.activate()` - Bring Safari to the foreground
- `safari.windows.length` - Number of open Safari windows
- `safari.Document().make()` - Create a new Safari window
- `window.currentTab` - Reference to the currently active tab
- `window.currentTab.url()` - Get the URL of the current tab
- `window.currentTab.url = 'https://example.com'` - Set the URL of the current tab
- `window.tabs.push(newTab)` - Add a new tab to a window
- `window.currentTab.name()` - Get the name (title) of the current tab

These basic operations form the foundation for more complex Safari automation tasks.