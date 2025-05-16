---
title: 'Reminders: Create New Reminder'
category: 09_productivity/reminders_app
id: reminders_create_simple_reminder
description: Creates a new reminder in the Reminders app with specified details.
keywords:
  - Reminders
  - create reminder
  - task
  - to-do
  - reminder item
language: applescript
argumentsPrompt: 'Enter the reminder title, due date (optional), and list name (optional)'
notes: >-
  Creates a new reminder with the specified title, optional due date, and in the
  specified list (or default list if none provided).
---

```applescript
on run {reminderTitle, dueDate, listName}
  tell application "Reminders"
    try
      -- Handle placeholder substitution
      if reminderTitle is "" or reminderTitle is missing value then
        set reminderTitle to "--MCP_INPUT:reminderTitle"
      end if
      
      if dueDate is "" or dueDate is missing value then
        set dueDate to "--MCP_INPUT:dueDate"
      end if
      
      if listName is "" or listName is missing value then
        set listName to "--MCP_INPUT:listName"
      end if
      
      -- Find or create the destination list
      set destinationList to missing value
      
      if listName is not "--MCP_INPUT:listName" and listName is not "" then
        -- Try to find the specified list
        try
          set destinationList to list listName
        on error
          -- If list doesn't exist, show available lists
          set allLists to name of every list
          set AppleScript's text item delimiters to ", "
          set listNamesString to allLists as string
          set AppleScript's text item delimiters to ""
          
          return "List \"" & listName & "\" not found. Available lists: " & listNamesString
        end try
      else
        -- Use default list if none specified
        set destinationList to default list
        set listName to name of destinationList
      end if
      
      -- Parse due date if provided
      set reminderDueDate to missing value
      
      if dueDate is not "--MCP_INPUT:dueDate" and dueDate is not "" then
        try
          -- Try to parse date in format "YYYY-MM-DD HH:MM:SS"
          set {year:y, month:m, day:d, hours:h, minutes:min} to my parseDateTime(dueDate)
          set reminderDueDate to current date
          
          set year of reminderDueDate to y
          set month of reminderDueDate to m
          set day of reminderDueDate to d
          set hours of reminderDueDate to h
          set minutes of reminderDueDate to min
          set seconds of reminderDueDate to 0
        on error
          return "Error: Could not parse due date. Please use format 'YYYY-MM-DD HH:MM:SS' (e.g., '2023-10-15 14:30:00')."
        end try
      end if
      
      -- Create the reminder
      tell destinationList
        set newReminder to make new reminder with properties {name:reminderTitle}
        
        -- Set due date if provided
        if reminderDueDate is not missing value then
          set due date of newReminder to reminderDueDate
        end if
      end tell
      
      -- Generate success message
      set resultText to "Reminder \"" & reminderTitle & "\" created in list \"" & listName & "\""
      
      if reminderDueDate is not missing value then
        set formattedDueDate to my formatDate(reminderDueDate)
        set resultText to resultText & " with due date " & formattedDueDate
      end if
      
      return resultText
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create reminder - " & errMsg
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
END_TIP
