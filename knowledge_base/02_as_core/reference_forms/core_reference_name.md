---
title: "Core: Name Reference Form"
category: "01_applescript_core"
id: core_reference_name
description: "Accessing objects by their specified name (e.g., files, applications, windows)."
keywords: ["reference form", "name", "file name", "application name", "window name", "object specifier"]
language: applescript
notes: |
  - This form is common when dealing with applications that have named elements.
  - The exact name must be known and is usually case-insensitive, but this can depend on the application.
  - If multiple items have the same name, this form usually refers to the first one found unless combined with other specifiers.
---

Objects can often be referred to directly by their name.

```applescript
-- File example (using Finder)
tell application "Finder"
  try
    -- Make sure a file named "MyTestDocument.txt" exists on your Desktop for this to work
    -- You might need to create it first for a successful run.
    -- set testFile to make new file at desktop with properties {name:"MyTestDocument.txt"}
    
    set myDoc to file "MyTestDocument.txt" of desktop
    set docName to name of myDoc
    set docKind to kind of myDoc
    
    -- Clean up (optional)
    -- delete myDoc
    
  on error errMsg
    set docName to "(Error: Ensure 'MyTestDocument.txt' exists on Desktop)"
    set docKind to errMsg
  end try
end tell

-- Application example
-- Note: Application names are usually the .app name without the extension.
tell application "TextEdit"
  activate
  -- If TextEdit is running and has an untitled document:
  try
    set frontDoc to document "Untitled"
    set frontDocName to name of frontDoc
  on error
    set frontDocName to "(TextEdit not running or no 'Untitled' document)"
  end try
end tell

-- Window example (using System Events for a specific application)
(*
tell application "System Events"
  tell process "Safari" -- Ensure Safari is running with a window
    try
      set mainSafariWindow to window 1 -- Get a reference to a window first
      -- Then, if you know its exact name (which can change or be non-unique)
      -- set specificWindowByName to window "Apple – Start page" -- Example, highly likely to change
      -- set windowTitle to name of specificWindowByName
      set windowTitle to name of mainSafariWindow -- More robust for this example
    on error
      set windowTitle to "(Error accessing Safari window or Safari not running)"
    end try
  end tell
end tell
*)
set windowTitle to "(Safari example commented out for general execution)"

return "Document Name (Finder): " & docName & ¬
  "\nDocument Kind (Finder): " & docKind & ¬
  "\nFront Document Name (TextEdit): " & frontDocName & ¬
  "\nWindow Title (System Events/Safari): " & windowTitle
```
END_TIP 