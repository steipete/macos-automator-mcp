---
id: devtools_capture_network_har
title: Capture Network Activity to HAR File
description: Captures network activity from browser developer tools and saves it as a HAR file
language: applescript
author: Claude
keywords:
  - network
  - debugging
  - performance
  - har
  - devtools
usage_examples:
  - "Record network traffic from a web application for debugging"
  - "Save API requests and responses for analysis"
  - "Monitor network performance of a website"
parameters:
  - name: savePath
    description: Path where to save the HAR file (POSIX path)
    required: true
  - name: duration
    description: Duration in seconds to record network activity (default 30)
    required: false
  - name: browser
    description: Browser to use (chrome or safari, default chrome)
    required: false
---

# Capture Network Activity to HAR File

This script opens browser developer tools, records network activity for a specified duration, and saves it as a HAR (HTTP Archive) file. HAR files contain detailed information about network requests including headers, timing, and response data.

```applescript
on run {input, parameters}
    set savePath to "--MCP_INPUT:savePath"
    set duration to "--MCP_INPUT:duration"
    set browser to "--MCP_INPUT:browser"
    
    -- Set defaults if parameters not provided
    if savePath is "" or savePath is missing value then
        set defaultFilename to "network_capture_" & (do shell script "date +%Y%m%d_%H%M%S") & ".har"
        set savePath to (POSIX path of (path to desktop)) & defaultFilename
    end if
    
    if duration is "" or duration is missing value then
        set duration to 30
    else
        try
            set duration to duration as number
        on error
            display dialog "Invalid duration: " & duration & ". Please enter a number in seconds." buttons {"OK"} default button "OK" with icon stop
            return
        end try
    end if
    
    if browser is "" or browser is missing value then
        set browser to "chrome"
    end if
    
    if browser is not "chrome" and browser is not "safari" then
        display dialog "Invalid browser: " & browser & ". Please specify 'chrome' or 'safari'." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Ensure save directory exists
    set saveDir to do shell script "dirname " & quoted form of savePath
    do shell script "mkdir -p " & quoted form of saveDir
    
    -- Start network recording based on browser choice
    if browser is "chrome" then
        recordInChrome(savePath, duration)
    else if browser is "safari" then
        recordInSafari(savePath, duration)
    end if
    
    return "Network activity saved to " & savePath
end run

on recordInChrome(savePath, duration)
    tell application "Google Chrome"
        activate
        
        -- Open DevTools with Network panel
        tell application "System Events"
            tell process "Google Chrome"
                -- Open DevTools with Option+Command+I
                keystroke "i" using {command down, option down}
                delay 1
                
                -- Switch to Network panel (Option+Command+N)
                keystroke "n" using {command down, option down}
                delay 1
                
                -- Clear network panel (Command+K)
                keystroke "k" using {command down}
                delay 0.5
                
                -- Start recording
                display notification "Recording network activity for " & duration & " seconds..." with title "Network Capture"
                
                -- Wait for specified duration
                delay duration
                
                -- Save HAR file
                -- Right-click in network panel
                click at {400, 300} using {control down}
                delay 0.5
                
                -- Find and click "Save all as HAR with content"
                set foundMenuItem to false
                repeat with menuItem in (menu items of menu 1 of menu item "Save all as HAR with content" of menu 1)
                    if name of menuItem contains "Save all as HAR with content" then
                        click menuItem
                        set foundMenuItem to true
                        exit repeat
                    end if
                end repeat
                
                if not foundMenuItem then
                    -- Try clicking the menu item directly
                    click menu item "Save all as HAR with content" of menu 1
                end if
                
                delay 1
                
                -- Enter save path in dialog
                keystroke savePath
                delay 0.5
                keystroke return
                
                -- Close DevTools (Option+Command+I again)
                delay 1
                keystroke "i" using {command down, option down}
            end tell
        end tell
    end tell
end recordInChrome

on recordInSafari(savePath, duration)
    tell application "Safari"
        activate
        
        -- Open Web Inspector with Network tab
        tell application "System Events"
            tell process "Safari"
                -- Open Web Inspector (Option+Command+I)
                keystroke "i" using {command down, option down}
                delay 1
                
                -- Switch to Network tab
                keystroke "2" using {command down, option down}
                delay 1
                
                -- Clear Network panel (Command+K)
                keystroke "k" using {command down}
                delay 0.5
                
                -- Start recording
                display notification "Recording network activity for " & duration & " seconds..." with title "Network Capture"
                
                -- Wait for specified duration
                delay duration
                
                -- Export HAR file
                -- Right-click in Network panel
                click at {400, 300} using {control down}
                delay 0.5
                
                -- Find and click "Export" or similar menu item (Safari's UI might vary)
                repeat with menuItem in menu items of menu 1
                    if name of menuItem contains "Export" then
                        click menuItem
                        exit repeat
                    end if
                end repeat
                
                delay 1
                
                -- Enter save path in dialog
                keystroke savePath
                delay 0.5
                keystroke return
                
                -- Close Web Inspector (Option+Command+I again)
                delay 1
                keystroke "i" using {command down, option down}
            end tell
        end tell
    end tell
end recordInSafari
```

## What is a HAR File?

HAR (HTTP Archive) is a JSON-formatted archive file format that contains a log of a web browser's interaction with a web server. HAR files include:

- Detailed timing data for each request
- HTTP request and response headers
- Cookies
- Request and response content
- IP addresses
- Connection information
- Browser cache information

## Uses for HAR Files

HAR files are valuable for:

1. **Debugging** - Analyze API calls and responses
2. **Performance analysis** - Identify slow requests and bottlenecks
3. **Documentation** - Archive API interactions for reference
4. **Testing** - Create realistic test scenarios based on actual traffic
5. **Sharing** - Send network activity to colleagues or support teams

## Analysis Tools

Several tools can help analyze HAR files:

- **HAR Analyzer** - Online tool to visualize and analyze HAR files
- **Chrome DevTools** - Import HAR files back into the Network panel
- **Fiddler** - Import and analyze HAR files
- **Charles Proxy** - View, filter, and search HAR files

## Security Note

HAR files may contain sensitive information such as:
- Authentication tokens and cookies
- Personal information in requests/responses
- Internal API details and structures

Be careful when sharing HAR files and redact sensitive data if necessary.