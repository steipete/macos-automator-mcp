---
title: Mail Organize Messages
category: 09_productivity
id: mail_organize_messages
description: >-
  Organize messages based on criteria like unread status, flags, sender, or
  subject into designated mailboxes for better email management.
language: applescript
keywords:
  - mail
  - organize
  - filter
  - sort
  - mailbox
  - unread
  - flagged
  - move
---

# Mail Organize Messages

This script organizes messages based on specific criteria into designated mailboxes, helping to keep your inbox organized and manageable.

## Usage

The script can be run standalone with dialogs or via MCP with parameters.

```applescript
-- Mail Organize Messages
-- Sort messages into folders based on criteria

on run
	try
		-- Interactive mode - uses default criteria
		return organizeMessages("unread", "Follow Up")
	on error errMsg
		return {success:false, error:errMsg}
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set organizeCriteria to "--MCP_INPUT:organizeCriteria"
	set organizeDestination to "--MCP_INPUT:organizeDestination"
	
	if organizeCriteria is "" then
		set organizeCriteria to "unread"
	end if
	
	if organizeDestination is "" then
		set organizeDestination to "Follow Up"
	end if
	
	return organizeMessages(organizeCriteria, organizeDestination)
end processMCPParameters

-- Organize messages based on criteria
on organizeMessages(criteria, destination)
	if criteria is missing value then
		set criteria to "unread"
	end if
	
	if destination is missing value then
		set destination to "Follow Up"
	end if
	
	tell application "Mail"
		try
			-- Create the destination mailbox if it doesn't exist
			try
				set targetMailbox to mailbox destination
			on error
				make new mailbox with properties {name:destination}
				set targetMailbox to mailbox destination
			end try
			
			-- Get messages to organize based on criteria
			set messagesToOrganize to {}
			
			if criteria is "unread" then
				set allMailboxes to every mailbox
				repeat with mb in allMailboxes
					set unreadMessages to (messages of mb whose read status is false)
					set messagesToOrganize to messagesToOrganize & unreadMessages
				end repeat
			else if criteria is "flagged" then
				set allMailboxes to every mailbox
				repeat with mb in allMailboxes
					set flaggedMessages to (messages of mb whose flagged status is true)
					set messagesToOrganize to messagesToOrganize & flaggedMessages
				end repeat
			else if criteria contains "from:" then
				set searchTerm to text 6 thru -1 of criteria
				set allMailboxes to every mailbox
				repeat with mb in allMailboxes
					set fromMessages to (messages of mb whose sender contains searchTerm)
					set messagesToOrganize to messagesToOrganize & fromMessages
				end repeat
			else if criteria contains "subject:" then
				set searchTerm to text 9 thru -1 of criteria
				set allMailboxes to every mailbox
				repeat with mb in allMailboxes
					set subjectMessages to (messages of mb whose subject contains searchTerm)
					set messagesToOrganize to messagesToOrganize & subjectMessages
				end repeat
			end if
			
			-- Move messages to destination
			set movedCount to 0
			repeat with theMessage in messagesToOrganize
				try
					move theMessage to targetMailbox
					set movedCount to movedCount + 1
				on error
					-- Skip messages that can't be moved
				end try
			end repeat
			
			return {success:true, message:"Organized " & movedCount & " messages matching criteria '" & criteria & "' to " & destination}
		on error errMsg
			return {success:false, error:"Error organizing messages: " & errMsg}
		end try
	end tell
end organizeMessages
```

## Criteria Options

- `"unread"`: Messages that haven't been read
- `"flagged"`: Messages marked with a flag
- `"from:email@domain.com"`: Messages from specific senders
- `"subject:keyword"`: Messages with specific subject keywords

## MCP Parameters

- `organizeCriteria`: The criteria to match messages (default: "unread")
- `organizeDestination`: The mailbox to move messages to (default: "Follow Up")

## Example Usage

### Organize unread messages
```json
{
  "organizeCriteria": "unread",
  "organizeDestination": "To Review"
}
```

### Organize messages from specific sender
```json
{
  "organizeCriteria": "from:important@client.com",
  "organizeDestination": "Important Clients"
}
```

### Organize by subject keyword
```json
{
  "organizeCriteria": "subject:invoice",
  "organizeDestination": "Accounting"
}
```

### Organize flagged messages
```json
{
  "organizeCriteria": "flagged",
  "organizeDestination": "Priority"
}
```

## Return Value

Returns an object with:
- `success`: Boolean indicating operation success
- `message`: Description of what was done
- `error`: Error message if operation failed

## Notes

- The destination mailbox is created automatically if it doesn't exist
- Messages are moved from their current location to the destination
- Searches for criteria like "from:" and "subject:" are case-insensitive
- The script searches across all mailboxes for matching messages