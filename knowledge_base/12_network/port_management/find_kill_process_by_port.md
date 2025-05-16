---
id: find_kill_process_by_port
title: Find and Kill Process by Port Number
description: >-
  AppleScript function to identify which process is using a specific TCP port
  and optionally terminate it.
language: applescript
compatibility: 'macOS Sonoma, Ventura, Monterey, Big Sur, Catalina'
author: Claude
tags:
  - network
  - ports
  - process management
  - tcp
  - kill process
keywords:
  - network
  - ports
  - tcp
  - process management
  - lsof
  - kill process
  - port finder
  - port conflict
guide: >
  This script provides a function to identify which process is using a specific
  TCP port

  and optionally terminate the process. It's useful for troubleshooting port
  conflicts

  when developing web applications or network services.


  The script:

  1. Takes a port number and a boolean flag indicating whether to kill the
  process

  2. Uses the `lsof` command to find processes listening on the specified port

  3. Extracts the process ID (PID) and name from the command output

  4. Optionally terminates the process if requested

  5. Returns information about the process or appropriate error messages


  To use this script:

  - Call `findProcessByPort(portNumber, shouldKill)` with the port to check

  - Set shouldKill to true to terminate the process, false to just get
  information


  Requirements:

  - macOS (uses lsof and kill commands)

  - Administrator privileges might be required to terminate certain processes
sample_snippets:
  - title: Initial version
    snippet: |
      -- Find which process is using a specific port and optionally kill it
      on findProcessByPort(portNumber, shouldKill)
          set portNumber to portNumber as string
          
          try
              -- Check if any process is using this port
              set portCheckCommand to "lsof -nP -iTCP:" & portNumber & " -sTCP:LISTEN"
              set portCheckResult to do shell script portCheckCommand
              
              -- Extract PID using awk
              set pid to do shell script "echo " & quoted form of portCheckResult & " | awk 'NR==2 {print $2}'"
              
              -- Get process name
              set processName to do shell script "ps -p " & pid & " -o comm= | xargs basename"
              
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
  - title: Improved version with direct extraction
    snippet: |
      -- Find which process is using a specific port and optionally kill it
      on findProcessByPort(portNumber, shouldKill)
          set portNumber to portNumber as string
          
          try
              -- Check if any process is using this port
              set portCheckCommand to "lsof -nP -iTCP:" & portNumber & " -sTCP:LISTEN"
              set portCheckResult to do shell script portCheckCommand
              
              -- Extract PID and process name directly with awk
              set pidAndName to do shell script "echo " & quoted form of portCheckResult & " | awk 'NR>1 {print $2 \" \" $1}' | head -1"
              
              -- Split the result into PID and name
              set AppleScript's text item delimiters to " "
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
  - title: Final optimized version
    snippet: |
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
arguments:
  - name: portNumber
    description: 'The TCP port number to check (e.g., 8080)'
    type: number
    required: true
  - name: shouldKill
    description: Whether to kill the process if found (true/false)
    type: boolean
    required: false
    default: false
category: 12_network/port_management
---

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

-- Run with parameters
findProcessByPort(--MCP_INPUT:portNumber--, --MCP_INPUT:shouldKill--)
```
