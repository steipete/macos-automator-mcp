---
title: Terminal Echo Mode
category: 06_terminal
id: terminal_echo_mode
description: >-
  Echo text to multiple terminal windows without executing commands, allowing
  review before manual execution across Terminal.app, iTerm2, and Ghostty.
keywords:
  - terminal
  - echo
  - preview
  - text
  - safety
  - iTerm2
  - Terminal.app
  - Ghostty
language: applescript
---

# Terminal Echo Mode

This script echoes text to multiple terminal windows without executing commands, providing a safe way to prepare commands for review before manual execution.

## Features

- Echo text to multiple terminals without execution
- Support for Terminal.app, iTerm2, and Ghostty
- Target all terminals or specific windows/tabs
- Perfect for preparing complex or sensitive commands

## Usage

```applescript
-- Terminal Echo Mode
-- Echo text without execution

on run
	try
		-- Default values for interactive mode
		set defaultText to ""
		set defaultTerminals to {"Terminal.app", "iTerm2", "Ghostty"}
		set defaultTargets to {}
		
		return echoText(defaultText, defaultTerminals, defaultTargets)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theText to "--MCP_INPUT:text"
	set theTerminals to "--MCP_INPUT:terminals"
	set theTargets to "--MCP_INPUT:targets"
	
	-- Default values
	if theTerminals is "" then
		set theTerminals to {"Terminal.app", "iTerm2", "Ghostty"}
	end if
	
	if theTargets is "" then
		set theTargets to {}
	end if
	
	-- Validate input
	if theText is "" then
		return "Error: No text provided to echo."
	end if
	
	return echoText(theText, theTerminals, theTargets)
end processMCPParameters

-- Main echo function
on echoText(textToEcho, terminals, targets)
	set successCount to 0
	set failCount to 0
	set resultMessage to ""
	
	-- Check which terminals are running
	set runningTerminals to {}
	
	tell application "System Events"
		if "Terminal" is in (name of processes) and "Terminal.app" is in terminals then
			set end of runningTerminals to "Terminal.app"
		end if
		if "iTerm2" is in (name of processes) and "iTerm2" is in terminals then
			set end of runningTerminals to "iTerm2"
		end if
		if "Ghostty" is in (name of processes) and "Ghostty" is in terminals then
			set end of runningTerminals to "Ghostty"
		end if
	end tell
	
	if length of runningTerminals is 0 then
		return "Error: None of the specified terminal applications are running."
	end if
	
	-- Process Terminal.app
	if "Terminal.app" is in runningTerminals then
		try
			tell application "Terminal"
				activate
				
				-- Determine target windows/tabs
				if length of targets is 0 then
					-- Target all windows and tabs
					repeat with i from 1 to count of windows
						set currentWindow to window i
						repeat with j from 1 to count of tabs of currentWindow
							set currentTab to tab j of currentWindow
							
							-- Echo the text
							tell currentTab
								set selected of currentTab to true
								delay 0.3
								
								tell application "System Events" to tell process "Terminal"
									keystroke textToEcho
									-- Do not press return - just echo
								end tell
							end tell
							
							set successCount to successCount + 1
							delay 0.3
						end repeat
					end repeat
				else
					-- Target specific windows/tabs from targets list
					set {successTargets, failTargets} to my processTerminalTargets(targets, textToEcho)
					set successCount to successCount + successTargets
					set failCount to failCount + failTargets
				end if
			end tell
		on error errMsg
			set resultMessage to resultMessage & "Error with Terminal.app: " & errMsg & "\n"
			set failCount to failCount + 1
		end try
	end if
	
	-- Process iTerm2
	if "iTerm2" is in runningTerminals then
		try
			tell application "iTerm2"
				activate
				
				-- Determine target windows/tabs/sessions
				if length of targets is 0 then
					-- Target all windows, tabs, and sessions
					repeat with i from 1 to count of windows
						tell window i
							repeat with j from 1 to count of tabs
								tell tab j
									repeat with k from 1 to count of sessions
										tell session k
											-- Select the session
											select
											delay 0.3
											
											-- Echo the text without executing
											tell application "System Events" to tell process "iTerm2"
												keystroke textToEcho
											end tell
											
											set successCount to successCount + 1
										end tell
									end repeat
								end tell
							end repeat
						end tell
					end repeat
				else
					-- Target specific windows/tabs/sessions from targets list
					set {successTargets, failTargets} to my processITermTargets(targets, textToEcho)
					set successCount to successCount + successTargets
					set failCount to failCount + failTargets
				end if
			end tell
		on error errMsg
			set resultMessage to resultMessage & "Error with iTerm2: " & errMsg & "\n"
			set failCount to failCount + 1
		end try
	end if
	
	-- Process Ghostty
	if "Ghostty" is in runningTerminals then
		try
			tell application "Ghostty"
				activate
				
				-- Echo to the active window
				tell application "System Events" to tell process "Ghostty"
					keystroke textToEcho
					-- Do not press return - just echo
				end tell
				
				set successCount to successCount + 1
			end tell
		on error errMsg
			set resultMessage to resultMessage & "Error with Ghostty: " & errMsg & "\n"
			set failCount to failCount + 1
		end try
	end if
	
	-- Build result message
	if successCount > 0 then
		set resultMessage to resultMessage & "Echo successful to " & successCount & " terminal" & (if successCount = 1 then "" else "s") & ". "
	end if
	
	if failCount > 0 then
		set resultMessage to resultMessage & "Failed to echo to " & failCount & " terminal" & (if failCount = 1 then "" else "s") & "."
	end if
	
	return resultMessage
end echoText

-- Process Terminal.app specific targets
on processTerminalTargets(targets, textToEcho)
	set successCount to 0
	set failCount to 0
	
	repeat with targetSpec in targets
		if targetSpec starts with "Terminal.app:" then
			set targetParts to my splitString(targetSpec, ":")
			
			if (count of targetParts) ≥ 3 then
				try
					set windowIndex to item 2 of targetParts as integer
					set tabIndex to item 3 of targetParts as integer
					
					tell application "Terminal"
						if windowIndex > 0 and windowIndex ≤ (count of windows) and ¬
							tabIndex > 0 and tabIndex ≤ (count of tabs of window windowIndex) then
							set currentTab to tab tabIndex of window windowIndex
							
							-- Echo the text
							tell currentTab
								set selected of currentTab to true
								delay 0.3
								
								tell application "System Events" to tell process "Terminal"
									keystroke textToEcho
								end tell
							end tell
							
							set successCount to successCount + 1
						else
							set failCount to failCount + 1
						end if
					end tell
				on error
					set failCount to failCount + 1
				end try
			end if
		end if
	end repeat
	
	return {successCount, failCount}
end processTerminalTargets

-- Process iTerm2 specific targets
on processITermTargets(targets, textToEcho)
	set successCount to 0
	set failCount to 0
	
	repeat with targetSpec in targets
		if targetSpec starts with "iTerm2:" then
			set targetParts to my splitString(targetSpec, ":")
			
			if (count of targetParts) ≥ 4 then
				try
					set windowIndex to item 2 of targetParts as integer
					set tabIndex to item 3 of targetParts as integer
					set sessionIndex to item 4 of targetParts as integer
					
					tell application "iTerm2"
						tell window windowIndex
							tell tab tabIndex
								tell session sessionIndex
									-- Select the session
									select
									delay 0.3
									
									-- Echo the text
									tell application "System Events" to tell process "iTerm2"
										keystroke textToEcho
									end tell
									
									set successCount to successCount + 1
								end tell
							end tell
						end tell
					end tell
				on error
					set failCount to failCount + 1
				end try
			end if
		end if
	end repeat
	
	return {successCount, failCount}
end processITermTargets

-- Helper function to split string
on splitString(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theItems to text items of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theItems
end splitString
```

## MCP Parameters

- `text`: The text to echo to terminals (required)
- `terminals`: List of terminal applications to target (default: all)
- `targets`: Specific windows/tabs to target (default: all)

## Example Usage

### Echo to all terminals
```json
{
  "text": "sudo systemctl restart nginx"
}
```

### Echo to specific terminals
```json
{
  "text": "rm -rf ./temp/*",
  "terminals": ["Terminal.app"]
}
```

### Target specific windows/tabs
```json
{
  "text": "docker-compose down && docker-compose up",
  "targets": ["iTerm2:1:1:1", "iTerm2:1:2:1"]
}
```

## Use Cases

1. **Dangerous Commands**: Prepare potentially destructive commands for review
2. **Complex Commands**: Echo lengthy commands for verification before execution
3. **Teaching**: Demonstrate commands without executing them
4. **Command Templates**: Prepare commands with placeholders for manual editing
5. **Multi-Step Operations**: Stage commands across terminals before coordinated execution

## Safety Benefits

- Commands are never executed automatically in echo mode
- Allows visual verification before manual execution
- Prevents accidental execution of destructive commands
- Enables careful review of complex command syntax
- Perfect for preparing sensitive operations

## Tips

1. Use echo mode to prepare commands that:
   - Contain sensitive information
   - Could be destructive (rm, format, etc.)
   - Have complex syntax that needs verification
   - Require manual parameter substitution

2. After echoing, manually review each terminal before pressing Enter

3. Combine with broadcast mode by first echoing, reviewing, then broadcasting

## Security Notes

- Echo mode is the safest way to distribute commands
- Commands remain in the terminal input but are not executed
- Users maintain full control over command execution
- Ideal for operations requiring human verification