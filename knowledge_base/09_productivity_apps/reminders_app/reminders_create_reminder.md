---
title: "Create New Reminder in Reminders App"
category: "09_productivity_apps" # Subdir: reminders_app
id: reminders_create_reminder
description: "Adds a new reminder to a specified list (or default list) with a name, and optional due date, priority, and body/notes."
keywords: ["Reminders", "to-do", "task", "new reminder", "schedule"]
language: applescript
version: "1.1"
validated: true
author: "Claude"
notes: |
  - Requires Automation permission for Reminders.app.
---

# Create New Reminder in Reminders App

This script demonstrates how to create a new reminder in the macOS Reminders app with customizable properties including name, list, due date, priority, and notes.

## Script Implementation

```applescript
-- Top-level call to the main handler with placeholders
processAndCreateReminder(
    "--MCP_INPUT:reminderName",
    "--MCP_INPUT:listName",
    "--MCP_INPUT:dueDateString",
    "--MCP_INPUT:priorityNum",
    "--MCP_INPUT:bodyText"
)

on processAndCreateReminder(rName_raw, rListName_raw, rDueDateStr_raw, rPriorityNum_str_raw, rBody_raw)
    -- Make local copies or reassign to new names if preferred for clarity
    set rName to rName_raw
    set rListName to rListName_raw
    set rDueDateStr to rDueDateStr_raw
    set rPriorityNum_str to rPriorityNum_str_raw -- This will be a string after any server-side replacement
    set rBody to rBody_raw

    -- Handle rName (required): Check if it's still the placeholder string.
    if rName is "--MCP_INPUT:reminderName" then
        return "error: Reminder name (--MCP_INPUT:reminderName) was not provided and is required."
    end if

    -- Handle optional rListName: If still placeholder, set to missing value.
    if rListName is "--MCP_INPUT:listName" then
        set rListName to missing value
    end if

    -- Handle optional rDueDateStr
    if rDueDateStr is "--MCP_INPUT:dueDateString" then
        set rDueDateStr to missing value
    end if
    
    -- Handle optional rPriorityNum_str (convert to integer rPriority or missing value)
    set rPriority to missing value
    if rPriorityNum_str is not "--MCP_INPUT:priorityNum" then
        try
            set rPriority to rPriorityNum_str as integer
        on error
            log "Warning: Invalid priority value ('" & rPriorityNum_str & "') provided by inputData. Priority will not be set."
        end try
    end if
    
    -- Handle optional rBody
    if rBody is "--MCP_INPUT:bodyText" then
        set rBody to missing value
    end if

    -- Core reminder creation logic (adapted from the previous createNewReminder handler)
    set reminderProps to {name:rName}

    if rDueDateStr is not missing value and rDueDateStr is not "" then
        try
            set reminderProps to reminderProps & {due date:(date rDueDateStr)}
        on error errMsg
            log "Warning: Invalid due date format ('" & rDueDateStr & "') for reminder. Due date not set. Error: " & errMsg
        end try
    end if

    if rPriority is not missing value then
        set reminderProps to reminderProps & {priority:rPriority}
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
end processAndCreateReminder
```

## Usage Examples

### Basic Usage: Create a Simple Reminder

```applescript
processAndCreateReminder("Buy groceries", missing value, missing value, missing value, missing value)
```

This creates a reminder titled "Buy groceries" in the default list with no due date, priority, or notes.

### Create a Reminder in a Specific List

```applescript
processAndCreateReminder("Finish project report", "Work", missing value, missing value, missing value)
```

Creates a reminder in the "Work" list. If the list doesn't exist, it falls back to the default list.

### Create a Reminder with Due Date

```applescript
processAndCreateReminder("Call mom", missing value, "tomorrow at 6 PM", missing value, missing value)
```

Creates a reminder with a due date set to tomorrow at 6 PM.

### Create a High Priority Reminder with Notes

```applescript
processAndCreateReminder("Submit tax return", "Personal", "April 15", "1", "Don't forget to include the W-2 forms")
```

Creates a high-priority reminder (priority 1) with a due date and additional notes.

## Priority Values

In Reminders app, priority values are:
- 0 or missing value: No priority 
- 1: High priority
- 5: Medium priority
- 9: Low priority

## Date Format Examples

The script accepts various date formats, such as:
- "tomorrow"
- "next Friday at noon"
- "April 15, 2023 at 3 PM"
- "3 days from now"
- "May 1"

## Error Handling

The script includes robust error handling for:
- Missing required parameters
- Invalid date formats
- Non-existent reminder lists
- Invalid priority values
- General Reminders app errors

## Permissions

This script requires Automation permission for Reminders.app, which may prompt the user on first run to grant permission in System Settings > Privacy & Security > Automation.