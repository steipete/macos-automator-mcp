---
title: "Terminal.app: Run Command in New Tab"
category: "03_terminal_emulators" # This will be nested, e.g., knowledge_base/03_terminal_emulators/terminal_app/
id: terminal_app_run_command_new_tab
description: "Opens a new tab in the built-in macOS Terminal.app and executes a specified command."
keywords: ["Terminal", "command", "do script", "new tab"]
language: applescript
argumentsPrompt: "Command to execute as 'shellCommand' in inputData."
---

```applescript
--MCP_INPUT:shellCommand

tell application "Terminal"
  activate
  do script "--MCP_INPUT:shellCommand"
end tell
return "Command '--MCP_INPUT:shellCommand' sent to new Terminal tab."
```
END_TIP