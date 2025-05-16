---
title: Docker Container Controller
description: >-
  Script to interact with Docker on macOS - list, start, stop, and inspect
  containers
keywords:
  - docker
  - container
  - management
  - list
  - start
  - stop
  - inspect
language: applescript
isComplex: false
category: 13_developer/docker
---

# Docker Container Controller

This script provides an interface for interacting with Docker containers on macOS. It includes functionality to list all containers, start and stop containers, and get detailed information about specific containers.

## Features

- Check if Docker is running and start it if needed
- List all containers (running and stopped)
- List only running containers
- Start a container by ID or name
- Stop a container by ID or name
- Get detailed information about a container
- Interactive container selection and management UI

## Script

```applescript
-- Docker Interaction AppleScript
-- This script demonstrates how to interact with Docker on macOS
-- Functions include: list containers, start/stop containers, and error handling

use AppleScript version "2.4" -- macOS 10.10 or later
use scripting additions
use framework "Foundation"

-- ===== Helper Functions =====

-- Convert shell command output to AppleScript list
on splitLines(theText)
    set AppleScript's text item delimiters to linefeed
    set theLines to every text item of theText
    set AppleScript's text item delimiters to ""
    return theLines
end splitLines

-- Check if Docker is running
on isDockerRunning()
    try
        do shell script "pgrep -f Docker"
        return true
    on error
        return false
    end try
end isDockerRunning

-- Start Docker if not running
on ensureDockerIsRunning()
    if not isDockerRunning() then
        log "Docker is not running. Starting Docker..."
        try
            tell application "Docker"
                activate
            end tell
            
            -- Wait for Docker to fully start up
            repeat 12 times
                if isDockerDaemonResponding() then
                    log "Docker has started successfully."
                    return true
                end if
                delay 5
            end repeat
            
            log "Timeout waiting for Docker to start."
            return false
        on error errMsg
            log "Error starting Docker: " & errMsg
            return false
        end try
    else
        log "Docker is already running."
        return true
    end if
end ensureDockerIsRunning

-- Check if Docker daemon is responding
on isDockerDaemonResponding()
    try
        do shell script "docker ps > /dev/null 2>&1"
        return true
    on error
        return false
    end try
end isDockerDaemonResponding

-- Format container info for better readability
on formatContainerInfo(containerData)
    set formattedInfo to {}
    repeat with i from 1 to count of containerData
        set containerLine to item i of containerData
        if containerLine is not "" and containerLine does not start with "CONTAINER ID" then
            -- Parse container line 
            set containerID to do shell script "echo " & quoted form of containerLine & " | awk '{print $1}'"
            set containerName to do shell script "echo " & quoted form of containerLine & " | awk '{for(i=NF;i>0;i--){if($i!~/->/ && $i !~ /^[0-9]/ && $i !~ /^[0-9.]+:[0-9]+/){name=$i; break}}} END{print name}'"
            set containerStatus to do shell script "echo " & quoted form of containerLine & " | awk '{for(i=1;i<=NF;i++){if($i~/Up/||$i~/Exited/){status=$i; for(j=i+1;j<=NF;j++){if($j~/seconds/||$j~/minutes/||$j~/hours/||$j~/days/){status=status\" \"$j; break}}; break}}} END{print status}'"
            
            set end of formattedInfo to {id:containerID, name:containerName, status:containerStatus}
        end if
    end repeat
    return formattedInfo
end formatContainerInfo

-- ===== Main Docker Interaction Functions =====

-- List all Docker containers (running and stopped)
on listAllContainers()
    if not ensureDockerIsRunning() then
        return {error:"Docker not running", containers:{}}
    end if
    
    try
        set containerOutput to do shell script "docker ps -a"
        set containerLines to splitLines(containerOutput)
        set formattedContainers to formatContainerInfo(containerLines)
        
        log "Found " & (count of formattedContainers) & " containers."
        return {error:false, containers:formattedContainers}
    on error errMsg
        log "Error listing containers: " & errMsg
        return {error:errMsg, containers:{}}
    end try
end listAllContainers

-- List only running Docker containers
on listRunningContainers()
    if not ensureDockerIsRunning() then
        return {error:"Docker not running", containers:{}}
    end if
    
    try
        set containerOutput to do shell script "docker ps"
        set containerLines to splitLines(containerOutput)
        set formattedContainers to formatContainerInfo(containerLines)
        
        log "Found " & (count of formattedContainers) & " running containers."
        return {error:false, containers:formattedContainers}
    on error errMsg
        log "Error listing running containers: " & errMsg
        return {error:errMsg, containers:{}}
    end try
end listRunningContainers

-- Start a Docker container by ID or name
on startContainer(containerIdentifier)
    if not ensureDockerIsRunning() then
        return {error:"Docker not running", success:false}
    end if
    
    try
        do shell script "docker start " & quoted form of containerIdentifier
        log "Container " & containerIdentifier & " started successfully."
        return {error:false, success:true}
    on error errMsg
        log "Error starting container " & containerIdentifier & ": " & errMsg
        return {error:errMsg, success:false}
    end try
end startContainer

-- Stop a Docker container by ID or name
on stopContainer(containerIdentifier)
    if not ensureDockerIsRunning() then
        return {error:"Docker not running", success:false}
    end if
    
    try
        do shell script "docker stop " & quoted form of containerIdentifier
        log "Container " & containerIdentifier & " stopped successfully."
        return {error:false, success:true}
    on error errMsg
        log "Error stopping container " & containerIdentifier & ": " & errMsg
        return {error:errMsg, success:false}
    end try
end stopContainer

-- Get detailed information about a specific container
on inspectContainer(containerIdentifier)
    if not ensureDockerIsRunning() then
        return {error:"Docker not running", details:""}
    end if
    
    try
        set containerInfo to do shell script "docker inspect --format='{{.Name}} - {{.State.Status}} - {{.Config.Image}}' " & quoted form of containerIdentifier
        log "Container details: " & containerInfo
        return {error:false, details:containerInfo}
    on error errMsg
        log "Error inspecting container " & containerIdentifier & ": " & errMsg
        return {error:errMsg, details:""}
    end try
end inspectContainer

-- ===== Example Usage =====

-- Main function to demonstrate Docker interactions
on runDockerDemo()
    display dialog "Docker Interaction Demo" buttons {"Continue"} default button "Continue"
    
    -- Check if Docker is running and start it if needed
    if not ensureDockerIsRunning() then
        display dialog "Failed to start Docker. Please start it manually." buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- List all containers
    set allContainers to listAllContainers()
    if error of allContainers is not false then
        display dialog "Error listing containers: " & (error of allContainers) buttons {"OK"} default button "OK" with icon stop
        return
    end if
    
    -- Check if we have containers to work with
    if (count of (containers of allContainers)) is 0 then
        display dialog "No Docker containers found. Please create at least one container before running this demo." buttons {"OK"} default button "OK" with icon caution
        return
    end if
    
    -- Display containers and let user select one
    set containerList to {}
    repeat with c in containers of allContainers
        set containerName to name of c
        set containerId to id of c
        set containerStatus to status of c
        set end of containerList to containerName & " (" & containerId & ") - " & containerStatus
    end repeat
    
    set selectedContainer to choose from list containerList with prompt "Select a container to manage:" default items (item 1 of containerList)
    
    if selectedContainer is false then
        display dialog "No container selected." buttons {"OK"} default button "OK"
        return
    end if
    
    -- Extract container ID from selection
    set selectedContainerInfo to item 1 of selectedContainer
    set containerId to do shell script "echo " & quoted form of selectedContainerInfo & " | sed -E 's/.*\\(([^)]+)\\).*/\\1/'"
    
    -- Show container management options
    set containerAction to button returned of (display dialog "Container: " & selectedContainerInfo & return & return & "What would you like to do?" buttons {"Start", "Stop", "Inspect", "Cancel"} default button "Start" cancel button "Cancel")
    
    if containerAction is "Start" then
        set startResult to startContainer(containerId)
        if error of startResult is not false then
            display dialog "Error starting container: " & (error of startResult) buttons {"OK"} default button "OK" with icon stop
        else
            display dialog "Container started successfully." buttons {"OK"} default button "OK"
        end if
    else if containerAction is "Stop" then
        set stopResult to stopContainer(containerId)
        if error of stopResult is not false then
            display dialog "Error stopping container: " & (error of stopResult) buttons {"OK"} default button "OK" with icon stop
        else
            display dialog "Container stopped successfully." buttons {"OK"} default button "OK"
        end if
    else if containerAction is "Inspect" then
        set inspectResult to inspectContainer(containerId)
        if error of inspectResult is not false then
            display dialog "Error inspecting container: " & (error of inspectResult) buttons {"OK"} default button "OK" with icon stop
        else
            display dialog "Container details:" & return & return & (details of inspectResult) buttons {"OK"} default button "OK"
        end if
    end if
end runDockerDemo

-- Run the demo
runDockerDemo()
```

## Usage

This script provides a simple UI to:

1. Check if Docker is running and start it if needed
2. List all Docker containers
3. Let the user select a container to manage
4. Provide options to start, stop, or inspect the selected container

The individual handler functions can also be used independently in other scripts to automate Docker container management.

## Requirements

- Docker for Mac installed
- macOS 10.10 or later
- Appropriate permissions for automation
