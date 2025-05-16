---
title: VMware Fusion VM Controller
description: AppleScript for managing VMware Fusion virtual machines - list, start, stop, and check VM status
keywords: [vmware, fusion, vm, virtual machine, controller, automation]
language: applescript
isComplex: false
---

# VMware Fusion VM Controller

This script provides a comprehensive interface for controlling VMware Fusion virtual machines on macOS. It allows users to list available VMs, start or stop VMs, and check their current status.

## Features

- Check if VMware Fusion is installed on the system
- List all available virtual machines
- Start a specific virtual machine
- Stop, suspend, or power off a running VM
- Check the current status of virtual machines
- Interactive user interface for VM management

## Script

```applescript
#!/usr/bin/osascript
(*
    VMware Fusion Controller
    
    This script demonstrates how to interact with VMware Fusion on macOS.
    It provides functionality to:
    - List all available virtual machines
    - Start a specific virtual machine
    - Stop/suspend a virtual machine
    - Check virtual machine status
    
    Requirements:
    - VMware Fusion installed
    - Appropriate permissions for automation
*)

-- Global properties
property appName : "VMware Fusion"
property appProcessName : "VMware Fusion"
property vmLibraryLocation : (path to home folder as text) & "Virtual Machines:"

-- Main handler to demonstrate functionality
on run
    try
        log "Starting VMware Fusion Controller..."
        
        -- Check if VMware Fusion is installed
        if not applicationIsInstalled(appName) then
            display dialog "VMware Fusion is not installed on this system." buttons {"OK"} default button "OK" with icon stop
            return
        end if
        
        -- List available VMs
        log "Listing available virtual machines..."
        set vmList to listVirtualMachines()
        
        if (count of vmList) is 0 then
            display dialog "No virtual machines found." buttons {"OK"} default button "OK"
            return
        end if
        
        -- Display list of VMs and let user select one
        set selectedVM to chooseVM(vmList)
        if selectedVM is false then return
        
        -- Main control interface for the selected VM
        controlVM(selectedVM)
        
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

-- Lists available virtual machines
on listVirtualMachines()
    set vmList to {}
    
    try
        -- Method 1: Through VMware Fusion application if supported
        tell application appName
            try
                -- This will work if VMware Fusion has a proper AppleScript dictionary with VM listing
                set vmList to get virtual machines
                return vmList
            on error
                -- If the above fails, we'll use file system instead
                log "Could not get VM list through application directly. Using file system instead."
            end try
        end tell
        
        -- Method 2: Use file system to find .vmwarevm bundles
        set vmFolders to {}
        
        -- Try to find VMs in standard location
        try
            set vmFolders to paragraphs of (do shell script "find \"" & POSIX path of vmLibraryLocation & "\" -name \"*.vmwarevm\" -type d -maxdepth 2")
        on error
            log "Could not search standard VM location. Trying home directory..."
            
            -- Try to find VMs in user's home directory
            try
                set homeFolder to POSIX path of (path to home folder)
                set vmFolders to paragraphs of (do shell script "find \"" & homeFolder & "\" -name \"*.vmwarevm\" -type d -maxdepth 3")
            on error
                log "Could not find VMs in home directory."
            end try
        end try
        
        -- Process found VM folders
        repeat with vmPath in vmFolders
            if vmPath is not "" then
                -- Extract VM name from path
                set AppleScript's text item delimiters to "/"
                set pathItems to text items of vmPath
                set vmName to item (count of pathItems) of pathItems
                set AppleScript's text item delimiters to ".vmwarevm"
                set vmName to text item 1 of vmName
                set AppleScript's text item delimiters to ""
                
                -- Add to our list with both name and path
                set end of vmList to {name:vmName, path:vmPath}
            end if
        end repeat
        
        return vmList
        
    on error errMsg number errNum
        log "Error listing VMs: " & errMsg & " (" & errNum & ")"
        return {}
    end try
end listVirtualMachines

-- Let user choose a VM from the list
on chooseVM(vmList)
    try
        set vmNames to {}
        repeat with vm in vmList
            if class of vm is record then
                set end of vmNames to vm's name
            else
                -- If vmList contains direct VM objects from the app
                try
                    set end of vmNames to get name of vm
                on error
                    set end of vmNames to "Unknown VM"
                end try
            end if
        end repeat
        
        set selectedVM to choose from list vmNames with prompt "Select a Virtual Machine:" default items (item 1 of vmNames)
        
        if selectedVM is false then
            return false
        else
            set selectedVMName to item 1 of selectedVM
            
            repeat with vm in vmList
                if class of vm is record then
                    if vm's name is selectedVMName then
                        return vm
                    end if
                else
                    try
                        if (get name of vm) is selectedVMName then
                            return vm
                        end if
                    on error
                        -- Skip this VM if we can't get its name
                    end try
                end if
            end repeat
        end if
        
        -- If we get here, something went wrong
        display dialog "Could not find the selected VM in the list." buttons {"OK"} default button "OK" with icon stop
        return false
        
    on error errMsg number errNum
        log "Error choosing VM: " & errMsg & " (" & errNum & ")"
        return false
    end try
end chooseVM

-- Control a specific virtual machine
on controlVM(vm)
    try
        set vmName to ""
        set vmPath to ""
        
        -- Determine VM details based on the type
        if class of vm is record then
            set vmName to vm's name
            set vmPath to vm's path
        else
            -- If vm is a direct reference from the app
            try
                set vmName to get name of vm
            on error
                set vmName to "Unknown VM"
            end try
        end if
        
        set vmStatus to getVMStatus(vm)
        
        -- Main control loop
        repeat
            set statusText to "Current Status: " & vmStatus
            set actionButton to "Start VM"
            
            if vmStatus contains "running" then
                set actionButton to "Stop VM"
            else if vmStatus contains "suspended" then
                set actionButton to "Resume VM"
            end if
            
            set userChoice to button returned of (display dialog "VM: " & vmName & return & statusText buttons {"Refresh Status", actionButton, "Cancel"} default button 2)
            
            if userChoice is "Refresh Status" then
                set vmStatus to getVMStatus(vm)
            else if userChoice is "Start VM" then
                startVM(vm)
                delay 2
                set vmStatus to getVMStatus(vm)
            else if userChoice is "Stop VM" then
                set stopOptions to button returned of (display dialog "How do you want to stop the VM?" buttons {"Shut Down", "Suspend", "Power Off", "Cancel"} default button 1)
                
                if stopOptions is "Shut Down" then
                    shutdownVM(vm)
                else if stopOptions is "Suspend" then
                    suspendVM(vm)
                else if stopOptions is "Power Off" then
                    powerOffVM(vm)
                end if
                
                delay 2
                set vmStatus to getVMStatus(vm)
            else if userChoice is "Resume VM" then
                startVM(vm)
                delay 2
                set vmStatus to getVMStatus(vm)
            else
                -- User chose Cancel
                exit repeat
            end if
        end repeat
        
    on error errMsg number errNum
        log "Error controlling VM: " & errMsg & " (" & errNum & ")"
        display dialog "An error occurred while controlling the VM: " & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end controlVM

-- Get the status of a VM
on getVMStatus(vm)
    try
        -- Try to get status through app if possible
        if class of vm is not record then
            tell application appName
                try
                    set vmState to get state of vm
                    return vmState as text
                on error
                    -- If direct status check fails, continue with alternative methods
                end try
            end tell
        end if
        
        -- Use UI scripting as fallback
        tell application appName
            activate
            delay 1
            
            -- Try to find if this VM is mentioned in window title
            set vmName to ""
            if class of vm is record then
                set vmName to vm's name
            else
                try
                    set vmName to get name of vm
                on error
                    set vmName to "Unknown"
                end try
            end if
            
            -- Look for running status in window titles
            try
                tell application "System Events"
                    set allWindows to windows of process appProcessName
                    repeat with aWindow in allWindows
                        set winTitle to name of aWindow
                        if winTitle contains vmName then
                            if winTitle contains "[Running]" then
                                return "running"
                            else if winTitle contains "[Suspended]" then
                                return "suspended"
                            else
                                return "unknown (window found)"
                            end if
                        end if
                    end repeat
                end tell
            on error
                log "Error checking window titles"
            end try
            
            -- If we get here, either VM is not running or we couldn't determine status
            return "powered off or unavailable"
        end tell
        
    on error errMsg number errNum
        log "Error getting VM status: " & errMsg & " (" & errNum & ")"
        return "error checking status"
    end try
end getVMStatus

-- Start a VM
on startVM(vm)
    try
        -- Try to start via app if possible
        if class of vm is not record then
            tell application appName
                try
                    start vm
                    return true
                on error
                    -- If direct start fails, continue with alternative methods
                end try
            end tell
        end if
        
        -- Use UI scripting as fallback
        tell application appName
            activate
            delay 1
            
            if class of vm is record then
                -- Try to open VM from file
                try
                    set vmPath to vm's path
                    do shell script "open \"" & vmPath & "\""
                    delay 2
                    
                    -- Click the "Start Up" button if needed
                    tell application "System Events"
                        repeat 5 times -- try a few times
                            try
                                if exists button "Start Up" of window 1 of process appProcessName then
                                    click button "Start Up" of window 1 of process appProcessName
                                    exit repeat
                                end if
                            on error
                                -- Button might not be visible yet
                            end try
                            delay 1
                        end repeat
                    end tell
                    
                    return true
                on error errMsg
                    log "Error starting VM from file: " & errMsg
                end try
            end if
            
            -- Additional approaches could be added here
            
            return false
        end tell
        
    on error errMsg number errNum
        log "Error starting VM: " & errMsg & " (" & errNum & ")"
        display dialog "Error starting VM: " & errMsg buttons {"OK"} default button "OK" with icon stop
        return false
    end try
end startVM

-- Shut down a VM (graceful)
on shutdownVM(vm)
    try
        -- Try to shut down via app if possible
        if class of vm is not record then
            tell application appName
                try
                    shut down vm
                    return true
                on error
                    -- If direct shutdown fails, continue with alternative methods
                end try
            end tell
        end if
        
        -- Use UI scripting as fallback
        tell application appName
            activate
            delay 1
            
            tell application "System Events"
                try
                    -- Try to use menu items
                    click menu item "Shut Down Guest" of menu "Virtual Machine" of menu bar 1 of process appProcessName
                    
                    -- Handle confirmation dialog if it appears
                    delay 1
                    if exists button "Shut Down" of sheet 1 of window 1 of process appProcessName then
                        click button "Shut Down" of sheet 1 of window 1 of process appProcessName
                    end if
                    
                    return true
                on error errMsg
                    log "UI scripting error for shutdown: " & errMsg
                end try
            end tell
            
            return false
        end tell
        
    on error errMsg number errNum
        log "Error shutting down VM: " & errMsg & " (" & errNum & ")"
        display dialog "Error shutting down VM: " & errMsg buttons {"OK"} default button "OK" with icon stop
        return false
    end try
end shutdownVM

-- Suspend a VM
on suspendVM(vm)
    try
        -- Try to suspend via app if possible
        if class of vm is not record then
            tell application appName
                try
                    suspend vm
                    return true
                on error
                    -- If direct suspend fails, continue with alternative methods
                end try
            end tell
        end if
        
        -- Use UI scripting as fallback
        tell application appName
            activate
            delay 1
            
            tell application "System Events"
                try
                    -- Try to use menu items
                    click menu item "Suspend" of menu "Virtual Machine" of menu bar 1 of process appProcessName
                    return true
                on error errMsg
                    log "UI scripting error for suspend: " & errMsg
                end try
            end tell
            
            return false
        end tell
        
    on error errMsg number errNum
        log "Error suspending VM: " & errMsg & " (" & errNum & ")"
        display dialog "Error suspending VM: " & errMsg buttons {"OK"} default button "OK" with icon stop
        return false
    end try
end suspendVM

-- Hard power off a VM
on powerOffVM(vm)
    try
        -- Try to power off via app if possible
        if class of vm is not record then
            tell application appName
                try
                    stop vm
                    return true
                on error
                    -- If direct power off fails, continue with alternative methods
                end try
            end tell
        end if
        
        -- Use UI scripting as fallback
        tell application appName
            activate
            delay 1
            
            tell application "System Events"
                try
                    -- Try to use menu items
                    click menu item "Power Off" of menu "Virtual Machine" of menu bar 1 of process appProcessName
                    
                    -- Handle confirmation dialog if it appears
                    delay 1
                    if exists button "Power Off" of sheet 1 of window 1 of process appProcessName then
                        click button "Power Off" of sheet 1 of window 1 of process appProcessName
                    end if
                    
                    return true
                on error errMsg
                    log "UI scripting error for power off: " & errMsg
                end try
            end tell
            
            return false
        end tell
        
    on error errMsg number errNum
        log "Error powering off VM: " & errMsg & " (" & errNum & ")"
        display dialog "Error powering off VM: " & errMsg buttons {"OK"} default button "OK" with icon stop
        return false
    end try
end powerOffVM
```

## Usage

This script provides a comprehensive user interface for managing VMware Fusion virtual machines:

1. When run, it first checks if VMware Fusion is installed
2. Lists all available virtual machines (searching in standard locations)
3. Allows the user to select a VM to manage
4. Presents options to start, stop (with shutdown, suspend, or power off options), or check the status of the VM

The individual handler functions can also be used independently in other scripts for automated VM management.

## Requirements

- VMware Fusion installed
- macOS 10.10 or later
- Appropriate permissions for automation and UI scripting
