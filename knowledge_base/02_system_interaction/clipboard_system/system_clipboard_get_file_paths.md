---
title: "System Clipboard: Get File Paths (if any)"
category: "02_system_interaction" # Subdir: clipboard_system
id: system_clipboard_get_file_paths
description: "Checks if the clipboard contains file references (e.g., copied from Finder) and returns their POSIX paths."
keywords: ["clipboard", "file path", "copy files", "Finder selection", "System Events"]
language: applescript
notes: "Returns a newline-separated string of paths or an informational message. Uses System Events for robust clipboard access."
---

```applescript
tell application "System Events"
  try
    set theClipboardContent to the clipboard
    
    -- Check if clipboard content is a list (often indicates files)
    if class of theClipboardContent is list then
      set filePaths to {}
      repeat with anItem in theClipboardContent
        try
          -- Coerce item to alias, then to POSIX path. 'file' objects on clipboard are often of class 'file'.
          set end of filePaths to POSIX path of (anItem as alias)
        on error
          -- Item might not be a file path (e.g., text mixed with files)
        end try
      end repeat
      if filePaths is not {} then
        set AppleScript's text item delimiters to "\\n"
        set pathsString to filePaths as string
        set AppleScript's text item delimiters to ""
        return pathsString
      else
        return "Clipboard contains a list, but no valid file paths found."
      end if
    else if (theClipboardContent as text) starts with "file://" then
      -- Sometimes clipboard has URI list as text
      set AppleScript's text item delimiters to linefeed
      set potentialPaths to paragraphs of (theClipboardContent as string)
      set AppleScript's text item delimiters to ""
      set filePaths to {}
      repeat with aPathStr in potentialPaths
        if aPathStr starts with "file://" then
          try
            -- Convert URI to POSIX path (basic attempt)
            set decodedPath to do shell script "echo " & quoted form of aPathStr & " | sed 's/^file:\\/\\///' | perl -MURI::Escape -ne 'print uri_unescape($_)'"
             -- Further check if it's a valid path
            do shell script "test -e " & quoted form of decodedPath -- Test existence
            set end of filePaths to decodedPath
          on error
            -- Not a valid path or other issue
          end try
        end if
      end repeat
       if filePaths is not {} then
        set AppleScript's text item delimiters to "\\n"
        set pathsString to filePaths as string
        set AppleScript's text item delimiters to ""
        return pathsString
      else
        return "Clipboard text looks like URIs, but no valid file paths extracted."
      end if
    else
      return "Clipboard does not appear to contain file paths."
    end if
  on error errMsg
    return "error: Failed to get clipboard file paths - " & errMsg
  end try
end tell
```
END_TIP 