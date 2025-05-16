---
title: 'Terminal: Send Control Character'
id: terminal_send_control_character
category: 06_terminal/terminal_app
description: >-
  Sends a control character (e.g., Ctrl-C, Escape) to the frontmost Terminal.app
  window by simulating keystrokes.
keywords:
  - Terminal.app
  - control character
  - Ctrl-C
  - escape
  - signal
  - keystroke
  - System Events
language: applescript
argumentsPrompt: >-
  Expects inputData: { "controlChar": "X" } where X is a single uppercase letter
  (A-Z) for Ctrl-X, or special strings like "ESC" (for Escape key), or "]" (for
  Ctrl-]).
isComplex: false
---

This script sends a control character to the active process in the frontmost `Terminal.app` window. It achieves this by using `System Events` to simulate the necessary keystrokes.

**Supported `controlChar` inputs:**
- A single uppercase letter from "A" to "Z" (e.g., "C" for Ctrl-C).
- "ESC" for the Escape key.
- "]" for Ctrl-] (Group Separator, ASCII 29).

**Important Notes:**
- `Terminal.app` must be running and have an active window.
- The script will target the frontmost window of `Terminal.app`.
- This relies on UI Scripting (`System Events`), so `Terminal.app` (or the application running this MCP server) may need Accessibility permissions.

```applescript
on runWithInput(inputData, legacyArguments)
    set charToSend to ""
    if inputData is not missing value and inputData contains {controlChar:""} then
        set charToSend to controlChar of inputData
    else
        return "Error: controlChar not provided in inputData. Expects e.g. { \"controlChar\": \"C\" }."
    end if

    if charToSend is "" then
        return "Error: controlChar was empty."
    end if
    
    -- MCP placeholder for input
    set charToSend to "--MCP_INPUT:controlChar" -- The control character to send (A-Z for Ctrl-A to Ctrl-Z, or ESC, or ])

    set upperChar to ""
    try
        string id (ASCII number of charToSend) -- crude way to check if it's a single char for ASCII number
        if (ASCII number of charToSend) is greater than or equal to (ASCII number of "a") and (ASCII number of charToSend) is less than or equal to (ASCII number of "z") then
            set upperChar to character id ((ASCII number of charToSend) - 32)
        else
            set upperChar to charToSend
        end if
    on error
        set upperChar to charToSend -- For multi-char like "ESC"
    end try


    tell application "Terminal"
        activate
        if not (exists window 1) then
            return "Error: Terminal.app has no windows open."
        end if
    end tell

    tell application "System Events"
        tell application process "Terminal"
            set frontmost to true
            delay 0.2 

            try
                if (length of upperChar is 1) and (upperChar is greater than or equal to "A") and (upperChar is less than or equal to "Z") then
                    keystroke (lower of upperChar) using control down
                    return "Sent Ctrl-" & upperChar & " to Terminal.app"
                else if upperChar is "ESC" then
                    key code 53 
                    return "Sent ESC to Terminal.app"
                else if upperChar is "]" then
                    keystroke "]" using control down 
                    return "Sent Ctrl-] to Terminal.app"
                else
                    return "Error: Unsupported controlChar value: '" & charToSend & "'. Supported: A-Z, ESC, ]."
                end if
            on error errMsg
                return "Error sending keystroke: " & errMsg
            end try
        end tell
    end tell
end runWithInput
```
--- 
