---
id: ghostty_automation
title: Automate Ghostty Terminal
description: Controls and automates the Ghostty terminal emulator
language: applescript
author: Claude
keywords:
  - terminal
  - ghostty
  - automation
  - workflow
  - command-line
usage_examples:
  - Open Ghostty terminal with specific commands
  - Create a multi-pane Ghostty workspace
  - Integrate Ghostty with Alfred workflows
parameters:
  - name: command
    description: Command to execute in Ghostty
    required: false
  - name: workDir
    description: Working directory to start in
    required: false
category: 06_terminal/ghostty
---

# Automate Ghostty Terminal

This script automates interactions with the Ghostty terminal emulator, a fast, feature-rich, and GPU-accelerated terminal for macOS.

```applescript
on run {input, parameters}
    set command to "--MCP_INPUT:command"
    set workDir to "--MCP_INPUT:workDir"
    
    -- Set default working directory if not specified
    if workDir is "" or workDir is missing value then
        set workDir to "~"
    end if
    
    -- Check if Ghostty is installed
    try
        do shell script "osascript -e 'exists application \"Ghostty\"'"
    on error
        display dialog "Ghostty terminal application is not installed on this system." buttons {"OK"} default button "OK" with icon stop
        return
    end try
    
    -- Launch Ghostty and execute command if provided
    tell application "Ghostty"
        activate
    end tell
    
    -- Allow time for Ghostty to launch
    delay 0.5
    
    -- Change to working directory
    if workDir is not "~" then
        sendTextToGhostty("cd " & workDir)
    end if
    
    -- Execute command if provided
    if command is not "" and command is not missing value then
        sendTextToGhostty(command)
    end if
    
    return "Ghostty terminal opened" & (if command is not "" and command is not missing value then " and executed: " & command else "")
end run

-- Helper function to send text to Ghostty
on sendTextToGhostty(text_to_send)
    tell application "System Events"
        tell process "Ghostty"
            set frontmost to true
            delay 0.3
            keystroke text_to_send
            keystroke return
        end tell
    end tell
end sendTextToGhostty
```

## About Ghostty Terminal

Ghostty is a modern terminal emulator that uses platform-native UI and GPU acceleration. It's designed to be fast, feature-rich, and cross-platform while maintaining native UI elements. Key features include:

- GPU-accelerated rendering for smooth performance
- Cross-platform support (macOS, Linux, Windows)
- Native UI integration
- Extensive customization options
- Swift integration on macOS

## Advanced Usage

### Multi-Pane Setup

To create a multi-pane Ghostty environment, you can extend this script to send the appropriate keyboard shortcuts for splitting panes:

```applescript
on createMultiPaneEnvironment()
    tell application "Ghostty"
        activate
    end tell
    
    delay 0.5
    
    -- Split horizontally (uses default Ghostty shortcuts)
    tell application "System Events"
        tell process "Ghostty"
            keystroke "d" using {shift down, command down}
            delay 0.3
            
            -- Split vertically in the right pane
            keystroke "d" using {command down}
            delay 0.3
            
            -- Go back to first pane
            keystroke "[" using {command down, option down}
        end tell
    end tell
end createMultiPaneEnvironment
```

### Alfred Integration

Ghostty can be integrated with Alfred using AppleScript. This allows you to create powerful workflows that launch Ghostty with specific configurations:

```applescript
on alfredRun(query)
    -- Parse the query into command components
    set command_parts to my splitString(query, " ")
    set cmd_name to item 1 of command_parts
    
    if cmd_name is "ssh" and (count of command_parts) > 1 then
        set server to item 2 of command_parts
        tell application "Ghostty"
            activate
        end tell
        delay 0.5
        sendTextToGhostty("ssh " & server)
    else if cmd_name is "project" and (count of command_parts) > 1 then
        set project_name to item 2 of command_parts
        set project_path to "~/Projects/" & project_name
        tell application "Ghostty"
            activate
        end tell
        delay 0.5
        sendTextToGhostty("cd " & project_path)
    end if
end alfredRun

on splitString(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theArray to every text item of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theArray
end splitString
```

## Configuration Options

Ghostty has extensive configuration options that can be managed through its config file, typically located at `~/.config/ghostty/config`. While these settings can't be changed directly through AppleScript, you can create and switch between configurations:

```applescript
on switchGhosttyConfig(configName)
    set configDir to (POSIX path of (path to home folder)) & ".config/ghostty/configs/"
    set targetConfig to configDir & configName & ".conf"
    set mainConfig to (POSIX path of (path to home folder)) & ".config/ghostty/config"
    
    try
        -- Check if the config exists
        do shell script "test -f " & quoted form of targetConfig
        
        -- Create a symbolic link to the config
        do shell script "ln -sf " & quoted form of targetConfig & " " & quoted form of mainConfig
        
        -- Restart Ghostty for the changes to take effect
        tell application "Ghostty" to quit
        delay 1
        tell application "Ghostty" to activate
        
        return "Switched to Ghostty config: " & configName
    on error
        return "Error: Config file " & configName & ".conf not found"
    end try
end switchGhosttyConfig
```

## macOS Integration

Ghostty integrates with Swift for its macOS implementation, leveraging native frameworks for optimal performance. This integration allows for:

1. Native window management
2. Smooth animations and rendering
3. Better system resource management
4. Support for macOS features like Secure Input

## Note on Permissions

For full automation, Ghostty needs accessibility permissions:

1. Open System Preferences > Security & Privacy > Privacy > Accessibility
2. Add Ghostty and any apps that will control it (like Script Editor or Alfred)
3. Ensure "Secure Input" is not active when automating keyboard entry
