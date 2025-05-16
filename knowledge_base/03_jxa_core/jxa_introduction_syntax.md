---
title: 'JXA Basics: Introduction and Syntax'
category: 03_jxa_core
id: jxa_introduction_syntax
description: >-
  Basic syntax for JavaScript for Automation (JXA), including how to target
  applications and execute commands.
keywords:
  - jxa
  - javascript
  - automation
  - syntax
  - Application object
language: javascript
notes: JXA scripts are run using `osascript -l JavaScript`.
---

JXA allows macOS automation using JavaScript.

```javascript
// JXA Script Content

// Get a reference to an application
var Finder = Application("Finder");
var Safari = Application("Safari"); // Case-sensitive for app name string

// Activate an application
Finder.activate();

// Run a command (if app is scriptable with it)
var desktopItemsCount = Finder.desktop.items.length; // Accessing properties
// var frontWindow = Finder.finderWindows[0]; // JXA uses 0-based indexing for arrays

// Standard Additions are available via Application.currentApplication()
var app = Application.currentApplication();
app.includeStandardAdditions = true; // Important for dialogs, etc.

app.displayDialog("Finder has " + desktopItemsCount + " items on the desktop.");

// Return value (last expression evaluated)
"JXA script executed. Desktop items: " + desktopItemsCount;
```
END_TIP 
