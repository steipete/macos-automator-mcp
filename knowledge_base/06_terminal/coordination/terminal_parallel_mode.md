---
title: Terminal Parallel Mode
category: 06_terminal
id: terminal_parallel_mode
description: >-
  Run different commands in parallel across multiple terminal windows, enabling
  coordinated but distinct operations across Terminal.app, iTerm2, and Ghostty.
keywords:
  - terminal
  - parallel
  - multi-command
  - orchestration
  - workflow
  - iTerm2
  - Terminal.app
  - Ghostty
language: applescript
---

# Terminal Parallel Mode

This script runs different commands in parallel across multiple terminal windows, tabs, or sessions. It's perfect for orchestrating complex workflows that require different operations to run simultaneously.

## Features

- Execute different commands in different terminals simultaneously
- Support for Terminal.app, iTerm2, and Ghostty
- Automatic terminal discovery and distribution
- Option to execute or just echo commands

## Usage

```applescript
-- Terminal Parallel Mode
-- Run different commands in parallel

on run
	try
		-- Default values for interactive mode
		set defaultCommands to {}
		set defaultTerminals to {"Terminal.app", "iTerm2", "Ghostty"}
		set defaultTargets to {}
		set defaultExecuteCommands to true
		
		return runParallelCommands(defaultCommands, defaultTerminals, defaultTargets, defaultExecuteCommands)
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handle MCP parameters
on processMCPParameters(inputParams)
	-- Extract parameters
	set theCommands to "--MCP_INPUT:commands"
	set theTerminals to "--MCP_INPUT:terminals"
	set theTargets to "--MCP_INPUT:targets"
	set executeCommands to "--MCP_INPUT:executeCommands"
	
	-- Default values
	if theTerminals is "" then
		set theTerminals to {"Terminal.app", "iTerm2", "Ghostty"}
	end if
	
	if theTargets is "" then
		set theTargets to {}
	end if
	
	if executeCommands is "" then
		set executeCommands to true
	else
		try
			set executeCommands to executeCommands as boolean
		on error
			set executeCommands to true
		end try
	end if
	
	-- Validate input
	if theCommands is "" or class of theCommands is not list then
		return "Error: Commands must be provided as a list."
	end if
	
	if length of theCommands is 0 then
		return "Error: No commands provided for parallel execution."
	end if
	
	return runParallelCommands(theCommands, theTerminals, theTargets, executeCommands)
end processMCPParameters

-- Main parallel execution function
on runParallelCommands(commands, terminals, targets, shouldExecute)
	set successCount to 0
	set failCount to 0
	set resultMessage to ""
	
	-- Validate commands list
	if class of commands is not list then
		return "Error: Commands must be a list for parallel execution."
	end if
	
	set commandCount to count of commands
	if commandCount = 0 then
		return "Error: No commands provided for parallel execution."
	end if
	
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
	
	-- Prepare target specs
	set targetSpecs to {}
	
	-- If no specific targets, build a list from available terminals
	if length of targets is 0 then
		-- Add Terminal.app targets
		if "Terminal.app" is in runningTerminals then
			tell application "Terminal"
				repeat with i from 1 to count of windows
					set currentWindow to window i
					repeat with j from 1 to count of tabs of currentWindow
						set end of targetSpecs to "Terminal.app:" & i & ":" & j
					end repeat
				end repeat
			end tell
		end if
		
		-- Add iTerm2 targets
		if "iTerm2" is in runningTerminals then
			tell application "iTerm2"
				repeat with i from 1 to count of windows
					tell window i
						repeat with j from 1 to count of tabs
							tell tab j
								repeat with k from 1 to count of sessions
									set end of targetSpecs to "iTerm2:" & i & ":" & j & ":" & k
								end repeat
							end tell
						end repeat
					end tell
				end repeat
			end tell
		end if
		
		-- Add Ghostty targets (simplified as just one target)
		if "Ghostty" is in runningTerminals then
			set end of targetSpecs to "Ghostty:1"
		end if
	else
		set targetSpecs to targets
	end if
	
	-- Execute commands in parallel
	set targetCount to count of targetSpecs
	set loopCount to my min(commandCount, targetCount)
	
	if loopCount = 0 then
		return "Error: No terminals available for parallel execution."
	end if
	
	repeat with i from 1 to loopCount
		set currentTarget to item i of targetSpecs
		set currentCommand to item i of commands
		
		if currentTarget starts with "Terminal.app:" then
			try
				set result to my executeInTerminal(currentTarget, currentCommand, shouldExecute)
				if result then
					set successCount to successCount + 1
				else
					set failCount to failCount + 1
				end if
			on error
				set failCount to failCount + 1
			end try
		else if currentTarget starts with "iTerm2:" then
			try
				set result to my executeInITerm(currentTarget, currentCommand, shouldExecute)
				if result then
					set successCount to successCount + 1
				else
					set failCount to failCount + 1
				end if
			on error
				set failCount to failCount + 1
			end try
		else if currentTarget starts with "Ghostty:" then
			try
				set result to my executeInGhostty(currentCommand, shouldExecute)
				if result then
					set successCount to successCount + 1
				else
					set failCount to failCount + 1
				end if
			on error
				set failCount to failCount + 1
			end try
		end if
		
		-- Add a slight delay between commands
		delay 0.5
	end repeat
	
	-- Build result message
	if successCount > 0 then
		set resultMessage to resultMessage & "Parallel commands sent to " & successCount & " terminal" & (if successCount = 1 then "" else "s") & ". "
	end if
	
	if failCount > 0 then
		set resultMessage to resultMessage & "Failed to send commands to " & failCount & " terminal" & (if failCount = 1 then "" else "s") & "."
	end if
	
	if commandCount > loopCount then
		set resultMessage to resultMessage & " Note: " & (commandCount - loopCount) & " command(s) not executed due to insufficient terminals."
	end if
	
	return resultMessage
end runParallelCommands

-- Execute command in Terminal.app
on executeInTerminal(targetSpec, command, shouldExecute)
	set targetParts to my splitString(targetSpec, ":")
	
	if (count of targetParts) < 3 then return false
	
	set windowIndex to item 2 of targetParts as integer
	set tabIndex to item 3 of targetParts as integer
	
	tell application "Terminal"
		if windowIndex > 0 and windowIndex ≤ (count of windows) and ¬
			tabIndex > 0 and tabIndex ≤ (count of tabs of window windowIndex) then
			set currentTab to tab tabIndex of window windowIndex
			
			-- Send the command
			tell currentTab
				set selected of currentTab to true
				delay 0.3
				
				tell application "System Events" to tell process "Terminal"
					keystroke command
					if shouldExecute then keystroke return
				end tell
			end tell
			
			return true
		else
			return false
		end if
	end tell
end executeInTerminal

-- Execute command in iTerm2
on executeInITerm(targetSpec, command, shouldExecute)
	set targetParts to my splitString(targetSpec, ":")
	
	if (count of targetParts) < 4 then return false
	
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
					
					-- Send the command
					if shouldExecute then
						write text command
					else
						-- Echo without executing
						tell application "System Events" to tell process "iTerm2"
							keystroke command
						end tell
					end if
					
					return true
				end tell
			end tell
		end tell
	end tell
end executeInITerm

-- Execute command in Ghostty
on executeInGhostty(command, shouldExecute)
	tell application "Ghostty"
		activate
		
		-- Use UI automation for Ghostty
		tell application "System Events" to tell process "Ghostty"
			keystroke command
			if shouldExecute then keystroke return
		end tell
		
		return true
	end tell
end executeInGhostty

-- Helper function to find minimum of two numbers
on min(a, b)
	if a < b then
		return a
	else
		return b
	end if
end min

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

- `commands`: List of commands to execute in parallel (required)
- `terminals`: List of terminal applications to use (default: all)
- `targets`: Specific windows/tabs to target (default: auto-discover)
- `executeCommands`: Whether to execute (true) or just echo (false)

## Example Usage

### Run different services in parallel
```json
{
  "commands": [
    "cd ~/projects/frontend && npm start",
    "cd ~/projects/backend && npm run dev",
    "cd ~/projects/db && docker-compose up"
  ],
  "executeCommands": true
}
```

### Deploy to multiple servers
```json
{
  "commands": [
    "ssh server1 'cd /app && git pull && pm2 restart all'",
    "ssh server2 'cd /app && git pull && pm2 restart all'",
    "ssh server3 'cd /app && git pull && pm2 restart all'"
  ],
  "terminals": ["iTerm2"],
  "executeCommands": true
}
```

### Stage commands for manual execution
```json
{
  "commands": [
    "sudo systemctl restart nginx",
    "sudo systemctl restart mysql",
    "tail -f /var/log/syslog"
  ],
  "executeCommands": false
}
```

### Target specific terminals
```json
{
  "commands": [
    "top",
    "htop",
    "iotop"
  ],
  "targets": [
    "Terminal.app:1:1",
    "Terminal.app:1:2",
    "Terminal.app:1:3"
  ],
  "executeCommands": true
}
```

## Use Cases

1. **Multi-Service Development**: Start frontend, backend, and database simultaneously
2. **Distributed Deployment**: Deploy to multiple servers in parallel
3. **System Monitoring**: Launch different monitoring tools in separate terminals
4. **Testing Workflows**: Run different test suites concurrently
5. **DevOps Operations**: Execute maintenance tasks across environments

## Command Distribution

- Commands are distributed to available terminals in order
- If there are more commands than terminals, excess commands are not executed
- If there are more terminals than commands, extra terminals remain unused
- Auto-discovery finds all available windows, tabs, and sessions

## Tips

1. **Order Matters**: Commands are assigned to terminals in the order they appear
2. **Pre-create Terminals**: Open the desired number of terminals before running
3. **Use Targets**: Specify exact targets for predictable command placement
4. **Echo First**: Use executeCommands:false to preview command distribution

## Notes

- Each command runs independently in its assigned terminal
- Commands start executing with a small delay between them
- Terminal selection respects the order of discovery
- Failed executions are reported but don't stop other commands

## Security Considerations

- Be careful with parallel execution of sensitive commands
- Review command distribution before executing
- Consider using echo mode for dangerous operations
- Ensure proper access controls for remote operations