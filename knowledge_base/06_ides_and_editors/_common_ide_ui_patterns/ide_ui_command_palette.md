---
title: "Common IDE UI: Open Command Palette & Run Command"
category: "05_ides_and_editors" # Subdir: _common_ide_ui_patterns
id: ide_ui_command_palette
description: "Simulates opening the Command Palette (usually Shift+Command+P) in the frontmost IDE and typing/selecting a command."
keywords: ["ide", "vscode", "cursor", "command palette", "ui scripting", "keystroke"]
language: applescript
isComplex: true
argumentsPrompt: "Name of the command to type into the palette as 'commandName' in inputData. Target IDE application name (e.g. 'Visual Studio Code') as 'targetAppName'."
notes: "Relies on standard shortcut and predictable UI flow. The target IDE must be frontmost. Delays may need adjustment."
---

```applescript
--MCP_INPUT:targetAppName
--MCP_INPUT:commandName

on runPaletteCommand(appName, paletteCommand)
  if appName is missing value or appName is "" then return "error: Target application name not provided."
  if paletteCommand is missing value or paletteCommand is "" then return "error: Palette command not provided."

  try
    tell application appName to activate
    delay 0.5

    tell application "System Events"
      tell process appName
        set frontmost to true
        keystroke "p" using {shift down, command down} -- Shift+Command+P
        delay 0.4 -- Wait for palette
        keystroke paletteCommand
        delay 0.3 -- Wait for filtering
        key code 36 -- Return key (Enter)
      end tell
    end tell
    return "Attempted to run '" & paletteCommand & "' via Command Palette in " & appName
  on error errMsg
    return "error: Failed to run palette command in " & appName & " - " & errMsg
  end try
end runPaletteCommand

return my runPaletteCommand("--MCP_INPUT:targetAppName", "--MCP_INPUT:commandName")
```
END_TIP 