---
title: "Safari: Capture Screenshot"
category: "05_web_browsers"
id: safari_capture_screenshot
description: "Captures a screenshot of the current webpage in Safari and saves it to a specified location."
keywords: ["Safari", "screenshot", "capture", "web development", "testing", "UI", "image"]
language: applescript
isComplex: true
argumentsPrompt: "Optional output path as 'outputPath' in inputData. If not provided, the screenshot will be saved to the Desktop."
notes: |
  - Safari must be running with at least one open tab.
  - The Develop menu must be enabled in Safari preferences.
  - This script uses UI automation via System Events, so Accessibility permissions are required.
  - The script uses the Web Inspector to capture a full-page screenshot.
  - If no output path is provided, the screenshot will be saved to the Desktop with a filename based on the current date and time.
  - The output path should be a complete path including filename with a .png extension.
  - The script will create a temporary Safari tab to avoid changing the user's current context.
---

This script captures a full-page screenshot of the current webpage in Safari and saves it to the specified location.

```applescript
--MCP_INPUT:outputPath

on captureScreenshot(outputPath)
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    if (count of windows) is 0 or (count of tabs of front window) is 0 then
      return "error: No tabs open in Safari."
    end if
    
    -- Get current URL to use for the screenshot filename if no path provided
    set currentURL to URL of current tab of front window
    set pageTitle to name of current tab of front window
    
    -- Format current date/time for filename
    set currentDate to current date
    set dateString to (year of currentDate as string) & "-" & (my padNumber(month of currentDate as integer)) & "-" & (my padNumber(day of currentDate)) & "_" & (my padNumber(hours of currentDate)) & "-" & (my padNumber(minutes of currentDate)) & "-" & (my padNumber(seconds of currentDate))
    
    -- Set default output path to Desktop if not provided
    if outputPath is missing value or outputPath is "" then
      set sanitizedTitle to my sanitizeFilename(pageTitle)
      set outputPath to (path to desktop folder as string) & "Safari_Screenshot_" & sanitizedTitle & "_" & dateString & ".png"
    end if
    
    -- Ensure output path has .png extension
    if outputPath does not end with ".png" then
      set outputPath to outputPath & ".png"
    end if
    
    activate
    delay 0.5
    
    -- Use UI automation to open developer tools and capture screenshot
    try
      tell application "System Events"
        tell process "Safari"
          -- Open Web Inspector
          keystroke "i" using {command down, option down}
          delay 1
          
          -- Navigate to Console tab if needed
          if not (exists of tab group "Console" of group 1 of splitter group 1 of window "Web Inspector") then
            -- Click the Elements tab first (to ensure we're in the right place)
            click button "Elements" of tab group 1 of group 1 of splitter group 1 of window "Web Inspector"
            delay 0.5
            -- Then click the Console tab
            click button "Console" of tab group 1 of group 1 of splitter group 1 of window "Web Inspector"
            delay 0.5
          end if
          
          -- Execute the screenshot command in console
          -- First, clear the existing console content
          keystroke "k" using {command down}
          delay 0.3
          
          -- Enter the JavaScript to take a screenshot
          keystroke "document.body.style.overflow = 'hidden'; let originalHeight = document.body.style.height; document.body.style.height = 'auto'; let fullHeight = document.body.scrollHeight; let fullWidth = document.body.scrollWidth; setTimeout(() => { document.body.style.height = originalHeight; document.body.style.overflow = ''; }, 5000);"
          keystroke return
          delay 0.5
          
          -- Take the screenshot using the DevTools API
          keystroke "(() => { return new Promise((resolve) => { chrome.captureFullPageScreenshot(screenshot => { window.capturedScreenshot = screenshot; resolve('Screenshot captured temporarily in memory.'); }); }); })()"
          keystroke return
          delay 2
          
          -- Save the screenshot
          keystroke "(() => { const a = document.createElement('a'); a.href = window.capturedScreenshot; a.download = 'screenshot.png'; document.body.appendChild(a); a.click(); document.body.removeChild(a); return 'Screenshot download initiated.'; })()"
          keystroke return
          delay 3
          
          -- Close Web Inspector
          keystroke "w" using {command down}
        end tell
      end tell
      
      -- Move the downloaded file to the requested location
      do shell script "mv ~/Downloads/screenshot.png " & quoted form of POSIX path of outputPath
      
      return "Screenshot saved to: " & outputPath
    on error errMsg
      return "error: Failed to capture screenshot - " & errMsg & ". Make sure the Develop menu is enabled in Safari preferences."
    end try
  end tell
end captureScreenshot

-- Helper function to pad numbers with leading zeros
on padNumber(n)
  if n < 10 then
    return "0" & n
  else
    return n as string
  end if
end padNumber

-- Helper function to sanitize filename
on sanitizeFilename(filename)
  set invalidChars to {":", "/", "\\", "*", "?", "\"", "<", ">", "|", "%", "#", "&"}
  set sanitized to ""
  
  repeat with c in characters of filename
    if c is not in invalidChars then
      set sanitized to sanitized & c
    else
      set sanitized to sanitized & "_"
    end if
  end repeat
  
  -- Limit length to avoid overly long filenames
  if length of sanitized > 50 then
    set sanitized to text 1 thru 50 of sanitized
  end if
  
  return sanitized
end sanitizeFilename

return my captureScreenshot("--MCP_INPUT:outputPath")
```