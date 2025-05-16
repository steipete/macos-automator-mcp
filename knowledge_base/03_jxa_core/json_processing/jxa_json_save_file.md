---
title: JXA JSON File Saving
category: 03_jxa_core
id: jxa_json_save_file
description: >-
  A script for saving JSON data to a file using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - file
  - save
  - write
  - export
  - persistence
---

# JXA JSON File Saving

This script provides functionality for saving JSON data to a file using JavaScript for Automation (JXA).

## Usage

The function can be used to save JSON data to a file with optional pretty-printing.

```javascript
// Save JSON data to a file
function saveJSON(data, filePath, pretty) {
    try {
        if (!data) {
            return {
                success: false,
                error: "Data is required to save"
            };
        }
        
        if (!filePath) {
            return {
                success: false,
                error: "File path is required"
            };
        }
        
        // Ensure data is serializable
        let jsonString;
        
        try {
            jsonString = JSON.stringify(data, null, pretty ? 2 : null);
        } catch (e) {
            return {
                success: false,
                error: `Failed to serialize JSON: ${e.message}`
            };
        }
        
        // Write to file
        const app = Application.currentApplication();
        app.includeStandardAdditions = true;
        
        // Ensure the directory exists
        const dirPath = filePath.substring(0, filePath.lastIndexOf("/"));
        app.doShellScript(`mkdir -p "${dirPath}"`);
        
        // Write the file
        app.doShellScript(`echo '${jsonString.replace(/'/g, "'")}' > "${filePath}"`);
        
        return {
            success: true,
            message: `JSON data saved to ${filePath}`,
            filePath: filePath
        };
    } catch (error) {
        return {
            success: false,
            error: `Error saving JSON data: ${error.message}`
        };
    }
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `data`: JSON data to save (required)
- `filePath`: Path where to save the JSON file (required)
- `pretty`: Whether to format the JSON with indentation (default: false)

## Example Usage

Here's an example of how to use the `saveJSON` function:

```json
{
  "action": "saveJSON",
  "data": {"processed": true, "results": [1, 2, 3]},
  "filePath": "/path/to/output.json",
  "pretty": true
}
```

The function creates any necessary directories in the specified path and ensures the data is properly serialized before saving to the file. When the `pretty` option is enabled, the JSON is formatted with indentation for better readability.