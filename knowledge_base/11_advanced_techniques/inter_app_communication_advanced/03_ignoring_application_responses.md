---
title: "Advanced: 'ignoring application responses' Block"
category: "11_advanced_techniques"
id: advanced_ignoring_responses
description: "Explains how to use 'ignoring application responses' to send commands without waiting for completion or handling errors from the target application."
keywords: ["Apple Events", "ignoring application responses", "asynchronous", "fire and forget", "error handling", "performance"]
language: applescript
notes: |
  - `ignoring application responses ... end ignoring` tells AppleScript not to wait for the target application to acknowledge or complete the command.
  - This can speed up scripts that send many commands to slow applications, or when the outcome of a command isn't critical.
  - Errors from the commands within the block are not reported back to the calling script.
  - Use with caution, as you lose confirmation that the command succeeded or any return value.
---

The `ignoring application responses` block allows scripts to send commands to an application without waiting for it to finish processing them or return a result.

This can be useful for "fire-and-forget" operations or when interacting with applications that might be slow to respond, preventing your script from hanging.

```applescript
-- Example: Quickly sending multiple commands to TextEdit without waiting

set appIsRunning to false
try
  tell application "System Events"
    if (name of first application process whose frontmost is true) is "TextEdit" or (exists process "TextEdit") then
      set appIsRunning to true
    end if
  end tell
end try

if not appIsRunning then
  -- For this example, ensure TextEdit is running, or it might not receive the events properly.
  -- activate application "TextEdit" -- uncomment if needed, but can interfere with `ignoring` block timing
end if

set statusLog to ""

tell application "TextEdit"
  -- Without ignoring responses, each `make new document` would wait for completion.
  -- With `ignoring application responses`, AppleScript sends the commands and moves on.
  
  ignoring application responses
    try
      make new document with properties {text: "Document 1 - Sent without waiting"}
      set statusLog to statusLog & "Sent command to create Document 1.\n"
      
      make new document with properties {text: "Document 2 - Also sent without waiting"}
      set statusLog to statusLog & "Sent command to create Document 2.\n"
      
      -- Even if an error occurred here (e.g., trying to access a non-existent document),
      -- the script might not immediately halt or report it *outside* the tell block.
      -- set text of document 99 to "This will likely fail silently inside ignore block"
      
    on error eMsg number eNum
      -- This error block within the ignoring block might not be hit reliably 
      -- if the error is from the target app not responding quickly enough.
      set statusLog to statusLog & "Error inside ignoring block (unlikely to be caught for app errors): " & eMsg & "\n"
    end try
  end ignoring
  
  set statusLog to statusLog & "Commands sent. TextEdit might still be processing.\n"
  
  -- Give TextEdit a moment to process the commands sent without waiting
  delay 1 -- This delay is outside the `ignoring` block
  
  try
    set docCount to count of documents
    set statusLog to statusLog & "TextEdit now has " & docCount & " documents.\n"
  on error e
    set statusLog to statusLog & "Could not get document count: " & e & "\n"
  end try
  
end tell

-- Example of where it's useful: telling multiple apps to quit
-- If one app hangs on quit, the script won't get stuck.
set quitStatus to ""
(* -- Uncomment to test with multiple apps
set appsToQuit to {"Calculator", "Stickies"} -- Make sure these are running
ignoring application responses
    repeat with anApp in appsToQuit
        try
            tell application anApp to quit
            set quitStatus to quitStatus & "Sent quit command to " & anApp & ".\n"
        on error quitErr
            set quitStatus to quitStatus & "Error sending quit to " & anApp & ": " & quitErr & ".\n"
        end try
    end repeat
end ignoring
set quitStatus to quitStatus & "All quit commands sent."
*)
if quitStatus is "" then set quitStatus to "(Quit example not run)"

return statusLog & "\n" & quitStatus
```
END_TIP 