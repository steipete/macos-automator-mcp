---
title: 'Xcode: Switch Scheme'
category: 13_developer
id: xcode_switch_scheme
description: Changes the active scheme in an open Xcode project.
keywords:
  - Xcode
  - scheme
  - switch
  - select
  - configuration
  - developer
  - iOS
  - macOS
language: applescript
isComplex: true
argumentsPrompt: Name of the scheme to switch to in 'schemeName' (required)
notes: |
  - Requires Xcode to be already open with a project loaded
  - Uses UI scripting via System Events so requires Accessibility permissions
  - Useful for automating testing with different schemes
  - Works with most versions of Xcode, but UI elements may vary across versions
---

```applescript
--MCP_INPUT:schemeName

on switchXcodeScheme(schemeName)
  if schemeName is missing value or schemeName is "" then
    return "error: Scheme name not provided."
  end if
  
  tell application "Xcode"
    activate
    delay 1
  end tell
  
  try
    tell application "System Events"
      tell process "Xcode"
        -- Find the scheme popup button in the toolbar
        set schemeButton to first button of window 1 whose description contains "Scheme"
        
        -- Click the scheme button
        click schemeButton
        delay 0.5
        
        -- Look for the scheme in the popup menu
        set foundScheme to false
        
        -- Get menu items from the popup
        set menuItems to menu items of menu 1 of schemeButton
        
        -- Loop through menu items to find our scheme
        repeat with menuItem in menuItems
          if name of menuItem contains schemeName then
            -- Found the scheme, click it
            click menuItem
            set foundScheme to true
            exit repeat
          end if
        end repeat
        
        if not foundScheme then
          -- If not found in top level, search in submenus (for workspaces with multiple projects)
          repeat with menuItem in menuItems
            -- Check if this menu item has a submenu
            try
              set submenuItems to menu items of menu 1 of menuItem
              repeat with submenuItem in submenuItems
                if name of submenuItem contains schemeName then
                  -- Found the scheme in submenu, click it
                  click submenuItem
                  set foundScheme to true
                  exit repeat
                end if
              end repeat
              
              if foundScheme then exit repeat
            end try
          end repeat
        end if
        
        if foundScheme then
          return "Successfully switched to scheme: " & schemeName
        else
          return "error: Could not find scheme named: " & schemeName
        end if
      end tell
    end tell
  on error errMsg number errNum
    return "error (" & errNum & ") switching Xcode scheme: " & errMsg
  end try
end switchXcodeScheme

return my switchXcodeScheme("--MCP_INPUT:schemeName")
```
