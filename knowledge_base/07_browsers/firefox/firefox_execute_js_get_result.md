---
title: "Firefox: Execute JavaScript and Get Result"
category: "05_web_browsers"
id: firefox_execute_js_get_result
description: "Executes JavaScript in the front tab of Firefox and returns the result."
keywords: ["Firefox", "JavaScript", "execute", "browser", "automation", "JS"]
language: applescript
notes: |
  - Firefox must be running.
  - This script uses UI scripting and the clipboard for output.
  - You may need to enable accessibility permissions for the script to work.
  - This works by opening the Web Console, executing the JS, and copying the result.
---

This script executes JavaScript in the current tab of Firefox and returns the result. Since Firefox has limited AppleScript support, this script uses UI scripting to open the Web Console, execute the JavaScript, and retrieve the result.

```applescript
on run {input, parameters}
  set jsCode to "--MCP_INPUT:javascript"
  
  -- Save the current clipboard content
  set oldClipboard to the clipboard
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Open Web Console
  tell application "System Events"
    tell process "Firefox"
      keystroke "k" using {command down, option down}
      delay 1 -- Allow console to open
    end tell
  end tell
  
  -- Clear any existing console content
  tell application "System Events"
    tell process "Firefox"
      keystroke "l" using {command down}
      delay 0.5
    end tell
  end tell
  
  -- Enter and execute JavaScript
  tell application "System Events"
    tell process "Firefox"
      keystroke jsCode
      keystroke return
      delay 0.5 -- Allow execution to complete
      
      -- Select the result (last line in console)
      keystroke "a" using {command down}
      delay 0.2
      keystroke "c" using {command down}
      delay 0.2
    end tell
  end tell
  
  -- Get result from clipboard
  set jsResult to the clipboard
  
  -- Close Web Console
  tell application "System Events"
    tell process "Firefox"
      keystroke "k" using {command down, option down}
    end tell
  end tell
  
  -- Restore the original clipboard content
  set the clipboard to oldClipboard
  
  return jsResult
end run
```

Note: This method is somewhat fragile as it depends on keyboard shortcuts and UI elements that might change in future Firefox versions. An alternative approach would be to use browser extensions or remote debugging protocols for more reliable Firefox automation.
END_TIP