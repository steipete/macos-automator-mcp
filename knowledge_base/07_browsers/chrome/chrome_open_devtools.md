---
title: 'Chrome: Open Developer Tools'
category: 07_browsers
id: chrome_open_devtools
description: >-
  Opens Chrome DevTools for the active tab using keyboard shortcuts or menu
  navigation, with options to target specific DevTools panels.
keywords:
  - Chrome
  - DevTools
  - inspect
  - developer tools
  - debug
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional panel name as 'panel' in inputData. For example: { "panel":
  "elements" } to open the Elements panel. Supported values: elements, console,
  sources, network, performance, memory, application, security, lighthouse.
  Leave empty for default (Elements).
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Uses keyboard shortcuts to open DevTools and specific panels.
  - Requires Accessibility permissions for UI scripting via System Events.
  - May not work if Chrome keyboard shortcuts have been customized.
---

This script opens Chrome DevTools for the active tab, with options to target specific panels.

```applescript
--MCP_INPUT:panel

on openChromeDevTools(panelName)
  -- Default to elements panel if not specified
  if panelName is missing value or panelName is "" then
    set panelName to "elements"
  end if
  
  -- Convert to lowercase for consistency
  set panelName to my toLowerCase(panelName)
  
  -- Check if Chrome is running
  tell application "Google Chrome"
    if not running then
      return "error: Google Chrome is not running."
    end if
    
    if (count of windows) is 0 then
      return "error: No Chrome windows open."
    end if
    
    if (count of tabs of front window) is 0 then
      return "error: No tabs in front Chrome window."
    end if
    
    -- Activate Chrome to ensure keyboard shortcuts work
    activate
  end tell
  
  -- Map panel names to keyboard shortcuts
  set shortcutMap to {¬
    {"elements", "c"}, ¬
    {"console", "j"}, ¬
    {"sources", "o"}, ¬
    {"network", "n"}, ¬
    {"performance", "e"}, ¬
    {"memory", "m"}, ¬
    {"application", "a"}, ¬
    {"security", "s"}, ¬
    {"lighthouse", "g"} ¬
  }
  
  -- Find the keyboard shortcut for the requested panel
  set panelShortcut to ""
  repeat with shortcutPair in shortcutMap
    if item 1 of shortcutPair is panelName then
      set panelShortcut to item 2 of shortcutPair
      exit repeat
    end if
  end repeat
  
  if panelShortcut is "" then
    return "error: Invalid panel name '" & panelName & "'. Supported panels: elements, console, sources, network, performance, memory, application, security, lighthouse."
  end if
  
  tell application "System Events"
    tell process "Google Chrome"
      set frontmost to true
      delay 0.3
      
      -- First open DevTools with Option+Command+I (key code 34 is 'i')
      key code 34 using {command down, option down}
      delay 0.5
      
      -- Then navigate to the specific panel with Command+Option+[panel_shortcut]
      key code (my getKeyCode(panelShortcut)) using {command down, option down}
      delay 0.3
    end tell
  end tell
  
  return "Successfully opened Chrome DevTools with the " & panelName & " panel."
end openChromeDevTools

-- Helper function to convert string to lowercase
on toLowerCase(inputString)
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  set outputString to ""
  
  repeat with i from 1 to length of inputString
    set currentChar to character i of inputString
    set charIndex to offset of currentChar in upperChars
    
    if charIndex > 0 then
      set outputString to outputString & character charIndex of lowerChars
    else
      set outputString to outputString & currentChar
    end if
  end repeat
  
  return outputString
end toLowerCase

-- Helper function to get key code for a character
on getKeyCode(char)
  set char to my toLowerCase(char)
  set keyCodeMap to {¬
    {"a", 0}, {"b", 11}, {"c", 8}, {"d", 2}, {"e", 14}, {"f", 3}, ¬
    {"g", 5}, {"h", 4}, {"i", 34}, {"j", 38}, {"k", 40}, {"l", 37}, ¬
    {"m", 46}, {"n", 45}, {"o", 31}, {"p", 35}, {"q", 12}, {"r", 15}, ¬
    {"s", 1}, {"t", 17}, {"u", 32}, {"v", 9}, {"w", 13}, {"x", 7}, ¬
    {"y", 16}, {"z", 6} ¬
  }
  
  repeat with keyPair in keyCodeMap
    if item 1 of keyPair is char then
      return item 2 of keyPair
    end if
  end repeat
  
  return 0 -- Default key code if not found (should never happen)
end getKeyCode

return my openChromeDevTools("--MCP_INPUT:panel")
```
END_TIP
