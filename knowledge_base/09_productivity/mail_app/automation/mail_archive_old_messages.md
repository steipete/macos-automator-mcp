---
title: Mail Archive Old Messages
category: 09_productivity
id: mail_archive_old_messages
description: >-
  Archive messages older than a specified number of days to designated folders,
  helping to keep mailboxes clean and organized while preserving old emails.
language: applescript
keywords:
  - mail
  - archive
  - cleanup
  - old
  - messages
  - organize
  - folder
---

# Mail Archive Old Messages

This script archives messages older than a specified number of days to designated archive folders, helping maintain clean and organized mailboxes.

## Usage

The script can be run standalone or via MCP with parameters.

```applescript
-- Mail Archive Old Messages
-- Clean up old emails by archiving them

on run
	try
		-- Default: archive messages older than 30 days
		return archiveOldMessages(30, missing value)
	on error errMsg
		return {success:false, error:errMsg}
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set archiveDays to "--MCP_INPUT:archiveDays"
	set archiveDestination to "--MCP_INPUT:archiveDestination"
	
	if archiveDays is "" then
		set archiveDays to 30
	else
		try
			set archiveDays to archiveDays as number
		on error
			set archiveDays to 30
		end try
	end if
	
	if archiveDestination is "" then
		set archiveDestination to missing value
	end if
	
	return archiveOldMessages(archiveDays, archiveDestination)
end processMCPParameters

-- Archive old messages
on archiveOldMessages(days, destination)
	if days is missing value then
		set days to 30
	end if
	
	if destination is missing value then
		set destination to "Archive/" & (year of (current date)) as string
	end if
	
	tell application "Mail"
		try
			-- Create archive folder if needed
			try
				set targetMailbox to mailbox destination
			on error
				make new mailbox with properties {name:destination}
				set targetMailbox to mailbox destination
			end try
			
			set cutoffDate to (current date) - (days * days)
			set archivedCount to 0
			
			-- Process each mailbox except the Archive
			set mailboxesToProcess to {}
			set allMailboxes to every mailbox
			repeat with mb in allMailboxes
				if name of mb does not start with "Archive" and name of mb is not destination then
					set end of mailboxesToProcess to mb
				end if
			end repeat
			
			-- Archive old messages
			repeat with mb in mailboxesToProcess
				set oldMessages to (messages of mb whose date received < cutoffDate)
				repeat with theMessage in oldMessages
					try
						move theMessage to targetMailbox
						set archivedCount to archivedCount + 1
					on error
						-- Skip messages that can't be moved
					end try
				end repeat
			end repeat
			
			return {success:true, message:"Archived " & archivedCount & " messages older than " & days & " days to " & destination}
		on error errMsg
			return {success:false, error:"Error archiving messages: " & errMsg}
		end try
	end tell
end archiveOldMessages
```

## MCP Parameters

- `archiveDays`: Number of days old messages should be before archiving (default: 30)
- `archiveDestination`: Folder to archive messages to (default: "Archive/[current year]")

## Example Usage

### Archive messages older than 30 days
```json
{
  "archiveDays": 30,
  "archiveDestination": ""
}
```

### Archive messages older than 90 days to specific folder
```json
{
  "archiveDays": 90,
  "archiveDestination": "Archive/Q1-2024"
}
```

### Archive year-old messages
```json
{
  "archiveDays": 365,
  "archiveDestination": "Archive/Old Messages"
}
```

### Archive to yearly folder
```json
{
  "archiveDays": 60,
  "archiveDestination": "Archive/2024"
}
```

## Archive Strategy

- Messages are moved from all mailboxes except those already in Archive folders
- Default destination creates year-based archive folders automatically
- The script preserves folder structure by moving messages to the same archive location
- Archive folders are created automatically if they don't exist

## Return Value

Returns an object with:
- `success`: Boolean indicating operation success
- `message`: Description of what was done, including count of archived messages
- `error`: Error message if operation failed

## Notes

- The script skips messages already in Archive folders to prevent duplicate archiving
- Messages are permanently moved, not copied
- The cutoff date is calculated as the specified number of days before today
- If a message can't be moved (due to permissions or other issues), it's skipped
- The default archive path includes the current year for automatic organization