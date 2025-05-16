---
title: 'Calendar: Find Events by Keyword'
category: 09_productivity
id: calendar_find_events
description: Searches for calendar events containing a specific keyword.
keywords:
  - Calendar
  - search events
  - find appointments
  - event search
  - meeting search
language: applescript
argumentsPrompt: Enter the keyword to search for in event titles
notes: >-
  Searches for events in all calendars that contain the specified keyword in
  their title.
---

```applescript
on run {searchKeyword}
  tell application "Calendar"
    try
      -- Handle placeholder substitution
      if searchKeyword is "" or searchKeyword is missing value then
        set searchKeyword to "--MCP_INPUT:searchKeyword"
      end if
      
      -- Get all calendars
      set allCalendars to every calendar
      set matchingEvents to {}
      
      -- Set date range for search (from today to 3 months ahead)
      set startDate to current date
      set endDate to startDate + (90 * days)
      
      -- Search each calendar for matching events
      repeat with currentCalendar in allCalendars
        set calendarName to name of currentCalendar
        
        -- Get events in the date range
        set calendarEvents to (every event of currentCalendar whose start date ? startDate and start date < endDate)
        
        -- Filter events by keyword
        repeat with currentEvent in calendarEvents
          set eventSummary to summary of currentEvent
          
          -- Check if the keyword is in the event summary (case-insensitive)
          if my stringContainsIgnoringCase(eventSummary, searchKeyword) then
            -- Get event details
            set eventStart to start date of currentEvent
            set eventEnd to end date of currentEvent
            set eventLocation to ""
            
            try
              set eventLocation to location of currentEvent
            on error
              -- Location might not be available
            end try
            
            -- Format the event information
            set eventInfo to {summary:eventSummary, calendar:calendarName, startDate:eventStart, endDate:eventEnd, location:eventLocation}
            
            -- Add to matching events list
            set end of matchingEvents to eventInfo
          end if
        end repeat
      end repeat
      
      -- Create response based on search results
      if (count of matchingEvents) is 0 then
        return "No events found containing \"" & searchKeyword & "\" in the next 3 months."
      else
        -- Sort events by start date
        set sortedEvents to my sortEventsByDate(matchingEvents)
        
        -- Format the results
        set resultText to "Found " & (count of sortedEvents) & " events containing \"" & searchKeyword & "\":" & return & return
        
        repeat with i from 1 to count of sortedEvents
          set currentEvent to item i of sortedEvents
          
          set eventSummary to summary of currentEvent
          set calendarName to calendar of currentEvent
          set eventStart to startDate of currentEvent
          set eventEnd to endDate of currentEvent
          set eventLocation to location of currentEvent
          
          -- Format dates
          set formattedStart to my formatDateTime(eventStart)
          set formattedEnd to my formatDateTime(eventEnd)
          
          -- Add event to results
          set resultText to resultText & "Event " & i & ": " & eventSummary & return
          set resultText to resultText & "  Calendar: " & calendarName & return
          set resultText to resultText & "  Date: " & formattedStart & return
          
          if eventLocation is not "" then
            set resultText to resultText & "  Location: " & eventLocation & return
          end if
          
          set resultText to resultText & return
        end repeat
        
        return resultText
      end if
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search for events - " & errMsg
    end try
  end tell
end run

-- Check if a string contains another string (case-insensitive)
on stringContainsIgnoringCase(theText, searchString)
  set lowercaseText to do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
  set lowercaseSearch to do shell script "echo " & quoted form of searchString & " | tr '[:upper:]' '[:lower:]'"
  
  return lowercaseText contains lowercaseSearch
end stringContainsIgnoringCase

-- Sort events by start date
on sortEventsByDate(eventsList)
  set n to count of eventsList
  repeat with i from 1 to n - 1
    repeat with j from 1 to n - i
      if startDate of item j of eventsList > startDate of item (j + 1) of eventsList then
        set temp to item j of eventsList
        set item j of eventsList to item (j + 1) of eventsList
        set item (j + 1) of eventsList to temp
      end if
    end repeat
  end repeat
  
  return eventsList
end sortEventsByDate

-- Format date and time in a user-friendly way
on formatDateTime(theDate)
  set dayNames to {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
  set monthNames to {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
  
  set dayName to item ((weekday of theDate) + 1) of dayNames
  set monthName to item (month of theDate) of monthNames
  
  set theDay to day of theDate as string
  set theYear to year of theDate as string
  
  set hours to hours of theDate
  set mins to minutes of theDate
  
  -- Format hours and minutes with leading zeros if needed
  if hours < 10 then set hours to "0" & hours
  if mins < 10 then set mins to "0" & mins
  
  return dayName & ", " & monthName & " " & theDay & ", " & theYear & " at " & hours & ":" & mins
end formatDateTime
```
END_TIP
