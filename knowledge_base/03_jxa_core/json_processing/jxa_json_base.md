---
title: JXA JSON Processing Base
category: 03_jxa_core
id: jxa_json_processing_base
description: >-
  Base functionality for processing JSON data using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - api
  - data
  - processing
---

# JXA JSON Processing Base

This script provides the core functionality for working with JSON data using JavaScript for Automation (JXA). It includes the main run function and parameter processing.

## Usage

This base script is designed to be used with various JSON processing actions.

```javascript
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
```

## Helper Function

The script includes a utility function to check if a value is an object.

```javascript
// Helper function to check if value is an object
function isObject(item) {
    return (item && typeof item === 'object' && !Array.isArray(item));
}
```

This base script works together with specialized functions for each JSON processing action.