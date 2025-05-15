---
title: "StandardAdditions: list disks and list folder Commands"
category: "01_applescript_core" # Subdir: scripting_additions_osax
id: osax_list_disk_folder
description: "Lists mounted disk volumes and the contents of a specified folder."
keywords: ["StandardAdditions", "list disks", "list folder", "file system", "directory listing", "volumes", "files", "folders", "osax"]
language: applescript
notes: |
  - `list disks` returns a list of names of all mounted volumes (e.g., "Macintosh HD", "Time Machine", "NetworkShare").
  - `list folder` takes a path (alias or string) to a folder and returns a list of names of items directly within that folder.
  - `list folder ... invisibles false` excludes invisible files/folders.
  - `list folder ... without invisibles` is an alias for `list folder ... invisibles false`.
---

Provides information about mounted disks and folder contents.

```applescript
-- List all mounted disks
set allDisks to list disks
set diskOutput to "Mounted Disks: " & (allDisks as string)

-- List contents of the user's Desktop folder (excluding invisibles)
set desktopPath to path to desktop
set desktopContents to "(Could not access Desktop or it is empty)"
try
  set folderItems to list folder desktopPath without invisibles
  if (count of folderItems) > 0 then
    -- Display first 5 items for brevity if many items
    if (count of folderItems) > 5 then
      set desktopContents to "Desktop (first 5 items): " & ((items 1 thru 5 of folderItems) as string)
    else
      set desktopContents to "Desktop items: " & (folderItems as string)
    end if
  else
    set desktopContents to "Desktop folder is empty or contains only invisibles."
  end if
on error err
  set desktopContents = "Error listing Desktop: " & err
end try

-- List contents of the /Applications folder including invisibles (first few)
set appsPathString to "/Applications/"
set appsContents to "(Could not access /Applications or it is empty)"
try
  set appFolderItems to list folder (POSIX file appsPathString as alias) -- No 'invisibles' parameter, so defaults to include them.
  if (count of appFolderItems) > 0 then
    if (count of appFolderItems) > 5 then
      set appsContents to "/Applications (first 5 items, incl. invisibles): " & ((items 1 thru 5 of appFolderItems) as string)
    else
      set appsContents to "/Applications items (incl. invisibles): " & (appFolderItems as string)
    end if
  else
    set appsContents to "/Applications folder is empty."
  end if
on error err2
  set appsContents = "Error listing /Applications: " & err2
end try

return diskOutput & "\n\n" & desktopContents & "\n\n" & appsContents
```
END_TIP 