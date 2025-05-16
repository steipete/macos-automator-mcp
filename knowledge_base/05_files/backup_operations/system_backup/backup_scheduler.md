---
title: System Backup Scheduler
category: 05_files
id: system_backup_scheduler
description: Scheduling functionality for automated backups using launchd
keywords:
  - backup
  - scheduler
  - launchd
  - automation
  - recurring
  - daily
  - weekly
  - monthly
language: applescript
notes: Provides the ability to schedule backups on a daily, weekly, or monthly basis using macOS launchd
---

# System Backup Scheduler

This script provides the scheduling functionality for the System Backup system, allowing users to set up automated recurring backups.

## Schedule Creation

```applescript
-- Schedule a backup (using launchd)
on scheduleBackup(frequency)
  try
    set scriptPath to path to me as string
    set plistLabel to "com.user.backup." & backupName
    set plistPath to "~/Library/LaunchAgents/" & plistLabel & ".plist"
    
    -- Expand the path
    set expandedPlistPath to do shell script "echo " & quoted form of plistPath
    
    -- Determine the schedule
    set startCalendarInterval to ""
    
    if frequency is "daily" then
      set startCalendarInterval to "<key>StartCalendarInterval</key>
      <dict>
        <key>Hour</key>
        <integer>1</integer>
        <key>Minute</key>
        <integer>0</integer>
      </dict>"
    else if frequency is "weekly" then
      set startCalendarInterval to "<key>StartCalendarInterval</key>
      <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>1</integer>
        <key>Minute</key>
        <integer>0</integer>
      </dict>"
    else if frequency is "monthly" then
      set startCalendarInterval to "<key>StartCalendarInterval</key>
      <dict>
        <key>Day</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>1</integer>
        <key>Minute</key>
        <integer>0</integer>
      </dict>"
    end if
    
    -- Create the plist content
    set plistContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>" & plistLabel & "</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/osascript</string>
        <string>" & (POSIX path of scriptPath) & "</string>
        <string>run_backup</string>
    </array>
    " & startCalendarInterval & "
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>"
    
    -- Write the plist file
    do shell script "echo " & quoted form of plistContent & " > " & quoted form of expandedPlistPath
    
    -- Load the launchd job
    do shell script "launchctl load " & quoted form of expandedPlistPath
    
    logMessage("Scheduled " & frequency & " backup")
    return "Backup scheduled: " & frequency
  on error errMsg
    logMessage("Error scheduling backup: " & errMsg)
    return "ERROR scheduling backup: " & errMsg
  end try
end scheduleBackup
```

## Schedule Removal

```applescript
-- Remove scheduled backup
on unscheduleBackup()
  try
    set plistLabel to "com.user.backup." & backupName
    set plistPath to "~/Library/LaunchAgents/" & plistLabel & ".plist"
    
    -- Expand the path
    set expandedPlistPath to do shell script "echo " & quoted form of plistPath
    
    -- Check if the plist exists
    set plistExists to do shell script "test -f " & quoted form of expandedPlistPath & " && echo 'yes' || echo 'no'"
    
    if plistExists is "yes" then
      -- Unload the launchd job
      do shell script "launchctl unload " & quoted form of expandedPlistPath
      
      -- Remove the plist file
      do shell script "rm " & quoted form of expandedPlistPath
      
      logMessage("Removed backup schedule")
      return "Backup schedule removed"
    else
      return "No backup schedule found"
    end if
  on error errMsg
    logMessage("Error removing backup schedule: " & errMsg)
    return "ERROR removing backup schedule: " & errMsg
  end try
end unscheduleBackup
```

## Command Line Handler

```applescript
-- Handle arguments from launchd
on run argv
  if (count of argv) > 0 then
    if item 1 of argv is "run_backup" then
      return performBackup()
    end if
  end if
  
  -- Interactive menu if no arguments
  showBackupMenu()
end run
```

These scheduling components work with macOS launchd to provide automated backup capabilities. The system can create scheduled backups on daily, weekly, or monthly intervals, and allows users to easily remove these schedules when no longer needed. The command line handler enables the script to be launched automatically by the system at the scheduled times.