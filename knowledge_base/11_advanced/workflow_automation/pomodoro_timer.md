---
title: Pomodoro Timer
category: 11_advanced/workflow_automation
id: pomodoro_timer
description: >-
  Implements a Pomodoro technique timer with customizable work/break intervals,
  notifications, and activity tracking
keywords:
  - pomodoro
  - timer
  - productivity
  - focus
  - notification
  - time management
  - work session
  - break
language: applescript
notes: >-
  Uses notification center for alerts. Can be customized with different time
  intervals and notification sounds.
---

```applescript
-- Pomodoro Timer
-- Implements the Pomodoro technique for improved productivity and focus

-- Configuration properties
property workDuration : 25 -- Minutes for work session (standard is 25)
property shortBreakDuration : 5 -- Minutes for short break (standard is 5)
property longBreakDuration : 15 -- Minutes for long break (standard is 15-30)
property pomodorosBeforeLongBreak : 4 -- Number of work sessions before a long break
property notificationSound : "Glass" -- Sound for notifications
property activateDoNotDisturb : true -- Automatically turn on Do Not Disturb during work sessions
property trackActivities : true -- Track activities/tasks for each Pomodoro
property logFile : "~/Library/Logs/PomodoroTimer.log" -- Path to log file
property activityHistory : {} -- Store completed Pomodoros and activities

-- Initialize the Pomodoro timer
on initializeTimer()
  -- Convert log path to full path
  set fullLogPath to do shell script "echo " & quoted form of logFile
  
  -- Initialize the log file if needed
  do shell script "touch " & quoted form of fullLogPath
  
  -- Log the start of a new Pomodoro session
  logMessage("Pomodoro session initialized at " & (current date as string))
  
  -- Return initialization message
  return "Pomodoro Timer initialized"
end initializeTimer

-- Log a message to the log file
on logMessage(message)
  set fullLogPath to do shell script "echo " & quoted form of logFile
  set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
  set logLine to timeStamp & " - " & message
  do shell script "echo " & quoted form of logLine & " >> " & quoted form of fullLogPath
end logMessage

-- Format time as MM:SS
on formatTime(totalSeconds)
  set minutes to totalSeconds div 60
  set seconds to totalSeconds mod 60
  
  -- Add leading zero if needed
  if seconds < 10 then
    set secondsStr to "0" & seconds
  else
    set secondsStr to seconds as string
  end if
  
  return minutes & ":" & secondsStr
end formatTime

-- Activate Do Not Disturb mode
on enableDoNotDisturb()
  try
    -- Method for macOS Monterey and newer
    do shell script "shortcuts run 'Turn On Focus'"
  on error
    -- Method for macOS Big Sur and older
    try
      tell application "System Events"
        tell process "Control Center"
          -- Click on Control Center icon in menu bar
          click menu bar item "Control Center" of menu bar 1
          delay 0.5
          -- Click on "Do Not Disturb" 
          click checkbox "Do Not Disturb" of group 1 of window "Control Center"
        end tell
      end tell
    on error
      -- Fallback method
      do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb -boolean true"
      do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturbDate -date \"`date -u +\"%Y-%m-%d %H:%M:%S +0000\"`\""
      do shell script "killall NotificationCenter"
    end try
  end try
  
  logMessage("Do Not Disturb enabled")
end enableDoNotDisturb

-- Disable Do Not Disturb mode
on disableDoNotDisturb()
  try
    -- Method for macOS Monterey and newer
    do shell script "shortcuts run 'Turn Off Focus'"
  on error
    -- Method for macOS Big Sur and older
    try
      tell application "System Events"
        tell process "Control Center"
          -- Click on Control Center icon in menu bar
          click menu bar item "Control Center" of menu bar 1
          delay 0.5
          -- Click on "Do Not Disturb" to turn it off
          click checkbox "Do Not Disturb" of group 1 of window "Control Center"
        end tell
      end tell
    on error
      -- Fallback method
      do shell script "defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb -boolean false"
      do shell script "killall NotificationCenter"
    end try
  end try
  
  logMessage("Do Not Disturb disabled")
end disableDoNotDisturb

-- Show a notification
on showNotification(title, message, soundName)
  display notification message with title title sound name soundName
  logMessage("Notification: " & title & " - " & message)
end showNotification

-- Run a countdown timer
on runCountdown(minutes, timerTitle, updateFunction)
  set totalSeconds to minutes * 60
  set startTime to current date
  set endTime to startTime + totalSeconds
  
  -- Show notification that timer has started
  showNotification(timerTitle & " Started", "Duration: " & minutes & " minutes", notificationSound)
  
  -- Loop until timer ends
  repeat until (current date) ≥ endTime
    set remainingSeconds to (endTime - (current date)) as integer
    
    -- Update the timer display (if updateFunction provided)
    if updateFunction is not "" then
      set timeString to formatTime(remainingSeconds)
      run script updateFunction & "(\"" & timerTitle & "\", \"" & timeString & "\")"
    end if
    
    -- Only check every second (to avoid high CPU usage)
    delay 1
  end repeat
  
  -- Return completion
  return timerTitle & " completed"
end runCountdown

-- Run a work session
on runWorkSession(sessionNumber)
  -- Enable Do Not Disturb if configured
  if activateDoNotDisturb then
    enableDoNotDisturb()
  end if
  
  -- Get the task for this Pomodoro if tracking is enabled
  set taskDescription to ""
  if trackActivities then
    set taskPrompt to display dialog "What will you work on for this Pomodoro #" & sessionNumber & "?" default answer "" buttons {"Cancel", "Start"} default button "Start"
    
    if button returned of taskPrompt is "Cancel" then
      logMessage("Work session " & sessionNumber & " cancelled")
      if activateDoNotDisturb then
        disableDoNotDisturb()
      end if
      return "Pomodoro cancelled"
    end if
    
    set taskDescription to text returned of taskPrompt
    logMessage("Work session " & sessionNumber & " started: " & taskDescription)
  else
    logMessage("Work session " & sessionNumber & " started")
  end if
  
  -- Run the timer
  set timerResult to runCountdown(workDuration, "Work Session #" & sessionNumber, "updateTimerDisplay")
  
  -- Record the completed session
  if trackActivities then
    set currentSession to {number:sessionNumber, type:"work", duration:workDuration, task:taskDescription, timestamp:(current date)}
    set end of activityHistory to currentSession
  end if
  
  -- Disable Do Not Disturb if it was enabled
  if activateDoNotDisturb then
    disableDoNotDisturb()
  end if
  
  -- Show completion notification
  showNotification("Work Session #" & sessionNumber & " Completed", "Time for a break!", notificationSound)
  
  return timerResult
end runWorkSession

-- Run a break session
on runBreakSession(sessionNumber, isLongBreak)
  -- Determine break type and duration
  set breakType to "Short Break"
  set breakDuration to shortBreakDuration
  
  if isLongBreak then
    set breakType to "Long Break"
    set breakDuration to longBreakDuration
  end if
  
  logMessage(breakType & " started after session #" & sessionNumber)
  
  -- Run the timer
  set timerResult to runCountdown(breakDuration, breakType & " after #" & sessionNumber, "updateTimerDisplay")
  
  -- Record the completed break
  if trackActivities then
    set currentBreak to {number:sessionNumber, type:if isLongBreak then "long_break" else "short_break", duration:breakDuration, timestamp:(current date)}
    set end of activityHistory to currentBreak
  end if
  
  -- Show completion notification
  showNotification(breakType & " Completed", "Ready for the next Pomodoro?", notificationSound)
  
  return timerResult
end runBreakSession

-- Update the timer display (can be customized for different UI implementations)
on updateTimerDisplay(timerTitle, timeRemaining)
  -- Simple implementation that shows progress in the app name
  -- In a more advanced UI, this could update a display element
  tell application "System Events" to set the name of the first process whose frontmost is true to timerTitle & " - " & timeRemaining
end updateTimerDisplay

-- Run a complete Pomodoro cycle
on runPomodoroCycle(numberOfPomodoros)
  -- Initialize the timer
  initializeTimer()
  
  -- Validate input
  if numberOfPomodoros < 1 then
    set numberOfPomodoros to 1
  end if
  
  -- Run the Pomodoro cycle
  repeat with i from 1 to numberOfPomodoros
    -- Run a work session
    runWorkSession(i)
    
    -- Determine if we need a long break
    set needsLongBreak to (i mod pomodorosBeforeLongBreak is 0) and (i < numberOfPomodoros)
    
    -- Run the appropriate break, unless this is the last Pomodoro
    if i < numberOfPomodoros then
      runBreakSession(i, needsLongBreak)
    end if
  end repeat
  
  -- Show completion notification
  showNotification("Pomodoro Cycle Completed", "You completed " & numberOfPomodoros & " Pomodoros!", notificationSound)
  
  -- Generate and return the session summary
  return generateSessionSummary()
end runPomodoroCycle

-- Generate a summary of the Pomodoro session
on generateSessionSummary()
  if trackActivities is false or (count of activityHistory) is 0 then
    return "Pomodoro session completed. No activity tracking enabled."
  end if
  
  -- Count completed Pomodoros
  set completedPomodoros to 0
  set workDetails to ""
  
  repeat with sessionItem in activityHistory
    if sessionItem's type is "work" then
      set completedPomodoros to completedPomodoros + 1
      set sessionNumber to sessionItem's number
      set sessionTask to sessionItem's task
      set workDetails to workDetails & "Session #" & sessionNumber & ": " & sessionTask & return
    end if
  end repeat
  
  -- Calculate total focused time
  set totalFocusMinutes to completedPomodoros * workDuration
  set hoursWorked to totalFocusMinutes div 60
  set minutesWorked to totalFocusMinutes mod 60
  
  -- Format the time string
  set timeWorked to ""
  if hoursWorked > 0 then
    set timeWorked to hoursWorked & " hour"
    if hoursWorked > 1 then set timeWorked to timeWorked & "s"
    if minutesWorked > 0 then set timeWorked to timeWorked & " and "
  end if
  if minutesWorked > 0 or hoursWorked is 0 then
    set timeWorked to timeWorked & minutesWorked & " minute"
    if minutesWorked is not 1 then set timeWorked to timeWorked & "s"
  end if
  
  -- Build summary string
  set summary to "Pomodoro Session Summary:" & return & return
  set summary to summary & "Completed Pomodoros: " & completedPomodoros & return
  set summary to summary & "Total focused time: " & timeWorked & return & return
  
  if workDetails is not "" then
    set summary to summary & "Tasks completed:" & return & workDetails
  end if
  
  -- Log the summary
  logMessage("Session Summary: " & completedPomodoros & " Pomodoros, " & timeWorked & " of focused work")
  
  return summary
end generateSessionSummary

-- Configure the Pomodoro timer settings
on configureSettings()
  -- Show the settings dialog
  set settingsPrompt to display dialog "Configure Pomodoro Timer Settings:" & return & return & "Work duration (minutes):" default answer workDuration buttons {"Cancel", "More Settings", "Save"} default button "Save"
  
  if button returned of settingsPrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  -- Update work duration
  try
    set newWorkDuration to (text returned of settingsPrompt) as number
    if newWorkDuration > 0 then
      set workDuration to newWorkDuration
    end if
  on error
    -- Invalid input, keep current setting
  end try
  
  -- If user wants more settings, show the break duration dialog
  if button returned of settingsPrompt is "More Settings" then
    set breakPrompt to display dialog "Break Durations:" & return & return & "Short break (minutes):" & return & "Long break (minutes):" default answer shortBreakDuration & return & longBreakDuration buttons {"Cancel", "More Settings", "Save"} default button "Save"
    
    if button returned of breakPrompt is "Cancel" then
      return "Configuration cancelled"
    end if
    
    -- Parse the break durations (short and long) separated by newline
    try
      set breakValues to paragraphs of (text returned of breakPrompt)
      
      if (count of breakValues) ≥ 1 then
        set newShortBreak to (item 1 of breakValues) as number
        if newShortBreak > 0 then
          set shortBreakDuration to newShortBreak
        end if
      end if
      
      if (count of breakValues) ≥ 2 then
        set newLongBreak to (item 2 of breakValues) as number
        if newLongBreak > 0 then
          set longBreakDuration to newLongBreak
        end if
      end if
    on error
      -- Invalid input, keep current settings
    end try
    
    -- If user wants even more settings, show the additional options
    if button returned of breakPrompt is "More Settings" then
      set optionsPrompt to display dialog "Additional Options:" & return & return & "Pomodoros before long break:" default answer pomodorosBeforeLongBreak buttons {"Cancel", "Save"} default button "Save"
      
      if button returned of optionsPrompt is "Cancel" then
        return "Configuration cancelled"
      end if
      
      -- Update number of Pomodoros before long break
      try
        set newPomodoroCount to (text returned of optionsPrompt) as number
        if newPomodoroCount > 0 then
          set pomodorosBeforeLongBreak to newPomodoroCount
        end if
      on error
        -- Invalid input, keep current setting
      end try
    end if
  end if
  
  -- Log the configuration changes
  logMessage("Configuration updated: Work=" & workDuration & "m, Short Break=" & shortBreakDuration & "m, Long Break=" & longBreakDuration & "m, Cycle=" & pomodorosBeforeLongBreak)
  
  return "Configuration saved: " & workDuration & "m work, " & shortBreakDuration & "m short break, " & longBreakDuration & "m long break, " & pomodorosBeforeLongBreak & " Pomodoros per cycle"
end configureSettings

-- Show the main Pomodoro menu
on showMainMenu()
  -- Create the menu options
  set menuOptions to {"Start Pomodoro", "Custom Pomodoro Cycle", "Configure Settings", "View Session Summary", "Exit"}
  
  -- Show the menu
  set selectedOption to choose from list menuOptions with prompt "Pomodoro Timer:" default items {"Start Pomodoro"}
  
  if selectedOption is false then
    return "Exiting Pomodoro Timer"
  end if
  
  set choice to item 1 of selectedOption
  
  if choice is "Start Pomodoro" then
    -- Run a single Pomodoro
    return runWorkSession(1)
    
  else if choice is "Custom Pomodoro Cycle" then
    -- Ask for the number of Pomodoros
    set cyclePrompt to display dialog "How many Pomodoros do you want to complete?" default answer "4" buttons {"Cancel", "Start Cycle"} default button "Start Cycle"
    
    if button returned of cyclePrompt is "Cancel" then
      return "Cycle cancelled"
    end if
    
    try
      set numberOfPomodoros to (text returned of cyclePrompt) as number
      if numberOfPomodoros < 1 then set numberOfPomodoros to 1
      if numberOfPomodoros > 10 then
        set confirmLarge to display dialog "You've set " & numberOfPomodoros & " Pomodoros. This will take approximately " & (numberOfPomodoros * workDuration / 60) & " hours. Continue?" buttons {"Cancel", "Continue"} default button "Continue"
        
        if button returned of confirmLarge is "Cancel" then
          return "Cycle cancelled"
        end if
      end if
      
      return runPomodoroCycle(numberOfPomodoros)
    on error
      return "Invalid number of Pomodoros"
    end try
    
  else if choice is "Configure Settings" then
    return configureSettings()
    
  else if choice is "View Session Summary" then
    -- Generate and show session summary
    set summary to generateSessionSummary()
    display dialog summary buttons {"OK"} default button "OK"
    return summary
    
  else
    return "Exiting Pomodoro Timer"
  end if
end showMainMenu

-- Run the Pomodoro timer application
on run
  return showMainMenu()
end run
```

This script implements a comprehensive Pomodoro technique timer to enhance productivity and focus. The Pomodoro technique is a time management method that uses timed intervals of focused work followed by short breaks, with longer breaks after completing multiple work sessions.

### Key Features:

1. **Customizable Timing Settings**:
   - Configurable work session duration (default: 25 minutes)
   - Adjustable short break duration (default: 5 minutes)
   - Configurable long break duration (default: 15 minutes)
   - Customizable cycle length (default: 4 Pomodoros before a long break)

2. **Do Not Disturb Integration**:
   - Automatically enables Do Not Disturb during work sessions
   - Supports multiple macOS versions with different Do Not Disturb implementations
   - Disables Do Not Disturb during breaks

3. **Notification System**:
   - Visual and audible notifications for session transitions
   - Configurable notification sounds
   - Informative start/end notifications

4. **Activity Tracking**:
   - Optional task tracking for each Pomodoro
   - Activity history recording
   - Session summary generation
   - Logging functionality for review

5. **User Interface**:
   - Interactive menu system
   - Configuration dialogs
   - Timer display during sessions
   - Session summary viewing

### How to Use:

1. **Start a Single Pomodoro**:
   - Select "Start Pomodoro" from the main menu
   - Optionally enter the task you'll be working on
   - Work until the timer completes (25 minutes by default)

2. **Run a Complete Cycle**:
   - Choose "Custom Pomodoro Cycle"
   - Enter the number of Pomodoros to complete
   - The script will alternate between work and break sessions
   - Long breaks are automatically inserted based on your settings

3. **Configure Settings**:
   - Adjust work duration
   - Set short and long break durations
   - Change the number of Pomodoros before a long break
   - Enable/disable activity tracking

4. **Review Your Progress**:
   - View a summary of your completed Pomodoros
   - See total focused work time
   - Review the tasks you've worked on

This Pomodoro timer can significantly improve productivity by encouraging focused work intervals with proper breaks, helping to maintain concentration and prevent burnout.
