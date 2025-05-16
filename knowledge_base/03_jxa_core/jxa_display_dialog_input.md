---
title: 'JXA Basics: Display Dialog and Get Input'
category: 03_jxa_core
id: jxa_display_dialog_input
description: Shows how to use 'displayDialog' in JXA to show messages and get user input.
keywords:
  - jxa
  - javascript
  - displayDialog
  - dialog
  - user input
  - prompt
language: javascript
notes: >-
  `app.includeStandardAdditions = true;` is required before using
  `displayDialog`.
---

```javascript
// JXA Script Content
var app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
  var dialogResult = app.displayDialog("What is your name?", {
    defaultAnswer: "",
    buttons: ["Cancel", "OK"],
    defaultButton: "OK",
    cancelButton: "Cancel",
    withTitle: "JXA Input",
    // withIcon: Path("/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserInfo.icns") // Using Path object for icon
  });

  if (dialogResult.buttonReturned === "OK") {
    var userName = dialogResult.textReturned;
    if (userName === "") {
      "User did not enter a name.";
    } else {
      "Hello, " + userName + "!";
    }
  } else {
    "User cancelled the dialog.";
  }
} catch (e) {
  // This catch block will capture errors if displayDialog itself fails,
  // but not user cancellation if cancelButton is defined (that's handled by buttonReturned).
  // If no cancelButton is specified, user cancel raises error -128.
  if (e.errorNumber === -128) {
     "User cancelled (error -128)."
  } else {
     "Error: " + e.message;
  }
}
```
END_TIP 
