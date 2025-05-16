---
title: Parallels Desktop VM Controller
description: >-
  Script for managing Parallels Desktop virtual machines - list, start, stop,
  and check VM status
keywords:
  - parallels
  - desktop
  - vm
  - virtual machine
  - controller
  - automation
language: applescript
isComplex: false
category: 13_developer
---

# Parallels Desktop VM Controller

This script provides a comprehensive interface for controlling Parallels Desktop virtual machines on macOS. It allows users to list available VMs, start/stop/suspend VMs, and check their current status.

## Features

- Check if Parallels Desktop is installed on the system
- List all available virtual machines
- Start a specific virtual machine
- Stop or power off a running VM
- Gracefully shut down a running VM
- Suspend a running VM (save state)
- Check the current status of virtual machines
- Interactive user interface for VM management

## Script

```applescript
#!/usr/bin/osascript
(*
    Parallels Desktop VM Controller
    
    This script demonstrates how to interact with Parallels Desktop on macOS.
    It provides functionality to:
    - List all available virtual machines
    - Start a specific virtual machine
    - Stop/shutdown a virtual machine
    - Suspend a virtual machine
    - Check virtual machine status
    
    Requirements:
    - Parallels Desktop installed
    - Appropriate permissions for automation
*)

-- Main handler to demonstrate functionality
on run
    try
        log "Starting Parallels Desktop Controller..."
        
        -- Check if Parallels Desktop is installed
        if not applicationIsInstalled("Parallels Desktop") then
            display dialog "Parallels Desktop is not installed on this system." buttons {"OK"} default button "OK" with icon stop
            return
        end if
        
        -- Demonstrate functionality through interactive menu
        showMainMenu()
        
    on error errMsg number errNum
        log "Error in main handler: " & errMsg & " (" & errNum & ")"
        display dialog "An error occurred: " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end run

-- Check if an application is installed
on applicationIsInstalled(appNameToCheck)
    try
        do shell script "osascript -e 'exists application \"" & appNameToCheck & "\"'"
        return true
    on error
        return false
    end try
end applicationIsInstalled

-- Main menu for interactive operation
on showMainMenu()
    set continueRunning to true
    
    repeat while continueRunning
        set userChoice to button returned of (display dialog "Parallels Desktop Controller" & return & return & "Select an operation:" buttons {"List VMs", "VM Operations", "Quit"} default button 1)
        
        if userChoice is "List VMs" then
            set vmList to listVirtualMachines()
            set vmDisplay to ""
            
            repeat with i from 1 to count of vmList
                set thisVM to item i of vmList
                set vmDisplay to vmDisplay & i & ". " & (name of thisVM) & " - " & (state of thisVM) & return
            end repeat
            
            if vmDisplay is "" then
                set vmDisplay to "No virtual machines found."
            end if
            
            display dialog "Virtual Machines:" & return & return & vmDisplay buttons {"OK"} default button "OK"
            
        else if userChoice is "VM Operations" then
            set vmList to listVirtualMachines()
            
            if (count of vmList) is 0 then
                display dialog "No virtual machines available." buttons {"OK"} default button "OK"
            else
                set vmNames to {}
                repeat with vm in vmList
                    set end of vmNames to (name of vm) & " (" & (state of vm) & ")"
                end repeat
                
                set selectedVM to choose from list vmNames with prompt "Select a Virtual Machine:" default items (item 1 of vmNames)
                
                if selectedVM is not false then
                    set vmName to extractVMName(item 1 of selectedVM)
                    vmOperationsMenu(vmName)
                end if
            end if
            
        else if userChoice is "Quit" then
            set continueRunning to false
        end if
    end repeat
end showMainMenu

-- Extract VM name from display string "Name (state)"
on extractVMName(vmDisplayString)
    set AppleScript's text item delimiters to " ("
    set vmName to text item 1 of vmDisplayString
    set AppleScript's text item delimiters to ""
    return vmName
end extractVMName

-- Menu for operations on a specific VM
on vmOperationsMenu(vmName)
    set continueVMOps to true
    
    repeat while continueVMOps
        -- Get current status
        set vmStatus to ""
        try
            tell application "Parallels Desktop"
                set targetVM to virtual machine vmName
                set vmStatus to state of targetVM as text
            end tell
        on error
            set vmStatus to "unknown"
        end try
        
        -- Show appropriate options based on current state
        set allButtons to {"Start", "Stop", "Suspend", "Refresh Status", "Back"}
        set enabledButtons to {}
        set defaultButton to "Refresh Status"
        
        if vmStatus is "running" then
            set enabledButtons to {"Stop", "Suspend", "Refresh Status", "Back"}
            set defaultButton to "Stop"
        else if vmStatus is "suspended" or vmStatus is "stopped" or vmStatus is "paused" then
            set enabledButtons to {"Start", "Refresh Status", "Back"}
            set defaultButton to "Start"
        else
            set enabledButtons to {"Start", "Refresh Status", "Back"}
            set defaultButton to "Refresh Status"
        end if
        
        set userChoice to button returned of (display dialog "VM: " & vmName & return & "Status: " & vmStatus buttons enabledButtons default button defaultButton)
        
        if userChoice is "Start" then
            startVM(vmName)
        else if userChoice is "Stop" then
            set stopType to button returned of (display dialog "How do you want to stop the VM?" buttons {"Shut Down", "Power Off", "Cancel"} default button 1)
            
            if stopType is "Shut Down" then
                shutdownVM(vmName)
            else if stopType is "Power Off" then
                stopVM(vmName)
            end if
        else if userChoice is "Suspend" then
            suspendVM(vmName)
        else if userChoice is "Back" then
            set continueVMOps to false
        end if
    end repeat
end vmOperationsMenu

-- Lists all available virtual machines
on listVirtualMachines()
    try
        tell application "Parallels Desktop"
            return every virtual machine
        end tell
    on error errMsg
        log "Failed to list virtual machines: " & errMsg
        return {}
    end try
end listVirtualMachines

-- Starts a VM
on startVM(vmName)
    try
        tell application "Parallels Desktop"
            set targetVM to virtual machine vmName
            
            -- Only start if not already running
            if state of targetVM is not running then
                display dialog "Starting virtual machine '" & vmName & "'..." buttons {"OK"} default button "OK"
                start targetVM
            else
                display dialog "Virtual machine '" & vmName & "' is already running." buttons {"OK"} default button "OK"
            end if
        end tell
    on error errMsg
        log "Failed to start '" & vmName & "': " & errMsg
        display dialog "Failed to start '" & vmName & "': " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end startVM

-- Stops a VM (power off)
on stopVM(vmName)
    try
        tell application "Parallels Desktop"
            set targetVM to virtual machine vmName
            
            -- Only stop if running
            if state of targetVM is running then
                display dialog "Powering off virtual machine '" & vmName & "'..." buttons {"OK"} default button "OK"
                stop targetVM with force
            else
                display dialog "Virtual machine '" & vmName & "' is not running." buttons {"OK"} default button "OK"
            end if
        end tell
    on error errMsg
        log "Failed to stop '" & vmName & "': " & errMsg
        display dialog "Failed to stop '" & vmName & "': " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end stopVM

-- Gracefully shuts down a VM
on shutdownVM(vmName)
    try
        tell application "Parallels Desktop"
            set targetVM to virtual machine vmName
            
            -- Only shutdown if running
            if state of targetVM is running then
                display dialog "Shutting down virtual machine '" & vmName & "'..." buttons {"OK"} default button "OK"
                
                -- Try to shutdown gracefully
                try
                    -- First try to use Parallels' API
                    stop targetVM without force
                on error
                    -- If that fails, try to send a shutdown command to guest OS
                    try
                        -- For Windows guests
                        execute command "shutdown /s /t 0" in targetVM
                    on error
                        -- For Linux/macOS guests
                        try
                            execute command "sudo shutdown -h now" in targetVM
                        on error
                            -- Last resort: force stop
                            stop targetVM with force
                        end try
                    end try
                end try
            else
                display dialog "Virtual machine '" & vmName & "' is not running." buttons {"OK"} default button "OK"
            end if
        end tell
    on error errMsg
        log "Failed to shutdown '" & vmName & "': " & errMsg
        display dialog "Failed to shutdown '" & vmName & "': " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end shutdownVM

-- Suspends a VM (save state)
on suspendVM(vmName)
    try
        tell application "Parallels Desktop"
            set targetVM to virtual machine vmName
            
            -- Only suspend if running
            if state of targetVM is running then
                display dialog "Suspending virtual machine '" & vmName & "'..." buttons {"OK"} default button "OK"
                suspend targetVM
            else
                display dialog "Virtual machine '" & vmName & "' is not running." buttons {"OK"} default button "OK"
            end if
        end tell
    on error errMsg
        log "Failed to suspend '" & vmName & "': " & errMsg
        display dialog "Failed to suspend '" & vmName & "': " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end suspendVM

-- Advanced VM operations (could be expanded)
on advancedVMOperations(vmName)
    try
        tell application "Parallels Desktop"
            set targetVM to virtual machine vmName
            
            -- Examples of advanced operations:
            
            -- 1. Get VM configuration properties
            set vmCPU to cpu count of configuration of targetVM
            set vmMemory to memory size of configuration of targetVM
            
            -- 2. Take a screenshot of the VM
            -- set screenshotPath to (path to desktop folder as text) & "vm_screenshot.png"
            -- execute command "screencapture -x " & screenshotPath in targetVM
            
            -- 3. Get VM network information
            -- set vmIPAddress to execute command "ipconfig getifaddr en0" in targetVM
            
            return "VM Configuration:" & return & "CPU: " & vmCPU & " cores" & return & "Memory: " & vmMemory & " MB"
        end tell
    on error errMsg
        log "Failed to perform advanced operations on '" & vmName & "': " & errMsg
        return "Error: " & errMsg
    end try
end advancedVMOperations
```

## Usage

This script provides a complete user interface for managing Parallels Desktop virtual machines:

1. When run, it first checks if Parallels Desktop is installed
2. Presents a main menu with options to list all VMs or perform operations on a specific VM
3. For VM operations, it presents contextual options based on the VM's current state:
   - For running VMs: Stop, Suspend
   - For stopped/suspended VMs: Start
4. When stopping a VM, it offers graceful shutdown or immediate power off options

The script takes advantage of Parallels Desktop's AppleScript support to directly control VMs without requiring UI scripting.

## Requirements

- Parallels Desktop installed
- macOS 10.10 or later
- Appropriate permissions for automation
