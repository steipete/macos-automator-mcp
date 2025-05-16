---
title: JXA JSON Format Conversion
category: 03_jxa_core
id: jxa_json_convert_format
description: >-
  A script for converting JSON data to different formats (CSV, XML, Property List) using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - csv
  - xml
  - plist
  - conversion
  - format
  - transform
---

# JXA JSON Format Conversion

This script provides functionality for converting JSON data to different formats using JavaScript for Automation (JXA).

## Usage

The function can convert JSON data to CSV, XML, or Property List formats.

```javascript
// Convert JSON to different formats
function convertJSON(data, format) {
    try {
        // Ensure we have data
        if (!data) {
            return {
                success: false,
                error: "Data is required for conversion"
            };
        }
        
        // Default to JSON format
        format = format || "json";
        
        // Handle different formats
        switch (format.toLowerCase()) {
            case "json":
                // Pretty-print JSON
                return {
                    success: true,
                    result: JSON.stringify(data, null, 2)
                };
                
            case "csv":
                // Convert to CSV
                const csv = jsonToCSV(data);
                return {
                    success: true,
                    result: csv
                };
                
            case "xml":
                // Convert to XML
                const xml = jsonToXML(data);
                return {
                    success: true,
                    result: xml
                };
                
            case "plist":
                // Convert to Property List format
                const plist = jsonToPlist(data);
                return {
                    success: true,
                    result: plist
                };
                
            default:
                return {
                    success: false,
                    error: `Unsupported format: ${format}`
                };
        }
    } catch (error) {
        return {
            success: false,
            error: `Error converting JSON: ${error.message}`
        };
    }
}

// Helper function to convert JSON to CSV
function jsonToCSV(data) {
    // Find the array to convert
    let arrayToConvert = data;
    
    // If data is an object with a single array property, use that
    if (!Array.isArray(data)) {
        const keys = Object.keys(data);
        for (const key of keys) {
            if (Array.isArray(data[key]) && data[key].length > 0) {
                arrayToConvert = data[key];
                break;
            }
        }
    }
    
    // If not an array, wrap in array
    if (!Array.isArray(arrayToConvert)) {
        arrayToConvert = [arrayToConvert];
    }
    
    // If empty array, return empty string
    if (arrayToConvert.length === 0) {
        return "";
    }
    
    // Get all possible headers from all objects
    const headers = new Set();
    arrayToConvert.forEach(item => {
        Object.keys(item).forEach(key => headers.add(key));
    });
    
    const headerRow = Array.from(headers).join(",");
    
    // Build rows
    const rows = arrayToConvert.map(item => {
        return Array.from(headers)
            .map(header => {
                const value = item[header];
                // Handle different types
                if (value === undefined || value === null) return "";
                if (typeof value === "string") return `"${value.replace(/"/g, '""')}"`;
                if (typeof value === "object") return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
                return value;
            })
            .join(",");
    });
    
    return [headerRow, ...rows].join("\n");
}

// Helper function to convert JSON to XML
function jsonToXML(data, rootName = "root") {
    function convertToXML(obj, nodeName) {
        if (obj === null || obj === undefined) {
            return `<${nodeName} />`;
        }
        
        if (Array.isArray(obj)) {
            // For arrays, create multiple nodes with the same name
            return obj.map(item => convertToXML(item, nodeName.replace(/s$/, ""))).join("\n");
        }
        
        if (typeof obj === "object") {
            // For objects, create a node with nested child nodes
            const children = Object.keys(obj).map(key => {
                return convertToXML(obj[key], key);
            }).join("\n");
            
            return `<${nodeName}>\n${children}\n</${nodeName}>`;
        }
        
        // For primitive values, create a node with the value as content
        return `<${nodeName}>${obj}</${nodeName}>`;
    }
    
    return `<?xml version="1.0" encoding="UTF-8"?>\n${convertToXML(data, rootName)}`;
}

// Helper function to convert JSON to Property List format
function jsonToPlist(data) {
    // Convert the data to an Objective-C object
    function toObjCObject(value) {
        if (value === null || value === undefined) {
            return $.NSNull.null;
        }
        
        if (typeof value === "string") {
            return $.NSString.stringWithString(value);
        }
        
        if (typeof value === "number") {
            if (Number.isInteger(value)) {
                return $.NSNumber.numberWithInt(value);
            } else {
                return $.NSNumber.numberWithDouble(value);
            }
        }
        
        if (typeof value === "boolean") {
            return $.NSNumber.numberWithBool(value);
        }
        
        if (Array.isArray(value)) {
            const array = $.NSMutableArray.alloc.init;
            value.forEach(item => {
                array.addObject(toObjCObject(item));
            });
            return array;
        }
        
        if (typeof value === "object") {
            const dict = $.NSMutableDictionary.alloc.init;
            Object.keys(value).forEach(key => {
                dict.setObjectForKey(toObjCObject(value[key]), key);
            });
            return dict;
        }
        
        return $.NSNull.null;
    }
    
    // Convert to ObjC object
    const objcData = toObjCObject(data);
    
    // Convert to property list format
    const plistData = $.NSPropertyListSerialization.dataWithPropertyListFormatOptionsError(
        objcData,
        $.NSPropertyListXMLFormat_v1_0,
        0,
        null
    );
    
    // Convert to string
    if (plistData) {
        const nsString = $.NSString.alloc.initWithDataEncoding(plistData, $.NSUTF8StringEncoding);
        return ObjC.unwrap(nsString);
    }
    
    throw new Error("Failed to convert to Property List format");
}
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `data`: JSON data to convert (required)
- `format`: Target format ("json", "csv", "xml", "plist")

## Example Usage

Here's an example of how to use the `convertJSON` function:

```json
{
  "action": "convertJSON",
  "data": {
    "people": [
      {"name": "Alice", "age": 30, "roles": ["developer", "designer"]},
      {"name": "Bob", "age": 25, "roles": ["manager"]},
      {"name": "Charlie", "age": 35, "roles": ["developer", "architect"]}
    ]
  },
  "format": "csv"
}
```

The script supports conversion to several formats:
- CSV (Comma-Separated Values) - ideal for spreadsheet applications
- XML (Extensible Markup Language) - widely used for data interchange
- Property List (plist) - commonly used in macOS and iOS applications