---
title: "Calendar: List Events for Today"
category: "07_productivity_apps"
id: calendar_list_today_events
description: "Retrieves and lists all events scheduled for the current day from all calendars."
keywords: ["Calendar", "list events", "today's schedule", "appointments"]
language: applescript
notes: "Formats output as a string. Returns events from all calendars."
---

```applescript
tell application "Calendar"
  activate
  try
    set todayStart to (current date)
    set time of todayStart to 0 -- Beginning of today (00:00:00)
    
    set tomorrowStart to todayStart + (1 * days) -- Beginning of tomorrow
    
    set eventSummaryList to {}
    set allEventsToday to every event whose start date ? todayStart and start date < tomorrowStart
    
    if (count of allEventsToday) is 0 then
      return "No events scheduled for today."
    end if
    
    set outputString to "Today's Events:\\n"
    
    repeat with anEvent in allEventsToday
      set eventName to summary of anEvent
      set eventStartDate to start date of anEvent
      set eventEndDate to end date of anEvent
      set eventCalendar to name of calendar of anEvent
      
      set startTimeString to time string of eventStartDate
      set endTimeString to time string of eventEndDate
      
      set eventDetails to "  - " & eventName & " (" & eventCalendar & ")\\n" & ¬
                         "    From: " & startTimeString & " To: " & endTimeString & "\\n"
      set end of eventSummaryList to eventDetails
    end repeat
    
    set AppleScript's text item delimiters to "\\n"
    set outputString to outputString & (eventSummaryList as string)
    set AppleScript's text item delimiters to "" -- Reset
    
    return outputString
    
  on error errMsg number errNum
    return "error (" & errNum & "): Failed to list today's events - " & errMsg
  end try
end tell
```
END_TIP 