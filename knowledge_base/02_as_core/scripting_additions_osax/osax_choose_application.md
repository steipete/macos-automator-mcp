---
title: "StandardAdditions: choose application Command"
category: "01_applescript_core"
id: osax_choose_application
description: "Displays a dialog allowing the user to select an application. Returns an alias to the chosen application."
keywords: ["StandardAdditions", "choose application", "application selection", "dialog", "osax"]
language: applescript
notes: |
  - Parameters: `with title "text"`, `with prompt "text"`, `as application bundle` (boolean, default true).
  - Returns an alias to the selected application bundle.
  - If the user cancels, an error (number -128) is raised.
---

Allows the user to select an application via a standard dialog.

```applescript
try
  set chosenAppAlias to choose application with title "Choose an Editor" with prompt "Please select your preferred text editor:"
  
  -- Get information about the chosen application
  tell application "Finder"
    set appName to name of chosenAppAlias
  end tell
  set appPath to POSIX path of chosenAppAlias
  
  set resultMessage to "You chose: " & appName & "\nPath: " & appPath
  
  -- Example: Try to get version (might fail if app not scriptable for version or not running)
  -- This is a more advanced step and often requires a separate tell block to the chosen app.
  (*
  try
    -- This is a simplified way, direct `version of chosenAppAlias` might not work.
    -- Typically, you would `tell application (chosenAppAlias as text)` or similar.
    set appIdentifier to id of application (path to chosenAppAlias) -- Get bundle ID
    tell application id appIdentifier
      set appVersion to version
      set resultMessage to resultMessage & "\nVersion: " & appVersion
    end tell
  on error verErr
    set resultMessage to resultMessage & "\nVersion: (Could not get version - " & verErr & ")"
  end try
  *)
  
on error errMsg number errNum
  if errNum is -128 then
    set resultMessage to "User cancelled application selection."
  else
    set resultMessage to "Error (" & errNum & "): " & errMsg
  end if
end try

return resultMessage
```
END_TIP 