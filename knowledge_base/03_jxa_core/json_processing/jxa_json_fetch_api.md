---
title: JXA JSON API Fetching
category: 03_jxa_core
id: jxa_json_fetch_api
description: >-
  A script for fetching data from REST APIs using JavaScript for Automation (JXA).
language: javascript
keywords:
  - jxa
  - javascript
  - json
  - api
  - rest
  - http
  - fetch
  - network
  - request
---

# JXA JSON API Fetching

This script provides functionality for fetching data from REST APIs using JavaScript for Automation (JXA).

## Usage

The function can be used to fetch data from various APIs with customizable request parameters.

```javascript
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
```

## Input Parameters

When using with MCP, you can provide these parameters:

- `url`: API endpoint URL (required)
- `method`: HTTP method (GET, POST, PUT, DELETE, etc.)
- `headers`: Object containing HTTP headers
- `body`: Request body (object for JSON, string for other formats)
- `auth`: Authentication details (e.g., `{type: "basic", username: "user", password: "pass"}`)

## Example Usage

Here's an example of how to use the `fetchAPI` function:

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

## Security Note

When fetching from external APIs, be aware of:

1. Data security - only transmit sensitive information over HTTPS
2. API rate limits - implement appropriate error handling and retries
3. Response validation - verify API responses before processing
4. Error handling - gracefully handle network errors and API failures