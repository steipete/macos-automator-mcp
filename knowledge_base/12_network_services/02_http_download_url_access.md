---
title: "HTTP Download with URL Access and curl"
category: "12_network_services"
id: network_http_download
description: "Download files and content from the internet using both modern curl and legacy URL Access approaches."
keywords: ["HTTP", "download", "URL", "web", "fetch", "curl", "URL Access"]
language: applescript
isComplex: true
argumentsPrompt: "Provide a URL to download as 'url' and a local file path to save to as 'localPath' in inputData."
notes: |
  - Modern macOS versions prefer the curl command for HTTP operations
  - URL Access is a legacy framework but still included for backward compatibility
  - For more advanced HTTP operations (POST, custom headers), use curl
  - Security considerations apply when downloading files from the internet
---

This script demonstrates how to download files and content from the web using both the modern `curl` command-line utility and the legacy URL Access Scripting framework.

```applescript
--MCP_INPUT:url
--MCP_INPUT:localPath

on downloadFromWeb(downloadUrl, savePath)
  -- Validate parameters
  if downloadUrl is missing value or downloadUrl is "" then
    return "error: URL is required."
  end if
  
  -- If no save path provided, create a default one in Downloads folder
  if savePath is missing value or savePath is "" then
    -- Get the filename from the URL
    set fileName to last text item of downloadUrl delimited by "/"
    if fileName is "" or fileName contains "?" then
      set fileName to "downloaded_file"
    end if
    
    -- Create path in Downloads folder
    set downloadsFolder to POSIX path of (path to downloads folder)
    set savePath to downloadsFolder & fileName
  end if
  
  -- Ensure URL has proper prefix
  if downloadUrl does not start with "http://" and downloadUrl does not start with "https://" then
    set downloadUrl to "https://" & downloadUrl
  end if
  
  -- Make sure the local file path is in POSIX format
  if character 1 of savePath is not "/" then
    -- Try to convert from HFS path if needed
    try
      set savePath to POSIX path of savePath
    on error
      -- Assume it's a relative path and try to use it as is
    end try
  end if
  
  -- Download using curl (recommended for modern macOS)
  set method to "curl"
  
  try
    if method is "curl" then
      -- Method 1: Using curl
      set curlOutput to ""
      set curlCmd to "curl -sSL -o " & quoted form of savePath & " " & quoted form of downloadUrl & " && echo 'Download successful.'"
      
      -- Download the file
      set curlOutput to do shell script curlCmd
      
      -- Check if file was downloaded and get its size
      set checkCmd to "ls -l " & quoted form of savePath & " | awk '{print $5}'"
      set fileSize to do shell script checkCmd
      
      -- Get file type if possible
      set fileTypeCmd to "file -b " & quoted form of savePath
      set fileType to do shell script fileTypeCmd
      
      return "Successfully downloaded from " & downloadUrl & return & ¬
        "Saved to: " & savePath & return & ¬
        "File size: " & fileSize & " bytes" & return & ¬
        "File type: " & fileType
    else
      -- Method 2: Using legacy URL Access Scripting (works on older macOS)
      tell application "URL Access Scripting"
        set destFile to savePath
        download downloadUrl to file destFile replacing yes
        return "Successfully downloaded using URL Access Scripting" & return & ¬
          "URL: " & downloadUrl & return & ¬
          "Saved to: " & savePath
      end tell
    end if
  on error errMsg
    return "Error downloading from URL: " & errMsg
  end try
end downloadFromWeb

-- Helper function for simple text content download (for small files, APIs, etc.)
on fetchUrlContent(theUrl)
  try
    -- Use curl to fetch web content
    set curlCmd to "curl -sSL " & quoted form of theUrl
    set webContent to do shell script curlCmd
    return webContent
  on error errMsg
    return "Error fetching URL content: " & errMsg
  end try
end fetchUrlContent

-- Example usage with MCP input placeholders
return my downloadFromWeb("--MCP_INPUT:url", "--MCP_INPUT:localPath")
```

This script provides two main approaches for downloading web content:

1. **Modern curl approach (Recommended)**
   - Uses the `curl` command-line tool built into macOS
   - Highly reliable and full-featured
   - Supports HTTPS, redirects, and proper error handling
   - Provides download status and file information

2. **Legacy URL Access Scripting approach**
   - Included for compatibility with older scripts and systems
   - Less feature-rich but has a simpler syntax
   - May be deprecated in future macOS versions

The script also includes a helper function `fetchUrlContent` for quickly retrieving the text content of a URL without saving to a file, which is useful for:
- Reading API responses
- Fetching small text files
- Checking web page content

Common use cases:
- Downloading files from web servers
- Fetching data from APIs
- Retrieving resources for local processing
- Backing up online content

For more advanced HTTP operations (like POST requests, custom headers, cookies, and authentication), the curl approach provides much more flexibility through additional command-line options.
END_TIP