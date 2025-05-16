---
title: 'Photos: Create New Album'
category: 10_creative/photos_app
id: photos_create_album
description: Creates a new album in the Photos app with a specified name.
keywords:
  - Photos
  - create album
  - photo album
  - photo organization
language: applescript
argumentsPrompt: Enter a name for the new album
notes: Creates an empty album that you can later add photos to.
---

```applescript
on run {albumName}
  tell application "Photos"
    activate
    try
      if albumName is "" or albumName is missing value then
        set albumName to "--MCP_INPUT:albumName"
      end if
      
      set newAlbum to make new album named albumName
      
      return "Successfully created new album: " & albumName
      
    on error errMsg number errNum
      if errNum is -1728 then
        return "Error: An album with this name already exists."
      else
        return "Error (" & errNum & "): Failed to create album - " & errMsg
      end if
    end try
  end tell
end run
```
END_TIP
