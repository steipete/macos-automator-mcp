---
title: JXA JSON Data Transformation
category: 03_jxa_core
id: jxa_json_transform_data
description: >-
  A script for transforming JSON data with operations like mapping, filtering, sorting, and aggregation using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - transform
  - map
  - filter
  - sort
  - group
  - aggregate
  - data processing
---

# JXA JSON Data Transformation

This script provides functionality for transforming JSON data with various operations using JavaScript for Automation (JXA).

## Usage

The function can transform JSON data using mapping, filtering, sorting, grouping, and aggregation operations.

```javascript
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
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `data`: JSON data to transform (required)
- `transformations`: Array of transformation operations:
  - Map: `{type: "map", field: "fieldName", mapping: function}`
  - Filter: `{type: "filter", field: "fieldName", condition: function}`
  - Sort: `{type: "sort", field: "fieldName", key: "sortKey", desc: boolean}`
  - Group: `{type: "group", field: "fieldName", key: "groupKey"}`
  - Aggregate: `{type: "aggregate", field: "fieldName", aggregates: [{type: "sum", property: "value"}]}`

## Example Usage

Here's an example of how to use the `transformData` function:

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

The script supports several transformation types that can be applied sequentially:
- Mapping: Transform each item in an array
- Filtering: Remove items that don't meet certain conditions
- Sorting: Order items by specified properties
- Grouping: Organize items into groups based on property values
- Aggregation: Calculate statistics like sum, average, min, max, and count