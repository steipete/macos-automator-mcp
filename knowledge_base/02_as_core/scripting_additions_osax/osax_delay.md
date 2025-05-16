---
title: 'StandardAdditions: delay Command'
category: 02_as_core
id: osax_delay
description: Pauses script execution for a specified number of seconds.
keywords:
  - StandardAdditions
  - delay
  - pause
  - wait
  - sleep
  - timing
  - osax
language: applescript
notes: >
  - The `delay` command takes a number (integer or real) representing seconds.

  - Fractional seconds are allowed (e.g., `delay 0.5`).

  - Useful for timing, waiting for UI elements to appear, or pacing script
  actions.
---

Pauses the script for a specified duration.

```applescript
log "Script started at: " & (time string of (current date))

delay 2 -- Pause for 2 seconds

log "Script resumed after 2 seconds at: " & (time string of (current date))

delay 0.5 -- Pause for half a second

set finalTime to time string of (current date)
log "Script finished after additional 0.5s delay at: " & finalTime

return "Script execution paused and resumed. Final log time: " & finalTime
```
END_TIP 
