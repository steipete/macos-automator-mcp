---
title: "Firefox: Bookmark Current Page"
category: "05_web_browsers"
id: firefox_bookmark_current_page
description: "Bookmarks the current page in Firefox, with options to specify folder and add tags."
keywords: ["Firefox", "bookmark", "current page", "save bookmark", "browser", "UI scripting"]
language: applescript
notes: |
  - Firefox must be running.
  - Uses UI scripting to navigate Firefox's bookmark dialog.
  - Requires accessibility permissions.
  - Can specify bookmark folder destination and custom tags.
---

This script bookmarks the current page in Firefox. It uses UI scripting to simulate the keyboard shortcut for bookmarking and then interacts with Firefox's bookmark dialog.

```applescript
on run {input, parameters}
  -- Get parameters (optional)
  set bookmarkFolder to "--MCP_INPUT:folder"
  set bookmarkTags to "--MCP_INPUT:tags"
  
  -- If no folder specified, use the default
  if bookmarkFolder is "" then set bookmarkFolder to "Other Bookmarks"
  
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  -- First get the current page title before bookmarking
  set pageTitle to ""
  tell application "System Events"
    tell process "Firefox"
      set frontWindow to first window
      set pageTitle to name of frontWindow
    end tell
  end tell
  
  -- Use keyboard shortcut to bookmark the current page (Command+D)
  tell application "System Events"
    tell process "Firefox"
      keystroke "d" using {command down}
      delay 0.5 -- Wait for bookmark dialog
    end tell
  end tell
  
  -- Interact with the bookmark dialog
  tell application "System Events"
    tell process "Firefox"
      -- Check if bookmark dialog appeared
      if exists (window 1 whose title contains "Bookmark") then
        -- Optional: Change folder if specified
        if bookmarkFolder is not "" and bookmarkFolder is not "Other Bookmarks" then
          -- Find and click the folder dropdown
          set folderMenuButton to button 1 of group 1 of window 1
          click folderMenuButton
          delay 0.3
          
          -- Try to find and select the specified folder
          -- This is a simplified approach - in reality you might need more complex
          -- UI navigating to find the exact menu item
          try
            set folderItems to menu items of menu 1 of folderMenuButton
            repeat with folderItem in folderItems
              if name of folderItem contains bookmarkFolder then
                click folderItem
                exit repeat
              end if
            end repeat
          end try
          delay 0.3
        end if
        
        -- Optional: Add tags if specified
        if bookmarkTags is not "" then
          -- Tab to the tags field and enter tags
          keystroke tab -- Move to Name field
          keystroke tab -- Move to Folder field
          keystroke tab -- Move to Tags field
          delay 0.2
          keystroke bookmarkTags
          delay 0.2
        end if
        
        -- Click Done to save the bookmark
        keystroke return -- Submit the dialog
        delay 0.5
        
        return "Bookmarked \"" & pageTitle & "\""
      else
        return "Bookmark dialog didn't appear or was already bookmarked"
      end if
    end tell
  end tell
end run
```

### Simplified Version (Bookmark Only)

This simplified version just bookmarks the page without attempting to modify folder or tags:

```applescript
on run
  tell application "Firefox"
    activate
    delay 0.3 -- Allow Firefox to activate
  end tell
  
  -- Use keyboard shortcut to bookmark the current page (Command+D)
  tell application "System Events"
    tell process "Firefox"
      -- Get window title for result message
      set windowTitle to name of front window
      
      -- Use bookmark shortcut
      keystroke "d" using {command down}
      delay 0.5 -- Wait for bookmark dialog
      
      -- Press Return to accept the default options
      keystroke return
    end tell
  end tell
  
  return "Bookmarked the current page in Firefox"
end run
```

### Advanced Version with Star Button

This version tries to use the star button in the URL bar if available:

```applescript
on run
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate fully
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Try to find and click the star/bookmark button in the toolbar
      try
        -- Look for the bookmark/star button in the toolbar
        -- This assumes the button is visible in the UI
        set toolbarGroups to groups of toolbar 1 of front window
        
        repeat with grp in toolbarGroups
          try
            -- Look for a button that might be the bookmark star
            set buttons to buttons of grp
            repeat with btn in buttons
              if description of btn contains "Bookmark" or description of btn contains "star" then
                click btn
                delay 0.5 -- Wait for bookmark dialog
                
                -- Press Return to accept the default options
                keystroke return
                return "Bookmarked the current page using toolbar button"
              end if
            end repeat
          end try
        end repeat
        
        -- If we couldn't find the button, fall back to keyboard shortcut
        keystroke "d" using {command down}
        delay 0.5
        keystroke return
        
      on error
        -- Fall back to keyboard shortcut if UI approach fails
        keystroke "d" using {command down}
        delay 0.5
        keystroke return
      end try
      
      return "Bookmarked the current page in Firefox"
    end tell
  end tell
end run
```

Note: The more advanced versions of this script might need adjustment based on your specific Firefox version and UI layout. Firefox's UI can change between versions, and the UI scripting approach might need to be updated accordingly.
END_TIP