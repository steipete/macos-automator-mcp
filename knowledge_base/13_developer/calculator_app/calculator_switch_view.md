---
title: 'Calculator: Switch Calculator View'
category: 13_developer/calculator_app
id: calculator_switch_view
description: >-
  Switches between the different calculator views (Basic, Scientific,
  Programmer).
keywords:
  - Calculator
  - view mode
  - scientific calculator
  - programmer calculator
  - basic calculator
language: applescript
argumentsPrompt: 'Enter the calculator view to switch to (Basic, Scientific, or Programmer)'
notes: >-
  Changes the Calculator app's view mode. Valid options are 'Basic',
  'Scientific', or 'Programmer'.
---

```applescript
on run {viewMode}
  tell application "Calculator"
    try
      if viewMode is "" or viewMode is missing value then
        set viewMode to "--MCP_INPUT:viewMode"
      end if
      
      -- Normalize the input
      set viewMode to do shell script "echo " & quoted form of viewMode & " | tr '[:upper:]' '[:lower:]'"
      
      activate
      
      -- Give Calculator time to launch
      delay 1
      
      tell application "System Events"
        tell process "Calculator"
          -- Determine which menu item to click based on the view mode
          if viewMode is "basic" then
            click menu item "Basic" of menu "View" of menu bar 1
            return "Switched to Basic calculator view"
          else if viewMode is "scientific" then
            click menu item "Scientific" of menu "View" of menu bar 1
            return "Switched to Scientific calculator view"
          else if viewMode is "programmer" then
            click menu item "Programmer" of menu "View" of menu bar 1
            return "Switched to Programmer calculator view"
          else
            return "Error: Invalid view mode. Please use 'Basic', 'Scientific', or 'Programmer'."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to switch calculator view - " & errMsg
    end try
  end tell
end run
```
END_TIP
