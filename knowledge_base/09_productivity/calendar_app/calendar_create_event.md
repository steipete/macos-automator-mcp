---
title: "Calendar: Create New Event"
category: "07_productivity_apps"
id: calendar_create_event
description: "Creates a new event in the Calendar app with specified details."
keywords: ["Calendar", "create event", "schedule event", "appointment", "meeting"]
language: applescript
argumentsPrompt: "Enter the event title, date/time, duration, and calendar name"
notes: "Creates a new event with the specified details. Date format should be 'YYYY-MM-DD HH:MM:SS'. Duration is in minutes."
---

```applescript
on run {eventTitle, eventDateTime, durationMinutes, calendarName}
  tell application "Calendar"
    try
      -- Handle placeholder substitution
      if eventTitle is "" or eventTitle is missing value then
        set eventTitle to "--MCP_INPUT:eventTitle"
      end if
      
      if eventDateTime is "" or eventDateTime is missing value then
        set eventDateTime to "--MCP_INPUT:eventDateTime"
      end if
      
      if durationMinutes is "" or durationMinutes is missing value then
        set durationMinutes to "--MCP_INPUT:durationMinutes"
      end if
      
      if calendarName is "" or calendarName is missing value then
        set calendarName to "--MCP_INPUT:calendarName"
      end if
      
      -- Convert durationMinutes to integer
      if durationMinutes is not a number then
        try
          set durationMinutes to durationMinutes as number
        on error
          set durationMinutes to 60 -- Default to 1 hour if conversion fails
        end try
      end if
      
      -- Find the specified calendar, or use the default calendar
      set targetCalendar to missing value
      
      if calendarName is not "--MCP_INPUT:calendarName" and calendarName is not "" then
        try
          set targetCalendar to calendar calendarName
        on error
          -- If specified calendar not found, list available calendars
          set allCalendars to name of every calendar
          set AppleScript's text item delimiters to ", "
          set calendarList to allCalendars as string
          set AppleScript's text item delimiters to ""
          
          return "Calendar \"" & calendarName & "\" not found. Available calendars: " & calendarList
        end try
      else
        -- Use default calendar
        set targetCalendar to default calendar
        set calendarName to name of targetCalendar
      end if
      
      -- Parse the date string
      set eventDate to missing value
      
      if eventDateTime is not "--MCP_INPUT:eventDateTime" and eventDateTime is not "" then
        try
          -- Try to parse date in format "YYYY-MM-DD HH:MM:SS"
          set {year:y, month:m, day:d, hours:h, minutes:min} to my parseDateTime(eventDateTime)
          set eventDate to current date
          
          set year of eventDate to y
          set month of eventDate to m
          set day of eventDate to d
          set hours of eventDate to h
          set minutes of eventDate to min
          set seconds of eventDate to 0
        on error
          return "Error: Could not parse date. Please use format 'YYYY-MM-DD HH:MM:SS' (e.g., '2023-10-15 14:30:00')."
        end try
      else
        -- Default to a time one hour from now, rounded to nearest 30 minutes
        set eventDate to current date
        set minutes of eventDate to (((minutes of eventDate) div 30) + 1) * 30
      end if
      
      -- Calculate end date based on duration
      set endDate to eventDate + (durationMinutes * minutes)
      
      -- Create the event
      tell targetCalendar
        make new event with properties {summary:eventTitle, start date:eventDate, end date:endDate}
      end tell
      
      -- Format dates for user-friendly output
      set formattedStart to my formatDate(eventDate)
      set formattedEnd to my formatDate(endDate)
      
      return "Event created successfully!" & return & return & ¬
             "Title: " & eventTitle & return & ¬
             "Calendar: " & calendarName & return & ¬
             "Start: " & formattedStart & return & ¬
             "End: " & formattedEnd & return & ¬
             "Duration: " & durationMinutes & " minutes"
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create event - " & errMsg
    end try
  end tell
end run

-- Helper function to parse date-time string in format "YYYY-MM-DD HH:MM:SS"
on parseDateTime(dateTimeStr)
  set dateTimeParts to my split(dateTimeStr, " ")
  
  if (count of dateTimeParts) < 2 then
    error "Invalid date-time format"
  end if
  
  set datePart to item 1 of dateTimeParts
  set timePart to item 2 of dateTimeParts
  
  set datePieces to my split(datePart, "-")
  set timePieces to my split(timePart, ":")
  
  if (count of datePieces) < 3 or (count of timePieces) < 2 then
    error "Invalid date-time components"
  end if
  
  set y to item 1 of datePieces as number
  set m to item 2 of datePieces as number
  set d to item 3 of datePieces as number
  set h to item 1 of timePieces as number
  set min to item 2 of timePieces as number
  
  return {year:y, month:m, day:d, hours:h, minutes:min}
end parseDateTime

-- Helper function to split text by delimiter
on split(theText, theDelimiter)
  set AppleScript's text item delimiters to theDelimiter
  set theTextItems to every text item of theText
  set AppleScript's text item delimiters to ""
  return theTextItems
end split

-- Helper function to format date in user-friendly format
on formatDate(theDate)
  set dateString to ""
  
  tell (theDate)
    set dateString to its year as string
    set dateString to dateString & "-" & my padZero(its month as integer)
    set dateString to dateString & "-" & my padZero(its day)
    set dateString to dateString & " " & my padZero(its hours)
    set dateString to dateString & ":" & my padZero(its minutes)
  end tell
  
  return dateString
end formatDate

-- Helper function to pad a number with a leading zero if needed
on padZero(n)
  if n < 10 then
    return "0" & n
  else
    return n as string
  end if
end padZero
```