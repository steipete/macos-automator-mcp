---
title: "Safari: Save Bookmark"
category: "05_web_browsers"
id: safari_save_bookmark
description: "Saves the current webpage as a bookmark in Safari."
keywords: ["Safari", "bookmark", "save bookmark", "web favorites", "bookmark page"]
language: applescript
argumentsPrompt: "Enter bookmark name and the folder to save in (optional)"
notes: "Saves the current page in Safari as a bookmark with the specified name and optionally in a specific folder."
---

```applescript
on run {bookmarkName, folderName}
  tell application "Safari"
    try
      -- Handle placeholder substitution
      if bookmarkName is "" or bookmarkName is missing value then
        set bookmarkName to "--MCP_INPUT:bookmarkName"
      end if
      
      if folderName is "" or folderName is missing value then
        set folderName to "--MCP_INPUT:folderName"
      end if
      
      -- Make sure Safari is active and has at least one window
      activate
      
      if (count of windows) is 0 then
        return "Error: No Safari windows open."
      end if
      
      -- Get the current tab's information
      set currentTab to current tab of front window
      set pageURL to URL of currentTab
      
      -- If no bookmark name specified, use the page title
      if bookmarkName is "--MCP_INPUT:bookmarkName" or bookmarkName is "" then
        set bookmarkName to name of currentTab
      end if
      
      -- Use UI scripting to create the bookmark
      tell application "System Events"
        tell process "Safari"
          -- Open the Add Bookmark dialog
          keystroke "d" using {command down}
          delay 0.5
          
          if exists sheet 1 of window 1 then
            -- Set the bookmark name
            set value of text field 1 of sheet 1 of window 1 to bookmarkName
            
            -- Set the bookmark folder if specified
            if folderName is not "--MCP_INPUT:folderName" and folderName is not "" then
              -- Click the folder selection popup
              click pop up button 1 of sheet 1 of window 1
              delay 0.3
              
              -- Attempt to find and select the folder
              try
                click menu item folderName of menu 1 of pop up button 1 of sheet 1 of window 1
              on error
                -- If folder not found, create a result message noting this
                set folderNotFound to true
              end try
            end if
            
            -- Click Add button to save the bookmark
            click button "Add" of sheet 1 of window 1
            
            -- Generate appropriate success message
            if folderName is not "--MCP_INPUT:folderName" and folderName is not "" then
              if exists variable "folderNotFound" then
                return "Bookmark \"" & bookmarkName & "\" saved for " & pageURL & "\\n(Note: Specified folder \"" & folderName & "\" was not found, bookmark saved to default location)"
              else
                return "Bookmark \"" & bookmarkName & "\" saved to folder \"" & folderName & "\" for " & pageURL
              end if
            else
              return "Bookmark \"" & bookmarkName & "\" saved for " & pageURL
            end if
          else
            return "Error: Add Bookmark dialog did not appear."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to save bookmark - " & errMsg
    end try
  end tell
end run
```
END_TIP