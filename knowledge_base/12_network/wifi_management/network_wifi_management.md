---
title: "WiFi Network Management"
category: "12_network_services"
id: network_wifi_management
description: "Manages WiFi connections including turning WiFi on/off, scanning for networks, connecting to preferred networks, and creating network profiles"
keywords: ["wifi", "network", "wireless", "airport", "connection", "scan", "SSID", "networksetup", "airport"]
language: applescript
notes: "Many commands require administrator privileges. Uses both AppleScript and shell commands via networksetup and airport utilities."
---

```applescript
-- Turn WiFi on
on turnWiFiOn()
  try
    do shell script "networksetup -setairportpower en0 on" with administrator privileges
    return "WiFi turned on"
  on error errMsg
    return "Error turning WiFi on: " & errMsg
  end try
end turnWiFiOn

-- Turn WiFi off
on turnWiFiOff()
  try
    do shell script "networksetup -setairportpower en0 off" with administrator privileges
    return "WiFi turned off"
  on error errMsg
    return "Error turning WiFi off: " & errMsg
  end try
end turnWiFiOff

-- Toggle WiFi state
on toggleWiFi()
  set currentState to do shell script "networksetup -getairportpower en0 | awk '{print $4}'"
  
  if currentState is "On" then
    turnWiFiOff()
    return "WiFi turned off"
  else
    turnWiFiOn()
    return "WiFi turned on"
  end if
end toggleWiFi

-- Get current WiFi status (on/off and connected network)
on getWiFiStatus()
  set powerStatus to do shell script "networksetup -getairportpower en0 | awk '{print $4}'"
  
  if powerStatus is "On" then
    set networkInfo to do shell script "networksetup -getairportnetwork en0"
    
    if networkInfo contains "You are not associated with an AirPort network" then
      return "WiFi is on but not connected to any network"
    else
      set currentNetwork to do shell script "echo " & quoted form of networkInfo & " | awk '{print $4}'"
      return "WiFi is on and connected to: " & currentNetwork
    end if
  else
    return "WiFi is off"
  end if
end getWiFiStatus

-- Scan for available WiFi networks
on scanForNetworks()
  -- Uses the airport command-line utility
  set airportPath to "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  
  set networkScan to do shell script airportPath & " -s"
  
  -- Parse and format the scan results
  set networksList to paragraphs of networkScan
  
  -- Skip the header line
  set availableNetworks to {}
  repeat with i from 2 to count of networksList
    set currentLine to item i of networksList
    if currentLine is not "" then
      -- Extract SSID (network name)
      set networkSSID to do shell script "echo " & quoted form of currentLine & " | awk '{print $1}'"
      -- Extract signal strength
      set signalStrength to do shell script "echo " & quoted form of currentLine & " | awk '{print $2}'"
      -- Extract security type
      set securityType to do shell script "echo " & quoted form of currentLine & " | awk '{print $7}'"
      
      set end of availableNetworks to {ssid:networkSSID, signal:signalStrength, security:securityType}
    end if
  end repeat
  
  return availableNetworks
end scanForNetworks

-- Connect to a specific WiFi network
on connectToNetwork(networkName, password)
  try
    -- Attempt to connect to the network
    if password is "" then
      -- Open network (no password)
      do shell script "networksetup -setairportnetwork en0 " & quoted form of networkName with administrator privileges
    else
      -- Password-protected network
      do shell script "networksetup -setairportnetwork en0 " & quoted form of networkName & " " & quoted form of password with administrator privileges
    end if
    
    -- Check if connection was successful
    delay 3 -- Wait for connection to establish
    set currentStatus to getWiFiStatus()
    
    if currentStatus contains networkName then
      return "Successfully connected to " & networkName
    else
      return "Failed to connect to " & networkName & ". Check the network name and password."
    end if
  on error errMsg
    return "Error connecting to WiFi: " & errMsg
  end try
end connectToNetwork

-- Create a new network location (profile)
on createNetworkLocation(locationName)
  try
    do shell script "networksetup -createlocation " & quoted form of locationName & " populate" with administrator privileges
    return "Network location '" & locationName & "' created"
  on error errMsg
    return "Error creating network location: " & errMsg
  end try
end createNetworkLocation

-- Switch to a different network location
on switchNetworkLocation(locationName)
  try
    do shell script "networksetup -switchtolocation " & quoted form of locationName with administrator privileges
    return "Switched to network location: " & locationName
  on error errMsg
    return "Error switching network location: " & errMsg
  end try
end switchNetworkLocation

-- List all available network locations
on listNetworkLocations()
  set locationsList to paragraphs of (do shell script "networksetup -listlocations")
  
  -- Get current location
  set currentLocation to do shell script "networksetup -getcurrentlocation"
  
  return {locations:locationsList, current:currentLocation}
end listNetworkLocations

-- Delete a network location
on deleteNetworkLocation(locationName)
  try
    do shell script "networksetup -deletelocation " & quoted form of locationName with administrator privileges
    return "Network location '" & locationName & "' deleted"
  on error errMsg
    return "Error deleting network location: " & errMsg
  end try
end deleteNetworkLocation

-- Get detailed WiFi information
on getDetailedWiFiInfo()
  set airportPath to "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  
  try
    set wifiInfo to do shell script airportPath & " -I"
    
    -- Parse the info into a more structured format
    set infoLines to paragraphs of wifiInfo
    set wifiDetails to {}
    
    repeat with infoLine in infoLines
      if infoLine contains ":" then
        set AppleScript's text item delimiters to ":"
        set lineItems to text items of infoLine
        set keyName to (text item 1 of lineItems)
        
        -- Join the rest of the items (in case there are multiple colons)
        set AppleScript's text item delimiters to ":"
        set valueItems to items 2 thru (count of lineItems) of lineItems
        set keyValue to valueItems as text
        
        -- Trim whitespace from key and value
        set keyName to do shell script "echo " & quoted form of keyName & " | xargs"
        set keyValue to do shell script "echo " & quoted form of keyValue & " | xargs"
        
        -- Add to our details dictionary
        set end of wifiDetails to {key:keyName, value:keyValue}
        
        -- Reset text item delimiters
        set AppleScript's text item delimiters to ""
      end if
    end repeat
    
    return wifiDetails
  on error errMsg
    return "Error getting WiFi details: " & errMsg
  end try
end getDetailedWiFiInfo

-- Create a WiFi network profile for automatic connection
on createWiFiProfile(networkName, password)
  try
    do shell script "networksetup -addpreferredwirelessnetworkatindex en0 " & quoted form of networkName & " 0 WPA2 " & quoted form of password with administrator privileges
    return "WiFi profile created for " & networkName
  on error errMsg
    return "Error creating WiFi profile: " & errMsg
  end try
end createWiFiProfile

-- Remove a WiFi network profile
on removeWiFiProfile(networkName)
  try
    do shell script "networksetup -removepreferredwirelessnetwork en0 " & quoted form of networkName with administrator privileges
    return "WiFi profile removed for " & networkName
  on error errMsg
    return "Error removing WiFi profile: " & errMsg
  end try
end removeWiFiProfile

-- List all preferred (saved) WiFi networks
on listPreferredNetworks()
  try
    set preferredNetworks to paragraphs of (do shell script "networksetup -listpreferredwirelessnetworks en0")
    
    -- Remove the header line
    set networks to {}
    repeat with i from 2 to count of preferredNetworks
      if item i of preferredNetworks is not "" then
        set end of networks to item i of preferredNetworks
      end if
    end repeat
    
    return networks
  on error errMsg
    return "Error listing preferred networks: " & errMsg
  end try
end listPreferredNetworks

-- Set WiFi network priority
on setNetworkPriority(networkName, priorityIndex)
  try
    -- First remove the network, then add it back at the desired index
    do shell script "networksetup -removepreferredwirelessnetwork en0 " & quoted form of networkName
    
    -- Get the password for the network (if needed)
    -- Note: This is a limitation as macOS doesn't provide a way to extract saved passwords
    set passwordPrompt to display dialog "Enter password for " & networkName & ":" default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK"
    set networkPassword to text returned of passwordPrompt
    
    -- Add it back with the new priority
    do shell script "networksetup -addpreferredwirelessnetworkatindex en0 " & quoted form of networkName & " " & priorityIndex & " WPA2 " & quoted form of networkPassword with administrator privileges
    
    return "Network priority updated for " & networkName
  on error errMsg
    return "Error setting network priority: " & errMsg
  end try
end setNetworkPriority

-- Interactive menu for WiFi management
on showWiFiMenu()
  set wifiOptions to {"WiFi Status", "Toggle WiFi", "Scan for Networks", "Connect to Network", "List Saved Networks", "Remove Network Profile", "Network Locations", "Detailed WiFi Info", "Cancel"}
  
  set selectedOption to choose from list wifiOptions with prompt "Select WiFi Operation:" default items {"WiFi Status"}
  
  if selectedOption is false then
    return "Operation cancelled"
  else
    set operation to item 1 of selectedOption
    
    if operation is "WiFi Status" then
      return getWiFiStatus()
      
    else if operation is "Toggle WiFi" then
      return toggleWiFi()
      
    else if operation is "Scan for Networks" then
      set foundNetworks to scanForNetworks()
      set networkReport to "Available Networks:" & return & return
      
      repeat with networkInfo in foundNetworks
        set networkReport to networkReport & networkInfo's ssid & " (Signal: " & networkInfo's signal & ", Security: " & networkInfo's security & ")" & return
      end repeat
      
      return networkReport
      
    else if operation is "Connect to Network" then
      -- Get nearby networks
      set availableNetworks to scanForNetworks()
      set networkNames to {}
      
      repeat with networkInfo in availableNetworks
        set end of networkNames to networkInfo's ssid
      end repeat
      
      -- Ask user to select a network
      set selectedNetwork to choose from list networkNames with prompt "Select a WiFi network:"
      if selectedNetwork is false then return "Connection cancelled"
      
      set networkSSID to item 1 of selectedNetwork
      
      -- Ask for password
      set passwordPrompt to display dialog "Enter password for " & networkSSID & ":" default answer "" with hidden answer buttons {"Cancel", "Connect"} default button "Connect"
      set networkPassword to text returned of passwordPrompt
      
      return connectToNetwork(networkSSID, networkPassword)
      
    else if operation is "List Saved Networks" then
      set savedNetworks to listPreferredNetworks()
      set networkList to "Saved Networks:" & return & return
      
      repeat with networkName in savedNetworks
        set networkList to networkList & networkName & return
      end repeat
      
      return networkList
      
    else if operation is "Remove Network Profile" then
      -- Get list of saved networks
      set savedNetworks to listPreferredNetworks()
      
      -- Ask user to select a network to remove
      set selectedNetwork to choose from list savedNetworks with prompt "Select a network profile to remove:"
      if selectedNetwork is false then return "Removal cancelled"
      
      return removeWiFiProfile(item 1 of selectedNetwork)
      
    else if operation is "Network Locations" then
      set locationInfo to listNetworkLocations()
      set locationReport to "Current Location: " & locationInfo's current & return & return & "Available Locations:" & return
      
      repeat with locationName in locationInfo's locations
        set locationReport to locationReport & locationName & return
      end repeat
      
      return locationReport
      
    else if operation is "Detailed WiFi Info" then
      set wifiDetails to getDetailedWiFiInfo()
      set detailReport to "Detailed WiFi Information:" & return & return
      
      repeat with infoItem in wifiDetails
        set detailReport to detailReport & infoItem's key & ": " & infoItem's value & return
      end repeat
      
      return detailReport
      
    else
      return "Operation cancelled"
    end if
  end if
end showWiFiMenu

-- Run the WiFi management menu
showWiFiMenu()
```

This script provides comprehensive WiFi network management capabilities with these key functions:

1. **Basic WiFi Controls**:
   - Turn WiFi on/off and toggle its state
   - Get current WiFi status (on/off and connected network)
   - Scan for available WiFi networks

2. **Network Connection Management**:
   - Connect to specific WiFi networks with password support
   - List all preferred (saved) WiFi networks
   - Create and remove WiFi profiles for automatic connection
   - Set network connection priorities

3. **Network Location Profiles**:
   - Create new network locations (profiles)
   - Switch between different network locations
   - List all available network locations
   - Delete network locations

4. **Diagnostic Information**:
   - Get detailed WiFi information including signal strength, channel, security type, etc.

5. **Interactive Interface**:
   - A menu-based interface for easy access to all WiFi management functions

The script uses a combination of AppleScript and shell commands, primarily leveraging the `networksetup` command-line utility and the `airport` utility (located in Apple's private frameworks). Many operations require administrator privileges and will prompt for a password when executed.

This WiFi management tool is particularly useful for:
- Quickly switching between different network environments
- Automating network connections based on location or time
- Creating network profiles for different use cases
- Troubleshooting network connectivity issues
- Building custom network management solutions