---
title: "Create Calendar Event"
description: "Creates a new event in Calendar (iCal) app with specified details"
keywords:
  - calendar
  - event
  - appointment
  - schedule
  - create event
  - iCal
language: applescript
id: calendar_create_event
argumentsPrompt: "Provide title, date, start time, end time, and optional notes for the event"
category: "07_productivity_apps"
---

This script creates a new event in the default calendar with the specified details.

```applescript
-- Event details (can be replaced with MCP placeholders)
set eventTitle to "Meeting with Client" -- --MCP_INPUT:title
set eventDate to "2025-01-15" -- --MCP_INPUT:date (format YYYY-MM-DD)
set startTime to "10:00" -- --MCP_INPUT:startTime (format HH:MM)
set endTime to "11:00" -- --MCP_INPUT:endTime (format HH:MM)
set eventNotes to "Discuss project timeline" -- --MCP_INPUT:notes

-- Convert string date/time to date objects
set eventStartDate to my makeDate(eventDate, startTime)
set eventEndDate to my makeDate(eventDate, endTime)

tell application "Calendar"
  -- Create a new event in the default calendar
  tell calendar 1
    set newEvent to make new event with properties {summary:eventTitle, start date:eventStartDate, end date:eventEndDate, description:eventNotes}
    
    -- Uncomment to add a location
    -- set location of newEvent to "Conference Room 1"
    
    -- Uncomment to add a URL
    -- set url of newEvent to "https://example.com/meeting"
    
    -- Uncomment to set all-day event
    -- set allday event of newEvent to true
    
    -- Uncomment to add an alarm
    -- tell newEvent to make new display alarm at end of every display alarm with properties {trigger interval:-30}
  end tell
  
  return "Created event: " & eventTitle & " on " & eventDate & " from " & startTime & " to " & endTime
end tell

-- Helper function to convert date and time strings to date objects
on makeDate(dateStr, timeStr)
  set {year:y, month:m, day:d} to {text 1 thru 4 of dateStr, text 6 thru 7 of dateStr, text 9 thru 10 of dateStr}
  set {hour:h, minute:min} to {text 1 thru 2 of timeStr, text 4 thru 5 of timeStr}
  
  set dateObj to current date
  set year of dateObj to y as integer
  set month of dateObj to m as integer
  set day of dateObj to d as integer
  set hours of dateObj to h as integer
  set minutes of dateObj to min as integer
  set seconds of dateObj to 0
  
  return dateObj
end makeDate
```

This script:
1. Creates a new event with a title, date, start time, end time, and notes
2. Can be customized with input placeholders (using `--MCP_INPUT:fieldName`)
3. Shows how to add optional properties like location, URL, all-day setting, and alarms
4. Includes a helper function to convert string date/time formats to date objects

END_TIP