---
id: terminal_find_kill_process_by_port
title: Find Process Using Port and Optionally Kill It
description: >-
  Identifies which process is using a specific port and provides the option to
  kill it
language: applescript
platform: macOS
kb_path: 04_terminal_emulators/terminal_app
author: Claude
version: 1.0.0
keywords:
  - port
  - process
  - kill
  - network
  - troubleshooting
required_permissions:
  - Network access
category: 06_terminal/terminal_app
---

# Find Process Using Port and Optionally Kill It

This script finds the process using a specified port and gives you the option to kill it.

## Usage
```applescript
-- Usage examples:
-- Find process using port 8080
my findProcessByPort(8080, false)

-- Find process using port 3000 and kill it if found
my findProcessByPort(3000, true)
```

## Script
```applescript
-- Find which process is using a specific port and optionally kill it
on findProcessByPort(portNumber, shouldKill)
	set portNumber to portNumber as string
	
	try
		-- Check if any process is using this port
		set portCheckCommand to "lsof -nP -iTCP:" & portNumber & " -sTCP:LISTEN"
		set portCheckResult to do shell script portCheckCommand
		
		-- Extract PID and process name directly from lsof output
		-- Format the command to extract both in one go to avoid empty result issues
		set pidAndName to do shell script "echo " & quoted form of portCheckResult & " | awk 'NR>1 {print $2 \"|\" $1}' | head -1"
		
		-- Split the result to get PID and process name
		set AppleScript's text item delimiters to "|"
		set pidAndNameItems to text items of pidAndName
		set pid to item 1 of pidAndNameItems
		set processName to item 2 of pidAndNameItems
		set AppleScript's text item delimiters to ""
		
		-- Create result message
		set resultMessage to "Port " & portNumber & " is being used by " & processName & " (PID: " & pid & ")"
		
		-- Kill the process if requested
		if shouldKill is true then
			do shell script "kill -9 " & pid
			set resultMessage to resultMessage & ". Process has been terminated."
		end if
		
		return resultMessage
	on error errorMessage
		if errorMessage contains "pattern not found" or errorMessage contains "not a valid process ID" then
			return "No process found using port " & portNumber
		else
			return "Error: " & errorMessage
		end if
	end try
end findProcessByPort

-- Alternative version that presents a dialog asking if the user wants to kill the process
on findProcessByPortWithPrompt(portNumber)
	set portNumber to portNumber as string
	
	try
		-- Check if any process is using this port
		set portCheckCommand to "lsof -nP -iTCP:" & portNumber & " -sTCP:LISTEN"
		set portCheckResult to do shell script portCheckCommand
		
		-- Extract PID and process name directly from lsof output
		set pidAndName to do shell script "echo " & quoted form of portCheckResult & " | awk 'NR>1 {print $2 \"|\" $1}' | head -1"
		
		-- Split the result to get PID and process name
		set AppleScript's text item delimiters to "|"
		set pidAndNameItems to text items of pidAndName
		set pid to item 1 of pidAndNameItems
		set processName to item 2 of pidAndNameItems
		set AppleScript's text item delimiters to ""
		
		-- Ask user if they want to kill the process
		set promptMessage to "Port " & portNumber & " is being used by " & processName & " (PID: " & pid & ")" & return & return & "Do you want to kill this process?"
		set userChoice to display dialog promptMessage buttons {"Cancel", "Kill Process"} default button "Cancel" with icon caution
		
		if button returned of userChoice is "Kill Process" then
			do shell script "kill -9 " & pid
			return "Process " & processName & " (PID: " & pid & ") has been terminated."
		else
			return "Process " & processName & " (PID: " & pid & ") was not terminated."
		end if
	on error errorMessage
		if errorMessage contains "pattern not found" or errorMessage contains "not a valid process ID" then
			return "No process found using port " & portNumber
		else
			return "Error: " & errorMessage
		end if
	end try
end findProcessByPortWithPrompt

-- Example usage with placeholder for MCP
-- Replace --MCP_INPUT:port with the port number to check
set portToCheck to --MCP_INPUT:port
my findProcessByPort(portToCheck, false)

-- Uncomment the line below to use the interactive version
-- my findProcessByPortWithPrompt(portToCheck)
```

## Notes
- The script uses `lsof` to find processes listening on the specified TCP port
- It extracts the process ID (PID) and process name
- Two versions are provided:
  - `findProcessByPort`: Programmatic version with a boolean parameter to kill the process
  - `findProcessByPortWithPrompt`: Interactive version that displays a dialog asking if you want to kill the process
- Error handling is included to gracefully handle cases where no process is found
