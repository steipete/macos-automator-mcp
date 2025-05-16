---
title: "JXA: Interacting with Finder"
category: "10_jxa_basics"
id: jxa_finder_interaction
description: "Demonstrates basic Finder operations like getting Desktop items and creating a folder using JXA."
keywords: ["jxa", "javascript", "finder", "file system", "automation"]
language: javascript
notes: "Finder object names and properties in JXA often mirror AppleScript but use JavaScript syntax (camelCase, array indexing)."
---

```javascript
// JXA Script Content
var Finder = Application("Finder");
Finder.includeStandardAdditions = true; // For displayDialog

// Activate Finder
Finder.activate();

// Get names of items on the Desktop
var desktopPath = Finder.desktop.url().replace(/^file:\/\//, ''); // Get POSIX path
var desktopItems = Finder.desktop.items(); // Returns an object specifier, not an array directly
var itemNames = [];
for (var i = 0; i < desktopItems.length; i++) {
  itemNames.push(desktopItems[i].name());
}

// Create a new folder on the Desktop
var newFolderName = "JXA Test Folder";
try {
  var newFolder = Finder.make({
    new: 'folder',
    at: Finder.desktop,
    withProperties: { name: newFolderName }
  });
  var creationMessage = "Folder '" + newFolderName + "' created.";
} catch (e) {
  var creationMessage = "Folder '" + newFolderName + "' might already exist or error: " + e.message;
}

Finder.displayDialog(
  "Desktop Items (" + itemNames.length + "):\\n" + itemNames.slice(0, 5).join("\\n") + (itemNames.length > 5 ? "\\n..." : "") +
  "\\n\\n" + creationMessage
);

"Finder interaction complete.";
``` 