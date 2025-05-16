---
title: Calendar Event Creator
category: 09_productivity/calendar_app
id: calendar_event_creator
description: >-
  Creates calendar events with custom details, recurrence, alerts, and attendees
  using AppleScript's Calendar application integration
keywords:
  - calendar
  - event
  - appointment
  - scheduling
  - reminders
  - recurrence
  - meeting
  - attendees
  - alerts
language: applescript
notes: >-
  Works with macOS Calendar application (formerly iCal). Supports natural
  language date parsing and advanced calendar features.
---

```applescript
-- Calendar Event Creator
-- Creates events in macOS Calendar app with various options

-- Default calendar selection
property defaultCalendar : "Calendar" -- Replace with your default calendar name
property defaultDuration : 60 -- Duration in minutes
property defaultAlert : 15 -- Default alert time in minutes before event
property defaultLocation : ""
property defaultURLString : ""
property defaultNotes : ""
property defaultAllDay : false

-- Initialize any necessary settings
on initialize()
  -- Check if the Calendar app is available
  try
    tell application "Calendar" to get name of calendars
    return true
  on error
    display dialog "Error: Cannot access Calendar application. Make sure it's installed." buttons {"OK"} default button "OK" with icon stop
    return false
  end try
end initialize

-- Get list of available calendars
on getAvailableCalendars()
  tell application "Calendar"
    set calendarList to {}
    set availableCalendars to name of calendars
    repeat with calName in availableCalendars
      set end of calendarList to calName as string
    end repeat
    return calendarList
  end tell
end getAvailableCalendars

-- Parse natural language date (e.g., "tomorrow at 3pm")
on parseDate(dateString)
  set dateCommand to "date -j -f \"%a %b %d %H:%M:%S %Z %Y\" \"`date \"+%a %b %d %H:%M:%S %Z %Y\" -d \"" & dateString & "\"`\" \"+%Y-%m-%d %H:%M:%S\""
  
  try
    set formattedDate to do shell script dateCommand
    
    -- Parse the formatted date string
    set yearStr to text 1 thru 4 of formattedDate
    set monthStr to text 6 thru 7 of formattedDate
    set dayStr to text 9 thru 10 of formattedDate
    set hourStr to text 12 thru 13 of formattedDate
    set minuteStr to text 15 thru 16 of formattedDate
    set secondStr to text 18 thru 19 of formattedDate
    
    -- Convert to numbers
    set yearNum to yearStr as integer
    set monthNum to monthStr as integer
    set dayNum to dayStr as integer
    set hourNum to hourStr as integer
    set minuteNum to minuteStr as integer
    set secondNum to secondStr as integer
    
    -- Create the date object
    set parsedDate to current date
    set year of parsedDate to yearNum
    set month of parsedDate to monthNum
    set day of parsedDate to dayNum
    set hours of parsedDate to hourNum
    set minutes of parsedDate to minuteNum
    set seconds of parsedDate to secondNum
    
    return parsedDate
  on error errMsg
    -- Fallback to basic date parsing
    try
      set parsedDate to date dateString
      return parsedDate
    on error
      display dialog "Error parsing date: " & dateString & return & "Try using a standard format like 'MM/DD/YYYY HH:MM AM/PM'" buttons {"OK"} default button "OK" with icon stop
      error "Date parsing failed: " & dateString
    end try
  end try
end parseDate

-- Create a basic calendar event
on createBasicEvent(eventTitle, startDateStr, calendarName)
  if calendarName is "" then set calendarName to defaultCalendar
  
  -- Parse the start date
  set startDate to parseDate(startDateStr)
  
  -- Set end date based on default duration
  set endDate to startDate + (defaultDuration * minutes)
  
  tell application "Calendar"
    -- Find the specified calendar
    try
      set targetCalendar to first calendar whose name is calendarName
    on error
      -- Use default calendar if specified one doesn't exist
      set availableCalendars to name of calendars
      if (count of availableCalendars) > 0 then
        set targetCalendar to first calendar
      else
        error "No calendars available"
      end if
    end try
    
    -- Create the event
    tell targetCalendar
      make new event with properties {summary:eventTitle, start date:startDate, end date:endDate}
    end tell
    
    return "Event \"" & eventTitle & "\" created at " & startDateStr & " in calendar \"" & calendarName & "\""
  end tell
end createBasicEvent

-- Create a detailed calendar event with all options
on createDetailedEvent(eventProperties)
  set validProperties to true
  set errorMessage to ""
  
  -- Get event title
  set eventTitle to eventProperties's eventTitle
  if eventTitle is "" then
    set validProperties to false
    set errorMessage to "Event title cannot be empty"
  end if
  
  -- Get start date
  try
    set startDate to parseDate(eventProperties's startDate)
  on error
    set validProperties to false
    set errorMessage to "Invalid start date format"
  end try
  
  -- Handle end date based on duration or explicit end date
  if eventProperties's duration is not "" then
    try
      set durationMinutes to eventProperties's duration as integer
      set endDate to startDate + (durationMinutes * minutes)
    on error
      set endDate to startDate + (defaultDuration * minutes)
    end try
  else if eventProperties's endDate is not "" then
    try
      set endDate to parseDate(eventProperties's endDate)
    on error
      set endDate to startDate + (defaultDuration * minutes)
    end try
  else
    set endDate to startDate + (defaultDuration * minutes)
  end if
  
  -- Validate date range
  if endDate < startDate then
    set validProperties to false
    set errorMessage to "End date cannot be before start date"
  end if
  
  -- Proceed with event creation if properties are valid
  if validProperties then
    tell application "Calendar"
      -- Find the specified calendar
      try
        set targetCalendar to first calendar whose name is eventProperties's calendarName
      on error
        -- Use default calendar if specified one doesn't exist
        set availableCalendars to name of calendars
        if (count of availableCalendars) > 0 then
          set targetCalendar to first calendar
          set eventProperties's calendarName to name of targetCalendar
        else
          error "No calendars available"
        end if
      end try
      
      -- Create the event with basic properties
      tell targetCalendar
        set newEvent to make new event with properties {summary:eventTitle, start date:startDate, end date:endDate, allday event:eventProperties's allDay}
        
        -- Set location if provided
        if eventProperties's location is not "" then
          set location of newEvent to eventProperties's location
        end if
        
        -- Set URL if provided
        if eventProperties's url is not "" then
          set url of newEvent to eventProperties's url
        end if
        
        -- Set notes/description if provided
        if eventProperties's notes is not "" then
          set description of newEvent to eventProperties's notes
        end if
        
        -- Set status (confirmed, tentative, cancelled)
        if eventProperties's status is not "" then
          set status of newEvent to eventProperties's status
        end if
        
        -- Add alerts if specified
        if eventProperties's alertMinutesBefore is not "" then
          try
            set alertMinutes to eventProperties's alertMinutesBefore as integer
            make new display alarm at newEvent with properties {trigger interval:-alertMinutes * minutes}
          end try
        end if
        
        -- Add recurrence if specified
        -- Note: Complex recurrence rules require more detailed implementation
        if eventProperties's recurrence is not "" then
          set recurrenceType to eventProperties's recurrence
          
          if recurrenceType is "daily" then
            set recurrence of newEvent to recur daily
          else if recurrenceType is "weekly" then
            set recurrence of newEvent to recur weekly
          else if recurrenceType is "monthly" then
            set recurrence of newEvent to recur monthly
          else if recurrenceType is "yearly" then
            set recurrence of newEvent to recur yearly
          end if
        end if
      end tell
      
      -- Add attendees if provided
      if eventProperties's attendees is not {} then
        repeat with attendeeEmail in eventProperties's attendees
          tell newEvent
            make new attendee with properties {email:attendeeEmail}
          end tell
        end repeat
      end if
      
      return "Event \"" & eventTitle & "\" created at " & eventProperties's startDate & " in calendar \"" & eventProperties's calendarName & "\""
    end tell
  else
    return "Error creating event: " & errorMessage
  end if
end createDetailedEvent

-- Get a list of upcoming events
on getUpcomingEvents(calendarName, daysAhead)
  if calendarName is "" then set calendarName to defaultCalendar
  if daysAhead is "" or daysAhead < 1 then set daysAhead to 7
  
  set startDate to current date
  set endDate to startDate + (daysAhead * days)
  
  tell application "Calendar"
    try
      if calendarName is "All" then
        set eventList to events whose start date is greater than or equal to startDate and start date is less than or equal to endDate
      else
        set targetCalendar to first calendar whose name is calendarName
        set eventList to events of targetCalendar whose start date is greater than or equal to startDate and start date is less than or equal to endDate
      end if
      
      set eventSummary to {}
      
      repeat with anEvent in eventList
        set eventTitle to summary of anEvent
        set eventStart to start date of anEvent
        set eventEnd to end date of anEvent
        set isAllDay to allday event of anEvent
        
        set eventInfo to {title:eventTitle, start:eventStart, end:eventEnd, allDay:isAllDay}
        set end of eventSummary to eventInfo
      end repeat
      
      return eventSummary
    on error errMsg
      return "Error getting events: " & errMsg
    end try
  end tell
end getUpcomingEvents

-- Delete a specific event
on deleteEvent(eventTitle, startDateStr, calendarName)
  if calendarName is "" then set calendarName to defaultCalendar
  
  -- Parse the start date
  try
    set startDate to parseDate(startDateStr)
  on error
    return "Error: Invalid date format for " & startDateStr
  end try
  
  -- Create a date range for matching
  set startRange to startDate - 1 * minutes
  set endRange to startDate + 1 * minutes
  
  tell application "Calendar"
    try
      set targetCalendar to first calendar whose name is calendarName
      
      -- Find events matching the criteria
      set matchingEvents to events of targetCalendar whose summary is eventTitle and start date is greater than startRange and start date is less than endRange
      
      if (count of matchingEvents) is 0 then
        return "No events found matching \"" & eventTitle & "\" at " & startDateStr
      else
        -- Delete the matching events
        repeat with anEvent in matchingEvents
          delete anEvent
        end repeat
        
        return "Deleted " & (count of matchingEvents) & " event(s) matching \"" & eventTitle & "\" at " & startDateStr
      end if
    on error errMsg
      return "Error deleting event: " & errMsg
    end try
  end tell
end deleteEvent

-- Parse and format attendees list
on parseAttendees(attendeesString)
  set AppleScript's text item delimiters to ","
  set attendeeItems to text items of attendeesString
  set AppleScript's text item delimiters to ""
  
  set attendeesList to {}
  
  repeat with anAttendee in attendeeItems
    -- Trim whitespace
    set trimmedAttendee to do shell script "echo " & quoted form of anAttendee & " | xargs"
    if trimmedAttendee is not "" then
      set end of attendeesList to trimmedAttendee
    end if
  end repeat
  
  return attendeesList
end parseAttendees

-- Show dialog to create a basic event
on showBasicEventDialog()
  set eventDialog to display dialog "Enter event details:" & return & return & "Event Title:" default answer "" buttons {"Cancel", "More Options", "Create"} default button "Create"
  
  if button returned of eventDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  set eventTitle to text returned of eventDialog
  if eventTitle is "" then
    display dialog "Event title cannot be empty" buttons {"OK"} default button "OK" with icon stop
    return "Event creation cancelled: No title provided"
  end if
  
  -- If user wants simple event, ask for date and create
  if button returned of eventDialog is "Create" then
    set dateDialog to display dialog "When is this event?" & return & "(e.g., \"tomorrow at 3pm\" or \"2023-12-25 10:00\")" default answer "" buttons {"Cancel", "Create"} default button "Create"
    
    if button returned of dateDialog is "Cancel" then
      return "Event creation cancelled"
    end if
    
    set startDateStr to text returned of dateDialog
    
    -- Get list of calendars for selection
    set calendarList to getAvailableCalendars()
    set selectedCalendar to choose from list calendarList with prompt "Select Calendar:" default items {defaultCalendar}
    
    if selectedCalendar is false then
      return "Event creation cancelled: No calendar selected"
    end if
    
    return createBasicEvent(eventTitle, startDateStr, item 1 of selectedCalendar)
  else
    -- Show detailed event dialog
    return showDetailedEventDialog(eventTitle)
  end if
end showBasicEventDialog

-- Show dialog for creating event with all options
on showDetailedEventDialog(initialTitle)
  -- Get available calendars
  set calendarList to getAvailableCalendars()
  
  -- First: Title and date
  set titleDialog to display dialog "Event Title:" default answer initialTitle buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of titleDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  set eventTitle to text returned of titleDialog
  if eventTitle is "" then
    display dialog "Event title cannot be empty" buttons {"OK"} default button "OK" with icon stop
    return "Event creation cancelled: No title provided"
  end if
  
  -- Date and time dialog
  set dateDialog to display dialog "When is this event?" & return & "(e.g., \"tomorrow at 3pm\" or \"2023-12-25 10:00\")" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of dateDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  set startDateStr to text returned of dateDialog
  
  -- Duration dialog
  set durationDialog to display dialog "Event Duration (minutes):" default answer defaultDuration buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of durationDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  try
    set durationMinutes to text returned of durationDialog as integer
  on error
    set durationMinutes to defaultDuration
  end try
  
  -- Calendar selection
  set selectedCalendar to choose from list calendarList with prompt "Select Calendar:" default items {defaultCalendar}
  
  if selectedCalendar is false then
    return "Event creation cancelled: No calendar selected"
  end if
  
  set calendarName to item 1 of selectedCalendar
  
  -- Location dialog
  set locationDialog to display dialog "Location: (optional)" default answer defaultLocation buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of locationDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  set locationString to text returned of locationDialog
  
  -- Additional options dialog for alerts and recurrence
  set optionsDialog to display dialog "Additional Options:" & return & return & "Alert (minutes before):" & return & "Recurrence (daily, weekly, monthly, yearly):" default answer defaultAlert & return & "" buttons {"Cancel", "More Options", "Create Event"} default button "Create Event"
  
  if button returned of optionsDialog is "Cancel" then
    return "Event creation cancelled"
  end if
  
  -- Parse alert and recurrence settings
  set optionsText to text returned of optionsDialog
  set AppleScript's text item delimiters to return
  set optionsLines to text items of optionsText
  set AppleScript's text item delimiters to ""
  
  set alertMinutes to ""
  set recurrenceType to ""
  
  if (count of optionsLines) > 0 then
    try
      set alertMinutes to item 1 of optionsLines as integer
    on error
      set alertMinutes to defaultAlert
    end try
  end if
  
  if (count of optionsLines) > 1 then
    set recurrenceType to item 2 of optionsLines
  end if
  
  -- Set all-day flag
  set isAllDay to false
  
  -- Prepare attendees list
  set attendeesList to {}
  
  -- If user wants even more options
  if button returned of optionsDialog is "More Options" then
    -- Notes dialog
    set notesDialog to display dialog "Notes: (optional)" default answer defaultNotes buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of notesDialog is "Cancel" then
      return "Event creation cancelled"
    end if
    
    set notesText to text returned of notesDialog
    
    -- URL dialog
    set urlDialog to display dialog "URL: (optional)" default answer defaultURLString buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of urlDialog is "Cancel" then
      return "Event creation cancelled"
    end if
    
    set urlString to text returned of urlDialog
    
    -- Attendees dialog
    set attendeesDialog to display dialog "Attendees: (comma-separated email addresses, optional)" default answer "" buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of attendeesDialog is "Cancel" then
      return "Event creation cancelled"
    end if
    
    set attendeesString to text returned of attendeesDialog
    set attendeesList to parseAttendees(attendeesString)
    
    -- All-day event option
    set allDayOptions to {"Yes", "No"}
    set allDayChoice to choose from list allDayOptions with prompt "Is this an all-day event?" default items {"No"}
    
    if allDayChoice is false then
      return "Event creation cancelled"
    end if
    
    set isAllDay to (item 1 of allDayChoice is "Yes")
  else
    -- Use defaults for advanced options
    set notesText to defaultNotes
    set urlString to defaultURLString
  end if
  
  -- Create the event with all specified properties
  set eventProperties to {eventTitle:eventTitle, startDate:startDateStr, endDate:"", duration:durationMinutes, calendarName:calendarName, location:locationString, url:urlString, notes:notesText, alertMinutesBefore:alertMinutes, recurrence:recurrenceType, attendees:attendeesList, allDay:isAllDay, status:"confirmed"}
  
  return createDetailedEvent(eventProperties)
end showDetailedEventDialog

-- Show calendar event manager menu
on showCalendarMenu()
  set calendarOptions to {"Create Event", "View Upcoming Events", "Delete Event", "Cancel"}
  
  set selectedOption to choose from list calendarOptions with prompt "Calendar Event Manager:" default items {"Create Event"}
  
  if selectedOption is false then
    return "Calendar operation cancelled"
  end if
  
  set choice to item 1 of selectedOption
  
  if choice is "Create Event" then
    return showBasicEventDialog()
    
  else if choice is "View Upcoming Events" then
    -- Get list of calendars for selection
    set calendarList to getAvailableCalendars()
    set allCalendarList to {"All"} & calendarList
    
    set selectedCalendar to choose from list allCalendarList with prompt "Select Calendar:" default items {"All"}
    
    if selectedCalendar is false then
      return "Calendar viewing cancelled"
    end if
    
    set calendarName to item 1 of selectedCalendar
    
    -- Ask for number of days to look ahead
    set daysPrompt to display dialog "How many days ahead to view events?" default answer "7" buttons {"Cancel", "View Events"} default button "View Events"
    
    if button returned of daysPrompt is "Cancel" then
      return "Event viewing cancelled"
    end if
    
    try
      set daysAhead to text returned of daysPrompt as integer
    on error
      set daysAhead to 7
    end try
    
    -- Get and display upcoming events
    set upcomingEvents to getUpcomingEvents(calendarName, daysAhead)
    
    if class of upcomingEvents is string then
      -- Error occurred
      return upcomingEvents
    else if (count of upcomingEvents) is 0 then
      return "No upcoming events in the next " & daysAhead & " days."
    else
      -- Format events for display
      set eventReport to "Upcoming Events for the Next " & daysAhead & " Days:" & return & return
      
      repeat with i from 1 to count of upcomingEvents
        set eventInfo to item i of upcomingEvents
        set eventTitle to eventInfo's title
        set eventStart to eventInfo's start as string
        set eventEnd to eventInfo's end as string
        set isAllDay to eventInfo's allDay
        
        set eventReport to eventReport & i & ". " & eventTitle & return
        if isAllDay then
          set eventReport to eventReport & "   When: " & eventStart & " (All day)" & return
        else
          set eventReport to eventReport & "   Start: " & eventStart & return
          set eventReport to eventReport & "   End: " & eventEnd & return
        end if
        set eventReport to eventReport & return
      end repeat
      
      -- Display the events
      display dialog eventReport buttons {"OK"} default button "OK"
      
      return "Displayed " & (count of upcomingEvents) & " upcoming events"
    end if
    
  else if choice is "Delete Event" then
    -- Get list of calendars for selection
    set calendarList to getAvailableCalendars()
    
    set selectedCalendar to choose from list calendarList with prompt "Select Calendar:" default items {defaultCalendar}
    
    if selectedCalendar is false then
      return "Event deletion cancelled"
    end if
    
    set calendarName to item 1 of selectedCalendar
    
    -- Ask for event details
    set eventDialog to display dialog "Event to Delete:" & return & return & "Event Title:" default answer "" buttons {"Cancel", "Next"} default button "Next"
    
    if button returned of eventDialog is "Cancel" then
      return "Event deletion cancelled"
    end if
    
    set eventTitle to text returned of eventDialog
    if eventTitle is "" then
      display dialog "Event title cannot be empty" buttons {"OK"} default button "OK" with icon stop
      return "Event deletion cancelled: No title provided"
    end if
    
    -- Ask for the date of the event
    set dateDialog to display dialog "When is this event?" & return & "(e.g., \"tomorrow at 3pm\" or \"2023-12-25 10:00\")" default answer "" buttons {"Cancel", "Delete Event"} default button "Delete Event"
    
    if button returned of dateDialog is "Cancel" then
      return "Event deletion cancelled"
    end if
    
    set startDateStr to text returned of dateDialog
    
    -- Confirm deletion
    set confirmDialog to display dialog "Are you sure you want to delete event \"" & eventTitle & "\"?" buttons {"Cancel", "Delete"} default button "Cancel" with icon caution
    
    if button returned of confirmDialog is "Cancel" then
      return "Event deletion cancelled"
    end if
    
    return deleteEvent(eventTitle, startDateStr, calendarName)
  else
    return "Calendar operation cancelled"
  end if
end showCalendarMenu

-- Initialize and run the calendar event manager
on run
  if initialize() then
    return showCalendarMenu()
  else
    return "Calendar Event Manager initialization failed"
  end if
end run
```

This Calendar Event Creator script provides a comprehensive interface for managing events in the macOS Calendar application (formerly iCal). It offers both simple and advanced event creation options, along with the ability to view upcoming events and delete existing ones.

### Key Features:

1. **Event Creation Options**:
   - Basic quick-create for simple events
   - Detailed creation with all calendar event properties
   - Support for natural language date parsing (e.g., "tomorrow at 3pm")
   - Custom duration and time selection

2. **Advanced Calendar Features**:
   - Location and URL attachment
   - Notes/description
   - Recurrence options (daily, weekly, monthly, yearly)
   - Alert notifications with customizable timing
   - Support for all-day events
   - Attendee management with email addresses

3. **Calendar Management**:
   - Selection from all available calendars
   - View upcoming events for specific time periods
   - Delete events with confirmation
   - Calendar status options (confirmed, tentative, cancelled)

4. **User Interface**:
   - Interactive dialogue-based interface
   - Step-by-step event creation process
   - Calendar selection menus
   - Formatted event listing for readability

5. **Utility Functions**:
   - Natural language date parsing
   - Calendar availability checking
   - Attendee list parsing
   - Date validation

The script handles both simple and complex calendar needs, making it suitable for quick event creation as well as detailed meeting scheduling with attendees and recurrence patterns. It's designed to work with the standard macOS Calendar application and respects its data structure and capabilities.

For recurring events, basic recurring patterns are supported (daily, weekly, monthly, yearly). For more complex recurrence rules (like "every third Thursday"), additional customization would be required.
