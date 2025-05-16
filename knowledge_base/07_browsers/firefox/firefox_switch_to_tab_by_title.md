---
title: 'Firefox: Switch to Tab by Title'
category: 07_browsers
id: firefox_switch_to_tab_by_title
description: Switches to a Firefox tab based on its title or partial title match.
keywords:
  - Firefox
  - tab
  - switch tab
  - find tab
  - browser
  - UI scripting
language: applescript
notes: |
  - Firefox must be running.
  - Uses UI scripting to navigate through tabs.
  - Requires accessibility permissions.
  - Partial title matching is supported (case-insensitive).
---

This script switches to a specified Firefox tab by searching for a match in the tab titles. It can find tabs based on exact or partial title matches, and is case-insensitive.

```applescript
on run {input, parameters}
  -- Get the tab title to search for
  set searchTitle to "--MCP_INPUT:tabTitle"
  
  -- Exit if no search title provided
  if searchTitle is "" then
    return "Error: No tab title to search for was provided"
  end if
  
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  -- First list all tabs using the tab overview
  set tabsList to {}
  
  tell application "System Events"
    tell process "Firefox"
      -- Open tab overview
      keystroke "," using {shift down, command down}
      delay 0.7 -- Allow overview to appear
      
      -- Get list of tab titles
      set tabElements to UI elements of group 1 of window 1 whose role is "AXStaticText"
      
      -- Extract tabs information
      repeat with tabElement in tabElements
        set tabName to value of tabElement
        if tabName is not "" and tabName is not "Tabs" then
          copy {title:tabName, element:tabElement} to end of tabsList
        end if
      end repeat
      
      -- Look for a matching tab
      set foundMatch to false
      set exactMatch to missing value
      set partialMatch to missing value
      
      repeat with tabInfo in tabsList
        set tabTitle to title of tabInfo
        set tabElement to element of tabInfo
        
        -- Check for an exact match first (case-insensitive)
        if tabTitle's lowercase is equal to searchTitle's lowercase then
          set exactMatch to tabElement
          exit repeat
        end if
        
        -- Check for a partial match
        if tabTitle's lowercase contains searchTitle's lowercase then
          set partialMatch to tabElement
        end if
      end repeat
      
      -- First try to use exact match if found
      if exactMatch is not missing value then
        click exactMatch
        set foundMatch to true
      else if partialMatch is not missing value then
        -- Otherwise use first partial match
        click partialMatch
        set foundMatch to true
      end if
      
      -- Close the tab overview if no match was found
      if not foundMatch then
        keystroke escape
        return "No tab with title containing \"" & searchTitle & "\" was found."
      end if
    end tell
  end tell
  
  return "Switched to tab matching \"" & searchTitle & "\""
end run
```

### Alternative Approach Using Tab Navigation

This alternative approach searches for a tab by cycling through each open tab and checking the window title:

```applescript
on run {input, parameters}
  -- Get the tab title to search for
  set searchTitle to "--MCP_INPUT:tabTitle"
  set searchTitle to searchTitle's lowercase
  
  -- Exit if no search title provided
  if searchTitle is "" then
    return "Error: No tab title to search for was provided"
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate fully
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Get the current active window to start with
      set frontWindow to first window
      set initialWindowName to name of frontWindow
      set initialWindowName to initialWindowName's lowercase
      
      -- Check if we're already on the target tab
      if initialWindowName contains searchTitle then
        return "Already on tab matching \"" & searchTitle & "\""
      end if
      
      -- Track if we've gone in a complete loop
      set checkedTabs to 1
      set totalTabsChecked to 0
      set maxTabsToCheck to 50 -- Safety limit
      
      -- Cycle through tabs until we find a match or complete a loop
      repeat while totalTabsChecked < maxTabsToCheck
        -- Go to the next tab
        keystroke "`" using {command down} -- Command+` to switch to the next tab
        delay 0.3 -- Allow window title to update
        
        -- Check if current tab matches search criteria
        set currentWindowName to name of frontWindow
        set currentWindowName to currentWindowName's lowercase
        
        if currentWindowName contains searchTitle then
          return "Switched to tab matching \"" & searchTitle & "\""
        end if
        
        -- Check if we've gone in a complete loop
        if currentWindowName is equal to initialWindowName then
          exit repeat
        end if
        
        -- Increment counter
        set totalTabsChecked to totalTabsChecked + 1
      end repeat
      
      -- If we've checked all tabs and found no match
      return "No tab with title containing \"" & searchTitle & "\" was found after checking " & totalTabsChecked & " tabs."
    end tell
  end tell
end run
```

### Implementation Using Tab Selector Menu

This version uses Firefox's built-in tab selector menu and attempts to find and click the matching tab:

```applescript
on run {input, parameters}
  -- Get the tab title to search for
  set searchTitle to "--MCP_INPUT:tabTitle"
  
  -- Exit if no search title provided
  if searchTitle is "" then
    return "Error: No tab title to search for was provided"
  end if
  
  -- Convert to lowercase for case-insensitive search
  set searchTitle to searchTitle's lowercase
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Use the tab list button (or keyboard shortcut)
      keystroke "," using {shift down, command down}
      delay 0.7 -- Allow the tab list to appear
      
      -- Try to find a tab matching the search term
      set foundTab to false
      
      -- Get all menu items from the tab list
      set allTabItems to menu items of menu 1 of front window
      
      -- Look for a matching tab title
      repeat with tabItem in allTabItems
        -- Get the name of the tab item and convert to lowercase
        set tabName to name of tabItem
        set tabNameLower to tabName's lowercase
        
        -- Check if this tab matches our search
        if tabNameLower contains searchTitle then
          -- Found a match, click it
          click tabItem
          set foundTab to true
          exit repeat
        end if
      end repeat
      
      -- If we couldn't find a match, close the menu
      if not foundTab then
        keystroke escape
        return "No tab with title containing \"" & searchTitle & "\" was found."
      end if
    end tell
  end tell
  
  return "Switched to tab matching \"" & searchTitle & "\""
end run
```

Note: These scripts rely on Firefox's UI elements and keyboard shortcuts, which can change between Firefox versions. You may need to adjust the UI scripting approach based on your specific Firefox version.
END_TIP
