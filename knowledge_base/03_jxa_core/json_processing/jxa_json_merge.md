---
title: JXA JSON Merging
category: 03_jxa_core
id: jxa_json_merge
description: >-
  A script for merging multiple JSON sources with different strategies using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - merge
  - combine
  - deep merge
  - array merge
  - data integration
---

# JXA JSON Merging

This script provides functionality for merging multiple JSON sources using JavaScript for Automation (JXA).

## Usage

The function can merge JSON data from multiple sources with different merging strategies.

```javascript
// Merge multiple JSON sources
function mergeJSON(sources, strategy) {
    try {
        if (!sources || !Array.isArray(sources) || sources.length === 0) {
            return {
                success: false,
                error: "Sources array is required and must not be empty"
            };
        }
        
        // Default merge strategy
        strategy = strategy || "deep";
        
        // Process each source
        const processedSources = [];
        
        for (const source of sources) {
            let processedSource;
            
            if (typeof source === "string") {
                // If source is a string, treat it as a file path
                try {
                    const app = Application.currentApplication();
                    app.includeStandardAdditions = true;
                    
                    // Check if file exists
                    const fileExists = app.doShellScript(`test -f "${source}" && echo "exists" || echo "not found"`).trim();
                    
                    if (fileExists !== "exists") {
                        // Skip non-existent files
                        continue;
                    }
                    
                    // Read the file
                    const fileContent = app.read(Path(source));
                    processedSource = JSON.parse(fileContent);
                } catch (e) {
                    // Skip files with parsing errors
                    continue;
                }
            } else {
                // If source is already an object, use it directly
                processedSource = source;
            }
            
            processedSources.push(processedSource);
        }
        
        if (processedSources.length === 0) {
            return {
                success: false,
                error: "No valid sources to merge"
            };
        }
        
        // Perform the merge based on strategy
        let mergedData;
        
        switch (strategy) {
            case "shallow":
                // Simple shallow merge using Object.assign
                mergedData = Object.assign({}, ...processedSources);
                break;
                
            case "deep":
                // Deep merge
                mergedData = deepMerge({}, ...processedSources);
                break;
                
            case "arrays_concat":
                // Special handling for arrays - concatenate them
                mergedData = deepMergeWithArrays({}, ...processedSources);
                break;
                
            case "arrays_unique":
                // Special handling for arrays - concatenate and keep unique values
                mergedData = deepMergeWithUniqueArrays({}, ...processedSources);
                break;
                
            default:
                // Default to deep merge
                mergedData = deepMerge({}, ...processedSources);
        }
        
        return {
            success: true,
            data: mergedData,
            message: `Merged ${processedSources.length} sources using ${strategy} strategy`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error merging JSON: ${error.message}`
        };
    }
}

// Helper function for deep merge
function deepMerge(target, ...sources) {
    if (!sources.length) return target;
    
    const source = sources.shift();
    
    if (isObject(target) && isObject(source)) {
        for (const key in source) {
            if (isObject(source[key])) {
                if (!target[key]) Object.assign(target, { [key]: {} });
                deepMerge(target[key], source[key]);
            } else {
                Object.assign(target, { [key]: source[key] });
            }
        }
    }
    
    return deepMerge(target, ...sources);
}

// Helper function for deep merge with array concatenation
function deepMergeWithArrays(target, ...sources) {
    if (!sources.length) return target;
    
    const source = sources.shift();
    
    if (isObject(target) && isObject(source)) {
        for (const key in source) {
            if (Array.isArray(source[key])) {
                if (!target[key]) target[key] = [];
                target[key] = target[key].concat(source[key]);
            } else if (isObject(source[key])) {
                if (!target[key]) Object.assign(target, { [key]: {} });
                deepMergeWithArrays(target[key], source[key]);
            } else {
                Object.assign(target, { [key]: source[key] });
            }
        }
    }
    
    return deepMergeWithArrays(target, ...sources);
}

// Helper function for deep merge with unique array values
function deepMergeWithUniqueArrays(target, ...sources) {
    if (!sources.length) return target;
    
    const source = sources.shift();
    
    if (isObject(target) && isObject(source)) {
        for (const key in source) {
            if (Array.isArray(source[key])) {
                if (!target[key]) target[key] = [];
                
                // Concatenate arrays and keep unique values
                const merged = target[key].concat(source[key]);
                target[key] = Array.from(new Set(merged.map(item => 
                    typeof item === 'object' ? JSON.stringify(item) : item
                ))).map(item => 
                    typeof item === 'string' && item.startsWith('{') ? JSON.parse(item) : item
                );
            } else if (isObject(source[key])) {
                if (!target[key]) Object.assign(target, { [key]: {} });
                deepMergeWithUniqueArrays(target[key], source[key]);
            } else {
                Object.assign(target, { [key]: source[key] });
            }
        }
    }
    
    return deepMergeWithUniqueArrays(target, ...sources);
}

// Helper function to check if value is an object
function isObject(item) {
    return (item && typeof item === 'object' && !Array.isArray(item));
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `sources`: Array of JSON sources (file paths or objects) to merge (required)
- `strategy`: Merge strategy ("shallow", "deep", "arrays_concat", "arrays_unique")

## Example Usage

Here's an example of how to use the `mergeJSON` function:

```json
{
  "action": "mergeJSON",
  "sources": [
    "/path/to/first.json",
    "/path/to/second.json",
    {"additionalData": "inline data"}
  ],
  "strategy": "deep"
}
```

The script supports several merging strategies:
- `shallow`: Simple object merging using Object.assign
- `deep`: Deep recursive merging of nested objects
- `arrays_concat`: Deep merging with array concatenation
- `arrays_unique`: Deep merging with array concatenation and duplicate removal

Sources can be file paths (which will be read) or direct JSON objects. Non-existent files or files with parsing errors are skipped automatically.