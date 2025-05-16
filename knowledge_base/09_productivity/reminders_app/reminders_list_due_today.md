---
title: 'Reminders: List Items Due Today'
category: 09_productivity
id: reminders_list_due_today
description: Lists all reminders that are due today.
keywords:
  - Reminders
  - due today
  - today's tasks
  - today's reminders
  - day's tasks
language: applescript
notes: 'Displays all reminders due today across all reminder lists, grouped by list.'
---

```applescript
tell application "Reminders"
  try
    -- Get today's date bounds
    set todayStart to current date
    set time of todayStart to 0 -- Beginning of today (00:00:00)
    
    set tomorrowStart to todayStart + (1 * days) -- Beginning of tomorrow
    
    -- Prepare to collect reminders due today
    set remindersByList to {}
    set allLists to every list
    
    -- Check each list for reminders due today
    repeat with currentList in allLists
      set listName to name of currentList
      set remindersDueToday to {}
      
      tell currentList
        -- Get reminders that are due today and not completed
        set dueReminders to (every reminder whose due date ? todayStart and due date < tomorrowStart and completed is false)
        
        if (count of dueReminders) > 0 then
          -- Add reminders to the list
          repeat with currentReminder in dueReminders
            set reminderName to name of currentReminder
            set reminderDueDate to due date of currentReminder
            
            -- Format the due time
            set dueHours to hours of reminderDueDate
            set dueMinutes to minutes of reminderDueDate
            
            -- Format with leading zeros
            if dueHours < 10 then
              set dueHours to "0" & dueHours
            end if
            if dueMinutes < 10 then
              set dueMinutes to "0" & dueMinutes
            end if
            
            set dueTimeString to dueHours & ":" & dueMinutes
            
            -- Add to the list
            set end of remindersDueToday to {name:reminderName, dueTime:dueTimeString}
          end repeat
          
          -- Add list and its reminders to the collection
          set end of remindersByList to {listName:listName, reminders:remindersDueToday}
        end if
      end tell
    end repeat
    
    -- Generate report
    if (count of remindersByList) is 0 then
      return "You have no reminders due today."
    else
      set totalCount to 0
      set resultText to "Reminders Due Today:" & return & return
      
      repeat with listInfo in remindersByList
        set listName to listName of listInfo
        set listReminders to reminders of listInfo
        set reminderCount to count of listReminders
        set totalCount to totalCount + reminderCount
        
        -- Add list header
        set resultText to resultText & "List: " & listName & " (" & reminderCount & " items)" & return
        
        -- Add each reminder
        repeat with i from 1 to count of listReminders
          set reminderInfo to item i of listReminders
          set reminderName to name of reminderInfo
          set dueTime to dueTime of reminderInfo
          
          set resultText to resultText & "  - " & reminderName & " (Due at " & dueTime & ")" & return
        end repeat
        
        set resultText to resultText & return
      end repeat
      
      set resultText to resultText & "Total reminders due today: " & totalCount
      
      return resultText
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list reminders due today - " & errMsg
  end try
end tell
```
END_TIP
