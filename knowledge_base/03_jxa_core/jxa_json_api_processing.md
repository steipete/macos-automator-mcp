---
title: JXA JSON & API Processing
category: 03_jxa_core
id: jxa_json_api_processing
description: >-
  A utility script for fetching, processing, and working with JSON data and REST
  APIs using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - api
  - rest
  - http
  - fetch
  - process
  - transform
  - data
---

# JXA JSON & API Processing

This script provides comprehensive functionality for working with JSON data and APIs using JavaScript for Automation (JXA). It enables fetching data from REST APIs, processing JSON, and transforming data for integration with other macOS automation tasks.

## Usage

The script can be used to fetch data from APIs, process JSON files, and transform data in various ways.

```javascript
// JXA JSON & API Processing
// A utility for working with JSON data and APIs

function run(argv) {
    // When run without arguments, show a demo
    if (argv.length === 0) {
        return demonstrateJSONProcessing();
    }
    
    return "Please use with MCP parameters";
}

// Handler for MCP input parameters
function processMCPParameters(params) {
    try {
        // Extract parameters
        const action = params.action || "";
        
        // Validate required parameters
        if (!action) {
            return {
                success: false,
                error: "Action parameter is required"
            };
        }
        
        // Perform the requested action
        switch (action) {
            case "fetchAPI":
                return fetchAPI(params.url, params.method, params.headers, params.body, params.auth);
            case "processJSONFile":
                return processJSONFile(params.filePath, params.transformation);
            case "convertJSON":
                return convertJSON(params.data, params.format);
            case "transformData":
                return transformData(params.data, params.transformations);
            case "saveJSON":
                return saveJSON(params.data, params.filePath, params.pretty);
            case "mergeJSON":
                return mergeJSON(params.sources, params.strategy);
            default:
                return {
                    success: false,
                    error: `Unknown action: ${action}`
                };
        }
    } catch (error) {
        return {
            success: false,
            error: `Error processing parameters: ${error.message}`
        };
    }
}

// Demonstrate basic JSON processing
function demonstrateJSONProcessing() {
    try {
        const app = Application.currentApplication();
        app.includeStandardAdditions = true;
        
        // Show example dialog
        const demoOptions = [
            "Fetch Weather API",
            "Process JSON File",
            "Convert JSON Format",
            "Transform JSON Data"
        ];
        
        const selectedDemo = app.chooseFromList(demoOptions, {
            withPrompt: "Select a JSON processing demonstration:",
            defaultItems: ["Fetch Weather API"]
        });
        
        if (!selectedDemo) return "Demonstration cancelled";
        
        switch (selectedDemo[0]) {
            case "Fetch Weather API":
                // Fetch a sample weather API
                const result = fetchAPI(
                    "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=temperature_2m,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m",
                    "GET", 
                    {}, 
                    null, 
                    null
                );
                
                if (result.success) {
                    const weatherData = result.data;
                    return {
                        success: true,
                        message: "Successfully fetched weather data",
                        temperature: weatherData.current.temperature_2m,
                        unit: weatherData.current_units.temperature_2m,
                        wind_speed: weatherData.current.wind_speed_10m,
                        wind_unit: weatherData.current_units.wind_speed_10m
                    };
                } else {
                    return result;
                }
                
            case "Process JSON File":
                // Create a temporary JSON file to process
                const tempFile = createTempJSONFile();
                
                // Process the file to extract specific data
                const fileResult = processJSONFile(tempFile, "extract");
                
                // Clean up the temporary file
                app.doShellScript(`rm "${tempFile}"`);
                
                return fileResult;
                
            case "Convert JSON Format":
                // Create sample data
                const sampleData = {
                    people: [
                        { name: "Alice", age: 30, roles: ["developer", "designer"] },
                        { name: "Bob", age: 25, roles: ["manager"] },
                        { name: "Charlie", age: 35, roles: ["developer", "architect"] }
                    ]
                };
                
                // Convert to different formats
                return convertJSON(sampleData, "csv");
                
            case "Transform JSON Data":
                // Create sample data
                const userData = {
                    users: [
                        { id: 1, firstName: "John", lastName: "Doe", email: "john@example.com" },
                        { id: 2, firstName: "Jane", lastName: "Smith", email: "jane@example.com" },
                        { id: 3, firstName: "Bob", lastName: "Johnson", email: "bob@example.com" }
                    ]
                };
                
                // Define transformations
                const transforms = [
                    { type: "map", field: "users", mapping: user => ({
                        id: user.id,
                        name: `${user.firstName} ${user.lastName}`,
                        contact: user.email
                    })},
                    { type: "filter", field: "users", condition: user => user.id > 1 },
                    { type: "sort", field: "users", key: "name" }
                ];
                
                return transformData(userData, transforms);
        }
    } catch (error) {
        return {
            success: false,
            error: `Error in demonstration: ${error.message}`
        };
    }
}

// Helper function to create a temporary JSON file
function createTempJSONFile() {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    
    const tempFolder = app.pathTo("temporary items").toString();
    const tempFile = `${tempFolder}/temp_json_demo.json`;
    
    const jsonData = JSON.stringify({
        products: [
            { id: 101, name: "Laptop", price: 999.99, stock: 45 },
            { id: 102, name: "Smartphone", price: 699.99, stock: 120 },
            { id: 103, name: "Tablet", price: 349.99, stock: 82 },
            { id: 104, name: "Monitor", price: 249.99, stock: 34 },
            { id: 105, name: "Keyboard", price: 49.99, stock: 210 }
        ],
        store: {
            name: "TechStore",
            location: "New York",
            established: 2010
        }
    }, null, 2);
    
    app.doShellScript(`echo '${jsonData.replace(/'/g, "\'")}' > "${tempFile}"`);
    
    return tempFile;
}

// Fetch data from an API
function fetchAPI(url, method, headers, body, auth) {
    try {
        if (!url) {
            return {
                success: false,
                error: "URL is required"
            };
        }
        
        // Default values
        method = method || "GET";
        headers = headers || {};
        
        // Create the URL object
        const nsurl = $.NSURL.URLWithString(url);
        const request = $.NSMutableURLRequest.alloc.initWithURL(nsurl);
        
        // Set the HTTP method
        request.setHTTPMethod(method);
        
        // Set headers
        for (const key in headers) {
            request.setValueForHTTPHeaderField(headers[key], key);
        }
        
        // Set auth if provided
        if (auth) {
            if (auth.type === "basic") {
                const authStr = $.NSString.alloc.initWithString(`${auth.username}:${auth.password}`);
                const authData = authStr.dataUsingEncoding($.NSUTF8StringEncoding);
                const base64Auth = authData.base64EncodedStringWithOptions(0);
                request.setValueForHTTPHeaderField(`Basic ${ObjC.unwrap(base64Auth)}`, "Authorization");
            } else if (auth.type === "bearer") {
                request.setValueForHTTPHeaderField(`Bearer ${auth.token}`, "Authorization");
            }
        }
        
        // Set body data if provided
        if (body) {
            let bodyData;
            
            if (typeof body === "object") {
                // Convert object to JSON
                const jsonString = $.NSString.alloc.initWithString(JSON.stringify(body));
                bodyData = jsonString.dataUsingEncoding($.NSUTF8StringEncoding);
                request.setValueForHTTPHeaderField("application/json", "Content-Type");
            } else if (typeof body === "string") {
                // Use string as-is
                const bodyString = $.NSString.alloc.initWithString(body);
                bodyData = bodyString.dataUsingEncoding($.NSUTF8StringEncoding);
            }
            
            if (bodyData) {
                request.setHTTPBody(bodyData);
            }
        }
        
        // Execute the request
        const response = $.NSURLConnection.sendSynchronousRequestReturningResponseError(request, null, null);
        
        // Process the response
        if (response) {
            // Check if we have data
            const responseData = response instanceof $NSData ? response : null;
            
            if (!responseData) {
                return {
                    success: false,
                    error: "No data returned from API"
                };
            }
            
            // Convert NSData to JavaScript string
            const nsString = $.NSString.alloc.initWithDataEncoding(responseData, $.NSUTF8StringEncoding);
            const responseString = ObjC.unwrap(nsString);
            
            // Try to parse as JSON
            try {
                const jsonData = JSON.parse(responseString);
                return {
                    success: true,
                    data: jsonData
                };
            } catch (e) {
                // Return raw string if not JSON
                return {
                    success: true,
                    data: responseString,
                    isJson: false
                };
            }
        } else {
            return {
                success: false,
                error: "Failed to connect to API"
            };
        }
    } catch (error) {
        return {
            success: false,
            error: `Error fetching API: ${error.message}`
        };
    }
}

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

// Transform JSON data with various operations
function transformData(data, transformations) {
    try {
        if (!data) {
            return {
                success: false,
                error: "Data is required for transformation"
            };
        }
        
        if (!transformations || !Array.isArray(transformations) || transformations.length === 0) {
            return {
                success: true,
                data: data,
                message: "No transformations applied"
            };
        }
        
        // Clone the data to avoid modifying the original
        let result = JSON.parse(JSON.stringify(data));
        
        // Apply each transformation in sequence
        for (const transform of transformations) {
            switch (transform.type) {
                case "map":
                    // Apply a mapping function to items in an array field
                    if (transform.field) {
                        const fieldPath = transform.field.split(".");
                        let target = result;
                        
                        // Navigate to the target field
                        for (let i = 0; i < fieldPath.length - 1; i++) {
                            target = target[fieldPath[i]];
                            if (!target) break;
                        }
                        
                        const lastField = fieldPath[fieldPath.length - 1];
                        
                        if (target && Array.isArray(target[lastField])) {
                            target[lastField] = target[lastField].map(transform.mapping);
                        }
                    } else {
                        // Apply to the whole data
                        if (Array.isArray(result)) {
                            result = result.map(transform.mapping);
                        }
                    }
                    break;
                    
                case "filter":
                    // Filter items in an array field
                    if (transform.field) {
                        const fieldPath = transform.field.split(".");
                        let target = result;
                        
                        // Navigate to the target field
                        for (let i = 0; i < fieldPath.length - 1; i++) {
                            target = target[fieldPath[i]];
                            if (!target) break;
                        }
                        
                        const lastField = fieldPath[fieldPath.length - 1];
                        
                        if (target && Array.isArray(target[lastField])) {
                            target[lastField] = target[lastField].filter(transform.condition);
                        }
                    } else {
                        // Apply to the whole data
                        if (Array.isArray(result)) {
                            result = result.filter(transform.condition);
                        }
                    }
                    break;
                    
                case "sort":
                    // Sort items in an array field
                    if (transform.field) {
                        const fieldPath = transform.field.split(".");
                        let target = result;
                        
                        // Navigate to the target field
                        for (let i = 0; i < fieldPath.length - 1; i++) {
                            target = target[fieldPath[i]];
                            if (!target) break;
                        }
                        
                        const lastField = fieldPath[fieldPath.length - 1];
                        
                        if (target && Array.isArray(target[lastField])) {
                            if (transform.key) {
                                // Sort by a specific key
                                target[lastField].sort((a, b) => {
                                    const valueA = typeof a[transform.key] === 'string' ? 
                                        a[transform.key].toLowerCase() : a[transform.key];
                                    const valueB = typeof b[transform.key] === 'string' ? 
                                        b[transform.key].toLowerCase() : b[transform.key];
                                        
                                    if (valueA < valueB) return transform.desc ? 1 : -1;
                                    if (valueA > valueB) return transform.desc ? -1 : 1;
                                    return 0;
                                });
                            } else {
                                // Simple sort
                                target[lastField].sort();
                                if (transform.desc) {
                                    target[lastField].reverse();
                                }
                            }
                        }
                    } else {
                        // Apply to the whole data
                        if (Array.isArray(result)) {
                            if (transform.key) {
                                // Sort by a specific key
                                result.sort((a, b) => {
                                    const valueA = typeof a[transform.key] === 'string' ? 
                                        a[transform.key].toLowerCase() : a[transform.key];
                                    const valueB = typeof b[transform.key] === 'string' ? 
                                        b[transform.key].toLowerCase() : b[transform.key];
                                        
                                    if (valueA < valueB) return transform.desc ? 1 : -1;
                                    if (valueA > valueB) return transform.desc ? -1 : 1;
                                    return 0;
                                });
                            } else {
                                // Simple sort
                                result.sort();
                                if (transform.desc) {
                                    result.reverse();
                                }
                            }
                        }
                    }
                    break;
                    
                case "group":
                    // Group items in an array field by a key
                    if (transform.field && transform.key) {
                        const fieldPath = transform.field.split(".");
                        let target = result;
                        
                        // Navigate to the target field
                        for (let i = 0; i < fieldPath.length - 1; i++) {
                            target = target[fieldPath[i]];
                            if (!target) break;
                        }
                        
                        const lastField = fieldPath[fieldPath.length - 1];
                        
                        if (target && Array.isArray(target[lastField])) {
                            const grouped = {};
                            target[lastField].forEach(item => {
                                const key = item[transform.key];
                                if (!grouped[key]) {
                                    grouped[key] = [];
                                }
                                grouped[key].push(item);
                            });
                            
                            // Replace with grouped data
                            if (transform.replaceWith === "groups") {
                                target[lastField] = grouped;
                            } else {
                                // Convert to array of groups
                                const groupsArray = Object.keys(grouped).map(key => ({
                                    key: key,
                                    items: grouped[key]
                                }));
                                target[lastField] = groupsArray;
                            }
                        }
                    }
                    break;
                    
                case "aggregate":
                    // Aggregate values in an array field
                    if (transform.field && transform.aggregates) {
                        const fieldPath = transform.field.split(".");
                        let target = result;
                        
                        // Navigate to the target field
                        for (let i = 0; i < fieldPath.length - 1; i++) {
                            target = target[fieldPath[i]];
                            if (!target) break;
                        }
                        
                        const lastField = fieldPath[fieldPath.length - 1];
                        
                        if (target && Array.isArray(target[lastField])) {
                            const aggregateResults = {};
                            
                            for (const agg of transform.aggregates) {
                                if (agg.type === "sum" && agg.property) {
                                    aggregateResults[`sum_${agg.property}`] = target[lastField].reduce(
                                        (sum, item) => sum + (parseFloat(item[agg.property]) || 0), 0
                                    );
                                } else if (agg.type === "avg" && agg.property) {
                                    const sum = target[lastField].reduce(
                                        (sum, item) => sum + (parseFloat(item[agg.property]) || 0), 0
                                    );
                                    aggregateResults[`avg_${agg.property}`] = sum / target[lastField].length;
                                } else if (agg.type === "min" && agg.property) {
                                    aggregateResults[`min_${agg.property}`] = Math.min(...target[lastField].map(
                                        item => parseFloat(item[agg.property]) || 0
                                    ));
                                } else if (agg.type === "max" && agg.property) {
                                    aggregateResults[`max_${agg.property}`] = Math.max(...target[lastField].map(
                                        item => parseFloat(item[agg.property]) || 0
                                    ));
                                } else if (agg.type === "count") {
                                    aggregateResults.count = target[lastField].length;
                                }
                            }
                            
                            // Add the aggregates to the result
                            if (transform.addToResult) {
                                // Create parent objects if needed
                                let current = result;
                                const parts = transform.addToResult.split(".");
                                
                                for (let i = 0; i < parts.length - 1; i++) {
                                    if (!current[parts[i]]) {
                                        current[parts[i]] = {};
                                    }
                                    current = current[parts[i]];
                                }
                                
                                current[parts[parts.length - 1]] = aggregateResults;
                            } else {
                                // Just add at the top level
                                result.aggregates = aggregateResults;
                            }
                        }
                    }
                    break;
            }
        }
        
        return {
            success: true,
            data: result,
            message: `Applied ${transformations.length} transformations`
        };
    } catch (error) {
        return {
            success: false,
            error: `Error transforming data: ${error.message}`
        };
    }
}

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

## Example Input Parameters

When using with MCP, you can provide these parameters based on the action:

### For `fetchAPI` action:
- `url`: API endpoint URL (required)
- `method`: HTTP method (GET, POST, PUT, DELETE, etc.)
- `headers`: Object containing HTTP headers
- `body`: Request body (object for JSON, string for other formats)
- `auth`: Authentication details (e.g., `{type: "basic", username: "user", password: "pass"}`)

### For `processJSONFile` action:
- `filePath`: Path to the JSON file to process (required)
- `transformation`: Type of transformation to apply ("extract", "stats", "structure")

### For `convertJSON` action:
- `data`: JSON data to convert (required)
- `format`: Target format ("json", "csv", "xml", "plist")

### For `transformData` action:
- `data`: JSON data to transform (required)
- `transformations`: Array of transformation operations:
  - Map: `{type: "map", field: "fieldName", mapping: function}`
  - Filter: `{type: "filter", field: "fieldName", condition: function}`
  - Sort: `{type: "sort", field: "fieldName", key: "sortKey", desc: boolean}`
  - Group: `{type: "group", field: "fieldName", key: "groupKey"}`
  - Aggregate: `{type: "aggregate", field: "fieldName", aggregates: [{type: "sum", property: "value"}]}`

### For `saveJSON` action:
- `data`: JSON data to save (required)
- `filePath`: Path where to save the JSON file (required)
- `pretty`: Whether to format the JSON with indentation (default: false)

### For `mergeJSON` action:
- `sources`: Array of JSON sources (file paths or objects) to merge (required)
- `strategy`: Merge strategy ("shallow", "deep", "arrays_concat", "arrays_unique")

## Example Usage

### Fetch data from an API

```json
{
  "action": "fetchAPI",
  "url": "https://api.example.com/data",
  "method": "GET",
  "headers": {
    "Accept": "application/json",
    "Content-Type": "application/json"
  },
  "auth": {
    "type": "bearer",
    "token": "your_access_token"
  }
}
```

### Transform JSON data

```json
{
  "action": "transformData",
  "data": {
    "employees": [
      {"id": 1, "firstName": "John", "lastName": "Doe", "department": "Engineering", "salary": 85000},
      {"id": 2, "firstName": "Jane", "lastName": "Smith", "department": "Marketing", "salary": 75000},
      {"id": 3, "firstName": "Bob", "lastName": "Johnson", "department": "Engineering", "salary": 82000},
      {"id": 4, "firstName": "Alice", "lastName": "Williams", "department": "HR", "salary": 70000}
    ]
  },
  "transformations": [
    {
      "type": "map",
      "field": "employees",
      "mapping": "employee => ({id: employee.id, name: `${employee.firstName} ${employee.lastName}`, department: employee.department, salary: employee.salary})"
    },
    {
      "type": "filter",
      "field": "employees",
      "condition": "employee => employee.salary > 75000"
    },
    {
      "type": "sort",
      "field": "employees",
      "key": "salary",
      "desc": true
    },
    {
      "type": "group",
      "field": "employees",
      "key": "department"
    }
  ]
}
```

### Process and save JSON data

```json
{
  "action": "processJSONFile",
  "filePath": "/path/to/data.json",
  "transformation": "stats"
}
```

```json
{
  "action": "saveJSON",
  "data": {"processed": true, "results": [1, 2, 3]},
  "filePath": "/path/to/output.json",
  "pretty": true
}
```

### Merge multiple JSON sources

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

## Security and Networking Note

This script requires network access for API requests. When fetching from external APIs, be aware of:

1. Data security - only transmit sensitive information over HTTPS
2. API rate limits - implement appropriate error handling and retries
3. Response validation - verify API responses before processing
4. Error handling - gracefully handle network errors and API failures

When working with local files, ensure proper permissions and validation to avoid security issues.
