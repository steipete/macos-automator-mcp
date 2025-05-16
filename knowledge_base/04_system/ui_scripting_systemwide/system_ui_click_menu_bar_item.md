---
title: 'System UI: Click Menu Bar Item of Frontmost App'
category: 04_system
id: system_ui_click_menu_bar_item
description: >-
  Clicks a top-level menu bar item (e.g., 'File', 'Edit') of the currently
  frontmost application.
keywords:
  - ui scripting
  - menu bar
  - click menu
  - System Events
  - frontmost app
language: applescript
isComplex: true
argumentsPrompt: 'Name of the menu to click (e.g., ''File'', ''Window'') as ''menuName'' in inputData.'
notes: >-
  Requires Accessibility permissions. The frontmost application must have the
  specified menu.
---

```applescript
--MCP_INPUT:menuName

on clickMenuBarItemOfFrontApp(theMenuName)
  if theMenuName is missing value or theMenuName is "" then return "error: Menu name not provided."
  
  tell application "System Events"
    try
      set frontAppProcess to first application process whose frontmost is true
      if frontAppProcess is missing value then return "error: Could not determine frontmost application."
      
      tell frontAppProcess
        if not (exists menu bar 1) then return "error: Frontmost application has no menu bar."
        if not (exists menu bar item theMenuName of menu bar 1) then return "error: Menu '" & theMenuName & "' not found in frontmost application."
        
        click menu bar item theMenuName of menu bar 1
        return "Clicked menu '" & theMenuName & "' of " & (name of frontAppProcess) & "."
      end tell
    on error errMsg
      return "error: Failed to click menu bar item - " & errMsg
    end try
  end tell
end clickMenuBarItemOfFrontApp

return my clickMenuBarItemOfFrontApp("--MCP_INPUT:menuName")
```
END_TIP 
