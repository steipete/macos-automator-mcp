---
id: virtualbuddy_controller
title: VirtualBuddy VM Controller
description: Script to manage VirtualBuddy macOS virtual machines - list, start, stop, and check status of VMs.
language: applescript
compatibility: macOS Sonoma, Ventura, Monterey
author: Claude
tags: [virtualbuddy, virtualization, macOS, virtual machines, vms]
keywords: [virtualbuddy, macOS, VM, virtual machine, management, UI automation, system events, start VM, stop VM]
guide: |
  This script provides a UI-based interface for controlling VirtualBuddy virtual machines on macOS.
  
  It demonstrates:
  1. Using UI scripting to interact with the VirtualBuddy application
  2. Listing available virtual machines
  3. Starting a specific virtual machine
  4. Stopping a virtual machine
  5. Checking VM status
  6. Error handling for all operations
  
  The script uses System Events for UI automation since VirtualBuddy doesn't expose 
  an AppleScript dictionary directly.
  
  To use this script:
  1. Run it directly
  2. Select an operation from the menu
  3. Choose a VM from the list when prompted
  
  Requirements:
  - VirtualBuddy app installed
  - Appropriate macOS permissions for automation and accessibility (System Settings > Privacy & Security)
sample_snippets:
  - title: List virtual machines
    snippet: |
      -- Handler to list all VMs in VirtualBuddy
      on listVirtualMachines()
          try
              set vmList to {}
              
              -- Launch VirtualBuddy if it's not already running
              tell application "VirtualBuddy" to activate
              delay 1 -- Give the app time to initialize
              
              tell application "System Events"
                  tell process "VirtualBuddy"
                      -- Get VM names from table view in main window
                      if exists table 1 of scroll area 1 of window 1 then
                          set vmRows to rows of table 1 of scroll area 1 of window 1
                          repeat with eachRow in vmRows
                              set vmName to value of text field 1 of eachRow as text
                              set end of vmList to vmName
                          end repeat
                      end if
                  end tell
              end tell
              
              if vmList is {} then
                  display dialog "No virtual machines found." buttons {"OK"} default button "OK" with icon note
              else
                  set formattedList to "Virtual Machines:" & return & return
                  repeat with i from 1 to count of vmList
                      set formattedList to formattedList & "• " & item i of vmList & return
                  end repeat
                  
                  display dialog formattedList buttons {"OK"} default button "OK" with icon note
              end if
              
              return vmList
              
          on error errMsg number errNum
              logError("Error listing VMs", errMsg, errNum)
              return {}
          end try
      end listVirtualMachines
  - title: Start a virtual machine
    snippet: |
      -- Handler to start a VM by name
      on startVirtualMachine(vmName)
          try
              tell application "VirtualBuddy" to activate
              delay 1
              
              -- Check if VM is already running
              if isVirtualMachineRunning(vmName) then
                  display dialog "VM \"" & vmName & "\" is already running." buttons {"OK"} default button "OK" with icon note
                  return
              end if
              
              tell application "System Events"
                  tell process "VirtualBuddy"
                      -- Find and select the VM in the list
                      if exists table 1 of scroll area 1 of window 1 then
                          set vmRows to rows of table 1 of scroll area 1 of window 1
                          repeat with eachRow in vmRows
                              if value of text field 1 of eachRow as text is vmName then
                                  select eachRow
                                  exit repeat
                              end if
                          end repeat
                      end if
                      
                      -- Click the "Start" button
                      if exists button "Start" of window 1 then
                          click button "Start" of window 1
                          display dialog "Starting VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
                      else
                          -- Try secondary method - click Start from toolbar
                          try
                              click button 1 of toolbar 1 of window 1
                              display dialog "Starting VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
                          on error
                              display dialog "Could not find Start button for VM \"" & vmName & "\"." buttons {"OK"} default button "OK" with icon stop
                          end try
                      end if
                  end tell
              end tell
              
          on error errMsg number errNum
              logError("Error starting VM: " & vmName, errMsg, errNum)
          end try
      end startVirtualMachine
  - title: Stop a virtual machine
    snippet: |
      -- Handler to stop a VM by name
      on stopVirtualMachine(vmName)
          try
              tell application "VirtualBuddy" to activate
              delay 1
              
              -- Check if VM is running
              if not isVirtualMachineRunning(vmName) then
                  display dialog "VM \"" & vmName & "\" is not running." buttons {"OK"} default button "OK" with icon note
                  return
              end if
              
              tell application "System Events"
                  tell process "VirtualBuddy"
                      -- Find and select the VM in the list
                      if exists table 1 of scroll area 1 of window 1 then
                          set vmRows to rows of table 1 of scroll area 1 of window 1
                          repeat with eachRow in vmRows
                              if value of text field 1 of eachRow as text is vmName then
                                  select eachRow
                                  exit repeat
                              end if
                          end repeat
                      end if
                      
                      -- Try to find the Stop button (might be labeled "Shut Down" or have an icon)
                      if exists button "Stop" of window 1 then
                          click button "Stop" of window 1
                      else if exists button "Shut Down" of window 1 then
                          click button "Shut Down" of window 1
                      else
                          -- Try secondary method - click Stop from toolbar (usually second button)
                          try
                              click button 2 of toolbar 1 of window 1
                          on error
                              display dialog "Could not find Stop button for VM \"" & vmName & "\"." buttons {"OK"} default button "OK" with icon stop
                              return
                          end try
                      end if
                      
                      -- Handle confirmation dialog if it appears
                      delay 1
                      if exists sheet 1 of window 1 then
                          if exists button "Shut Down" of sheet 1 of window 1 then
                              click button "Shut Down" of sheet 1 of window 1
                          else if exists button "Force Shut Down" of sheet 1 of window 1 then
                              click button "Force Shut Down" of sheet 1 of window 1
                          end if
                      end if
                      
                      display dialog "Stopping VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
                  end tell
              end tell
              
          on error errMsg number errNum
              logError("Error stopping VM: " & vmName, errMsg, errNum)
          end try
      end stopVirtualMachine
  - title: Check if a VM is running
    snippet: |
      -- Helper handler to check if a VM is running
      on isVirtualMachineRunning(vmName)
          try
              tell application "VirtualBuddy" to activate
              delay 1
              
              set isRunning to false
              
              tell application "System Events"
                  tell process "VirtualBuddy"
                      -- Find the VM in the list
                      if exists table 1 of scroll area 1 of window 1 then
                          set vmRows to rows of table 1 of scroll area 1 of window 1
                          repeat with eachRow in vmRows
                              if value of text field 1 of eachRow as text is vmName then
                                  -- Look for "Running" text in the status column (typically column 2)
                                  try
                                      set status to value of text field 2 of eachRow as text
                                      if status contains "Running" then
                                          set isRunning to true
                                      end if
                                  on error
                                      -- Alternative: Check if Stop button is enabled (only when VM is running)
                                      select eachRow
                                      delay 0.5
                                      if exists button "Stop" of window 1 then
                                          if enabled of button "Stop" of window 1 then
                                              set isRunning to true
                                          end if
                                      else if exists button "Shut Down" of window 1 then
                                          if enabled of button "Shut Down" of window 1 then
                                              set isRunning to true
                                          end if
                                      end if
                                  end try
                                  exit repeat
                              end if
                          end repeat
                      end if
                  end tell
              end tell
              
              return isRunning
              
          on error errMsg number errNum
              logError("Error checking if VM is running: " & vmName, errMsg, errNum)
              return false
          end try
      end isVirtualMachineRunning
---

```applescript
-- VirtualBuddy Automation Script
-- This script demonstrates how to interact with VirtualBuddy application
-- to manage macOS virtual machines

-- Set error handling to use try/on error blocks
use scripting additions
use framework "Foundation"

-- Main handler for VirtualBuddy operations
on run
    try
        -- Check if VirtualBuddy is installed
        if not applicationIsInstalled("VirtualBuddy") then
            display dialog "VirtualBuddy is not installed on this system." buttons {"OK"} default button "OK" with icon stop
            return
        end if
        
        -- Main menu for the script
        set actionChoice to choose from list {"List VMs", "Start VM", "Stop VM", "Check VM Status", "Quit"} with prompt "Select an action:" default items {"List VMs"}
        
        if actionChoice is false then
            return
        end if
        
        set selectedAction to item 1 of actionChoice
        
        if selectedAction is "List VMs" then
            listVirtualMachines()
        else if selectedAction is "Start VM" then
            set vmList to listVirtualMachines()
            if vmList is not {} then
                set vmChoice to choose from list vmList with prompt "Select a VM to start:" default items {item 1 of vmList}
                if vmChoice is not false then
                    startVirtualMachine(item 1 of vmChoice)
                end if
            end if
        else if selectedAction is "Stop VM" then
            set vmList to listVirtualMachines()
            if vmList is not {} then
                set vmChoice to choose from list vmList with prompt "Select a VM to stop:" default items {item 1 of vmList}
                if vmChoice is not false then
                    stopVirtualMachine(item 1 of vmChoice)
                end if
            end if
        else if selectedAction is "Check VM Status" then
            set vmList to listVirtualMachines()
            if vmList is not {} then
                set vmChoice to choose from list vmList with prompt "Select a VM to check status:" default items {item 1 of vmList}
                if vmChoice is not false then
                    checkVirtualMachineStatus(item 1 of vmChoice)
                end if
            end if
        else if selectedAction is "Quit" then
            return
        end if
        
    on error errMsg number errNum
        logError("Error in main handler", errMsg, errNum)
    end try
end run

-- Handler to check if an application is installed
on applicationIsInstalled(appName)
    try
        tell application "System Events"
            set appExists to exists application file (appName & ".app") of application folder
            return appExists
        end tell
    on error
        try
            -- Alternative way to check if app exists
            do shell script "mdfind 'kMDItemKind == \"Application\"' -name " & quoted form of appName & " | grep -i " & quoted form of appName
            return true
        on error
            return false
        end try
    end try
end applicationIsInstalled

-- Handler to list all VMs in VirtualBuddy
on listVirtualMachines()
    try
        set vmList to {}
        
        -- Launch VirtualBuddy if it's not already running
        tell application "VirtualBuddy" to activate
        delay 1 -- Give the app time to initialize
        
        tell application "System Events"
            tell process "VirtualBuddy"
                -- Get VM names from table view in main window
                if exists table 1 of scroll area 1 of window 1 then
                    set vmRows to rows of table 1 of scroll area 1 of window 1
                    repeat with eachRow in vmRows
                        set vmName to value of text field 1 of eachRow as text
                        set end of vmList to vmName
                    end repeat
                end if
            end tell
        end tell
        
        if vmList is {} then
            display dialog "No virtual machines found." buttons {"OK"} default button "OK" with icon note
        else
            set formattedList to "Virtual Machines:" & return & return
            repeat with i from 1 to count of vmList
                set formattedList to formattedList & "• " & item i of vmList & return
            end repeat
            
            display dialog formattedList buttons {"OK"} default button "OK" with icon note
        end if
        
        return vmList
        
    on error errMsg number errNum
        logError("Error listing VMs", errMsg, errNum)
        return {}
    end try
end listVirtualMachines

-- Handler to start a VM by name
on startVirtualMachine(vmName)
    try
        tell application "VirtualBuddy" to activate
        delay 1
        
        -- Check if VM is already running
        if isVirtualMachineRunning(vmName) then
            display dialog "VM \"" & vmName & "\" is already running." buttons {"OK"} default button "OK" with icon note
            return
        end if
        
        tell application "System Events"
            tell process "VirtualBuddy"
                -- Find and select the VM in the list
                if exists table 1 of scroll area 1 of window 1 then
                    set vmRows to rows of table 1 of scroll area 1 of window 1
                    repeat with eachRow in vmRows
                        if value of text field 1 of eachRow as text is vmName then
                            select eachRow
                            exit repeat
                        end if
                    end repeat
                end if
                
                -- Click the "Start" button
                if exists button "Start" of window 1 then
                    click button "Start" of window 1
                    display dialog "Starting VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
                else
                    -- Try secondary method - click Start from toolbar
                    try
                        click button 1 of toolbar 1 of window 1
                        display dialog "Starting VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
                    on error
                        display dialog "Could not find Start button for VM \"" & vmName & "\"." buttons {"OK"} default button "OK" with icon stop
                    end try
                end if
            end tell
        end tell
        
    on error errMsg number errNum
        logError("Error starting VM: " & vmName, errMsg, errNum)
    end try
end startVirtualMachine

-- Handler to stop a VM by name
on stopVirtualMachine(vmName)
    try
        tell application "VirtualBuddy" to activate
        delay 1
        
        -- Check if VM is running
        if not isVirtualMachineRunning(vmName) then
            display dialog "VM \"" & vmName & "\" is not running." buttons {"OK"} default button "OK" with icon note
            return
        end if
        
        tell application "System Events"
            tell process "VirtualBuddy"
                -- Find and select the VM in the list
                if exists table 1 of scroll area 1 of window 1 then
                    set vmRows to rows of table 1 of scroll area 1 of window 1
                    repeat with eachRow in vmRows
                        if value of text field 1 of eachRow as text is vmName then
                            select eachRow
                            exit repeat
                        end if
                    end repeat
                end if
                
                -- Try to find the Stop button (might be labeled "Shut Down" or have an icon)
                if exists button "Stop" of window 1 then
                    click button "Stop" of window 1
                else if exists button "Shut Down" of window 1 then
                    click button "Shut Down" of window 1
                else
                    -- Try secondary method - click Stop from toolbar (usually second button)
                    try
                        click button 2 of toolbar 1 of window 1
                    on error
                        display dialog "Could not find Stop button for VM \"" & vmName & "\"." buttons {"OK"} default button "OK" with icon stop
                        return
                    end try
                end if
                
                -- Handle confirmation dialog if it appears
                delay 1
                if exists sheet 1 of window 1 then
                    if exists button "Shut Down" of sheet 1 of window 1 then
                        click button "Shut Down" of sheet 1 of window 1
                    else if exists button "Force Shut Down" of sheet 1 of window 1 then
                        click button "Force Shut Down" of sheet 1 of window 1
                    end if
                end if
                
                display dialog "Stopping VM \"" & vmName & "\"..." buttons {"OK"} default button "OK" with icon note
            end tell
        end tell
        
    on error errMsg number errNum
        logError("Error stopping VM: " & vmName, errMsg, errNum)
    end try
end stopVirtualMachine

-- Handler to check VM status
on checkVirtualMachineStatus(vmName)
    try
        tell application "VirtualBuddy" to activate
        delay 1
        
        set isRunning to isVirtualMachineRunning(vmName)
        
        if isRunning then
            display dialog "VM \"" & vmName & "\" is currently running." buttons {"OK"} default button "OK" with icon note
        else
            display dialog "VM \"" & vmName & "\" is currently stopped." buttons {"OK"} default button "OK" with icon note
        end if
        
    on error errMsg number errNum
        logError("Error checking VM status: " & vmName, errMsg, errNum)
    end try
end checkVirtualMachineStatus

-- Helper handler to check if a VM is running
on isVirtualMachineRunning(vmName)
    try
        tell application "VirtualBuddy" to activate
        delay 1
        
        set isRunning to false
        
        tell application "System Events"
            tell process "VirtualBuddy"
                -- Find the VM in the list
                if exists table 1 of scroll area 1 of window 1 then
                    set vmRows to rows of table 1 of scroll area 1 of window 1
                    repeat with eachRow in vmRows
                        if value of text field 1 of eachRow as text is vmName then
                            -- Look for "Running" text in the status column (typically column 2)
                            try
                                set status to value of text field 2 of eachRow as text
                                if status contains "Running" then
                                    set isRunning to true
                                end if
                            on error
                                -- Alternative: Check if Stop button is enabled (only when VM is running)
                                select eachRow
                                delay 0.5
                                if exists button "Stop" of window 1 then
                                    if enabled of button "Stop" of window 1 then
                                        set isRunning to true
                                    end if
                                else if exists button "Shut Down" of window 1 then
                                    if enabled of button "Shut Down" of window 1 then
                                        set isRunning to true
                                    end if
                                end if
                            end try
                            exit repeat
                        end if
                    end repeat
                end if
            end tell
        end tell
        
        return isRunning
        
    on error errMsg number errNum
        logError("Error checking if VM is running: " & vmName, errMsg, errNum)
        return false
    end try
end isVirtualMachineRunning

-- Helper handler for error logging
on logError(context, errMsg, errNum)
    set errorInfo to context & ":" & return & "Error: " & errMsg & return & "Error number: " & errNum
    log errorInfo
    display dialog errorInfo buttons {"OK"} default button "OK" with icon stop
end logError
```