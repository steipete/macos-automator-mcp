# AppleScript: Network Operations

This document demonstrates how to perform network operations like downloading files, fetching web content, and working with network services using AppleScript.

## Downloading Files with curl

```applescript
on downloadWithCurl(downloadUrl, savePath)
  -- Ensure URL has proper prefix
  if downloadUrl does not start with "http://" and downloadUrl does not start with "https://" then
    set downloadUrl to "https://" & downloadUrl
  end if
  
  -- If no save path provided, use Downloads folder
  if savePath is missing value or savePath is "" then
    set fileName to last text item of downloadUrl delimited by "/"
    if fileName is "" or fileName contains "?" then
      set fileName to "downloaded_file"
    end if
    
    set downloadsFolder to POSIX path of (path to downloads folder)
    set savePath to downloadsFolder & fileName
  end if
  
  -- Download the file with curl
  set curlCmd to "curl -sSL -o " & quoted form of savePath & " " & quoted form of downloadUrl
  try
    do shell script curlCmd
    
    -- Get file size
    set fileSize to do shell script "ls -l " & quoted form of savePath & " | awk '{print $5}'"
    
    return "Successfully downloaded to: " & savePath & " (" & fileSize & " bytes)"
  on error errMsg
    return "Error downloading: " & errMsg
  end try
end downloadWithCurl

-- Usage example
downloadWithCurl("https://example.com/sample.pdf", "")
```

## Fetching Web Content (Text/API)

```applescript
on fetchWebContent(theUrl)
  -- Ensure URL has proper prefix
  if theUrl does not start with "http://" and theUrl does not start with "https://" then
    set theUrl to "https://" & theUrl
  end if
  
  try
    -- Use curl to fetch text content
    set curlCmd to "curl -sSL " & quoted form of theUrl
    set webContent to do shell script curlCmd
    return webContent
  on error errMsg
    return "Error fetching content: " & errMsg
  end try
end fetchWebContent

-- Usage example (get weather data from an API)
set weatherJSON to fetchWebContent("https://api.weather.gov/points/39.7456,-97.0892")
```

## Making POST Requests

```applescript
on postToWebService(apiUrl, jsonData)
  -- Create the curl command for a POST request with JSON
  set curlCmd to "curl -sSL -X POST -H 'Content-Type: application/json' -d " & ¬
                  quoted form of jsonData & " " & quoted form of apiUrl
  
  try
    set apiResponse to do shell script curlCmd
    return apiResponse
  on error errMsg
    return "Error making POST request: " & errMsg
  end try
end postToWebService

-- Usage example
set userData to "{\"name\":\"John Doe\",\"email\":\"john@example.com\"}"
postToWebService("https://api.example.com/users", userData)
```

## Checking Network Connection

```applescript
on checkNetworkConnection()
  try
    -- Ping Google's DNS to check connection (with 2 second timeout)
    do shell script "ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1"
    return true
  on error
    return false
  end try
end checkNetworkConnection

if checkNetworkConnection() then
  display dialog "Internet connection is active"
else
  display dialog "No internet connection available" buttons {"OK"} default button 1 with icon stop
end if
```

## Common Use Cases

- Downloading files and resources for local processing
- Fetching data from web APIs and services
- Interacting with web applications programmatically
- Automating web-based workflows
- Checking network status before performing operations
- Backing up online content to local storage

## Notes and Limitations

- These operations require active internet connectivity
- For HTTPS URLs, proper certificates must be in place
- Some network operations may require specific permissions or entitlements
- Large downloads should provide progress feedback in production scripts
- For complex HTTP operations, using curl with advanced parameters is recommended
- Network timeouts should be handled gracefully in production scripts