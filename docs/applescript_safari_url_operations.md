# AppleScript: Safari URL Operations

This document demonstrates how to automate Safari for URL operations using AppleScript. You can open URLs in new tabs, get the current page URL, and manage browser windows and tabs.

## Opening a URL in a New Tab

```applescript
on openInSafariNewTab(theURL)
  tell application "Safari"
    -- Launch Safari if it's not running
    if not running then
      run
      delay 1 -- Give Safari time to launch
    end if
    activate
    
    -- Open in new window if no windows exist, or new tab if windows already open
    if (count of windows) is 0 then
      make new document with properties {URL:theURL}
    else
      tell front window
        set newTab to make new tab with properties {URL:theURL}
        set current tab to newTab -- Make the new tab active
      end tell
    end if
  end tell
end openInSafariNewTab

-- Usage example:
openInSafariNewTab("https://apple.com")
```

## Getting the URL from the Current Tab

```applescript
tell application "Safari"
  if not running then
    return "Safari is not running"
  end if
  
  if (count of windows) is 0 then
    return "No Safari windows are open"
  end if
  
  set currentURL to URL of current tab of front window
  return currentURL
end tell
```

## Common Use Cases

- Automating web research by opening multiple URLs
- Creating workflows that navigate to specific web applications
- Building dashboard systems that open multiple monitoring pages
- Integrating with other scripts to open URLs based on conditions or events
- Setting up a daily workflow that opens specific sites you use regularly

## Advanced Usage: Managing Multiple Tabs

```applescript
tell application "Safari"
  activate
  
  -- Open multiple websites in new tabs
  set siteList to {"https://apple.com", "https://developer.apple.com", "https://support.apple.com"}
  
  repeat with currentSite in siteList
    tell front window
      make new tab with properties {URL:currentSite}
    end tell
  end repeat
  
  -- Switch to the first tab we created
  tell front window
    set current tab to tab 2 -- Tab 1 is the original tab
  end tell
end tell
```

## Notes and Limitations

- These scripts require permission to control Safari, which the user must grant
- Some operations may be blocked by Safari's privacy and security measures
- For websites requiring authentication, these simple scripts won't handle logins
- Safari must be the active application to ensure proper tab focus
- If Automation privacy settings are restrictive, the script may fail with permission errors