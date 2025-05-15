---
title: "Shortcuts: Run Shortcut by Name"
category: "11_developer_and_utility_apps" # Subdir: shortcuts_app
id: shortcuts_run_by_name
description: "Executes a specified macOS Shortcut by its name. Optionally provide input to the Shortcut."
keywords: ["Shortcuts", "automation", "run shortcut", "Shortcuts Events"]
language: applescript
isComplex: true
argumentsPrompt: "Name of the Shortcut as 'shortcutName'. Optionally, text input for the shortcut as 'shortcutInput' in inputData."
notes: |
  - Uses "Shortcuts Events" to run the shortcut, which usually happens in the background without opening the Shortcuts app UI.
  - The Shortcut must exist and be correctly named.
  - Input is passed as text. The Shortcut needs to be designed to accept text input if 'shortcutInput' is used.
---

```applescript
--MCP_INPUT:shortcutName
--MCP_INPUT:shortcutInput

on runNamedShortcut(sName, sInput)
  if sName is missing value or sName is "" then return "error: Shortcut name is required."
  
  try
    tell application "Shortcuts Events"
      if sInput is not missing value and sInput is not "" then
        set shortcutResult to run shortcut sName with input sInput
      else
        set shortcutResult to run shortcut sName
      end if
    end tell
    
    if shortcutResult is missing value then
      return "Shortcut '" & sName & "' executed. No explicit output from shortcut."
    else
      -- Coerce result to string for consistent return type
      return "Shortcut '" & sName & "' executed. Output: " & (shortcutResult as text)
    end if
    
  on error errMsg number errNum
    return "error (" & errNum & "): Failed to run Shortcut '" & sName & "': " & errMsg
  end try
end runNamedShortcut

return my runNamedShortcut("--MCP_INPUT:shortcutName", "--MCP_INPUT:shortcutInput")
``` 