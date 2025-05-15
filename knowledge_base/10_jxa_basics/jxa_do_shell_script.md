---
title: "JXA: Running Shell Scripts"
category: "10_jxa_basics"
id: jxa_do_shell_script
description: "Shows how to execute shell commands from JXA using `app.doShellScript()`."
keywords: ["jxa", "javascript", "shell script", "terminal command", "execute"]
language: javascript
notes: "`app.includeStandardAdditions = true;` is required. Paths in shell commands should be POSIX. Use `Path().toString()` or `quoted form of` for paths with spaces."
---

```javascript
// JXA Script Content
var app = Application.currentApplication();
app.includeStandardAdditions = true;

var whoAmI = app.doShellScript("whoami");
var desktopPath = Path("~/Desktop").toString(); // Expands ~
var fileList = app.doShellScript("ls -la " +desktopPath); // Note: no 'quoted form of' in JXA directly for Path objects to shell. Better to build command carefully.

// For paths with spaces, it's safer to quote them within the shell command string
var folderWithSpaces = "My Folder With Spaces";
var desktopFolder = Path("~/Desktop/" + folderWithSpaces);
// Create the folder if it doesn't exist for the example
// app.doShellScript("mkdir -p " + desktopFolder.toString().replace(/ /g, '\\\\ ')); // Manual space escaping
// A better way is to ensure the path is quoted FOR the shell
var command = "ls -l " + quotedForm(desktopFolder.toString());
var listFolderWithSpaces = app.doShellScript(command);


function quotedForm(s) {
    return "'" + s.replace(/'/g, "'\\''") + "'";
}


app.displayDialog(
  "User: " + whoAmI +
  "\\n\\nDesktop List (first 100 chars):\\n" + fileList.substring(0, 100) + "..." +
  "\\n\\nList of '" + folderWithSpaces + "':\\n" + listFolderWithSpaces.substring(0,100) + "..."
);

"Shell scripts executed.";
``` 