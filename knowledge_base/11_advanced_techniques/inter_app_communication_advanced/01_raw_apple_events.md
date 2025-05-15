---
title: "Advanced: Raw Apple Events"
category: "13_advanced_techniques" # Subdir: inter_app_communication_advanced
id: advanced_raw_apple_events
description: "Explains raw Apple Events using four-character codes (chevrons «») and their limited use cases."
keywords: ["Apple Events", "raw events", "four-char codes", "chevrons", "low-level", "scripting bridge", "sdef"]
language: applescript
notes: |
  - Raw Apple Events use four-character codes (e.g., `«event ToySRunT»`) instead of human-readable terms.
  - Guillemets (`«` and `»`) are used to denote these codes. You can type them with Option-\ and Shift-Option-\
  - This is a lower-level way to send commands to applications and is rarely needed by scripters, as application dictionaries usually provide human-readable terms.
  - It can be useful if an application responds to an event that isn't documented in its dictionary, or when dealing with very old applications or custom inter-application communication.
  - The `event ID` is a combination of an Event Class and an Event ID (both four-character codes).
---

Raw Apple Events provide a low-level mechanism to communicate with applications using their internal four-character codes.

While application dictionaries typically provide user-friendly terms, understanding raw events can be helpful for debugging or advanced scenarios.

**How to type Guillemets:**

*   `«` : Option + \
*   `»` : Shift + Option + \

```applescript
-- This example demonstrates sending a raw 'run' event to Finder.
-- The 'run' event for most applications is defined in the Core Suite (aevt) with ID 'oapp'.
-- However, Finder has its own 'run' event: class 'fndr', ID 'run ' (note the trailing space).

-- Most applications will respond to a 'core' 'run' event, which is equivalent to 'launch' or 'activate'
try
  tell application "Finder"
    -- Send the standard 'run' event (oapp)
    -- This is often implicitly handled by `launch` or `activate`
    -- but can be sent explicitly if needed, for example, to a remote application.
    event "aevtoapp"
  end tell
  set result1 to "Finder launched/activated via standard 'run' event (aevtoapp)."
on error e1
  set result1 to "Error sending standard 'run' event to Finder: " & e1
end try

-- Sending Finder's specific 'run ' event.
-- This is equivalent to just `tell application "Finder" to run` or `activate`.
-- It's shown here to illustrate the raw event format.
try
  tell application "Finder"
    -- «event fndrrun » -- This is the raw Apple Event notation.
    -- The string equivalent is "fndrrun " (note the space at the end of run)
    event "fndrrun "
  end tell
  set result2 to "Finder activated via its specific 'fndrrun ' event."
on error e2
  set result2 to "Error sending 'fndrrun ' event to Finder: " & e2
end try

-- Example of a raw event with a parameter (setting the selection)
-- This is a more complex example and highly specific to Finder.
-- 'core' 'setd' is the event for setting data.
-- The direct parameter is a list of items to select.
-- The key 'Want' (kobj) specifies the object whose selection is being set (e.g., desktop window).

set selectionResult to "(Raw selection example not run by default due to complexity and potential side effects)"
(* -- Uncomment to test, make sure you have an item named "TestFile.txt" on your Desktop
set desktopPath to path to desktop as text
set testFilePath to desktopPath & "MyTestFile.txt"
-- Create a dummy file for selection
try
  close access (open for access file testFilePath with write permission)
on error
  -- file already exists or other error, ignore for this example
end try

tell application "Finder"
  try
    set targetFile to file testFilePath
    -- Raw Apple Event to set selection
    -- Event Class: core (Core Suite)
    -- Event ID:    setd (set data)
    -- Direct Parameter: list of items to select (e.g., {alias "Mac HD:Users:user:Desktop:MyTestFile.txt"})
    -- Parameter '----': the object whose selection to set (e.g., desktop window)
    -- '----' is the raw code for the direct parameter.
    -- 'kocl' is the code for `class` and 'obj ' is the element type for object specifier.
    -- 'form' is `prop`, 'want' is `csel` (current selection), 'seld' is the data to set.
    
    -- This is highly complex and usually abstracted by dictionary terms like `select`
    -- The below is a conceptual representation. Constructing complex raw events manually is rare.
    -- event "coresetd" given {"----":{targetFile}, "kobj":desktop window 1}
    
    -- The simpler, dictionary-based way:
    select targetFile
    set selectionResult to "Selected '" & (name of targetFile) & "' using standard select command."
  on error e3
    set selectionResult to "Error in selection example: " & e3
  end try
  -- Clean up
  -- delete file testFilePath 
end tell
*)

return result1 & "\n" & result2 & "\n" & selectionResult
```
END_TIP 