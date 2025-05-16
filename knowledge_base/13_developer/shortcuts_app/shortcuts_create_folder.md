---
title: 'Shortcuts: Create New Folder'
category: 13_developer
id: shortcuts_create_folder
description: Creates a new folder in the Shortcuts app to organize shortcuts.
keywords:
  - Shortcuts
  - create folder
  - shortcut organization
  - folder
  - organize shortcuts
language: applescript
argumentsPrompt: Enter the name for the new folder
notes: >-
  Creates a new folder in the Shortcuts app for organizing your shortcuts.
  Useful for keeping different types of shortcuts organized.
---

```applescript
on run {folderName}
  tell application "Shortcuts"
    try
      -- Handle placeholder substitution
      if folderName is "" or folderName is missing value then
        set folderName to "--MCP_INPUT:folderName"
      end if
      
      activate
      
      -- Give Shortcuts app time to launch
      delay 1
      
      tell application "System Events"
        tell process "Shortcuts"
          -- Click the "+" button in the toolbar to show the dropdown menu
          if exists button 1 of group 1 of toolbar 1 of window 1 then
            click button 1 of group 1 of toolbar 1 of window 1
            delay 0.5
            
            -- Click "New Folder" from the menu
            if exists menu item "New Folder" of menu 1 then
              click menu item "New Folder" of menu 1
              delay 0.5
              
              -- Enter the folder name in the dialog
              if exists sheet 1 of window 1 then
                set value of text field 1 of sheet 1 of window 1 to folderName
                
                -- Click Create button
                click button "Create" of sheet 1 of window 1
                
                return "Successfully created new Shortcuts folder: " & folderName
              else
                return "Failed to create folder: Folder creation dialog did not appear."
              end if
            else
              return "Failed to create folder: 'New Folder' menu item not found."
            end if
          else
            -- Alternative method if the button layout has changed
            -- Try to use File menu
            click menu item "File" of menu bar 1
            delay 0.3
            click menu item "New Folder" of menu "File" of menu bar 1
            delay 0.5
            
            -- Enter the folder name in the dialog
            if exists sheet 1 of window 1 then
              set value of text field 1 of sheet 1 of window 1 to folderName
              
              -- Click Create button
              click button "Create" of sheet 1 of window 1
              
              return "Successfully created new Shortcuts folder: " & folderName
            else
              return "Failed to create folder: Folder creation dialog did not appear."
            end if
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create folder - " & errMsg
    end try
  end tell
end run
```
END_TIP
