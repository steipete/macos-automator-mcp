---
title: 'Electron Editors: Open File or Folder'
category: 08_editors
id: electron_open_file_folder
description: >-
  Opens a specified file or folder in an Electron-based editor like VS Code or
  Cursor.
keywords:
  - vscode
  - cursor
  - electron
  - open file
  - open folder
language: applescript
isComplex: true
argumentsPrompt: >-
  Target editor application name as 'targetAppName', and absolute POSIX path to
  file/folder as 'itemPath' in inputData.
---

```applescript
--MCP_INPUT:targetAppName
--MCP_INPUT:itemPath

on openItemInEditor(appName, posixPath)
  if appName is missing value or appName is "" then return "error: Target application name not provided."
  if posixPath is missing value or posixPath is "" then return "error: Item path not provided."
  
  try
    -- Method 1: Using 'open' command of the application (preferred if supported)
    tell application appName
      activate
      open (POSIX file posixPath)
    end tell
    return "Opened " & posixPath & " in " & appName
  on error directOpenError
    -- Method 2: Fallback to 'do shell script' (more generic)
    try
      -- Use bundle ID for reliability if known, otherwise app name.
      -- VS Code: com.microsoft.VSCode
      -- Cursor: com.cursor.ide (verify)
      set appIdentifier to appName
      if appName is "Visual Studio Code" then set appIdentifier to "com.microsoft.VSCode"
      if appName is "Cursor" then set appIdentifier to "com.cursor.ide"
      
      do shell script "open -b " & quoted form of appIdentifier & " " & quoted form of posixPath
      -- Or: do shell script "open -a " & quoted form of appName & " " & quoted form of posixPath
      return "Attempted to open " & posixPath & " in " & appName & " via shell."
    on error shellOpenError
      return "error: Failed to open " & posixPath & " in " & appName & " (tried direct & shell): " & directOpenError & " / " & shellOpenError
    end try
  end try
end openItemInEditor

return my openItemInEditor("--MCP_INPUT:targetAppName", "--MCP_INPUT:itemPath")
```
END_TIP 
