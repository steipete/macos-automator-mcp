---
title: System Backup Engine
category: 05_files
id: system_backup_engine
description: Core backup and restore functionality for the System Backup solution
keywords:
  - backup
  - restore
  - rsync
  - encryption
  - disk image
  - copy
language: applescript
notes: Handles the main backup operations and restoration functionality
---

# System Backup Engine

This script provides the core backup and restore functionality for the System Backup system, handling the actual process of backing up files and restoring from backups.

## Backup Operation

```applescript
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
```

## Restore Operation

```applescript
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
```

## Backup History

```applescript
-- Show backup history
on showBackupHistory()
  try
    -- Get list of backups
    set backupPattern to backupDestination & "/" & backupName & "_*"
    set existingBackups to paragraphs of (do shell script "ls -d " & backupPattern & " 2>/dev/null | sort -r || echo ''")
    
    -- Remove empty items
    set cleanBackups to {}
    repeat with backup in existingBackups
      if backup is not "" then
        set end of cleanBackups to backup
      end if
    end repeat
    
    -- Check if we have any backups
    if (count of cleanBackups) is 0 then
      logMessage("No backups found")
      return "No backups found"
    end if
    
    -- Build the history text
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
```

These components provide the core backup and restore functionality, handling the creation of backups, restoration of data, and viewing backup history. They work with both standard folder backups and encrypted disk images for secure backups.