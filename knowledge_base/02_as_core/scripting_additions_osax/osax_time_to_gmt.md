---
title: 'StandardAdditions: time to GMT Command'
category: 02_as_core/scripting_additions_osax
id: osax_time_to_gmt
description: >-
  Returns the difference in seconds between the computer's local time zone and
  Greenwich Mean Time (GMT)/Coordinated Universal Time (UTC).
keywords:
  - StandardAdditions
  - time to GMT
  - UTC offset
  - timezone
  - osax
language: applescript
notes: >
  - A negative number means local time is earlier than GMT (e.g., Americas).

  - A positive number means local time is later than GMT (e.g., Asia,
  Australia).

  - Result is in seconds. Divide by 3600 for hours.
---

```applescript
set gmtOffsetInSeconds to time to GMT
set gmtOffsetInHours to gmtOffsetInSeconds / (60 * 60)

return "Offset from GMT: " & gmtOffsetInSeconds & " seconds (" & gmtOffsetInHours & " hours)."
```
END_TIP 
