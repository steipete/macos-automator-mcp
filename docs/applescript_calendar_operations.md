# AppleScript: Calendar Operations

This document demonstrates how to automate Calendar.app (formerly iCal) operations using AppleScript. You can create new events, list existing events, and manage calendars through automation.

## Creating a Calendar Event

```applescript
-- Event details
set eventTitle to "Team Meeting"
set eventDate to "2025-01-15" -- Format: YYYY-MM-DD
set startTime to "10:00" -- Format: HH:MM
set endTime to "11:00" -- Format: HH:MM
set eventNotes to "Discuss quarterly goals"

-- Convert string date/time to date objects
set eventStartDate to my makeDate(eventDate, startTime)
set eventEndDate to my makeDate(eventDate, endTime)

tell application "Calendar"
  -- Create a new event in the default calendar
  tell calendar 1
    make new event with properties {
      summary: eventTitle,
      start date: eventStartDate, 
      end date: eventEndDate, 
      description: eventNotes
    }
  end tell
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

## Listing Today's Events

```applescript
tell application "Calendar"
  -- Get current date with time set to beginning of day
  set todayStart to current date
  set hours of todayStart to 0
  set minutes of todayStart to 0
  set seconds of todayStart to 0
  
  -- Set end time to end of today
  set todayEnd to todayStart + (24 * 60 * 60) -- Add seconds in a day
  
  -- Get events from all calendars
  set todaysEvents to {}
  repeat with currentCal in calendars
    set calEvents to events of currentCal whose start date is greater than or equal to todayStart and start date is less than todayEnd
    set todaysEvents to todaysEvents & calEvents
  end repeat
  
  -- Create a summary of events
  set eventSummary to "Today's events (" & (count of todaysEvents) & " total):" & return
  repeat with thisEvent in todaysEvents
    set eventStart to start date of thisEvent
    set eventTitle to summary of thisEvent
    set eventSummary to eventSummary & return & ¬
      time string of eventStart & " - " & eventTitle
  end repeat
  
  return eventSummary
end tell
```

## Advanced: Creating an Event with Alarms and Invitees

```applescript
tell application "Calendar"
  set defaultCal to calendar "Work"
  
  tell defaultCal
    -- Create the event
    set newMeeting to make new event with properties {
      summary: "Project Review",
      start date: (current date) + (24 * 60 * 60), -- Tomorrow
      end date: (current date) + (25 * 60 * 60), -- Tomorrow + 1 hour
      location: "Conference Room A"
    }
    
    -- Add an alarm 15 minutes before
    tell newMeeting
      make new display alarm at end of display alarms with properties {
        trigger interval: -15 * minutes
      }
      
      -- Add attendees (requires properly configured Mail)
      make new attendee at end of attendees with properties {
        email: "colleague@example.com"
      }
    end tell
  end tell
end tell
```

## Common Use Cases

- Scheduling recurring meetings automatically
- Creating events based on external data sources
- Building automated daily/weekly planning systems
- Generating summary reports of upcoming appointments
- Syncing events between different calendar systems

## Notes and Limitations

- These scripts require permission to control Calendar.app
- For more complex date manipulations, helper functions are often necessary
- Adding attendees requires proper configuration of Mail.app
- Calendar names may vary between systems, so consider querying for available calendars first
- Event creation operations may require user confirmation depending on security settings