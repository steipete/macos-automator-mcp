---
title: Mail Create Email Digest
category: 09_productivity
id: mail_create_email_digest
description: >-
  Create a digest of recent messages from a specified time period, compiling
  message summaries into a single email for quick review.
language: applescript
keywords:
  - mail
  - digest
  - summary
  - report
  - email
  - recent
  - compile
---

# Mail Create Email Digest

This script creates a digest of recent email messages from a specified time period, compiling their summaries into a single email for easy review.

## Usage

The script can be run standalone or via MCP with parameters.

```applescript
-- Mail Create Email Digest
-- Compile recent messages into a digest

on run
	try
		-- Default: digest messages from the past day
		return createEmailDigest(1, "")
	on error errMsg
		return {success:false, error:errMsg}
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set digestDays to "--MCP_INPUT:digestDays"
	set digestFolder to "--MCP_INPUT:digestFolder"
	
	if digestDays is "" then
		set digestDays to 1
	else
		try
			set digestDays to digestDays as number
		on error
			set digestDays to 1
		end try
	end if
	
	return createEmailDigest(digestDays, digestFolder)
end processMCPParameters

-- Create a digest of recent messages
on createEmailDigest(days, folder)
	if days is missing value then
		set days to 1
	end if
	
	if folder is missing value then
		set folder to ""
	end if
	
	tell application "Mail"
		try
			set digestContent to "Email Digest - " & ((current date) as string) & "

Messages from the past " & days & " day(s):
-------------------------------------------------
"
			
			set cutoffDate to (current date) - (days * days)
			set messagesToInclude to {}
			
			-- Get messages from specified folder or all inboxes
			if folder is "" then
				set messagesToInclude to messages of inbox whose date received > cutoffDate
			else
				try
					set targetMailbox to mailbox folder
					set messagesToInclude to messages of targetMailbox whose date received > cutoffDate
				on error
					set messagesToInclude to messages of inbox whose date received > cutoffDate
				end try
			end if
			
			set messageCount to count of messagesToInclude
			
			-- Create the digest content
			repeat with i from 1 to messageCount
				set theMessage to item i of messagesToInclude
				set messageDate to date received of theMessage
				set messageSender to sender of theMessage
				set messageSubject to subject of theMessage
				
				set digestContent to digestContent & "
From: " & messageSender & "
Date: " & messageDate & "
Subject: " & messageSubject & "
--------------------
"
			end repeat
			
			set digestContent to digestContent & "
End of digest. Total messages: " & messageCount & "."
			
			-- Create a new email with the digest
			set newMessage to make new outgoing message with properties {subject:"Email Digest - " & ((current date) as string), content:digestContent, visible:true}
			
			return {success:true, message:"Created email digest with " & messageCount & " messages", result:messageCount}
		on error errMsg
			return {success:false, error:"Error creating email digest: " & errMsg}
		end try
	end tell
end createEmailDigest
```

## MCP Parameters

- `digestDays`: Number of days to include in the digest (default: 1)
- `digestFolder`: Specific folder to create digest from (default: inbox)

## Example Usage

### Create digest of last 24 hours
```json
{
  "digestDays": 1,
  "digestFolder": ""
}
```

### Create weekly digest from specific folder
```json
{
  "digestDays": 7,
  "digestFolder": "Work"
}
```

### Create monthly digest
```json
{
  "digestDays": 30,
  "digestFolder": ""
}
```

### Create digest from a specific mailbox
```json
{
  "digestDays": 3,
  "digestFolder": "Important"
}
```

## Digest Format

The digest includes:
- Email Digest header with current date
- Time period covered
- For each message:
  - From address
  - Received date
  - Subject line
  - Separator line
- Total message count

## Return Value

Returns an object with:
- `success`: Boolean indicating operation success
- `message`: Description of what was done
- `result`: Number of messages included in the digest
- `error`: Error message if operation failed

## Notes

- If no folder is specified, the script uses the inbox
- The digest is created as a new draft email that's displayed for review
- Messages are sorted by date received
- The cutoff date is calculated as days before the current date