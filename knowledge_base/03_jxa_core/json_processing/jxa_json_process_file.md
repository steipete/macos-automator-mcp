---
title: JXA JSON File Processing
category: 03_jxa_core
id: jxa_json_process_file
description: >-
  A script for processing JSON files with various transformations using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - file
  - processing
  - transform
  - extract
  - analyze
---

# JXA JSON File Processing

This script provides functionality for processing JSON files with various transformations using JavaScript for Automation (JXA).

## Usage

The function can be used to read, parse, and transform JSON files.

```javascript
// Process a JSON file with transformations
function processJSONFile(filePath, transformation) {
    try {
        if (!filePath) {
            return {
                success: false,
                error: "File path is required"
            };
        }
        
        // Read the file
        const app = Application.currentApplication();
        app.includeStandardAdditions = true;
        
        // Ensure file exists
        const fileExists = app.doShellScript(`test -f "${filePath}" && echo "exists" || echo "not found"`).trim();
        
        if (fileExists !== "exists") {
            return {
                success: false,
                error: `File not found: ${filePath}`
            };
        }
        
        // Read and parse the JSON file
        const fileContent = app.read(Path(filePath));
        let jsonData;
        
        try {
            jsonData = JSON.parse(fileContent);
        } catch (e) {
            return {
                success: false,
                error: `Failed to parse JSON: ${e.message}`
            };
        }
        
        // Apply the specified transformation
        let result;
        
        switch (transformation) {
            case "extract":
                // Example: Extract all product names and prices
                if (jsonData.products) {
                    result = {
                        productInfo: jsonData.products.map(p => ({
                            name: p.name,
                            price: p.price
                        })),
                        storeInfo: jsonData.store
                    };
                } else {
                    result = {
                        message: "No products found in the JSON file",
                        structure: Object.keys(jsonData)
                    };
                }
                break;
                
            case "stats":
                // Example: Calculate statistics on products
                if (jsonData.products) {
                    const prices = jsonData.products.map(p => p.price);
                    const totalStock = jsonData.products.reduce((sum, p) => sum + p.stock, 0);
                    
                    result = {
                        productCount: jsonData.products.length,
                        averagePrice: prices.reduce((sum, price) => sum + price, 0) / prices.length,
                        minPrice: Math.min(...prices),
                        maxPrice: Math.max(...prices),
                        totalStock: totalStock
                    };
                } else {
                    result = {
                        message: "No products found for statistics calculation",
                        structure: Object.keys(jsonData)
                    };
                }
                break;
                
            case "structure":
                // Analyze the structure of the JSON
                result = analyzeJSONStructure(jsonData);
                break;
                
            default:
                // Return the data as-is
                result = jsonData;
        }
        
        return {
            success: true,
            data: result
        };
        
    } catch (error) {
        return {
            success: false,
            error: `Error processing JSON file: ${error.message}`
        };
    }
}

// Analyze the structure of a JSON object
function analyzeJSONStructure(jsonData, maxDepth = 3) {
    function getType(value) {
        if (value === null) return "null";
        if (Array.isArray(value)) return "array";
        return typeof value;
    }
    
    function analyzeStructure(data, depth = 0) {
        if (depth > maxDepth) return "...";
        
        const type = getType(data);
        
        if (type === "object") {
            const structure = {};
            for (const key in data) {
                structure[key] = analyzeStructure(data[key], depth + 1);
            }
            return structure;
        } else if (type === "array") {
            if (data.length === 0) return "empty array";
            // Just analyze the first item as a sample
            return `array[${data.length}] of ${getType(data[0])}`;
        } else {
            return type;
        }
    }
    
    return analyzeStructure(jsonData);
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `filePath`: Path to the JSON file to process (required)
- `transformation`: Type of transformation to apply ("extract", "stats", "structure")

## Example Usage

Here's an example of how to use the `processJSONFile` function:

```json
{
  "action": "processJSONFile",
  "filePath": "/path/to/data.json",
  "transformation": "stats"
}
```

The function can analyze the structure of JSON data, extract specific information, or calculate statistics on numeric values within the data.