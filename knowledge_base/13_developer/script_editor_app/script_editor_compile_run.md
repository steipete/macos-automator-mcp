---
title: 'Script Editor: Compile and Run Active Script'
category: 13_developer
id: script_editor_compile_run
description: Tells Script Editor to compile and then run its frontmost document.
keywords:
  - Script Editor
  - compile
  - run script
  - applescript development
language: applescript
notes: >
  - Script Editor must have a document open and be the frontmost application.

  - Useful for programmatic testing or chaining script executions during
  development.
---

```applescript
tell application "Script Editor"
  if not running then
    run -- Launch Script Editor if not running
    delay 1
    -- Optionally make new document if none are open upon launch
    -- if (count of documents) is 0 then make new document
  end if
  activate
  
  if (count of documents) is 0 then
    return "error: No script document open in Script Editor."
  end if
  
  try
    tell front document
      -- Compile first (optional, run usually compiles implicitly)
      -- check syntax -- older command
      compile -- modern command
      delay 0.2
      if not (compiled) then
        return "error: Script did not compile successfully."
      end if
      
      set scriptResult to run
      if scriptResult is missing value then
        return "Script ran. No explicit result returned."
      else
        return "Script ran. Result: " & (scriptResult as text)
      end if
    end tell
  on error errMsg number errNum
    return "error (" & errNum & ") in Script Editor: " & errMsg
  end try
end tell
``` 
