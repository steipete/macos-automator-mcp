---
title: Mail Process Inbox with Rules
category: 09_productivity
id: mail_process_inbox_rules
description: >-
  Process inbox messages using predefined or custom rules to automatically flag,
  categorize, and organize emails based on sender, subject, or content criteria.
language: applescript
keywords:
  - mail
  - inbox
  - rules
  - filter
  - organize
  - flag
  - move
  - automation
---

# Mail Process Inbox with Rules

This script processes inbox messages using predefined or custom rules, automatically organizing emails based on specified criteria like sender, subject, or content.

## Usage

The script can be run standalone or via MCP with parameters.

```applescript
-- Mail Process Inbox with Rules
-- Automatically process emails based on rules

on run
	try
		return processInboxWithRules("default")
	on error errMsg
		return {success:false, error:errMsg}
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set rules to "--MCP_INPUT:rules"
	
	if rules is "" then
		set rules to "default"
	end if
	
	return processInboxWithRules(rules)
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

-- Utility function to split string by delimiter
on splitString(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end splitString
```

## Rule Structure

Each rule consists of:
- `name`: Descriptive name for the rule
- `criteria`: What to check ("from", "subject", or "content")
- `value`: Comma-separated list of keywords to match
- `action`: What to do ("flag" or "move")
- `destination`: Mailbox name for "move" action

## Default Rules

The default ruleset includes:
1. **Important**: Flags emails from boss, manager, CEO, or with "urgent"
2. **Newsletter**: Moves newsletters to "Newsletters" folder
3. **Receipt**: Moves receipts and invoices to "Receipts" folder
4. **Social**: Moves social media notifications to "Social" folder
5. **Unsubscribe**: Moves promotional emails to "Promotions" folder

## MCP Parameters

- `rules`: Ruleset to use ("default" or custom rule array)

## Example Usage

### Use default rules
```json
{
  "rules": "default"
}
```

### Custom rules example
```json
{
  "rules": [
    {
      "name": "VIP", 
      "criteria": "from", 
      "value": "john@example.com,jane@company.com", 
      "action": "flag", 
      "destination": ""
    },
    {
      "name": "Development", 
      "criteria": "subject", 
      "value": "GitHub,pull request,CI/CD", 
      "action": "move", 
      "destination": "Development"
    }
  ]
}
```

## Return Value

Returns an object with:
- `success`: Boolean indicating operation success
- `message`: Description of what was done
- `result`: Number of messages processed