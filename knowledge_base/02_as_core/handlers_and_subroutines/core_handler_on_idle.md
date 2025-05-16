---
title: 'Core: Stay-Open Applet Handler ''on idle'''
category: 02_as_core/handlers_and_subroutines
id: core_handler_on_idle
description: >-
  Defines a handler that executes periodically if the script is saved as a 'Stay
  Open' application. Returning a number sets the next idle interval in seconds.
keywords:
  - handler
  - idle
  - stay open
  - applet
  - background task
  - periodic
language: applescript
notes: >
  - Script must be saved as an Application with the "Stay open after run
  handler" checkbox checked.

  - The `idle` handler is called automatically by the system.

  - `return <number_of_seconds>` sets how long to wait before the next `idle`
  call. Default is 30 seconds if no value or an invalid value is returned.
---

```applescript
-- This stay-open applet will display the current time every 10 seconds.

property lastTimeDisplayed : ""

on idle
  set currentTimeString to time string of (current date)
  if currentTimeString is not lastTimeDisplayed then
    -- display notification currentTimeString with title "Idle Check" -- Can be annoying
    log "Idle tick: " & currentTimeString -- Check Script Editor log
    set lastTimeDisplayed to currentTimeString
  end if
  return 10 -- Check again in 10 seconds
end idle

-- Optional: on run handler is executed once when the applet first launches
on run
  log "Stay-open applet started. Idle handler will run periodically."
  -- Perform initial setup if any
end run

-- Optional: on quit handler for cleanup when the applet is quit
on quit
  log "Stay-open applet quitting."
  -- Perform cleanup
  continue quit -- Allow the applet to actually quit
end quit
```
END_TIP 
