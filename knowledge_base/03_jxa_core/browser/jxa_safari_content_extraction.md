---
title: 'JXA Safari Content Extraction'
category: 03_jxa_core
id: jxa_safari_content_extraction
description: Extract data from web pages using Safari and JavaScript for Automation
keywords:
  - jxa
  - javascript
  - safari
  - browser automation
  - web scraping
  - content extraction
  - links
  - metadata
language: javascript
---

# JXA Safari Content Extraction

This script demonstrates how to extract content from web pages using Safari and JavaScript for Automation.

## Prerequisites

Safari must have Automation permissions enabled in System Settings → Privacy & Security → Automation.

## Web Content Extraction

```javascript
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
```

## Content Extraction Techniques

The script demonstrates the following operations:

1. Activating Safari and accessing the current tab
2. Executing JavaScript in the current tab to extract data
3. Extracting and processing all links on the page
4. Gathering page metadata like title, description, and element counts
5. Formatting and displaying the extracted data

## Using `execute()` to Run JavaScript

The `execute()` method allows you to run JavaScript code in the context of the web page, which is powerful for content extraction:

- `tab.execute({javascript: 'document.title'})` - Execute simple JavaScript and return the result
- More complex scripts can perform DOM queries and manipulation
- Using JSON.stringify/parse to transfer complex data structures between the web page and JXA

## Common Web Content Extraction Tasks

- Getting the page title: `document.title`
- Getting the page URL: `window.location.href`
- Finding elements: `document.querySelectorAll('selector')`
- Reading meta tags: `document.querySelector('meta[name="description"]')?.content`
- Counting elements: `document.querySelectorAll('img').length`
- Extracting text: `element.textContent.trim()`
- Getting attributes: `element.getAttribute('href')`

Safari's JavaScript execution via JXA is generally more reliable than Chrome's, making it the preferred choice for content extraction tasks on macOS.