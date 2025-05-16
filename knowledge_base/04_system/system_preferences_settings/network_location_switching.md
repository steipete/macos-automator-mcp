---
title: 'System Preferences: Switch Network Locations'
category: 04_system/system_preferences_settings
id: system_network_location_switching
description: >-
  Switch between network locations using shell commands, enabling easy
  transitions between different network configurations.
keywords:
  - network location
  - networksetup
  - Network preferences
  - location switching
  - network configuration
  - network profile
language: applescript
notes: |
  - Requires administrator privileges for the networksetup command
  - Location names are case-sensitive and must match exactly
  - This replaces the older "Location Manager" functionality from classic Mac OS
---

Network locations allow you to store and quickly switch between different network configurations. This script demonstrates how to programmatically switch network locations using the `networksetup` command line tool.

```applescript
--MCP_INPUT:locationName

on switchNetworkLocation(locationName)
  if locationName is missing value or locationName is "" then
    return "error: Location name not provided."
  end if
  
  -- First, list available network locations to verify the requested one exists
  try
    set locationListCmd to "networksetup -listlocations"
    set availableLocations to paragraphs of (do shell script locationListCmd)
    
    -- Check if requested location exists
    set locationExists to false
    repeat with locName in availableLocations
      if locName is locationName then
        set locationExists to true
        exit repeat
      end if
    end repeat
    
    if not locationExists then
      return "error: Location '" & locationName & "' not found. Available locations: " & (availableLocations as text)
    end if
    
    -- Switch to the requested location
    set switchCmd to "networksetup -switchtolocation " & quoted form of locationName
    do shell script switchCmd with administrator privileges
    
    -- Get current location to confirm the switch
    set currentLocationCmd to "networksetup -getcurrentlocation"
    set currentLocation to do shell script currentLocationCmd
    
    if currentLocation is locationName then
      return "Successfully switched to network location: " & locationName
    else
      return "Warning: Command completed but current location is: " & currentLocation
    end if
  on error errMsg
    return "Error switching network location: " & errMsg
  end try
end switchNetworkLocation

return my switchNetworkLocation("--MCP_INPUT:locationName")
```

This script demonstrates how to:

1. List all available network locations
2. Check if a requested location exists
3. Switch to a specified network location
4. Verify the switch was successful

Common network location use cases:
- Home configuration (with home Wi-Fi and custom DNS)
- Office configuration (with corporate network settings)
- Travel/Hotel configuration (with simplified settings for public networks)
- Offline configuration (with all networking disabled)

Network locations can store different settings for all network interfaces, DNS servers, proxies, and other network configurations. Switching locations is a convenient way to apply multiple network settings at once.

Note: This functionality replaces the older "Location Manager" from classic Mac OS. The `networksetup` command is the modern way to interact with network locations.
END_TIP
