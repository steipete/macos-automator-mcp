---
title: FTP Operations with URL Access
category: 12_network
id: network_ftp_operations
description: >-
  Use URL Access scripting to perform FTP operations like downloading and
  uploading files.
keywords:
  - FTP
  - download
  - upload
  - URL Access
  - file transfer
  - network
  - curl
language: applescript
notes: |
  - Modern macOS versions prefer the curl command for FTP operations
  - URL Access is a legacy framework but still useful for simple operations
  - FTP credentials should be handled securely
  - May require authentication for non-public servers
---

This script demonstrates how to perform FTP operations in AppleScript using both the classic URL Access framework and the more modern `curl` command-line utility.

```applescript
--MCP_INPUT:ftpServer
--MCP_INPUT:username
--MCP_INPUT:password
--MCP_INPUT:remoteFilePath
--MCP_INPUT:localFilePath
--MCP_INPUT:operation

on performFtpOperation(ftpServer, username, password, remoteFilePath, localFilePath, operation)
  -- Validate required parameters
  if ftpServer is missing value or ftpServer is "" then
    return "error: FTP server address is required."
  end if
  if remoteFilePath is missing value or remoteFilePath is "" then
    return "error: Remote file path is required."
  end if
  if localFilePath is missing value or localFilePath is "" then
    return "error: Local file path is required."
  end if
  
  -- Default to download if operation not specified
  if operation is missing value or operation is "" then
    set operation to "download"
  end if
  
  -- Ensure the FTP URL has the proper format
  if ftpServer does not start with "ftp://" then
    set ftpServer to "ftp://" & ftpServer
  end if
  
  -- Construct the full FTP URL with credentials if provided
  set ftpUrl to ftpServer
  if username is not missing value and username is not "" then
    if password is not missing value and password is not "" then
      -- Include username and password
      set ftpUrl to "ftp://" & username & ":" & password & "@" & text 7 thru -1 of ftpServer
    else
      -- Include username only
      set ftpUrl to "ftp://" & username & "@" & text 7 thru -1 of ftpServer
    end if
  end if
  
  -- Append the remote file path to the URL
  if character 1 of remoteFilePath is not "/" then
    set remoteFilePath to "/" & remoteFilePath
  end if
  set ftpUrl to ftpUrl & remoteFilePath
  
  -- Make sure the local file path is in POSIX format
  if character 1 of localFilePath is not "/" then
    -- Try to convert from HFS path if needed
    try
      set localFilePath to POSIX path of localFilePath
    on error
      -- Assume it's a relative path and try to use it as is
    end try
  end if
  
  -- Perform the operation
  try
    if operation is "download" then
      -- Method 1: Using curl (recommended for modern macOS)
      set curlCmd to "curl -s -o " & quoted form of localFilePath & " " & quoted form of ftpUrl
      do shell script curlCmd
      return "Successfully downloaded file from " & ftpUrl & " to " & localFilePath
      
    else if operation is "upload" then
      -- Method 1: Using curl for upload
      set curlCmd to "curl -s -T " & quoted form of localFilePath & " " & quoted form of ftpUrl
      do shell script curlCmd
      return "Successfully uploaded file from " & localFilePath & " to " & ftpUrl
      
    else if operation is "list" then
      -- List directory contents
      set curlCmd to "curl -s -l " & quoted form of ftpUrl
      set directoryListing to do shell script curlCmd
      return "Directory listing for " & ftpUrl & ":" & return & directoryListing
      
    else
      return "error: Invalid operation. Use 'download', 'upload', or 'list'."
    end if
    
  on error errMsg
    return "Error performing FTP operation: " & errMsg
  end try
end performFtpOperation

-- Method 2: Legacy URL Access approach (for older macOS versions)
-- This is included for reference but the curl method above is recommended
on legacyFtpDownload(ftpUrl, localPath)
  try
    tell application "URL Access Scripting"
      set destFile to localPath
      download ftpUrl to file destFile replacing yes
      return "Successfully downloaded via URL Access Scripting"
    end tell
  on error errMsg
    return "Error using URL Access Scripting: " & errMsg
  end try
end legacyFtpDownload

-- Example usage with MCP input values
return my performFtpOperation("--MCP_INPUT:ftpServer", "--MCP_INPUT:username", "--MCP_INPUT:password", "--MCP_INPUT:remoteFilePath", "--MCP_INPUT:localFilePath", "--MCP_INPUT:operation")
```

This script provides three main FTP operations:

1. **Download Files**
   - Retrieves a file from an FTP server and saves it locally
   - Example: Download a configuration file from a server

2. **Upload Files**
   - Sends a local file to an FTP server
   - Example: Upload a log file or backup to a server

3. **List Directory Contents**
   - Lists files and directories at the specified remote path
   - Example: Check what files are available on the server

The script includes two implementation methods:
- Modern approach using `curl` (recommended for current macOS versions)
- Legacy approach using URL Access Scripting (included for reference)

Security considerations:
- FTP sends credentials in plain text (consider SFTP or FTPS for secure transfers)
- For security, never hardcode credentials in your scripts
- If your connection requires passive mode, add `-P -` to the curl commands
END_TIP
