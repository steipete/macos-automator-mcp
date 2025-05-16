---
id: test_port_finder_variants
title: Port Finder Script Variations
description: >-
  Three versions of an AppleScript for finding and killing processes using
  specific TCP ports, from basic to optimized implementations.
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
  This file contains three progressive versions of an AppleScript function to
  identify and 

  optionally terminate processes using specific TCP ports. It's useful for
  troubleshooting 

  port conflicts when developing web applications or network services.


  The three versions demonstrate different implementation approaches:

  1. Initial version: Uses separate commands to extract PID and process name

  2. Improved version: Extracts PID and process name in a single command with
  space delimiter

  3. Final optimized version: Uses a pipe character delimiter for more reliable
  extraction


  Each version includes the same core functionality:

  - Takes a port number and a boolean flag indicating whether to kill the
  process

  - Uses the `lsof` command to find processes listening on the specified port

  - Extracts the process ID (PID) and name from the command output

  - Optionally terminates the process if requested

  - Returns information about the process or appropriate error messages


  To use any of these scripts:

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
  - title: Final optimized version with pipe delimiter
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
category: 12_network
---

```applescript
-- Find which process is using a specific port and optionally kill it
-- Version 1: Initial implementation
on findProcessByPort_initial(portNumber, shouldKill)
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
end findProcessByPort_initial

-- Version 2: Improved version with direct extraction
on findProcessByPort_improved(portNumber, shouldKill)
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
end findProcessByPort_improved

-- Version 3: Final optimized version with pipe delimiter
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

-- Example usage: Find which process is using port 8080 but don't kill it
findProcessByPort(--MCP_INPUT:portNumber--, --MCP_INPUT:shouldKill--)
```
