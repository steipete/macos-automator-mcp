---
title: 'Safari: Manage Bookmarks'
category: 07_browsers
id: safari_manage_bookmarks
description: >-
  Creates, edits, or deletes Safari bookmarks including folders and Reading List
  items.
keywords:
  - Safari
  - bookmarks
  - favorites
  - reading list
  - browser
  - web
  - add bookmark
  - edit bookmark
  - delete bookmark
language: applescript
isComplex: true
argumentsPrompt: >-
  Action type as 'action' ('add', 'edit', 'delete'), URL as 'url', title as
  'title', folder path as 'folder', and optionally reading list flag as
  'addToReadingList' in inputData.
notes: >
  - Safari must be running for this script to work.

  - The script can manage bookmarks in the Favorites Bar, Bookmarks Menu, or any
  other bookmark folder.

  - For the 'folder' parameter, use slash-separated paths like 'Favorites
  Bar/Work' or 'Bookmarks Menu/Reference'.

  - Set 'addToReadingList' to 'true' to add an item to the Reading List instead
  of regular bookmarks.

  - This script uses UI automation via System Events, so Accessibility
  permissions are required.

  - Some operations may be slower due to UI automation, especially when working
  with deeply nested folders.
---

This script manages Safari bookmarks, allowing you to add, edit, or delete bookmarks and folders.

```applescript
--MCP_INPUT:action
--MCP_INPUT:url
--MCP_INPUT:title
--MCP_INPUT:folder
--MCP_INPUT:addToReadingList

on manageSafariBookmarks(action, url, title, folder, addToReadingList)
  -- Validate inputs
  if action is missing value or action is "" then
    return "error: Action not provided. Must be 'add', 'edit', or 'delete'."
  end if
  
  set action to my toLowerCase(action)
  if action is not "add" and action is not "edit" and action is not "delete" then
    return "error: Invalid action. Must be 'add', 'edit', or 'delete'."
  end if
  
  if url is missing value or url is "" then
    if action is not "delete" then
      return "error: URL not provided."
    end if
  end if
  
  -- Set default title if not provided
  if title is missing value or title is "" then
    if action is "add" or action is "edit" then
      set title to "Untitled Bookmark"
    end if
  end if
  
  -- Set default folder if not provided
  if folder is missing value or folder is "" then
    set folder to "Favorites Bar"
  end if
  
  -- Handle Reading List flag
  set useReadingList to false
  if addToReadingList is not missing value and addToReadingList is not "" then
    if addToReadingList is "true" or addToReadingList is "yes" or addToReadingList is "1" then
      set useReadingList to true
    end if
  end if
  
  -- Check if URL has a proper prefix for adding/editing
  if (action is "add" or action is "edit") and url does not start with "http://" and url does not start with "https://" then
    set url to "https://" & url
  end if
  
  -- Ensure Safari is running
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  -- Handle Reading List specially
  if useReadingList and action is "add" then
    tell application "Safari"
      try
        -- Open the URL in a new tab
        tell window 1
          set current tab to (make new tab with properties {URL:url})
          delay 1
        end tell
        
        -- Add to Reading List via menu
        tell application "System Events"
          tell process "Safari"
            click menu item "Add to Reading List" of menu "Bookmarks" of menu bar 1
            delay 0.5
          end tell
        end tell
        
        -- Close the tab we just opened
        tell window 1
          close current tab
        end tell
        
        return "Successfully added URL to Reading List: " & url
      on error errMsg
        return "error: Failed to add to Reading List - " & errMsg
      end try
    end tell
  end if
  
  -- Regular bookmark management
  tell application "System Events"
    tell process "Safari"
      -- Open Bookmarks Editor
      try
        click menu item "Show Bookmarks" of menu "Bookmarks" of menu bar 1
        delay 1
      on error
        -- Bookmarks already shown, try using keyboard shortcut
        keystroke "b" using {command down, option down}
        delay 1
      end try
      
      -- Now perform the requested action
      if action is "add" then
        -- Add a new bookmark
        try
          -- First navigate to the correct folder using folder path
          set folderPath to my parseFolder(folder)
          set folderFound to my navigateToFolder(folderPath)
          
          if not folderFound then
            return "error: Could not find folder: " & folder
          end if
          
          -- Add new bookmark
          -- Try different methods since Safari's UI structure can vary
          try
            -- Method 1: Use menu
            click menu item "Add Bookmark..." of menu "Bookmarks" of menu bar 1
          on error
            -- Method 2: Try using the Add button
            try
              set addButtons to buttons of window 1 whose description contains "Add"
              if (count of addButtons) > 0 then
                click item 1 of addButtons
              else
                -- Method 3: Try keyboard shortcut
                keystroke "d" using {command down}
              end if
            end try
          end try
          
          delay 1
          
          -- Fill in the bookmark details
          set addDialogFound to false
          
          -- Try to find and interact with the dialog
          try
            -- Look for the bookmark sheet or dialog
            set dialogGroups to groups of window 1 whose description contains "bookmark" or description contains "Bookmark"
            if (count of dialogGroups) > 0 then
              set dialogGroup to item 1 of dialogGroups
              set addDialogFound to true
              
              -- Find the URL and title text fields
              set textFields to text fields of dialogGroup
              if (count of textFields) ≥ 2 then
                -- Usually the first field is for the name/title
                set value of item 1 of textFields to title
                
                -- And the second field is for the URL
                set value of item 2 of textFields to url
                
                -- Click Add button
                set addButton to button "Add" of dialogGroup
                click addButton
              end if
            end if
          end try
          
          if not addDialogFound then
            return "error: Could not find bookmark dialog to enter details."
          end if
          
          -- Close Bookmarks Editor
          keystroke "w" using command down
          
          return "Successfully added bookmark: " & title & " (" & url & ") to " & folder
        on error errMsg
          return "error: Failed to add bookmark - " & errMsg
        end try
        
      else if action is "edit" then
        -- Edit an existing bookmark
        try
          -- First find the bookmark to edit
          set bookmarkFound to my findBookmark(title, url)
          
          if not bookmarkFound then
            return "error: Could not find bookmark to edit with title: " & title & " or URL: " & url
          end if
          
          -- Perform the edit action
          -- Usually right-click or command+click the bookmark
          set selected to true
          delay 0.5
          
          -- Try to use contextual menu
          try
            -- Right-click to open context menu
            perform action "AXShowMenu" of UI element 1 of UI element 1 of row 1 of outline 1 of scroll area 1 of window 1
            delay 0.5
            
            -- Click Edit bookmark
            click menu item "Edit Bookmark..." of menu 1
            delay 0.5
            
            -- Edit dialog
            set dialogGroups to groups of window 1 whose description contains "Edit" or description contains "edit"
            if (count of dialogGroups) > 0 then
              set dialogGroup to item 1 of dialogGroups
              
              -- Find the URL and title text fields
              set textFields to text fields of dialogGroup
              if (count of textFields) ≥ 2 then
                -- Usually the first field is for the name/title
                set value of item 1 of textFields to title
                
                -- And the second field is for the URL
                set value of item 2 of textFields to url
                
                -- Click Done button
                set doneButton to button "Done" of dialogGroup
                click doneButton
              end if
            end if
          on error
            -- Alternative approach using menu bar
            click menu item "Edit Bookmark..." of menu "Bookmarks" of menu bar 1
          end try
          
          -- Close Bookmarks Editor
          keystroke "w" using command down
          
          return "Successfully edited bookmark to: " & title & " (" & url & ")"
        on error errMsg
          return "error: Failed to edit bookmark - " & errMsg
        end try
        
      else if action is "delete" then
        -- Delete a bookmark
        try
          -- First find the bookmark to delete
          if title is not missing value and title is not "" then
            set bookmarkFound to my findBookmark(title, url)
          else
            set bookmarkFound to my findBookmark("", url)
          end if
          
          if not bookmarkFound then
            return "error: Could not find bookmark to delete."
          end if
          
          -- Delete the bookmark
          -- Try using keyboard shortcut first
          keystroke (ASCII character 127) -- Delete key
          delay 0.5
          
          -- Confirm deletion if dialog appears
          try
            set deleteButtons to buttons of window 1 whose name contains "Delete"
            if (count of deleteButtons) > 0 then
              click item 1 of deleteButtons
            end if
          end try
          
          -- Close Bookmarks Editor
          keystroke "w" using command down
          
          return "Successfully deleted bookmark: " & title & if url is not "" then " (" & url & ")" else ""
        on error errMsg
          return "error: Failed to delete bookmark - " & errMsg
        end try
      end if
    end tell
  end tell
end manageSafariBookmarks

-- Helper function to parse folder path into components
on parseFolder(folderPath)
  set AppleScript's text item delimiters to "/"
  set folderComponents to text items of folderPath
  set AppleScript's text item delimiters to ""
  
  -- Standardize top-level folder names
  if (count of folderComponents) > 0 then
    if item 1 of folderComponents is "Favorites Bar" or item 1 of folderComponents is "BookmarksBar" or item 1 of folderComponents is "Favorites" then
      set item 1 of folderComponents to "Favorites Bar"
    else if item 1 of folderComponents is "Bookmarks Menu" or item 1 of folderComponents is "BookmarksMenu" then
      set item 1 of folderComponents to "Bookmarks Menu"
    end if
  end if
  
  return folderComponents
end parseFolder

-- Helper function to navigate to a specific folder in the bookmark editor
on navigateToFolder(folderComponents)
  tell application "System Events"
    tell process "Safari"
      try
        -- First select the root container (Favorites Bar or Bookmarks Menu)
        if (count of folderComponents) > 0 then
          set rootFolder to item 1 of folderComponents
          
          -- Try to find and select the root folder
          set rootFound to false
          
          -- Look for a sidebar or source list with folders
          set sidebarElements to UI elements of window 1
          repeat with element in sidebarElements
            try
              if description of element contains "source list" or description of element contains "sidebar" or description of element contains "outline" then
                set outlines to outlines of element
                if (count of outlines) > 0 then
                  set rows to rows of outline 1 of element
                  repeat with r in rows
                    try
                      if name of r contains rootFolder then
                        select r
                        set rootFound to true
                        delay 0.5
                        exit repeat
                      end if
                    end try
                  end repeat
                end if
              end if
            end try
            
            if rootFound then exit repeat
          end repeat
          
          if not rootFound then
            -- Try alternate approaches if we couldn't find the root folder
            -- This might happen in different Safari versions
            log "Warning: Could not find root folder using primary method."
          end if
          
          -- If we have subfolder(s), navigate to them
          if (count of folderComponents) > 1 then
            -- For each subfolder in the path
            repeat with i from 2 to (count of folderComponents)
              set currentFolder to item i of folderComponents
              
              -- Try to find and click this subfolder
              set folderFound to false
              
              -- Look for the folder in the current view
              set bookmarkRows to rows of outline 1 of scroll area 1 of window 1
              repeat with r in bookmarkRows
                try
                  if name of r contains currentFolder then
                    select r
                    -- Double-click to open folder
                    click r
                    click r
                    set folderFound to true
                    delay 0.5
                    exit repeat
                  end if
                end try
              end repeat
              
              if not folderFound then
                return false
              end if
            end repeat
          end if
          
          return true
        end if
        
        return false
      on error errMsg
        log "Error navigating to folder: " & errMsg
        return false
      end try
    end tell
  end tell
end navigateToFolder

-- Helper function to find a bookmark by title or URL
on findBookmark(bookmarkTitle, bookmarkURL)
  tell application "System Events"
    tell process "Safari"
      try
        -- Get all bookmark rows
        set bookmarkRows to rows of outline 1 of scroll area 1 of window 1
        
        -- Look for matching bookmark
        repeat with r in bookmarkRows
          try
            -- Check if this is a bookmark (not a folder) and matches title or URL
            set rowName to name of r
            
            if bookmarkTitle is not "" and rowName contains bookmarkTitle then
              select r
              return true
            else if bookmarkURL is not "" then
              -- Check URL by selecting and inspecting properties
              select r
              delay 0.5
              
              -- Try to get URL from inspector or properties
              try
                click menu item "Show Info" of menu "File" of menu bar 1
                delay 0.5
                
                set infoGroups to groups of window 1 whose description contains "Info" or description contains "info"
                if (count of infoGroups) > 0 then
                  set infoGroup to item 1 of infoGroups
                  set infoTexts to text fields of infoGroup
                  
                  repeat with t in infoTexts
                    try
                      if value of t contains bookmarkURL then
                        -- Close info window
                        click button 1 of infoGroup
                        return true
                      end if
                    end try
                  end repeat
                  
                  -- Close info window if we didn't find a match
                  click button 1 of infoGroup
                end if
              end try
            end if
          end try
        end repeat
        
        return false
      on error errMsg
        log "Error finding bookmark: " & errMsg
        return false
      end try
    end tell
  end tell
end findBookmark

-- Helper function to convert text to lowercase
on toLowerCase(sourceText)
  set lowercaseText to ""
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  
  repeat with i from 1 to length of sourceText
    set currentChar to character i of sourceText
    set charPos to offset of currentChar in upperChars
    
    if charPos > 0 then
      set lowercaseText to lowercaseText & character charPos of lowerChars
    else
      set lowercaseText to lowercaseText & currentChar
    end if
  end repeat
  
  return lowercaseText
end toLowerCase

return my manageSafariBookmarks("--MCP_INPUT:action", "--MCP_INPUT:url", "--MCP_INPUT:title", "--MCP_INPUT:folder", "--MCP_INPUT:addToReadingList")
```
