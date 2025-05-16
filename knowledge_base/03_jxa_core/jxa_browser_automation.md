---
title: "JXA: Browser Automation"
category: "10_jxa_basics"
id: jxa_browser_automation
description: "Examples of automating Safari, Chrome, and other browsers using JXA to control tabs, perform web actions, and extract content."
keywords: ["jxa", "javascript", "safari", "chrome", "browser automation", "web scripting", "tabs", "url"]
language: javascript
notes: "Browser scripting capabilities may change with browser updates. Safari offers the most reliable automation experience on macOS."
---

```javascript
// Browser Automation with JXA

// EXAMPLE 1: Safari Basic Operations
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

// EXAMPLE 2: Google Chrome Operations
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

// EXAMPLE 3: Safari Web Content Extraction
function extractSafariContent() {
  const safari = Application('Safari');
  safari.activate();
  
  const currentTab = safari.windows[0].currentTab;
  
  // Execute JavaScript in Safari to extract page content
  // This is more reliable in Safari than in Chrome via JXA
  const pageTitle = currentTab.execute({javascript: 'document.title'});
  
  // Extract all links on the page
  const linksScript = `
    const links = Array.from(document.querySelectorAll('a'));
    const linkData = links.map(link => ({
      text: link.textContent.trim(),
      href: link.href
    }));
    JSON.stringify(linkData.slice(0, 10)); // Limit to first 10 links
  `;
  
  const linksJson = currentTab.execute({javascript: linksScript});
  const links = JSON.parse(linksJson);
  
  // Format links as text
  let linksText = "Links on the page:\n";
  links.forEach((link, i) => {
    linksText += `${i+1}. "${link.text}" - ${link.href}\n`;
  });
  
  // Get page metadata
  const metadataScript = `
    const metadata = {
      title: document.title,
      url: window.location.href,
      description: document.querySelector('meta[name="description"]')?.content || "No description",
      h1Count: document.querySelectorAll('h1').length,
      imageCount: document.querySelectorAll('img').length
    };
    JSON.stringify(metadata);
  `;
  
  const metadataJson = currentTab.execute({javascript: metadataScript});
  const metadata = JSON.parse(metadataJson);
  
  // Format metadata as text
  const metadataText = `Page Information:
Title: ${metadata.title}
URL: ${metadata.url}
Description: ${metadata.description}
H1 Headings: ${metadata.h1Count}
Images: ${metadata.imageCount}`;
  
  // Display the information
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  app.displayDialog(metadataText + "\n\n" + linksText);
  
  return "Safari content extraction completed.";
}

// EXAMPLE 4: Multi-browser Tab Management
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

// Uncomment one of these to run the examples
// safariBasicOperations();
// chromeOperations();
// extractSafariContent();
// manageBrowserTabs();

"Browser automation examples completed.";
```