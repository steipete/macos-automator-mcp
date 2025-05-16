---
title: 'Reminders: Create Advanced Reminder'
id: reminders_create_reminder_complex
category: 09_productivity/reminders_app
description: >-
  Adds a new reminder to a specified list (or default list) with a name, and
  optional due date, priority, and body/notes.
keywords:
  - Reminders
  - to-do
  - task
  - new reminder
  - schedule
  - priority
  - notes
language: applescript
argumentsPrompt: >-
  Expects inputData with:

  - reminderName (string, required): The name of the reminder.

  - listName (string, optional): The Reminders list to add to. Defaults to the
  default list.

  - dueDateString (string, optional): The due date (e.g., "12/25/2023 10:00
  AM").

  - priorityNum (integer, optional): Priority (0 for none, 1-9. Typically
  1=High, 5=Medium, 9=Low).

  - bodyText (string, optional): Notes for the reminder.
isComplex: true
---

This script creates a new reminder in the Reminders application with advanced options including priority and notes.

```applescript
--MCP_INPUT:reminderName
--MCP_INPUT:listName
--MCP_INPUT:dueDateString
--MCP_INPUT:priorityNum
--MCP_INPUT:bodyText

on runWithInput(inputData, legacyArguments)
    set rName to missing value
    set rListName to missing value
    set rDueDateStr to missing value
    set rPriorityNum to missing value
    set rBody to missing value

    if inputData is not missing value then
        if inputData contains {reminderName:""} then
            set rName to reminderName of inputData
        end if
        if inputData contains {listName:""} then
            set rListName to listName of inputData
        end if
        if inputData contains {dueDateString:""} then
            set rDueDateStr to dueDateString of inputData
        end if
        if inputData contains {priorityNum:""} then
            set rPriorityNum to priorityNum of inputData
        end if
        if inputData contains {bodyText:""} then
            set rBody to bodyText of inputData
        end if
    end if

    if rName is missing value or rName is "" then
        return "Error: reminderName is required and was not provided."
    end if

    set reminderProps to {name:rName}
    
    if rDueDateStr is not missing value and rDueDateStr is not "" then
        try
            set reminderProps to reminderProps & {due date:(date rDueDateStr)}
        on error errMsg
            log "Warning: Invalid due date format ('" & rDueDateStr & "') for reminder. Due date not set. Error: " & errMsg
        end try
    end if
    
    if rPriorityNum is not missing value and rPriorityNum is not "" then
        try
            set numericPriority to rPriorityNum as integer
            if numericPriority is greater than or equal to 0 and numericPriority is less than or equal to 9 then
                 set reminderProps to reminderProps & {priority:numericPriority}
            else
                 log "Warning: Invalid priority number: " & rPriorityNum & ". Priority must be 0-9. Priority not set."
            end if
        on error
            log "Warning: Priority '" & rPriorityNum & "' was not a valid number. Priority not set."
        end try
    end if
    
    if rBody is not missing value and rBody is not "" then
        set reminderProps to reminderProps & {body:rBody}
    end if
    
    tell application "Reminders"
        activate
        try
            set targetList to missing value
            if rListName is not missing value and rListName is not "" then
                if exists list rListName then
                    set targetList to list rListName
                else
                    log "Warning: Reminder list '" & rListName & "' not found. Using default list."
                end if
            end if
            
            if targetList is missing value then
                set targetList to default list
            end if
            
            tell targetList
                make new reminder with properties reminderProps
            end tell
            return "Reminder '" & rName & "' created in list '" & (name of targetList) & "'."
        on error errMsg
            return "error: Could not create reminder - " & errMsg
        end try
    end tell
end runWithInput

-- This is the direct call that happens after substitution by the MCP server
-- For testing in Script Editor, you'd call it like:
-- my runWithInput({reminderName:"Test From Script Editor", priorityNum:5, dueDateString:"tomorrow 5pm"}, missing value)
return my runWithInput(inputData, legacyArguments)
```
END_TIP
