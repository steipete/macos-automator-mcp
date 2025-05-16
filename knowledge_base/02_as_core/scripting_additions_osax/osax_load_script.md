---
title: 'StandardAdditions: load script Command'
category: 02_as_core/scripting_additions_osax
id: osax_load_script
description: >-
  Loads a compiled script file (.scpt) or script application (.app) into memory
  as a script object, allowing its handlers and properties to be called.
keywords:
  - StandardAdditions
  - load script
  - script object
  - reusable code
  - library
  - module
  - osax
language: applescript
notes: >
  - `load script` takes a file reference (alias or HFS path string) to a
  compiled script file (.scpt) or a script application (.app).

  - It returns a script object representing the loaded script.

  - You can then call handlers defined within that script object using `tell
  scriptObjectName to handlerName()` or `handlerName() of scriptObjectName`.

  - Useful for creating reusable code libraries or modules.

  - The script being loaded must be compiled; it cannot be plain text.
---

Loads a compiled AppleScript from a file, making its handlers and properties available.

```applescript
-- Assume we have a file named "MyLibrary.scpt" on the Desktop with the following content:
-- on greet(personName)
--   return "Hello, " & personName & "!"
-- end greet
-- property libVersion : "1.0"

set desktopPath to path to desktop
set libPathString to (desktopPath as text) & "MyLibrary.scpt" -- HFS path string

-- First, create the library script if it doesn't exist (for this example)
set libScriptContent to "on greet(personName)\n  return \"Hello, \" & personName & \"!\"\nend greet\nproperty libVersion : \"1.0\""
try
  set libFile to open for access file libPathString with write permission
  set eof libFile to 0
  write libScriptContent to libFile
  close access libFile
  -- Compile the script (important for load script)
  -- This step is normally done by saving as .scpt in Script Editor
  -- For programmatic creation, we can use `store script`
  set tempScript to script
    property libVersion : "1.0"
    on greet(personName)
      return "Hello, " & personName & "!"
    end greet
  end script
  store script tempScript in file libPathString replacing yes -- This compiles and saves it

on error e
  -- Might fail if permissions are wrong or path is bad
  return "Error creating library file: " & e
end try

set loadedLib to missing value
set greetingResult to ""
set versionResult to ""

try
  set libFileAlias to alias libPathString
  set loadedLib to load script libFileAlias
  
  -- Call a handler from the loaded script
  set greetingResult to greet("World") of loadedLib
  -- Access a property from the loaded script
  set versionResult to libVersion of loadedLib
  
  -- Alternatively, using `tell` block
  -- tell loadedLib
  --   set greetingResult to greet("Again")
  --   set versionResult to libVersion
  -- end tell
  
  set finalMessage to "Greeting: " & greetingResult & "\nLibrary Version: " & versionResult
  
on error errMsg number errNum
  set finalMessage to "Error loading or using script (" & errNum & "): " & errMsg
end try

-- Clean up the created library file (optional)
try
  tell application "Finder" to delete file libPathString
on error
  -- ignore cleanup error
end try

return finalMessage
```
END_TIP 
