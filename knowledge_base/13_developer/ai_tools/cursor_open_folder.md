---
id: cursor_open_folder
title: Open Folder in Cursor IDE
description: >-
  Opens a folder in Cursor, the AI-first code editor, using the cursor CLI command.
language: applescript
keywords:
  - cursor
  - ide
  - editor
  - ai
  - folder
  - project
usage_examples:
  - Open a project folder in Cursor for AI-assisted coding
  - Launch Cursor with a specific workspace
parameters:
  - name: folder_path
    description: The absolute path to the folder to open
    required: true
  - name: new_window
    description: 'Whether to open in a new window (default: true)'
    required: false
category: 13_developer
---

# Open Folder in Cursor IDE

This script opens a folder in Cursor, the AI-powered code editor built on VS Code.

```applescript
on run {input, parameters}
    set folderPath to "--MCP_INPUT:folder_path"
    set newWindow to "--MCP_INPUT:new_window"

    -- Validate folder path
    if folderPath is "" or folderPath is missing value then
        return "Error: No folder path provided."
    end if

    -- Default to new window
    if newWindow is "" or newWindow is missing value then
        set newWindow to true
    end if

    -- Build cursor command
    set cursorCommand to "cursor"
    if newWindow then
        set cursorCommand to cursorCommand & " -n"
    end if
    set cursorCommand to cursorCommand & " " & quoted form of folderPath

    try
        do shell script cursorCommand
        return "Opened Cursor with folder: " & folderPath
    on error errMsg
        return "Error opening Cursor: " & errMsg
    end try
end run
```

## Use Cases

### Basic Usage

Open a project folder in Cursor:

```json
{
  "kb_script_id": "cursor_open_folder",
  "input_data": {
    "folder_path": "/Users/me/projects/my-app"
  }
}
```

### Open in Same Window

Add to existing Cursor window:

```json
{
  "kb_script_id": "cursor_open_folder",
  "input_data": {
    "folder_path": "/Users/me/projects/my-app",
    "new_window": false
  }
}
```

## Requirements

- Cursor must be installed
- The `cursor` CLI command must be available in PATH
  - Install via Cursor: Cmd+Shift+P > "Shell Command: Install 'cursor' command"
