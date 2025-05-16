---
title: 'Core: Date Data Type'
category: 02_as_core/variables_and_data_types
id: core_datatype_date
description: Working with dates and times in AppleScript.
keywords:
  - date
  - time
  - data type
  - current date
  - format
  - calculation
language: applescript
notes: >-
  AppleScript is sensitive to date string formats. 'date "string"' is used for
  coercion.
---

```applescript
-- Get current date and time
set now to current date

-- Create a specific date
set specificDate to date "December 25, 2024 10:30:00 AM"

-- Get parts of a date
set theYear to year of now
set theMonth to month of now -- returns a month constant, e.g., 'December'
set theDay to day of now
set theWeekday to weekday of now -- returns a weekday constant, e.g., 'Wednesday'
set timeString to time string of now

-- Date calculations (result is in seconds, or can be coerced back to date)
set oneHourLater to now + (1 * hours) -- 'hours' is a constant
set secondsDifference to specificDate - now

return "Now: " & (now as string) & "\\nYear: " & theYear & "\\nOne hour later: " & (oneHourLater as string) & "\\nSeconds diff: " & secondsDifference
``` 
