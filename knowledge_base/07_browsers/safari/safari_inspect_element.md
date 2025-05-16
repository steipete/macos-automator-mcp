---
title: 'Safari: Inspect Element'
category: 07_browsers
id: safari_inspect_element
description: >-
  Opens Safari's Web Inspector and activates the element selection tool to
  inspect page elements.
keywords:
  - Safari
  - Web Inspector
  - inspect element
  - developer tools
  - HTML
  - CSS
  - debugging
  - web development
  - DOM
language: applescript
isComplex: false
notes: >
  - Safari must be running with at least one open tab.

  - The Develop menu must be enabled in Safari preferences.

  - This script uses UI automation via System Events, so Accessibility
  permissions are required.

  - The script opens the Web Inspector in Elements mode and activates the
  element selection tool.

  - This allows the user to click any element on the page to inspect its HTML
  and CSS.
---

This script opens Safari's Web Inspector and activates the element inspection tool for selecting and analyzing page elements.

```applescript
on run
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    if (count of windows) is 0 or (count of tabs of front window) is 0 then
      return "error: No tabs open in Safari."
    end if
    
    activate
    delay 0.5
    
    try
      tell application "System Events"
        tell process "Safari"
          -- Check if the Develop menu exists
          if not (exists menu bar item "Develop" of menu bar 1) then
            return "error: Develop menu not enabled in Safari. Enable it in Safari > Preferences > Advanced."
          end if
          
          -- First check if Web Inspector is already open
          set inspectorOpen to false
          try
            if window "Web Inspector" exists then
              set inspectorOpen to true
            end if
          end try
          
          if not inspectorOpen then
            -- Open the Web Inspector if not already open
            click menu bar item "Develop" of menu bar 1
            delay 0.2
            click menu item "Show Web Inspector" of menu of menu bar item "Develop" of menu bar 1
            delay 1
          end if
          
          -- Ensure Elements tab is selected in Web Inspector
          try
            -- Look for Elements tab button in the Web Inspector
            set elementsTabFound to false
            
            repeat with btn in (buttons of tab group 1 of group 1 of splitter group 1 of window "Web Inspector")
              if the name of btn is "Elements" then
                click btn
                set elementsTabFound to true
                exit repeat
              end if
            end repeat
            
            if not elementsTabFound then
              -- Try clicking first tab button (usually Elements)
              click button 1 of tab group 1 of group 1 of splitter group 1 of window "Web Inspector"
            end if
            
            delay 0.5
          end try
          
          -- Now activate the element selection tool (magnifying glass)
          -- Method 1: Use keyboard shortcut
          keystroke "c" using {command down, shift down}
          delay 0.2
          
          -- Method 2: If keyboard shortcut fails, try clicking the button
          try
            set inspectButtonFound to false
            
            -- Try to find the inspect button by various attributes
            repeat with btn in (buttons of toolbar 1 of window "Web Inspector")
              set btnDesc to ""
              try
                set btnDesc to description of btn
              end try
              
              if btnDesc contains "Select Element" or btnDesc contains "Inspect" then
                click btn
                set inspectButtonFound to true
                exit repeat
              end if
            end repeat
            
            if not inspectButtonFound then
              -- Try using menu item as a fallback
              click menu bar item "Develop" of menu bar 1
              delay 0.2
              click menu item "Select Element" of menu of menu bar item "Develop" of menu bar 1
            end if
          end try
          
          return "Web Inspector opened with element selection tool activated. Click any element on the page to inspect it."
        end tell
      end tell
    on error errMsg
      return "error: Failed to activate inspect element - " & errMsg & ". Make sure the Develop menu is enabled in Safari preferences."
    end try
  end tell
end run
```
