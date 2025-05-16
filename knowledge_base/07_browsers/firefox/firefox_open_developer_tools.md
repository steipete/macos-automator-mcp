---
title: 'Firefox: Open Developer Tools'
category: 07_browsers
id: firefox_open_developer_tools
description: >-
  Opens Firefox Developer Tools, optionally focusing on a specific panel
  (Elements, Console, Network, etc.).
keywords:
  - Firefox
  - developer tools
  - DevTools
  - web development
  - debugging
  - inspect element
  - console
language: applescript
notes: |
  - Firefox must be running.
  - Uses keyboard shortcuts to open Developer Tools.
  - Requires accessibility permissions for UI scripting.
  - Can open and focus specific DevTools panels.
---

This script opens the Firefox Developer Tools and optionally focuses on a specific panel like Elements, Console, Network, etc. It's useful for web developers who need to inspect and debug web pages.

```applescript
on run {input, parameters}
  -- Get the DevTools panel to focus (optional)
  set devToolsPanel to "--MCP_INPUT:panel"
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- If no panel specified, just open the default DevTools
  if devToolsPanel is "" or devToolsPanel is "--MCP_INPUT:panel" then
    tell application "System Events"
      tell process "Firefox"
        -- Use F12 to open Developer Tools
        key code 111 -- F12
      end tell
    end tell
    
    return "Opened Firefox Developer Tools"
  end if
  
  -- First open DevTools with F12
  tell application "System Events"
    tell process "Firefox"
      key code 111 -- F12
      delay 1 -- Allow DevTools to open
    end tell
  end tell
  
  -- Now switch to the specific panel based on input
  set panelFound to true
  
  tell application "System Events"
    tell process "Firefox"
      -- Convert panel name to lowercase to make case insensitive
      set panelLower to lowercase of devToolsPanel
      
      if panelLower is "elements" or panelLower is "inspector" then
        -- Open Elements panel (Command+Option+C)
        keystroke "c" using {command down, option down}
        set panelName to "Elements/Inspector"
        
      else if panelLower is "console" then
        -- Open Console panel (Command+Option+K)
        keystroke "k" using {command down, option down}
        set panelName to "Console"
        
      else if panelLower is "debugger" or panelLower is "sources" then
        -- Open Debugger panel (Command+Option+S)
        keystroke "s" using {command down, option down}
        set panelName to "Debugger/Sources"
        
      else if panelLower is "network" then
        -- Open Network panel (Command+Option+E)
        keystroke "e" using {command down, option down}
        set panelName to "Network"
        
      else if panelLower is "performance" then
        -- Open Performance panel (Shift+F5)
        key code 96 using {shift down} -- Shift+F5
        set panelName to "Performance"
        
      else if panelLower is "memory" then
        -- Open Memory panel
        -- This might need manual navigation in some Firefox versions
        keystroke "m" using {command down, option down}
        set panelName to "Memory"
        
      else if panelLower is "storage" then
        -- Open Storage panel
        keystroke "l" using {command down, option down}
        set panelName to "Storage"
        
      else
        -- If panel not recognized, just leave DevTools open on default panel
        set panelFound to false
        set panelName to "default"
      end if
    end tell
  end tell
  
  if panelFound then
    return "Opened Firefox Developer Tools with " & panelName & " panel"
  else
    return "Opened Firefox Developer Tools (panel '" & devToolsPanel & "' not recognized)"
  end if
end run
```

### Alternative Implementation for Quick Panel Selection

This version uses a simpler approach with fewer panel options but faster execution:

```applescript
on run {input, parameters}
  -- Map input panel names to their keyboard shortcuts
  set panelName to "--MCP_INPUT:panel"
  set panelName to lowercase of panelName
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- First open DevTools with F12 if not already open
      key code 111 -- F12
      delay 0.7 -- Allow DevTools to open
      
      -- Switch to the requested panel
      if panelName is "elements" or panelName is "inspector" then
        keystroke "1" using {command down}
        return "Opened Firefox DevTools - Elements panel"
        
      else if panelName is "console" then
        keystroke "2" using {command down}
        return "Opened Firefox DevTools - Console panel"
        
      else if panelName is "debugger" then
        keystroke "3" using {command down}
        return "Opened Firefox DevTools - Debugger panel"
        
      else if panelName is "network" then
        keystroke "4" using {command down}
        return "Opened Firefox DevTools - Network panel"
        
      else if panelName is "performance" then
        keystroke "5" using {command down}
        return "Opened Firefox DevTools - Performance panel"
        
      else if panelName is "storage" then
        keystroke "9" using {command down}
        return "Opened Firefox DevTools - Storage panel"
        
      else
        -- Just leave DevTools open on whatever panel it opened with
        return "Opened Firefox DevTools"
      end if
    end tell
  end tell
end run
```

### Example: Opening Element Inspector for a Specific Element

This more specialized version opens the Element Inspector and tries to select a specific element by its selector:

```applescript
on run {input, parameters}
  -- Get the CSS selector for the element to inspect
  set elementSelector to "--MCP_INPUT:selector"
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- First open DevTools and switch to Elements panel
  tell application "System Events"
    tell process "Firefox"
      -- Use F12 to open Developer Tools
      key code 111 -- F12
      delay 0.7 -- Allow DevTools to open
      
      -- Ensure we're on the Elements panel
      keystroke "c" using {command down, option down}
      delay 0.3
    end tell
  end tell
  
  -- If a selector was provided, try to select that element
  if elementSelector is not "" and elementSelector is not "--MCP_INPUT:selector" then
    -- Execute JavaScript to select the element in the Inspector
    -- We need to use the execute_js_get_result script
    set jsCommand to "inspect(document.querySelector('" & elementSelector & "'));"
    
    -- Use JavaScript Console to run the command
    tell application "System Events"
      tell process "Firefox"
        -- Focus on Console panel
        keystroke "k" using {command down, option down}
        delay 0.3
        
        -- Enter and execute the JavaScript
        keystroke jsCommand
        delay 0.2
        keystroke return
        
        -- Go back to Elements panel to see the selected element
        keystroke "c" using {command down, option down}
      end tell
    end tell
    
    return "Opened Firefox Element Inspector for selector: " & elementSelector
  end if
  
  return "Opened Firefox Element Inspector"
end run
```

Note: Firefox's keyboard shortcuts and UI can change between versions. These scripts might need adjustment to work with your specific Firefox version. The key codes for function keys (F1-F12) can also vary depending on keyboard setup.
END_TIP
