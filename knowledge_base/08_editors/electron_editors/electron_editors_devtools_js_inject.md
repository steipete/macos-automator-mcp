---
title: 'Electron Editors: Open DevTools & Inject JavaScript'
category: 08_editors
id: electron_editors_devtools_js_inject
description: >-
  Opens Developer Tools in a frontmost Electron-based editor (VS Code, Cursor,
  etc.) and types/executes JavaScript in its console.
keywords:
  - vscode
  - cursor
  - windsurf
  - electron
  - devtools
  - javascript
  - inject
  - console
  - ui scripting
language: applescript
isComplex: true
argumentsPrompt: >-
  Target application name (e.g., 'Visual Studio Code' or 'Cursor') as
  'targetAppName' and JavaScript code (single line recommended for direct
  keystroke) as 'jsCodeToRun' in inputData.
notes: >
  - Target application must be frontmost or activated by the script.

  - Relies on the standard DevTools shortcut (Option+Command+I).

  - UI scripting is fragile; delays might need adjustment.

  - Best for short, single-line JS. For multiline, use clipboard paste method
  (see separate tip).

  - The script types the JS; it doesn't directly get a return value back to
  AppleScript.
---

```applescript
--MCP_INPUT:targetAppName
--MCP_INPUT:jsCodeToRun

on injectJSViaDevTools(appName, jsCode)
  if appName is missing value or appName is "" then return "error: Target application name not provided."
  if jsCode is missing value or jsCode is "" then return "error: JavaScript code not provided."

  try
    tell application appName
      activate
    end tell
    delay 0.5 -- Allow app to activate

    tell application "System Events"
      tell process appName -- Ensures keystrokes go to the target app
        set frontmost to true
        
        -- Open Developer Tools (Option+Command+I)
        key code 34 using {command down, option down} -- Key code for 'I'
        delay 1.0 -- Wait for DevTools to open (console usually gets focus)
        
        -- Keystroke the JavaScript. Note: complex characters might not type correctly.
        keystroke jsCode
        delay 0.2
        key code 36 -- Return (Enter key) to execute
        
        -- Optional: Close DevTools again
        -- delay 0.5
        -- key code 34 using {command down, option down}
      end tell
    end tell
    return "JavaScript injection attempted in " & appName & "'s DevTools."
  on error errMsg
    return "error: Failed to inject JS in " & appName & " - " & errMsg
  end try
end injectJSViaDevTools

return my injectJSViaDevTools("--MCP_INPUT:targetAppName", "--MCP_INPUT:jsCodeToRun")
```
END_TIP
