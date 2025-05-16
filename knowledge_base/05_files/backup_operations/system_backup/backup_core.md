---
title: System Backup Core Components
category: 05_files
id: system_backup_core
description: Core initialization, configuration, and utility functions for the System Backup solution
keywords:
  - backup
  - initialization
  - configuration
  - logging
  - utility
  - properties
language: applescript
notes: Provides the foundation components used by other parts of the backup system
---

# System Backup Core Components

This script provides the core functionality, initialization, and utility functions for the System Backup system.

## Configuration Properties

```applescript
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
```

## Initialization

```applescript
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
```

## Logging System

```applescript
-- Log a message to the log file
on logMessage(message)
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    set logLine to timeStamp & " - " & message
    do shell script "echo " & quoted form of logLine & " >> " & quoted form of fullLogPath
  end if
end logMessage
```

## Date Formatting

```applescript
-- Format current date according to dateFormat
on formatDate()
  set theDate to current date
  set dateCommand to "date +'%" & dateFormat & "'"
  set formattedDate to do shell script dateCommand
  return formattedDate
end formatDate
```

## Path Management

```applescript
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
```

## Source Validation

```applescript
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
```

## Utility Functions

```applescript
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
```

These core components provide the foundation for the backup system, handling initialization, logging, and basic utility functions. They establish the infrastructure needed by the other specialized components of the system.