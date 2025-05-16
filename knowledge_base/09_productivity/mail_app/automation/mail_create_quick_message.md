---
title: Mail Create Quick Message
category: 09_productivity
id: mail_create_quick_message
description: >-
  Create and compose a quick email message with recipient, subject, and content,
  perfect for rapid email composition without navigating the Mail app interface.
language: applescript
keywords:
  - mail
  - quick
  - compose
  - message
  - email
  - send
  - create
---

# Mail Create Quick Message

This script creates a quick email message with specified recipient, subject, and content. It's designed for rapid email composition without the need to navigate through the Mail app interface.

## Usage

The script can be run standalone with prompts or via MCP with parameters.

```applescript
-- Mail Create Quick Message
-- Rapid email composition

on run
	try
		-- Interactive mode - prompts for input
		return createQuickMessage(missing value, missing value, missing value)
	on error errMsg
		return {success:false, error:errMsg}
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set quickRecipient to "--MCP_INPUT:quickRecipient"
	set quickSubject to "--MCP_INPUT:quickSubject"
	set quickContent to "--MCP_INPUT:quickContent"
	
	if quickRecipient is "" then
		return {success:false, error:"Recipient is required for quick message"}
	end if
	
	if quickSubject is "" then
		set quickSubject to "Quick Message"
	end if
	
	return createQuickMessage(quickRecipient, quickSubject, quickContent)
end processMCPParameters

-- Create a quick message
on createQuickMessage(recipient, subject, content)
	-- Interactive mode if parameters not provided
	if recipient is missing value then
		tell application "Mail"
			set recipientInput to text returned of (display dialog "Enter recipient:" default answer "")
			set recipient to recipientInput
			
			set subjectInput to text returned of (display dialog "Enter subject:" default answer "Quick Message")
			set subject to subjectInput
			
			set contentInput to text returned of (display dialog "Enter message content:" default answer "" with icon note)
			set content to contentInput
		end tell
	end if
	
	if subject is missing value or subject is "" then
		set subject to "Quick Message"
	end if
	
	if content is missing value then
		set content to ""
	end if
	
	tell application "Mail"
		set newMessage to make new outgoing message with properties {subject:subject, content:content, visible:true}
		tell newMessage
			make new to recipient at end of to recipients with properties {address:recipient}
		end tell
		
		return {success:true, message:"Created quick message to " & recipient}
	end tell
end createQuickMessage
```

## MCP Parameters

- `quickRecipient`: Email address of the recipient (required)
- `quickSubject`: Subject line of the email (default: "Quick Message")
- `quickContent`: Body content of the email (optional)

## Example Usage

### Simple message
```json
{
  "quickRecipient": "colleague@company.com",
  "quickSubject": "Meeting Tomorrow",
  "quickContent": "Can we reschedule our meeting to 3 PM?"
}
```

### Quick note
```json
{
  "quickRecipient": "notes@example.com",
  "quickSubject": "Reminder",
  "quickContent": "Don't forget to submit the report by Friday"
}
```

### Basic message with default subject
```json
{
  "quickRecipient": "friend@email.com",
  "quickSubject": "",
  "quickContent": "Hey, are you free for lunch today?"
}
```

### Minimal parameters
```json
{
  "quickRecipient": "contact@domain.com"
}
```

## Interactive Mode

When run without parameters, the script presents three dialog boxes:
1. Recipient email address (required)
2. Subject line (defaults to "Quick Message")
3. Message content (optional)

## Return Value

Returns an object with:
- `success`: Boolean indicating operation success
- `message`: Confirmation message with recipient address
- `error`: Error message if operation failed

## Notes

- The message is created as a draft and displayed in Mail for review
- The recipient field is required; the script will error without it
- Empty subject defaults to "Quick Message"
- Content can be empty for a blank message
- The message is not automatically sent - user must click Send in Mail
- Multiple recipients can be added manually in Mail after creation