---
title: "System Backup Script"
category: "03_file_system_and_finder"
id: system_backup_script
description: "Creates customizable backups of important files and folders with scheduling, compression, encryption, and retention options"
keywords: ["backup", "rsync", "archive", "incremental", "compression", "encryption", "schedule", "restoration"]
language: applescript
notes: "Some operations require administrator privileges. Uses rsync for efficient incremental backups and optionally supports encrypted disk images."
---

```applescript
-- System Backup Script
-- Provides comprehensive backup of files/folders with multiple options

-- Configuration properties (customize as needed)
property backupSourceFolders : {} -- Will be set by user
property backupDestination : "" -- Will be set by user
property backupName : "MacBackup"
property dateFormat : "yyyyMMdd-HHmmss"
property compressionEnabled : true
property encryptionEnabled : false
property encryptionPassword : ""
property incrementalBackup : true
property maxBackupSets : 5 -- Number of backup sets to keep
property excludePatterns : {".DS_Store", "*.tmp", "*/Caches/*", "*/Trash/*"}
property logEnabled : true
property logFile : "~/Library/Logs/MacBackup.log"

-- Initialize the backup script
on initializeBackup()
  -- Convert log path to full path
  set fullLogPath to do shell script "echo " & quoted form of logFile
  
  -- Initialize the log file if logging is enabled
  if logEnabled then
    do shell script "touch " & quoted form of fullLogPath
    logMessage("Backup initialized at " & (current date as string))
  end if
  
  return "Backup system initialized"
end initializeBackup

-- Log a message to the log file
on logMessage(message)
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    set logLine to timeStamp & " - " & message
    do shell script "echo " & quoted form of logLine & " >> " & quoted form of fullLogPath
  end if
end logMessage

-- Format current date according to dateFormat
on formatDate()
  set theDate to current date
  set dateCommand to "date +'%" & dateFormat & "'"
  set formattedDate to do shell script dateCommand
  return formattedDate
end formatDate

-- Create the backup destination folder if it doesn't exist
on createBackupDestination()
  try
    if backupDestination is "" then
      logMessage("Error: Backup destination not specified")
      return "ERROR: Backup destination not specified"
    end if
    
    -- Expand tilde in destination path if needed
    if backupDestination starts with "~" then
      set expandedPath to do shell script "echo " & quoted form of backupDestination
      set backupDestination to expandedPath
    end if
    
    -- Create destination directory if it doesn't exist
    do shell script "mkdir -p " & quoted form of backupDestination
    
    return "Backup destination created: " & backupDestination
  on error errMsg
    logMessage("Error creating backup destination: " & errMsg)
    return "ERROR: " & errMsg
  end try
end createBackupDestination

-- Validate source folders exist
on validateSources()
  if backupSourceFolders is {} then
    logMessage("Error: No backup sources specified")
    return "ERROR: No backup sources specified"
  end if
  
  set validSources to {}
  set invalidSources to {}
  
  repeat with sourceFolder in backupSourceFolders
    -- Expand tilde in source path if needed
    if sourceFolder starts with "~" then
      set expandedPath to do shell script "echo " & quoted form of sourceFolder
      set sourceFolder to expandedPath
    end if
    
    -- Check if source exists
    set sourceExists to do shell script "test -e " & quoted form of sourceFolder & " && echo 'yes' || echo 'no'"
    
    if sourceExists is "yes" then
      set end of validSources to sourceFolder
    else
      set end of invalidSources to sourceFolder
    end if
  end repeat
  
  if (count of invalidSources) > 0 then
    set invalidList to join(invalidSources, ", ")
    logMessage("Warning: Some backup sources do not exist: " & invalidList)
    return "WARNING: Some backup sources do not exist: " & invalidList
  end if
  
  if (count of validSources) is 0 then
    logMessage("Error: No valid backup sources available")
    return "ERROR: No valid backup sources available"
  end if
  
  set backupSourceFolders to validSources
  logMessage("Validated " & (count of validSources) & " backup sources")
  return "Validated backup sources: " & (count of validSources)
end validateSources

-- Helper function to join a list with a delimiter
on join(theList, delimiter)
  set AppleScript's text item delimiters to delimiter
  set joinedText to theList as text
  set AppleScript's text item delimiters to ""
  return joinedText
end join

-- Create exclude patterns file for rsync
on createExcludeFile()
  set excludePath to "/tmp/backup_exclude_" & (do shell script "echo $RANDOM")
  set excludeContent to ""
  
  repeat with pattern in excludePatterns
    set excludeContent to excludeContent & pattern & return
  end repeat
  
  do shell script "echo " & quoted form of excludeContent & " > " & quoted form of excludePath
  return excludePath
end createExcludeFile

-- Clean up old backups based on retention policy
on cleanupOldBackups()
  try
    if maxBackupSets < 1 then
      logMessage("Backup retention disabled, skipping cleanup")
      return "Backup retention disabled"
    end if
    
    logMessage("Checking for old backups to clean up")
    
    -- List existing backups, sorted by date (oldest first)
    set backupPattern to backupDestination & "/" & backupName & "_*"
    set existingBackups to paragraphs of (do shell script "ls -d " & backupPattern & " 2>/dev/null | sort || echo ''")
    
    -- Remove empty items
    set cleanBackups to {}
    repeat with backup in existingBackups
      if backup is not "" then
        set end of cleanBackups to backup
      end if
    end repeat
    
    set backupCount to count of cleanBackups
    
    -- If we have more backups than our retention policy allows, remove the oldest ones
    if backupCount > maxBackupSets then
      set backupsToRemove to backupCount - maxBackupSets
      
      logMessage("Removing " & backupsToRemove & " old backup(s)")
      
      repeat with i from 1 to backupsToRemove
        set oldBackup to item i of cleanBackups
        
        if oldBackup contains backupName then -- Safety check
          do shell script "rm -rf " & quoted form of oldBackup
          logMessage("Removed old backup: " & oldBackup)
        else
          logMessage("Skipped removal of unrecognized backup: " & oldBackup)
        end if
      end repeat
      
      return "Cleaned up " & backupsToRemove & " old backup(s)"
    else
      logMessage("No cleanup needed, have " & backupCount & " of " & maxBackupSets & " maximum backups")
      return "No old backups to clean up"
    end if
  on error errMsg
    logMessage("Error during backup cleanup: " & errMsg)
    return "ERROR during cleanup: " & errMsg
  end try
end cleanupOldBackups

-- Perform the backup operation
on performBackup()
  try
    -- Initialize
    initializeBackup()
    
    -- Validate configuration
    set validationResult to validateSources()
    if validationResult starts with "ERROR:" then
      return validationResult
    end if
    
    -- Create destination
    set destinationResult to createBackupDestination()
    if destinationResult starts with "ERROR:" then
      return destinationResult
    end if
    
    -- Generate backup folder name with date
    set backupDate to formatDate()
    set backupFolder to backupDestination & "/" & backupName & "_" & backupDate
    
    logMessage("Starting backup to: " & backupFolder)
    
    -- Create the exclude patterns file
    set excludeFile to createExcludeFile()
    
    -- Prepare the backup commands
    if encryptionEnabled then
      -- Create an encrypted disk image for backup
      set dmgSize to "8g" -- Default size, adjust as needed
      set dmgPath to backupFolder & ".dmg"
      
      logMessage("Creating encrypted disk image: " & dmgPath)
      
      -- Create the encrypted disk image
      set createDmgCmd to "hdiutil create -size " & dmgSize & " -encryption -stdinpass -volname " & quoted form of backupName & " -fs APFS " & quoted form of dmgPath
      
      do shell script createDmgCmd & " <<< " & quoted form of encryptionPassword
      
      -- Mount the disk image
      set mountDmgCmd to "echo " & quoted form of encryptionPassword & " | hdiutil attach -stdinpass " & quoted form of dmgPath
      set mountOutput to do shell script mountDmgCmd
      
      -- Extract the mount point
      set mountPoint to do shell script "echo " & quoted form of mountOutput & " | grep /Volumes | awk '{print $NF}'"
      
      -- Update the backup folder to the mounted image
      set backupFolder to mountPoint
    else
      -- Create the regular backup folder
      do shell script "mkdir -p " & quoted form of backupFolder
    end if
    
    -- Perform the backup for each source folder
    repeat with sourceFolder in backupSourceFolders
      set sourceName to do shell script "basename " & quoted form of sourceFolder
      set targetFolder to backupFolder & "/" & sourceName
      
      logMessage("Backing up: " & sourceFolder & " to " & targetFolder)
      
      -- Create the rsync command
      set rsyncOptions to "-a" -- Archive mode
      
      if incrementalBackup then
        set rsyncOptions to rsyncOptions & "u" -- Update only
      end if
      
      if compressionEnabled then
        set rsyncOptions to rsyncOptions & "z" -- Compression
      end if
      
      -- Add verbose and human-readable options
      set rsyncOptions to rsyncOptions & "vh"
      
      set rsyncCmd to "rsync " & rsyncOptions & " --exclude-from=" & quoted form of excludeFile & " " & quoted form of sourceFolder & " " & quoted form of backupFolder
      
      -- Execute the rsync command
      set rsyncOutput to do shell script rsyncCmd
      
      logMessage("Backup completed for: " & sourceFolder)
    end repeat
    
    -- Clean up temporary exclude file
    do shell script "rm " & quoted form of excludeFile
    
    -- Unmount encrypted disk image if used
    if encryptionEnabled then
      do shell script "hdiutil detach " & quoted form of backupFolder
      logMessage("Unmounted encrypted backup disk image")
    end if
    
    -- Clean up old backups based on retention policy
    cleanupOldBackups()
    
    logMessage("Backup completed successfully")
    return "Backup completed successfully to " & backupFolder
  on error errMsg
    logMessage("Error during backup: " & errMsg)
    return "ERROR during backup: " & errMsg
  end try
end performBackup

-- Restore from backup
on restoreFromBackup(restoreSource, restoreTarget)
  try
    logMessage("Starting restore from: " & restoreSource & " to " & restoreTarget)
    
    -- Validate source
    set sourceExists to do shell script "test -e " & quoted form of restoreSource & " && echo 'yes' || echo 'no'"
    if sourceExists is "no" then
      logMessage("Error: Restore source does not exist: " & restoreSource)
      return "ERROR: Restore source does not exist"
    end if
    
    -- Check if source is encrypted disk image
    if restoreSource ends with ".dmg" then
      -- Mount the disk image
      set passwordPrompt to display dialog "Enter password for encrypted backup:" default answer "" with hidden answer buttons {"Cancel", "Mount"} default button "Mount"
      set dmgPassword to text returned of passwordPrompt
      
      set mountCmd to "echo " & quoted form of dmgPassword & " | hdiutil attach -stdinpass " & quoted form of restoreSource
      set mountOutput to do shell script mountCmd
      
      -- Extract the mount point
      set mountPoint to do shell script "echo " & quoted form of mountOutput & " | grep /Volumes | awk '{print $NF}'"
      
      -- Update the restore source to the mounted image
      set restoreSource to mountPoint
      set didMountImage to true
    else
      set didMountImage to false
    end if
    
    -- Create the target directory if it doesn't exist
    do shell script "mkdir -p " & quoted form of restoreTarget
    
    -- Create the rsync command for restore
    set rsyncOptions to "-avh" -- Archive mode, verbose, human-readable
    
    set rsyncCmd to "rsync " & rsyncOptions & " " & quoted form of restoreSource & "/ " & quoted form of restoreTarget
    
    -- Execute the rsync command
    set rsyncOutput to do shell script rsyncCmd
    
    -- Unmount encrypted disk image if used
    if didMountImage then
      do shell script "hdiutil detach " & quoted form of restoreSource
      logMessage("Unmounted encrypted backup disk image after restore")
    end if
    
    logMessage("Restore completed successfully")
    return "Restore completed successfully to " & restoreTarget
  on error errMsg
    logMessage("Error during restore: " & errMsg)
    return "ERROR during restore: " & errMsg
  end try
end restoreFromBackup

-- Show backup history
on showBackupHistory()
  try
    -- Find all backups
    set backupPattern to backupDestination & "/" & backupName & "_*"
    set existingBackups to paragraphs of (do shell script "ls -d " & backupPattern & " 2>/dev/null | sort -r || echo ''")
    
    -- Remove empty items
    set cleanBackups to {}
    repeat with backup in existingBackups
      if backup is not "" then
        set end of cleanBackups to backup
      end if
    end repeat
    
    if (count of cleanBackups) is 0 then
      return "No backups found"
    end if
    
    -- Format the backup history
    set historyText to "Backup History:" & return & return
    
    repeat with i from 1 to count of cleanBackups
      set backupPath to item i of cleanBackups
      
      -- Extract the date part from the backup name
      set backupName to do shell script "basename " & quoted form of backupPath
      
      -- Get backup size
      set backupSize to do shell script "du -sh " & quoted form of backupPath & " | awk '{print $1}'"
      
      set historyText to historyText & i & ". " & backupName & " (" & backupSize & ")" & return
    end repeat
    
    return historyText
  on error errMsg
    logMessage("Error getting backup history: " & errMsg)
    return "ERROR getting backup history: " & errMsg
  end try
end showBackupHistory

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

-- Show the main backup menu
on showBackupMenu()
  -- First, ask for the backup configuration if not set
  if backupSourceFolders is {} then
    set dialogResult to display dialog "Would you like to configure a new backup?" buttons {"Cancel", "Configure"} default button "Configure"
    if button returned of dialogResult is "Configure" then
      configureBackup()
    else
      return "Backup configuration cancelled"
    end if
  end if
  
  -- Show the main menu
  set menuOptions to {"Run Backup Now", "Restore from Backup", "Show Backup History", "Schedule Backup", "Configure Backup", "Cancel"}
  
  set selectedOption to choose from list menuOptions with prompt "Backup System:" default items {"Run Backup Now"}
  
  if selectedOption is false then
    return "Operation cancelled"
  else
    set operation to item 1 of selectedOption
    
    if operation is "Run Backup Now" then
      return performBackup()
      
    else if operation is "Restore from Backup" then
      -- Show available backups for restore
      set backupList to showBackupHistory()
      if backupList starts with "No backups" or backupList starts with "ERROR" then
        display dialog backupList buttons {"OK"} default button "OK"
        return backupList
      end if
      
      -- Get available backups
      set backupPattern to backupDestination & "/" & backupName & "_*"
      set existingBackups to paragraphs of (do shell script "ls -d " & backupPattern & " 2>/dev/null | sort -r || echo ''")
      
      -- Remove empty items
      set cleanBackups to {}
      repeat with backup in existingBackups
        if backup is not "" then
          set end of cleanBackups to backup
        end if
      end repeat
      
      -- Let user select a backup
      set backupLabels to {}
      repeat with i from 1 to count of cleanBackups
        set backupPath to item i of cleanBackups
        set backupName to do shell script "basename " & quoted form of backupPath
        set end of backupLabels to backupName
      end repeat
      
      set selectedBackup to choose from list backupLabels with prompt "Select a backup to restore from:" default items item 1 of backupLabels
      
      if selectedBackup is false then
        return "Restore cancelled"
      end if
      
      -- Find the selected backup path
      set backupIndex to 1
      repeat with i from 1 to count of backupLabels
        if item i of backupLabels is item 1 of selectedBackup then
          set backupIndex to i
          exit repeat
        end if
      end repeat
      
      set selectedBackupPath to item backupIndex of cleanBackups
      
      -- Ask for restore target
      set targetPrompt to display dialog "Enter the destination path for restore:" default answer "~/RestoreBackup" buttons {"Cancel", "Restore"} default button "Restore"
      
      if button returned of targetPrompt is "Cancel" then
        return "Restore cancelled"
      end if
      
      set restoreTarget to text returned of targetPrompt
      
      -- Expand the path
      set expandedTarget to do shell script "echo " & quoted form of restoreTarget
      
      -- Perform the restore
      return restoreFromBackup(selectedBackupPath, expandedTarget)
      
    else if operation is "Show Backup History" then
      set historyText to showBackupHistory()
      display dialog historyText buttons {"OK"} default button "OK"
      return historyText
      
    else if operation is "Schedule Backup" then
      set scheduleOptions to {"Daily", "Weekly", "Monthly", "Remove Schedule"}
      set selectedSchedule to choose from list scheduleOptions with prompt "Select backup schedule:" default items {"Daily"}
      
      if selectedSchedule is false then
        return "Scheduling cancelled"
      end if
      
      set frequency to item 1 of selectedSchedule
      
      if frequency is "Remove Schedule" then
        return unscheduleBackup()
      else
        return scheduleBackup(frequency as string)
      end if
      
    else if operation is "Configure Backup" then
      return configureBackup()
      
    else
      return "Operation cancelled"
    end if
  end if
end showBackupMenu

-- Configure backup settings interactively
on configureBackup()
  -- Ask for backup sources
  set sourcePrompt to display dialog "Enter paths to backup (separate with commas):" default answer "~/Documents, ~/Pictures" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of sourcePrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  -- Parse the source paths
  set sourcePaths to text returned of sourcePrompt
  set AppleScript's text item delimiters to ","
  set sourceList to text items of sourcePaths
  set AppleScript's text item delimiters to ""
  
  -- Trim whitespace and add to sources
  set newSources to {}
  repeat with sourcePath in sourceList
    -- Trim whitespace
    set trimmedPath to do shell script "echo " & quoted form of sourcePath & " | xargs"
    if trimmedPath is not "" then
      set end of newSources to trimmedPath
    end if
  end repeat
  
  set backupSourceFolders to newSources
  
  -- Ask for backup destination
  set destPrompt to display dialog "Enter backup destination path:" default answer "~/Backups" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of destPrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  set backupDestination to text returned of destPrompt
  
  -- Ask for backup name
  set namePrompt to display dialog "Enter backup name:" default answer backupName buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of namePrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  set backupName to text returned of namePrompt
  
  -- Ask for backup options
  set optionsPrompt to display dialog "Select backup options:" & return & return & "• Incremental backup: Faster but only updates changed files" & return & "• Compression: Reduces backup size" & return & "• Encryption: Secure but slower" default answer "" buttons {"Cancel", "Configure Options"} default button "Configure Options"
  
  if button returned of optionsPrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  -- Show options dialog
  set optionsList to {"Incremental Backup", "Compression", "Encryption"}
  set defaultOptions to {}
  if incrementalBackup then set end of defaultOptions to "Incremental Backup"
  if compressionEnabled then set end of defaultOptions to "Compression"
  if encryptionEnabled then set end of defaultOptions to "Encryption"
  
  set selectedOptions to choose from list optionsList with prompt "Select backup options:" with multiple selections allowed default items defaultOptions
  
  if selectedOptions is false then
    return "Option selection cancelled"
  end if
  
  -- Update options based on selection
  set incrementalBackup to "Incremental Backup" is in selectedOptions
  set compressionEnabled to "Compression" is in selectedOptions
  set encryptionEnabled to "Encryption" is in selectedOptions
  
  -- If encryption is enabled, ask for password
  if encryptionEnabled then
    set passwordPrompt to display dialog "Enter encryption password:" default answer "" with hidden answer buttons {"Cancel", "Save"} default button "Save"
    
    if button returned of passwordPrompt is "Cancel" then
      return "Password entry cancelled"
    end if
    
    set encryptionPassword to text returned of passwordPrompt
  end if
  
  -- Ask for retention policy
  set retentionPrompt to display dialog "How many backups to keep? (0 = keep all)" default answer maxBackupSets as string buttons {"Cancel", "Save Configuration"} default button "Save Configuration"
  
  if button returned of retentionPrompt is "Cancel" then
    return "Configuration cancelled"
  end if
  
  set maxBackupSets to (text returned of retentionPrompt) as number
  
  -- Save the configuration
  logMessage("Backup configuration updated")
  return "Backup configuration saved:" & return & return & "Sources: " & (count of backupSourceFolders) & " folders" & return & "Destination: " & backupDestination & return & "Options: " & (join(selectedOptions, ", ")) & return & "Retention: " & maxBackupSets & " backups"
end configureBackup

-- Run the backup menu
showBackupMenu()
```

This script provides a comprehensive file backup system with these key features:

1. **Customizable Backup Options**:
   - Multiple source folders
   - Configurable backup destination
   - Incremental backup for speed
   - Compression for space efficiency
   - Optional encryption for security
   - Retention policy for managing backup history

2. **Efficient Backup Engine**:
   - Uses `rsync` for fast, efficient file copying
   - Only transfers changed files when using incremental mode
   - Includes pattern-based exclusions for temporary files
   - Detailed logging of all operations

3. **Restore Functionality**:
   - Restores from any saved backup set
   - Handles encrypted backups with password protection
   - Preserves file attributes and permissions

4. **Schedule Management**:
   - Sets up scheduled backups using macOS launchd
   - Supports daily, weekly, or monthly schedules
   - Easy removal of scheduled tasks

5. **User Interface**:
   - Interactive menu for all backup operations
   - Guided configuration wizard
   - Backup history viewer
   - Progress and status reporting

This backup system is suitable for:
- Regular backups of important user data
- Creating secure, encrypted archives
- Setting up automated backup schedules
- Managing multiple backup sets with retention policies

The script maintains a log file of all operations, which is helpful for troubleshooting and verification. It's designed to be run directly from Script Editor or as a saved application.