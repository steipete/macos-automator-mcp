---
title: Manage macOS Sharing Services
category: 12_network
id: network_sharing_services_status
description: >-
  Check and toggle macOS sharing services like File Sharing, Screen Sharing, and
  Remote Login using shell commands.
keywords:
  - Sharing
  - File Sharing
  - Screen Sharing
  - Remote Login
  - SSH
  - VNC
  - service
  - systemsetup
language: applescript
notes: |
  - Many sharing commands require administrator privileges
  - Modern macOS versions use systemsetup or launchctl to manage services
  - For older macOS versions, UI scripting might be necessary
  - Only activate sharing services you actually need for security reasons
---

This script demonstrates how to manage macOS sharing services like File Sharing, Screen Sharing, and Remote Login (SSH) using shell commands.

```applescript
-- Sharing Services Management

-- 1. Check status of sharing services
on getServicesStatus()
  set statusReport to "macOS Sharing Services Status:" & return & return
  
  try
    -- Check Remote Login (SSH) status
    set sshStatus to do shell script "systemsetup -getremotelogin"
    set statusReport to statusReport & "• Remote Login (SSH): " & sshStatus & return & return
    
    -- Check Screen Sharing (VNC) status
    set screenSharingStatus to "Unknown"
    try
      set screenSharingCmd to "launchctl list | grep com.apple.screensharing"
      do shell script screenSharingCmd
      set screenSharingStatus to "On"
    on error
      set screenSharingStatus to "Off"
    end try
    set statusReport to statusReport & "• Screen Sharing (VNC): " & screenSharingStatus & return & return
    
    -- Check File Sharing (SMB) status
    set smbStatus to "Unknown"
    try
      set smbCmd to "launchctl list | grep com.apple.smbd"
      do shell script smbCmd
      set smbStatus to "On"
    on error
      set smbStatus to "Off"
    end try
    set statusReport to statusReport & "• File Sharing (SMB): " & smbStatus & return & return
    
    -- Check Remote Management (Apple Remote Desktop) status
    set ardStatus to "Unknown"
    try
      set ardCmd to "launchctl list | grep com.apple.RemoteDesktop.agent"
      do shell script ardCmd
      set ardStatus to "On"
    on error
      set ardStatus to "Off"
    end try
    set statusReport to statusReport & "• Remote Management (ARD): " & ardStatus & return & return
    
    -- Check Remote Apple Events status
    set raeStatus to "Unknown"
    try
      set raeCmd to "systemsetup -getremoteappleevents"
      set raeStatus to do shell script raeCmd
    on error
      set raeStatus to "Error getting Remote Apple Events status"
    end try
    set statusReport to statusReport & "• Remote Apple Events: " & raeStatus & return & return
    
    -- Get computer name and sharing name
    set computerName to do shell script "scutil --get ComputerName"
    set localHostName to do shell script "scutil --get LocalHostName"
    
    set statusReport to statusReport & "Computer Name: " & computerName & return
    set statusReport to statusReport & "Local Network Name: " & localHostName & return
    
    return statusReport
  on error errMsg
    return "Error getting services status: " & errMsg
  end try
end getServicesStatus

-- 2. Toggle Remote Login (SSH)
on toggleRemoteLogin(enableService)
  try
    -- Set Remote Login on or off
    if enableService is true then
      set toggleCmd to "systemsetup -setremotelogin on"
      set resultMsg to "Remote Login (SSH) has been enabled."
    else
      set toggleCmd to "systemsetup -setremotelogin off"
      set resultMsg to "Remote Login (SSH) has been disabled."
    end if
    
    do shell script toggleCmd with administrator privileges
    return resultMsg
  on error errMsg
    return "Error toggling Remote Login: " & errMsg
  end try
end toggleRemoteLogin

-- 3. Toggle Screen Sharing
on toggleScreenSharing(enableService)
  try
    -- Set Screen Sharing on or off
    if enableService is true then
      set toggleCmd to "launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist"
      set resultMsg to "Screen Sharing has been enabled."
    else
      set toggleCmd to "launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist"
      set resultMsg to "Screen Sharing has been disabled."
    end if
    
    do shell script toggleCmd with administrator privileges
    return resultMsg
  on error errMsg
    return "Error toggling Screen Sharing: " & errMsg
  end try
end toggleScreenSharing

-- 4. Toggle File Sharing (SMB)
on toggleFileSharing(enableService)
  try
    -- Set File Sharing (SMB) on or off
    if enableService is true then
      set toggleCmd to "launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
      set resultMsg to "File Sharing has been enabled."
    else
      set toggleCmd to "launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist"
      set resultMsg to "File Sharing has been disabled."
    end if
    
    do shell script toggleCmd with administrator privileges
    return resultMsg
  on error errMsg
    return "Error toggling File Sharing: " & errMsg
  end try
end toggleFileSharing

-- 5. Set Computer Name and Local Network Name
on setComputerNames(newComputerName, newLocalHostName)
  try
    -- Set Computer Name (user-friendly name)
    set computerNameCmd to "scutil --set ComputerName " & quoted form of newComputerName
    do shell script computerNameCmd with administrator privileges
    
    -- Set Local Network Name (Bonjour name for sharing)
    -- Convert to valid hostname (alphanumeric and hyphen only, no spaces)
    if newLocalHostName is missing value or newLocalHostName is "" then
      set newLocalHostName to newComputerName
    end if
    
    -- Replace spaces and special characters with hyphens
    set validHostname to do shell script "echo " & quoted form of newLocalHostName & " | tr -c 'a-zA-Z0-9-' '-'"
    set localHostNameCmd to "scutil --set LocalHostName " & quoted form of validHostname
    do shell script localHostNameCmd with administrator privileges
    
    -- Also set the HostName (mainly used for Terminal/command line)
    set hostNameCmd to "scutil --set HostName " & quoted form of validHostname
    do shell script hostNameCmd with administrator privileges
    
    return "Computer Name changed to: " & newComputerName & return & ¬
      "Local Host Name changed to: " & validHostname
  on error errMsg
    return "Error setting computer names: " & errMsg
  end try
end setComputerNames

-- Example usage - run with "true" to enable or "false" to disable services
-- set sshResult to my toggleRemoteLogin(false)
-- set screenResult to my toggleScreenSharing(false)
-- set fileResult to my toggleFileSharing(false)
-- set namesResult to my setComputerNames("My Mac", "my-mac")

-- Get current status of all services
set servicesStatus to my getServicesStatus()
return servicesStatus
```

This comprehensive script provides several functions for managing macOS sharing services:

1. **Check Sharing Services Status**
   - Shows which sharing services are currently active or inactive
   - Displays computer name and local network name
   - Provides a summary report of all services

2. **Toggle Remote Login (SSH)**
   - Enables or disables the SSH server
   - Uses the `systemsetup` command with administrator privileges

3. **Toggle Screen Sharing (VNC)**
   - Enables or disables the built-in VNC server (Screen Sharing)
   - Uses `launchctl` to manage the service daemon

4. **Toggle File Sharing (SMB)**
   - Enables or disables the SMB server for file sharing
   - Uses `launchctl` to manage the service daemon

5. **Set Computer Names**
   - Sets the friendly Computer Name (visible to users)
   - Sets the Local Host Name (used for Bonjour sharing services)
   - Ensures host names are valid (removing special characters)

Security Considerations:
- Only enable services you actively need
- Disable sharing services when not in use, especially in public networks
- Remote Login (SSH) should only be enabled with strong password or key authentication
- Screen Sharing gives full graphical access to your Mac

This script is especially useful for:
- Setting up new Macs with consistent sharing configurations
- Creating automated workflows that need to toggle services
- System administration and remote management
- Security protocols that require controlled access to services
END_TIP
