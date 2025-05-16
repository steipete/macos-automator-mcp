---
title: 'JXA Multi-browser Tab Management'
category: 03_jxa_core
id: jxa_multi_browser_tab_management
description: Manage tabs across multiple browsers using JavaScript for Automation
keywords:
  - jxa
  - javascript
  - safari
  - chrome
  - browser automation
  - tab management
  - multi-browser
  - unified control
language: javascript
---

# JXA Multi-browser Tab Management

This script demonstrates how to manage tabs across multiple browsers using JavaScript for Automation.

## Prerequisites

Both Safari and Google Chrome must have Automation permissions enabled in System Settings → Privacy & Security → Automation.

## Multi-browser Tab Management

```javascript
function manageBrowserTabs() {
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  // Function to get tab info from both browsers
  function getBrowserTabsInfo() {
    let info = "";
    
    // Check Safari
    try {
      const safari = Application('Safari');
      if (safari.running()) {
        info += "SAFARI TABS:\n";
        for (let i = 0; i < safari.windows.length; i++) {
          const tabs = safari.windows[i].tabs;
          info += `Window ${i+1}: ${tabs.length} tabs\n`;
          for (let j = 0; j < tabs.length; j++) {
            info += `  ${j+1}. ${tabs[j].name()}\n`;
          }
        }
      } else {
        info += "Safari is not running.\n";
      }
    } catch (e) {
      info += "Error accessing Safari: " + e + "\n";
    }
    
    // Check Chrome
    try {
      const chrome = Application('Google Chrome');
      if (chrome.running()) {
        info += "\nCHROME TABS:\n";
        for (let i = 0; i < chrome.windows.length; i++) {
          const tabs = chrome.windows[i].tabs;
          info += `Window ${i+1}: ${tabs.length} tabs\n`;
          for (let j = 0; j < tabs.length; j++) {
            info += `  ${j+1}. ${tabs[j].title()}\n`;
          }
        }
      } else {
        info += "Chrome is not running.\n";
      }
    } catch (e) {
      info += "Error accessing Chrome: " + e + "\n";
    }
    
    return info;
  }
  
  // Get initial tab information
  const tabInfo = getBrowserTabsInfo();
  app.displayDialog(tabInfo);
  
  // Bonus: Open the same URL in both browsers
  const url = app.displayDialog("Enter a URL to open in both browsers:", {
    defaultAnswer: "https://apple.com",
    buttons: ["Cancel", "Open"],
    defaultButton: "Open"
  }).textReturned;
  
  if (url) {
    // Open in Safari
    try {
      const safari = Application('Safari');
      safari.activate();
      if (safari.windows.length === 0) {
        safari.Document().make();
      }
      safari.windows[0].currentTab.url = url;
    } catch (e) {
      app.displayDialog("Error opening in Safari: " + e);
    }
    
    // Open in Chrome
    try {
      const chrome = Application('Google Chrome');
      chrome.activate();
      if (chrome.windows.length === 0) {
        chrome.Window().make();
      }
      chrome.windows[0].activeTab.url = url;
    } catch (e) {
      app.displayDialog("Error opening in Chrome: " + e);
    }
  }
  
  return "Browser tab management completed.";
}
```

## Multi-browser Operations

The script demonstrates the following operations:

1. Collecting tab information from both Safari and Chrome
2. Checking if browsers are running before attempting to access them
3. Error handling for each browser operation
4. Getting user input for a URL
5. Opening the same URL in both browsers

## Cross-browser Automation Techniques

This script shows several important techniques for multi-browser automation:

- Defensive coding with try/catch blocks for each browser
- Checking if a browser is running with `browser.running()`
- Consistent handling of similar operations across different browsers
- Graceful error handling for browser-specific issues
- Working with different property names (e.g., Safari's `name()` vs Chrome's `title()`)

## Common Applications

Multi-browser tab management can be useful for:

1. Testing websites across browsers
2. Creating development environments
3. Archiving tabs from multiple browsers
4. Synchronizing browsing sessions
5. Collecting tab information for reporting

This approach can be extended to include other browsers like Firefox, Opera, or Edge if they are installed on the macOS system.