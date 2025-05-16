---
id: pomodoro_focus
title: Pomodoro Focus Timer with Distractions Management
description: Implements a Pomodoro timer that automatically manages distractions
language: applescript
author: Claude
keywords:
  - productivity
  - focus
  - time management
  - pomodoro
  - distraction-free
usage_examples:
  - Start a Pomodoro session with automatic distraction management
  - Focus on work by temporarily closing distracting apps
parameters:
  - name: durationMinutes
    description: Duration of the Pomodoro session in minutes (default 25)
    required: false
  - name: distractingApps
    description: >-
      Comma-separated list of distracting apps to quit (e.g.,
      'Slack,Mail,Messages')
    required: false
category: 11_advanced/workflow_automation
---

# Pomodoro Focus Timer with Distractions Management

This script implements the Pomodoro technique by setting a timer and automatically closing distracting applications. When the timer completes, it will notify you and reopen the previously closed applications.

```applescript
on run {input, parameters}
    set durationMinutes to "--MCP_INPUT:durationMinutes"
    set distractingApps to "--MCP_INPUT:distractingApps"
    
    -- Set default duration if not specified
    if durationMinutes is "" or durationMinutes is missing value then
        set durationMinutes to 25
    else
        try
            set durationMinutes to durationMinutes as number
        on error
            display dialog "Invalid duration: " & durationMinutes & ". Please enter a number." buttons {"OK"} default button "OK" with icon stop
            return
        end try
    end if
    
    -- Set default distracting apps if not specified
    if distractingApps is "" or distractingApps is missing value then
        set distractingAppsList to {"Mail", "Messages", "Slack", "Discord", "Twitter", "Music"}
    else
        -- Convert comma-separated string to list
        set AppleScript's text item delimiters to ","
        set distractingAppsList to text items of distractingApps
        set AppleScript's text item delimiters to ""
    end if
    
    -- Store which apps were actually running
    set runningApps to {}
    
    -- Check and quit distracting apps
    repeat with appName in distractingAppsList
        tell application "System Events"
            if exists process appName then
                set end of runningApps to appName
                tell application appName to quit
            end if
        end tell
    end repeat
    
    -- Enable Do Not Disturb (Big Sur and later)
    try
        tell application "System Events"
            tell application process "ControlCenter"
                set frontmost to true
                click menu bar item "Focus" of menu bar 1
                delay 0.5
                click button "Do Not Disturb" of window 1
            end tell
        end tell
    on error
        -- Fallback for older macOS versions or if the above fails
        -- No reliable AppleScript method for older versions
        log "Could not enable Do Not Disturb automatically"
    end try
    
    -- Show start notification
    display notification "Focus session started for " & durationMinutes & " minutes" with title "Pomodoro Timer" sound name "Glass"
    
    -- Set the timer
    set durationSeconds to durationMinutes * 60
    set endTime to (current date) + durationSeconds
    
    -- Optional: Display a countdown (uncomment to use)
    --repeat while (current date) < endTime
    --    set timeLeft to endTime - (current date)
    --    set minutesLeft to (timeLeft / 60) div 1
    --    set secondsLeft to (timeLeft mod 60)
    --    -- Update display somehow (could use a dialog with a timeout)
    --    delay 1
    --end repeat
    
    -- Wait for the timer to finish
    delay durationSeconds
    
    -- Timer completed
    display notification "Time to take a break!" with title "Pomodoro Timer Completed" subtitle "You focused for " & durationMinutes & " minutes" sound name "Glass"
    
    -- Disable Do Not Disturb (attempt for Big Sur and later)
    try
        tell application "System Events"
            tell application process "ControlCenter"
                set frontmost to true
                click menu bar item "Focus" of menu bar 1
                delay 0.5
                click button "Do Not Disturb" of window 1
            end tell
        end tell
    on error
        log "Could not disable Do Not Disturb automatically"
    end try
    
    -- Reopen apps that were closed
    repeat with appName in runningApps
        tell application appName to activate
    end repeat
    
    return "Completed " & durationMinutes & " minute Pomodoro session"
end run
```

## Pomodoro Technique Overview

The Pomodoro Technique is a time management method developed by Francesco Cirillo in the late 1980s. The technique uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks. Each interval is known as a "pomodoro," from the Italian word for tomato, after the tomato-shaped kitchen timer Cirillo used as a university student.

The basic steps are:
1. Decide on the task to be done
2. Set the timer (traditionally to 25 minutes)
3. Work on the task until the timer rings
4. Take a short break (5 minutes)
5. After four pomodoros, take a longer break (15-30 minutes)

## Customization Options

This script can be customized in several ways:

1. Change the default Pomodoro duration (25 minutes)
2. Modify the list of applications considered "distracting"
3. Add a visual countdown timer
4. Implement a break timer after the work session
5. Add statistics tracking for completed Pomodoros

To add a visual countdown instead of just waiting:

```applescript
-- Create a progress dialog
set dlg to display dialog "Pomodoro in progress..." buttons {"Cancel"} default button "Cancel" with title "Pomodoro Timer" giving up after durationSeconds
```

## Compatibility Notes

- The Do Not Disturb toggling works on macOS Big Sur and later
- For earlier versions, you would need different approaches to manage notifications
- The script has been tested on macOS Monterey but should work on most recent macOS versions
