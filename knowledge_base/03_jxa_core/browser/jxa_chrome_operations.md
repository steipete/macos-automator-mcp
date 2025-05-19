---
title: 'JXA Chrome Operations'
category: 03_jxa_core
id: jxa_chrome_operations
description: Control Google Chrome windows and tabs using JavaScript for Automation
keywords:
  - jxa
  - javascript
  - chrome
  - google chrome
  - browser automation
  - tabs
  - url
  - windows
language: javascript
---

# JXA Chrome Operations

This script demonstrates how to control Google Chrome windows and tabs using JavaScript for Automation.

## Prerequisites

Google Chrome must have Automation permissions enabled in System Settings → Privacy & Security → Automation.

## Basic Chrome Operations

```javascript
function chromeOperations() {
  // Get the Chrome application object
  const chrome = Application('Google Chrome');
  
  // Activate Chrome
  chrome.activate();
  
  // Open a URL in a new tab
  chrome.windows[0].tabs.push(chrome.Tab({url: 'https://google.com'}));
  
  // Current tab in first window
  const currentTab = chrome.windows[0].activeTab;
  
  // Execute JavaScript in the current tab (this requires Chrome's JXA support)
  // Note: This may not work in all Chrome versions as scripting support can vary
  try {
    const result = currentTab.execute({javascript: 'document.title'});
    
    // Display information using system dialog
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.displayDialog("Current page title: " + result);
  } catch (error) {
    // Chrome's JavaScript execution support via JXA is limited
    // Alternative: Use System Events for Chrome UI automation
    
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.displayDialog("Note: Direct JavaScript execution in Chrome may not be supported.");
  }
  
  // List all tabs in all Chrome windows
  let allTabs = "All Chrome tabs:\n";
  for (let i = 0; i < chrome.windows.length; i++) {
    allTabs += `\nWindow ${i+1}:\n`;
    const tabs = chrome.windows[i].tabs;
    for (let j = 0; j < tabs.length; j++) {
      allTabs += `  ${j+1}. ${tabs[j].title()} - ${tabs[j].url()}\n`;
    }
  }
  
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  app.displayDialog(allTabs);
  
  return "Chrome operations completed.";
}
```

## Window and Tab Operations

The script demonstrates the following operations:

1. Activating the Chrome application
2. Opening a URL in a new tab
3. Accessing the active tab
4. Attempting to execute JavaScript in a tab (with compatibility note)
5. Listing all tabs in all Chrome windows

## Common Chrome JXA Properties and Methods

- `chrome.activate()` - Bring Chrome to the foreground
- `chrome.windows.length` - Number of open Chrome windows
- `chrome.windows[0].tabs.push(tab)` - Add a new tab to a window
- `chrome.windows[0].activeTab` - Reference to the currently active tab
- `tab.title()` - Get the title of a tab
- `tab.url()` - Get the URL of a tab
- `tab.execute({javascript: '...'})` - Execute JavaScript in a tab (may have limited support)

## Compatibility Notes

Google Chrome's JavaScript execution support via JXA may be limited in some versions. For more reliable automation, consider using System Events for UI-based automation or using the browser automation capabilities via Safari.