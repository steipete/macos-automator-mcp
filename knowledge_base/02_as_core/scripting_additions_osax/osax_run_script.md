---
title: 'StandardAdditions: run script Command'
category: 02_as_core
id: osax_run_script
description: >-
  Executes a script object, script file, or script applet from within another
  script. Can pass parameters and receive a return value.
keywords:
  - StandardAdditions
  - run script
  - execute script
  - call script
  - modular scripting
  - osax
language: applescript
notes: >
  - `run script` takes a file reference (alias or HFS path string) to a compiled
  .scpt or .app file, or a script object.

  - Can also execute a string containing AppleScript code if the `in` parameter
  specifies `AppleScript` language (though `load script` is generally preferred
  for strings of code).

  - `with parameters {param1, param2, ...}` passes arguments to the `on run
  {arg1, arg2, ...}` handler of the target script.

  - `with in` parameter can specify the scripting language if running a string
  (`AppleScript` or `JavaScript`).

  - The target script's `run` handler is executed, and its return value is
  returned by `run script`.
---

Executes another AppleScript file or script object, optionally passing parameters.

```applescript
-- Setup: Create a simple script file to be run
set desktopPath to path to desktop
set targetScriptPath to (desktopPath as text) & "TargetScript.scpt"
set targetScriptContent to "on run {name, count}\n  set message to \"Hello, \" & name & \"! You ran this " & count & " times.\"\n  return message\nend run"

try
  set fRef to open for access file targetScriptPath with write permission
  set eof fRef to 0
  write targetScriptContent to fRef
  close access fRef
  -- For `run script` with a file, it should be compiled.
  -- `store script` will compile it.
  set tempScriptObj to script
    on run {name, count}
      set message to "Hello, " & name & "! You ran this " & count & " times."
      return message
    end run
  end script
  store script tempScriptObj in file targetScriptPath replacing yes
on error e
  return "Error creating target script: " & e
end try

set result1 to ""
set result2 to ""

-- 1. Run script from file with parameters
try
  set scriptFileAlias to alias targetScriptPath
  set result1 to run script scriptFileAlias with parameters {"Alice", 1}
on error e
  set result1 to "Error running script from file: " & e
end try

-- 2. Run a script object directly
set myScriptObject to script
  property greeting : "Hola"
  on wave(person)
    return greeting & " " & person & ", *waves*"
  end wave
  on run {arg1}
    return "Script object ran with: " & arg1
  end run
end script

try
  -- To run the 'run' handler of the script object:
  set result2_run to run script myScriptObject with parameters {"Direct Param"}
  -- To run a specific handler from the script object:
  set result2_wave to wave("Bob") of myScriptObject
  set result2 to result2_run & "\n" & result2_wave
on error e
  set result2 to "Error running script object: " & e
end try

-- Clean up the created script file (optional)
try
  tell application "Finder" to delete file targetScriptPath
on error
  -- ignore cleanup error
end try

return "Result from file: " & result1 & "\n\nResult from object: " & result2
```
END_TIP 
