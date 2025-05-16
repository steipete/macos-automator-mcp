---
title: Multi-Terminal Coordination
id: terminal_multi_coordination
category: 06_terminal
description: >-
  Coordinates actions across multiple terminal windows, tabs, or panes, such as
  broadcasting input or synchronizing commands.
keywords:
  - terminal
  - coordination
  - broadcast
  - multi
  - sync
  - iTerm2
  - Terminal.app
  - Ghostty
  - input
  - parallel
language: applescript
argumentsPrompt: >-
  Expects inputData with: { "action": "broadcast", "echo", or "parallel",
  "text": "command to send", "terminals": ["Terminal.app", "iTerm2", "Ghostty"],
  "targets": ["specific list of targets"], "executeCommands": true/false }
isComplex: true
---

This script allows you to coordinate actions across multiple terminal applications, windows, or tabs. It supports broadcasting the same command to multiple terminals simultaneously, echoing text across terminals without execution, and running parallel commands in different terminals.

**Features:**
- Send the same command to multiple terminal applications simultaneously
- Target specific applications (Terminal.app, iTerm2, Ghostty)
- Echo text without execution or execute commands
- Run different commands in parallel across terminals
- Specify targets as a list or default to all visible terminals

**Important Note:**
- Requires accessibility permissions to control multiple terminal applications
- May require adjustments based on specific terminal application versions

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultAction to "broadcast"
    set defaultText to ""
    set defaultTerminals to {"Terminal.app", "iTerm2", "Ghostty"}
    set defaultTargets to {}
    set defaultExecuteCommands to true
    
    -- Parse input parameters
    set theAction to defaultAction
    set theText to defaultText
    set theTerminals to defaultTerminals
    set theTargets to defaultTargets
    set executeCommands to defaultExecuteCommands
    
    -- MCP placeholders for input parameters
    set actionPlaceholder to "--MCP_INPUT:action" -- "broadcast", "echo", or "parallel"
    set textPlaceholder to "--MCP_INPUT:text" -- The command or text to send
    set terminalsPlaceholder to "--MCP_INPUT:terminals" -- List of terminals to target
    set targetsPlaceholder to "--MCP_INPUT:targets" -- List of specific targets
    set executeCommandsPlaceholder to "--MCP_INPUT:executeCommands" -- Whether to execute commands
    
    -- Check for MCP placeholders first, then fallback to inputData
    if actionPlaceholder is not equal to "--MCP_INPUT:action" then
        set theAction to actionPlaceholder
    else if inputData is not missing value and inputData contains {action:""} then
        set theAction to action of inputData
    end if
    
    if textPlaceholder is not equal to "--MCP_INPUT:text" then
        set theText to textPlaceholder
    else if inputData is not missing value and inputData contains {text:""} then
        set theText to text of inputData
    end if
    
    if terminalsPlaceholder is not equal to "--MCP_INPUT:terminals" then
        set theTerminals to terminalsPlaceholder
    else if inputData is not missing value and inputData contains {terminals:""} then
        set theTerminals to terminals of inputData
    end if
    
    if targetsPlaceholder is not equal to "--MCP_INPUT:targets" then
        set theTargets to targetsPlaceholder
    else if inputData is not missing value and inputData contains {targets:""} then
        set theTargets to targets of inputData
    end if
    
    if executeCommandsPlaceholder is not equal to "--MCP_INPUT:executeCommands" then
        try
            set executeCommands to executeCommandsPlaceholder as boolean
        on error
            -- Keep default if conversion fails
        end try
    else if inputData is not missing value and inputData contains {executeCommands:""} then
        try
            set executeCommands to executeCommands of inputData as boolean
        on error
            -- Keep default
        end try
    end if
    
    -- Validate input
    if theText is "" then
        return "Error: No text or command provided to send to terminals."
    end if
    
    -- Convert action to lowercase
    set theAction to my toLower(theAction)
    
    -- Validate action
    if theAction is not in {"broadcast", "echo", "parallel"} then
        return "Error: Invalid action. Use 'broadcast', 'echo', or 'parallel'."
    end if
    
    -- Additional validation for parallel action
    if theAction is "parallel" and (class of theText is not list or length of theText is 0) then
        return "Error: Parallel action requires a list of commands."
    end if
    
    -- Check which terminals are running
    set runningTerminals to {}
    
    tell application "System Events"
        if "Terminal" is in (name of processes) and "Terminal.app" is in theTerminals then
            set end of runningTerminals to "Terminal.app"
        end if
        if "iTerm2" is in (name of processes) and "iTerm2" is in theTerminals then
            set end of runningTerminals to "iTerm2"
        end if
        if "Ghostty" is in (name of processes) and "Ghostty" is in theTerminals then
            set end of runningTerminals to "Ghostty"
        end if
    end tell
    
    if length of runningTerminals is 0 then
        return "Error: None of the specified terminal applications are running."
    end if
    
    -- Perform the requested action
    if theAction is "broadcast" then
        return broadcastToTerminals(theText, runningTerminals, theTargets, executeCommands)
    else if theAction is "echo" then
        -- Echo is just broadcast without execution
        return broadcastToTerminals(theText, runningTerminals, theTargets, false)
    else if theAction is "parallel" then
        return runParallelCommands(theText, runningTerminals, theTargets, executeCommands)
    end if
end runWithInput

-- Function to broadcast the same text to multiple terminals
on broadcastToTerminals(textToSend, terminals, targets, shouldExecute)
    set successCount to 0
    set failCount to 0
    set resultMessage to ""
    
    -- Process Terminal.app
    if "Terminal.app" is in terminals then
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
                            
                            -- Send the text
                            tell currentTab
                                set selected of currentTab to true
                                delay 0.3
                                
                                tell application "System Events" to tell process "Terminal"
                                    keystroke textToSend
                                    if shouldExecute then keystroke return
                                end tell
                            end tell
                            
                            set successCount to successCount + 1
                            delay 0.3
                        end repeat
                    end repeat
                else
                    -- Target specific windows/tabs
                    -- Format expected: {"Terminal.app:1:2"} for window 1, tab 2
                    repeat with targetSpec in targets
                        if targetSpec starts with "Terminal.app:" then
                            set targetParts to my splitString(targetSpec, ":")
                            
                            if (count of targetParts) ≥ 3 then
                                try
                                    set windowIndex to item 2 of targetParts as integer
                                    set tabIndex to item 3 of targetParts as integer
                                    
                                    if windowIndex > 0 and windowIndex ≤ (count of windows) and tabIndex > 0 and tabIndex ≤ (count of tabs of window windowIndex) then
                                        set currentTab to tab tabIndex of window windowIndex
                                        
                                        -- Send the text
                                        tell currentTab
                                            set selected of currentTab to true
                                            delay 0.3
                                            
                                            tell application "System Events" to tell process "Terminal"
                                                keystroke textToSend
                                                if shouldExecute then keystroke return
                                            end tell
                                        end tell
                                        
                                        set successCount to successCount + 1
                                    else
                                        set failCount to failCount + 1
                                    end if
                                on error
                                    set failCount to failCount + 1
                                end try
                            end if
                        end if
                    end repeat
                end if
            end tell
        on error errMsg
            set resultMessage to resultMessage & "Error with Terminal.app: " & errMsg & "
"
            set failCount to failCount + 1
        end try
    end if
    
    -- Process iTerm2
    if "iTerm2" is in terminals then
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
                                            
                                            -- Send the text
                                            if shouldExecute then
                                                write text textToSend
                                            else
                                                -- Echo without executing
                                                tell application "System Events" to tell process "iTerm2"
                                                    keystroke textToSend
                                                end tell
                                            end if
                                            
                                            set successCount to successCount + 1
                                        end tell
                                    end repeat
                                end tell
                            end repeat
                        end tell
                    end repeat
                else
                    -- Target specific windows/tabs/sessions
                    -- Format expected: {"iTerm2:1:2:3"} for window 1, tab 2, session 3
                    repeat with targetSpec in targets
                        if targetSpec starts with "iTerm2:" then
                            set targetParts to my splitString(targetSpec, ":")
                            
                            if (count of targetParts) ≥ 4 then
                                try
                                    set windowIndex to item 2 of targetParts as integer
                                    set tabIndex to item 3 of targetParts as integer
                                    set sessionIndex to item 4 of targetParts as integer
                                    
                                    tell window windowIndex
                                        tell tab tabIndex
                                            tell session sessionIndex
                                                -- Select the session
                                                select
                                                delay 0.3
                                                
                                                -- Send the text
                                                if shouldExecute then
                                                    write text textToSend
                                                else
                                                    -- Echo without executing
                                                    tell application "System Events" to tell process "iTerm2"
                                                        keystroke textToSend
                                                    end tell
                                                end if
                                                
                                                set successCount to successCount + 1
                                            end tell
                                        end tell
                                    end tell
                                on error
                                    set failCount to failCount + 1
                                end try
                            end if
                        end if
                    end repeat
                end if
            end tell
        on error errMsg
            set resultMessage to resultMessage & "Error with iTerm2: " & errMsg & "
"
            set failCount to failCount + 1
        end try
    end if
    
    -- Process Ghostty
    if "Ghostty" is in terminals then
        try
            tell application "Ghostty"
                activate
                
                -- Ghostty doesn't have robust AppleScript support yet, so we'll use UI automation
                tell application "System Events" to tell process "Ghostty"
                    -- For simplicity, we'll just send to the active window
                    keystroke textToSend
                    if shouldExecute then keystroke return
                end tell
                
                set successCount to successCount + 1
            end tell
        on error errMsg
            set resultMessage to resultMessage & "Error with Ghostty: " & errMsg & "
"
            set failCount to failCount + 1
        end try
    end if
    
    -- Build result message
    set actionType to "Broadcast"
    if not shouldExecute then set actionType to "Echo"
    
    if successCount > 0 then
        set resultMessage to resultMessage & actionType & " successful to " & successCount & " terminal" & (if successCount = 1 then "" else "s") & ". "
    end if
    
    if failCount > 0 then
        set resultMessage to resultMessage & "Failed to reach " & failCount & " terminal" & (if failCount = 1 then "" else "s") & "."
    end if
    
    return resultMessage
end broadcastToTerminals

-- Function to run different commands in parallel across terminals
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
    
    -- Prepare target specs
    set targetSpecs to {}
    
    -- If no specific targets, build a list from available terminals
    if length of targets is 0 then
        -- Add Terminal.app targets
        if "Terminal.app" is in terminals then
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
        if "iTerm2" is in terminals then
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
        if "Ghostty" is in terminals then
            set end of targetSpecs to "Ghostty:1"
        end if
    else
        set targetSpecs to targets
    end if
    
    -- Execute commands in parallel
    set targetCount to count of targetSpecs
    set loopCount to min of commandCount and targetCount
    
    repeat with i from 1 to loopCount
        set currentTarget to item i of targetSpecs
        set currentCommand to item i of commands
        
        if currentTarget starts with "Terminal.app:" then
            try
                set targetParts to my splitString(currentTarget, ":")
                
                if (count of targetParts) ≥ 3 then
                    tell application "Terminal"
                        set windowIndex to item 2 of targetParts as integer
                        set tabIndex to item 3 of targetParts as integer
                        
                        if windowIndex > 0 and windowIndex ≤ (count of windows) and tabIndex > 0 and tabIndex ≤ (count of tabs of window windowIndex) then
                            set currentTab to tab tabIndex of window windowIndex
                            
                            -- Send the text
                            tell currentTab
                                set selected of currentTab to true
                                delay 0.3
                                
                                tell application "System Events" to tell process "Terminal"
                                    keystroke currentCommand
                                    if shouldExecute then keystroke return
                                end tell
                            end tell
                            
                            set successCount to successCount + 1
                        else
                            set failCount to failCount + 1
                        end if
                    end tell
                end if
            on error
                set failCount to failCount + 1
            end try
            
        else if currentTarget starts with "iTerm2:" then
            try
                set targetParts to my splitString(currentTarget, ":")
                
                if (count of targetParts) ≥ 4 then
                    tell application "iTerm2"
                        set windowIndex to item 2 of targetParts as integer
                        set tabIndex to item 3 of targetParts as integer
                        set sessionIndex to item 4 of targetParts as integer
                        
                        tell window windowIndex
                            tell tab tabIndex
                                tell session sessionIndex
                                    -- Select the session
                                    select
                                    delay 0.3
                                    
                                    -- Send the text
                                    if shouldExecute then
                                        write text currentCommand
                                    else
                                        -- Echo without executing
                                        tell application "System Events" to tell process "iTerm2"
                                            keystroke currentCommand
                                        end tell
                                    end if
                                    
                                    set successCount to successCount + 1
                                end tell
                            end tell
                        end tell
                    end tell
                end if
            on error
                set failCount to failCount + 1
            end try
            
        else if currentTarget starts with "Ghostty:" then
            try
                tell application "Ghostty"
                    activate
                    
                    -- Ghostty doesn't have robust AppleScript support yet, so we'll use UI automation
                    tell application "System Events" to tell process "Ghostty"
                        keystroke currentCommand
                        if shouldExecute then keystroke return
                    end tell
                    
                    set successCount to successCount + 1
                end tell
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
    
    return resultMessage
end runParallelCommands

-- Helper function to split a string
on splitString(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theItems to text items of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theItems
end splitString

-- Helper function to convert text to lowercase
on toLower(theText)
    set lowercaseText to ""
    repeat with i from 1 to length of theText
        set currentChar to character i of theText
        if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
            -- Convert uppercase letter to lowercase
            set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
        else
            -- Keep the character as is
            set lowercaseText to lowercaseText & currentChar
        end if
    end repeat
    return lowercaseText
end toLower
```

## Multi-Terminal Coordination

Coordinating actions across multiple terminal windows, tabs, or even different terminal applications can significantly improve productivity for complex workflows. This script provides tools for broadcasting commands, echoing text, and running parallel operations across your terminal environment.

### Coordination Modes

#### Broadcast Mode

The broadcast mode sends the same command or text to multiple terminal targets:

- **Use Case**: When you need to run identical commands on multiple systems
- **Benefits**: Saves time and ensures consistency across environments
- **Example Scenarios**:
  - Running the same git command across multiple project repositories
  - Updating packages on multiple servers
  - Starting the same service in different environments

#### Echo Mode

The echo mode sends text to terminals without executing commands:

- **Use Case**: When you want to prepare commands in multiple terminals before executing them
- **Benefits**: Allows review before execution, reduces the risk of errors
- **Example Scenarios**:
  - Preparing complex commands that need verification before running
  - Setting up a series of steps to execute manually
  - Preparing terminals with documentation or reference information

#### Parallel Mode

The parallel mode runs different commands on different terminals simultaneously:

- **Use Case**: When you have a series of related but different operations to perform
- **Benefits**: Executes workflows in parallel, reducing total execution time
- **Example Scenarios**:
  - Starting different components of a distributed system
  - Running database migrations while simultaneously updating application code
  - Executing a sequence of commands that don't depend on each other

### Terminal Application Support

This script supports coordination across three popular macOS terminal applications:

1. **Terminal.app**: Apple's built-in terminal application
2. **iTerm2**: A popular Terminal replacement with advanced features
3. **Ghostty**: A modern, GPU-accelerated terminal emulator

Each terminal application has different levels of AppleScript support:

- **Terminal.app**: Basic AppleScript support for window and tab manipulation
- **iTerm2**: Extensive AppleScript support for windows, tabs, and sessions
- **Ghostty**: Limited AppleScript support, requiring more UI automation

### Target Specification

You can target specific terminals, windows, tabs, or sessions using a colon-separated notation:

- **Terminal.app**: `Terminal.app:window:tab`
  - Example: `Terminal.app:1:2` for window 1, tab 2
  
- **iTerm2**: `iTerm2:window:tab:session`
  - Example: `iTerm2:1:2:3` for window 1, tab 2, session 3
  
- **Ghostty**: `Ghostty:window`
  - Example: `Ghostty:1` for window 1

If no targets are specified, the script will broadcast to all available terminals.

### Use Cases for Terminal Coordination

#### 1. DevOps and System Administration

- **Server Management**: Execute the same command across multiple server terminals
- **Configuration Updates**: Apply consistent configuration changes to multiple systems
- **Monitoring Setup**: Initialize monitoring tools across different services

#### 2. Development Workflows

- **Building Multi-Component Systems**: Start different components of a system in parallel
- **Testing**: Run different tests in separate terminals
- **Branch Management**: Execute git operations across multiple project repositories

#### 3. Batch Operations

- **Database Operations**: Run database scripts across multiple instances
- **Log Aggregation**: Start collecting logs from multiple services simultaneously
- **Deployment**: Execute deployment steps in parallel

#### 4. Teaching and Demonstrations

- **Demo Environment Setup**: Prepare multiple terminals with example commands
- **Classroom Instruction**: Show the same command executed in different environments
- **Presentation Preparation**: Set up multiple terminals for a live demonstration

### Example Usage Patterns

#### Broadcasting to All Terminals

```json
{
  "action": "broadcast",
  "text": "git pull",
  "executeCommands": true
}
```

This will send `git pull` to all open terminals and execute it.

#### Parallel Commands Across Different Projects

```json
{
  "action": "parallel",
  "text": [
    "cd ~/Projects/frontend && npm start",
    "cd ~/Projects/backend && npm run server",
    "cd ~/Projects/database && docker-compose up"
  ],
  "terminals": ["iTerm2"],
  "executeCommands": true
}
```

This will start three different components of a system in parallel in iTerm2.

#### Preparing Multiple Terminals for a Complex Operation

```json
{
  "action": "echo",
  "text": "sudo systemctl restart nginx",
  "targets": ["Terminal.app:1:1", "Terminal.app:1:2"]
}
```

This will prepare two tabs with the same command, allowing you to verify before manually executing.

### Security and Permissions Considerations

Before using this script:

1. **Accessibility Permissions**: Ensure terminal applications are granted accessibility permissions
2. **Command Verification**: Be careful with broadcast mode, as it will execute commands immediately
3. **Secure Environment**: Be mindful of broadcasting commands that might contain sensitive information

For safety-critical operations, consider using echo mode first to verify commands before execution.
