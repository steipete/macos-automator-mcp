---
title: 'StandardAdditions: current date Command'
category: 02_as_core/scripting_additions_osax
id: osax_current_date
description: Returns the current system date and time as a date object.
keywords:
  - StandardAdditions
  - current date
  - date
  - time
  - now
  - timestamp
  - osax
language: applescript
notes: >-
  The returned value is a standard AppleScript date object, from which you can
  extract components like year, month, day, time string, etc.
---

`current date` retrieves the system's current date and time.

```applescript
set now to current date

-- Extracting components
set theYear to year of now
set theMonth to month of now -- e.g., December (a month constant)
set theDay to day of now     -- e.g., 7 (an integer)
set theWeekday to weekday of now -- e.g., Sunday (a weekday constant)

set theHours to hours of now       -- e.g., 14 (integer, 24-hour format)
set theMinutes to minutes of now   -- e.g., 30 (integer)
set theSeconds to seconds of now   -- e.g., 5 (integer)

set timeStr to time string of now  -- e.g., "2:30:05 PM"
set dateStr to date string of now  -- e.g., "Sunday, 7 July 2024"

-- Coercing the full date object to a string
set fullDateString to now as string -- e.g., "Sunday, 7 July 2024 at 14:30:05"

return "Full Date: " & fullDateString & ¬
  "\nYear: " & theYear & ¬
  "\nMonth: " & (theMonth as string) & ¬ -- Coerce month constant for display
  "\nDay: " & theDay & ¬
  "\nWeekday: " & (theWeekday as string) & ¬ -- Coerce weekday constant for display
  "\nTime String: " & timeStr & ¬
  "\nHours: " & theHours & ":" & theMinutes & ":" & theSeconds
```
END_TIP 
