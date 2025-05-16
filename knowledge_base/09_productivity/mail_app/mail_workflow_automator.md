---
title: Email Workflow Automator
category: 09_productivity/mail_app
id: mail_workflow_automator
description: >-
  Advanced script to automate common email workflows including template
  responses, message categorization, rule-based processing, and batch
  operations.
language: applescript
keywords:
  - email
  - mail
  - rules
  - workflow
  - automate
  - templates
  - respond
  - filter
  - batch
  - archive
---

# Email Workflow Automator

This script provides comprehensive email workflow automation capabilities for the macOS Mail app. It enables automated processing of messages using rules, template responses, message categorization, and batch operations to streamline email management.

## Usage

The script can be used to automate various email workflows either interactively or programmatically.

```applescript
-- Email Workflow Automator
-- Advanced email automation for Apple Mail

on run
	-- Interactive mode when run directly
	try
		set workflowOptions to {"Process inbox with rules", "Apply template responses", "Organize messages", "Create email digest", "Archive old messages", "Create quick message"}
		
		set selectedOption to choose from list workflowOptions with prompt "Select email workflow to run:" default items {"Process inbox with rules"}
		
		if selectedOption is false then
			return "Operation cancelled."
		end if
		
		set selectedAction to item 1 of selectedOption
		
		if selectedAction is "Process inbox with rules" then
			return processInboxWithRules()
		else if selectedAction is "Apply template responses" then
			return applyTemplateResponses()
		else if selectedAction is "Organize messages" then
			return organizeMessages()
		else if selectedAction is "Create email digest" then
			return createEmailDigest()
		else if selectedAction is "Archive old messages" then
			return archiveOldMessages()
		else if selectedAction is "Create quick message" then
			return createQuickMessage()
		end if
		
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handler for processing input parameters when running with MCP
on processMCPParameters(inputParams)
	-- Extract parameters
	set action to "--MCP_INPUT:action"
	set rules to "--MCP_INPUT:rules"
	set templateName to "--MCP_INPUT:templateName"
	set templateRecipient to "--MCP_INPUT:templateRecipient"
	set organizeCriteria to "--MCP_INPUT:organizeCriteria"
	set organizeDestination to "--MCP_INPUT:organizeDestination"
	set digestDays to "--MCP_INPUT:digestDays"
	set digestFolder to "--MCP_INPUT:digestFolder"
	set archiveDays to "--MCP_INPUT:archiveDays"
	set archiveDestination to "--MCP_INPUT:archiveDestination"
	set quickRecipient to "--MCP_INPUT:quickRecipient"
	set quickSubject to "--MCP_INPUT:quickSubject"
	set quickContent to "--MCP_INPUT:quickContent"
	
	-- Process based on requested action
	if action is "processInbox" then
		if rules is "" then
			set rules to "default"
		end if
		return processInboxWithRules(rules)
	else if action is "applyTemplate" then
		if templateName is "" or templateRecipient is "" then
			return {success:false, error:"Template name and recipient are required"}
		end if
		return applyTemplateResponses(templateName, templateRecipient)
	else if action is "organizeMessages" then
		if organizeCriteria is "" then
			set organizeCriteria to "unread"
		end if
		if organizeDestination is "" then
			set organizeDestination to "Follow Up"
		end if
		return organizeMessages(organizeCriteria, organizeDestination)
	else if action is "createDigest" then
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
	else if action is "archiveOld" then
		if archiveDays is "" then
			set archiveDays to 30
		else
			try
				set archiveDays to archiveDays as number
			on error
				set archiveDays to 30
			end try
		end if
		return archiveOldMessages(archiveDays, archiveDestination)
	else if action is "quickMessage" then
		if quickRecipient is "" then
			return {success:false, error:"Recipient is required for quick message"}
		end if
		if quickSubject is "" then
			set quickSubject to "Quick Message"
		end if
		return createQuickMessage(quickRecipient, quickSubject, quickContent)
	else
		return {success:false, error:"Invalid action. Valid actions: processInbox, applyTemplate, organizeMessages, createDigest, archiveOld, quickMessage"}
	end if
end processMCPParameters

-- Process inbox messages using predefined or custom rules
on processInboxWithRules(ruleSet)
	if ruleSet is missing value then
		set ruleSet to "default"
	end if
	
	-- Load rule definitions
	if ruleSet is "default" then
		set rules to {¬
			{name:"Important", criteria:"from", value:"boss,manager,ceo,urgent", action:"flag", destination:"Important"}, ¬
			{name:"Newsletter", criteria:"subject", value:"newsletter,update,weekly", action:"move", destination:"Newsletters"}, ¬
			{name:"Receipt", criteria:"subject", value:"receipt,order,confirmation,invoice", action:"move", destination:"Receipts"}, ¬
			{name:"Social", criteria:"from", value:"facebook,twitter,instagram,linkedin", action:"move", destination:"Social"}, ¬
			{name:"Unsubscribe", criteria:"subject", value:"unsubscribe", action:"move", destination:"Promotions"} ¬
		}
	else
		-- Parse custom rules if provided
		try
			set rules to ruleSet
		on error
			set rules to {}
		end try
	end if
	
	tell application "Mail"
		set processedCount to 0
		set inboxMessages to messages of inbox
		set messageCount to count of inboxMessages
		
		-- Process each message with the rules
		repeat with i from 1 to messageCount
			set theMessage to item i of inboxMessages
			
			repeat with theRule in rules
				set ruleName to name of theRule
				set ruleCriteria to criteria of theRule
				set ruleValue to value of theRule
				set ruleAction to action of theRule
				set ruleDestination to destination of theRule
				
				set valueList to my splitString(ruleValue, ",")
				set matchFound to false
				
				-- Check if message matches criteria
				if ruleCriteria is "from" then
					set messageSender to sender of theMessage
					repeat with valueItem in valueList
						if messageSender contains valueItem then
							set matchFound to true
							exit repeat
						end if
					end repeat
				else if ruleCriteria is "subject" then
					set messageSubject to subject of theMessage
					repeat with valueItem in valueList
						if messageSubject contains valueItem then
							set matchFound to true
							exit repeat
						end if
					end repeat
				else if ruleCriteria is "content" then
					set messageContent to content of theMessage
					repeat with valueItem in valueList
						if messageContent contains valueItem then
							set matchFound to true
							exit repeat
						end if
					end repeat
				end if
				
				-- Apply the rule action if criteria matched
				if matchFound then
					if ruleAction is "flag" then
						set flag index of theMessage to 1
						set read status of theMessage to true
						set processedCount to processedCount + 1
					else if ruleAction is "move" then
						try
							-- Check if destination mailbox exists, create if needed
							try
								set targetMailbox to mailbox ruleDestination
							on error
								make new mailbox with properties {name:ruleDestination}
								set targetMailbox to mailbox ruleDestination
							end try
							
							-- Move the message
							move theMessage to targetMailbox
							set processedCount to processedCount + 1
						on error errMsg
							log "Error moving message: " & errMsg
						end try
					end if
					
					-- Once a rule is applied, move to next message
					exit repeat
				end if
			end repeat
		end repeat
		
		return {success:true, message:"Processed " & processedCount & " messages with rules", result:processedCount}
	end tell
end processInboxWithRules

-- Apply email templates to quickly respond to messages
on applyTemplateResponses(templateName, recipient)
	set templates to {¬
		{name:"Meeting Request", subject:"Meeting Request Response", content:"Thank you for your meeting request. I am available on [DATE] at [TIME]. Please let me know if this works for you."}, ¬
		{name:"Out of Office", subject:"Out of Office Reply", content:"Thank you for your email. I am currently out of the office until [DATE] with limited access to email. I will respond to your message upon my return."}, ¬
		{name:"Support Request", subject:"Support Request Confirmation", content:"Thank you for contacting support. Your request has been received and assigned ticket number [TICKET]. We'll get back to you within 24 hours."}, ¬
		{name:"Thank You", subject:"Thank You", content:"Thank you for your email. I appreciate your [MESSAGE] and will get back to you as soon as possible."}, ¬
		{name:"Job Application", subject:"Job Application Received", content:"Thank you for applying for the [POSITION] position. We have received your application and will review it shortly. We'll contact you if your qualifications match our needs."} ¬
	}
	
	-- Interactive mode if parameters not provided
	if templateName is missing value or recipient is missing value then
		tell application "Mail"
			-- Get template names
			set templateNames to {}
			repeat with t in templates
				set end of templateNames to name of t
			end repeat
			
			-- Select template
			set selectedTemplate to choose from list templateNames with prompt "Select a response template:"
			if selectedTemplate is false then
				return {success:false, error:"No template selected"}
			end if
			set templateName to item 1 of selectedTemplate
			
			-- Select recipient
			set recipientOptions to {}
			set selectedMessages to selection
			if (count of selectedMessages) > 0 then
				set theMessage to item 1 of selectedMessages
				set end of recipientOptions to sender of theMessage
			end if
			
			set recipientInput to text returned of (display dialog "Enter recipient:" default answer (item 1 of recipientOptions))
			set recipient to recipientInput
		end tell
	end if
	
	-- Find the template
	set templateFound to false
	set templateSubject to ""
	set templateContent to ""
	
	repeat with t in templates
		if name of t is templateName then
			set templateFound to true
			set templateSubject to subject of t
			set templateContent to content of t
			exit repeat
		end if
	end repeat
	
	if not templateFound then
		return {success:false, error:"Template '" & templateName & "' not found"}
	end if
	
	-- Apply any needed substitutions
	set templateContent to replaceTokenInString(templateContent, "[DATE]", (current date) as string)
	set templateContent to replaceTokenInString(templateContent, "[TIME]", time string of (current date))
	set templateContent to replaceTokenInString(templateContent, "[TICKET]", "SR-" & (random number from 10000 to 99999) as string)
	
	-- Create and send the message
	tell application "Mail"
		set newMessage to make new outgoing message with properties {subject:templateSubject, content:templateContent, visible:true}
		tell newMessage
			make new to recipient at end of to recipients with properties {address:recipient}
		end tell
		
		return {success:true, message:"Created message from template '" & templateName & "' to " & recipient}
	end tell
end applyTemplateResponses

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

-- Helper function to split a string
on splitString(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end splitString

-- Helper function to replace tokens in a string
on replaceTokenInString(theString, theToken, theReplacement)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theToken
	set theArray to every text item of theString
	set AppleScript's text item delimiters to theReplacement
	set theResult to theArray as string
	set AppleScript's text item delimiters to oldDelimiters
	return theResult
end replaceTokenInString
```

## Example Input Parameters

When using with MCP, you can provide these parameters:

- `action`: The workflow action to perform (required)
  - Valid values: `processInbox`, `applyTemplate`, `organizeMessages`, `createDigest`, `archiveOld`, `quickMessage`
- Additional parameters depend on the action:

### For `processInbox` action:
- `rules`: Custom rules or "default" to use built-in rules (optional)

### For `applyTemplate` action:
- `templateName`: Name of the template to use (required)
- `templateRecipient`: Email address of the recipient (required)

### For `organizeMessages` action:
- `organizeCriteria`: Criteria for selecting messages (e.g., "unread", "flagged", "from:someone", "subject:important")
- `organizeDestination`: Destination mailbox for organized messages

### For `createDigest` action:
- `digestDays`: Number of days to include in the digest
- `digestFolder`: Specific folder to create digest from (optional)

### For `archiveOld` action:
- `archiveDays`: Number of days threshold for archiving
- `archiveDestination`: Destination mailbox for archived messages

### For `quickMessage` action:
- `quickRecipient`: Email address of the recipient (required)
- `quickSubject`: Subject of the message (optional)
- `quickContent`: Content of the message (optional)

## Example Usage

### Process inbox with default rules

```json
{
  "action": "processInbox"
}
```

### Apply an "Out of Office" template

```json
{
  "action": "applyTemplate",
  "templateName": "Out of Office",
  "templateRecipient": "colleague@example.com"
}
```

### Organize unread messages

```json
{
  "action": "organizeMessages",
  "organizeCriteria": "unread",
  "organizeDestination": "Follow Up"
}
```

### Create email digest for the last 3 days

```json
{
  "action": "createDigest",
  "digestDays": 3,
  "digestFolder": "Inbox"
}
```

### Archive messages older than 60 days

```json
{
  "action": "archiveOld",
  "archiveDays": 60,
  "archiveDestination": "Archive/2023"
}
```

### Send a quick message

```json
{
  "action": "quickMessage",
  "quickRecipient": "friend@example.com",
  "quickSubject": "Quick Update",
  "quickContent": "Just wanted to give you a quick update on the project. Everything is on track for our deadline next week."
}
```

## Advanced Rule Usage

The mail processing rules can be customized by providing a list of rule objects, each with the following properties:

- `name`: Name of the rule
- `criteria`: What to match against ("from", "subject", "content")
- `value`: Comma-separated values to match
- `action`: Action to take ("flag", "move")
- `destination`: Destination mailbox for "move" action

For example:

```json
{
  "action": "processInbox",
  "rules": [
    {
      "name": "Client Messages",
      "criteria": "from",
      "value": "client1.com,client2.com,client3.com",
      "action": "move",
      "destination": "Clients"
    },
    {
      "name": "Project Updates",
      "criteria": "subject",
      "value": "project,update,status",
      "action": "flag",
      "destination": "Projects"
    }
  ]
}
```
