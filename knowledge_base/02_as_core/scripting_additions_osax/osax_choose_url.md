---
title: 'StandardAdditions: choose URL Command'
category: 02_as_core/scripting_additions_osax
id: osax_choose_url
description: >-
  Displays a dialog for the user to enter or select a URL. Returns the entered
  URL as text.
keywords:
  - StandardAdditions
  - choose URL
  - URL input
  - dialog
  - web address
  - osax
language: applescript
notes: >
  - Parameters: `with title "text"`, `showing (URL | FTP | File | All)`, `with
  prompt "text"`.

  - `showing URL` (default): Shows a field for HTTP/HTTPS URLs.

  - `showing FTP`: Shows fields for FTP URLs.

  - `showing File`: Shows a file browser to select a local file URL
  (`file:///...`).

  - `showing All`: Provides a popup to switch between URL, FTP, and File.

  - Returns the URL as a string (e.g., "http://www.apple.com" or
  "ftp://ftp.example.com" or "file:///Users/user/Desktop/file.txt").

  - If the user cancels, an error (number -128) is raised.
---

Allows the user to input or select a URL via a specialized dialog.

```applescript
set chosenURL to ""
try
  -- Choose a URL, showing HTTP/HTTPS field by default
  set urlResult to choose URL with prompt "Enter the website URL:" with title "Website Chooser"
  if urlResult is not false then
    set chosenURL to "URL: " & urlResult
  else
    set chosenURL to "User cancelled URL input."
  end if
  
  -- Choose a File URL
  set fileURLResult to choose URL showing File with prompt "Select a local file to get its URL:" with title "File URL Chooser"
  if fileURLResult is not false then
    set chosenURL to chosenURL & "\nFile URL: " & fileURLResult
  else
    set chosenURL to chosenURL & "\nUser cancelled File URL input."
  end if
  
on error errMsg number errNum
  if errNum is -128 then
    set chosenURL to chosenURL & "\nUser cancelled a dialog (-128)."
  else
    set chosenURL to chosenURL & "\nError (" & errNum & "): " & errMsg
  end if
end try

return chosenURL
```
END_TIP 
