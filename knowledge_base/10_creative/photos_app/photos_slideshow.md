---
title: 'Photos: Start Slideshow'
category: 10_creative
id: photos_slideshow
description: Starts a slideshow of selected photos or an album in the Photos app.
keywords:
  - Photos
  - slideshow
  - photo presentation
  - image slideshow
  - view photos
language: applescript
argumentsPrompt: 'Enter the album name (optional, uses selected photos if not specified)'
notes: >-
  Starts a slideshow in the Photos app. Either uses currently selected photos or
  a specified album.
---

```applescript
on run {albumName}
  tell application "Photos"
    try
      activate
      
      if albumName is "" or albumName is missing value then
        set albumName to "--MCP_INPUT:albumName"
      end if
      
      -- Check if an album name was provided
      if albumName is not "--MCP_INPUT:albumName" and albumName is not "" then
        -- Try to find and select the specified album
        try
          -- First check if album exists
          set albumExists to false
          set allAlbums to albums
          
          repeat with currentAlbum in allAlbums
            if name of currentAlbum is albumName then
              set albumExists to true
              exit repeat
            end if
          end repeat
          
          if not albumExists then
            return "Album \"" & albumName & "\" not found. Please check the album name."
          end if
          
          -- Use UI scripting to navigate to and select the album
          tell application "System Events"
            tell process "Photos"
              -- Click on Albums in the sidebar if it exists
              if exists row "Albums" of outline 1 of scroll area 1 of splitter group 1 of window 1 then
                click row "Albums" of outline 1 of scroll area 1 of splitter group 1 of window 1
                delay 0.5
              end if
              
              -- Look for the album in the main view
              set albumFound to false
              set viewItems to UI elements of scroll area 1 of group 1 of splitter group 1 of window 1
              
              repeat with viewItem in viewItems
                if exists static text 1 of viewItem then
                  if value of static text 1 of viewItem is albumName then
                    -- Double-click to open the album
                    click viewItem
                    delay 0.1
                    click viewItem
                    set albumFound to true
                    delay 0.5
                    exit repeat
                  end if
                end if
              end repeat
              
              if not albumFound then
                return "Album \"" & albumName & "\" found but could not be selected in the UI."
              end if
              
              -- Select all photos in the album (Cmd+A)
              keystroke "a" using {command down}
              delay 0.5
            end tell
          end tell
          
        on error errMsg number errNum
          return "Error (" & errNum & "): Failed to select album - " & errMsg
        end try
      else
        -- Use selected photos
        set selectedItems to selection
        
        if (count of selectedItems) is 0 then
          return "No photos selected and no album specified. Please select photos or specify an album name."
        end if
      end if
      
      -- Start the slideshow
      tell application "System Events"
        tell process "Photos"
          -- Use keyboard shortcut to start slideshow (Cmd+Y or Play button if visible)
          keystroke "y" using {command down}
          
          return "Slideshow started."
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to start slideshow - " & errMsg
    end try
  end tell
end run
```
END_TIP
