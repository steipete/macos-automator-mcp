---
title: "iOS Simulator: Set Device Location"
category: "09_developer_and_utility_apps"
id: ios_simulator_set_location
description: "Sets a custom GPS location for an iOS Simulator device."
keywords: ["iOS Simulator", "Xcode", "location", "GPS", "coordinates", "CoreLocation", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Latitude as 'latitude', longitude as 'longitude', optional device identifier as 'deviceIdentifier' (defaults to 'booted'), and optional location name as 'locationName' for easy identification."
notes: |
  - Simulates GPS location for location-aware app testing
  - Can specify any latitude/longitude coordinates
  - Location persists until reset or simulator restart
  - Overrides actual location for all apps on the simulator
  - Useful for testing location-based features and edge cases
  - The simulator must be booted for this to work
---

```applescript
--MCP_INPUT:latitude
--MCP_INPUT:longitude
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:locationName

on setSimulatorLocation(latitude, longitude, deviceIdentifier, locationName)
  if latitude is missing value or latitude is "" then
    return "error: Latitude not provided. Specify a valid latitude value (between -90 and 90)."
  end if
  
  if longitude is missing value or longitude is "" then
    return "error: Longitude not provided. Specify a valid longitude value (between -180 and 180)."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default location name
  if locationName is missing value or locationName is "" then
    set locationName to "Custom Location"
  end if
  
  -- Validate latitude and longitude
  try
    set latNum to latitude as number
    set lonNum to longitude as number
    
    if latNum < -90 or latNum > 90 then
      return "error: Invalid latitude. Must be between -90 and 90."
    end if
    
    if lonNum < -180 or lonNum > 180 then
      return "error: Invalid longitude. Must be between -180 and 180."
    end if
  on error
    return "error: Invalid latitude or longitude. Please provide valid numeric values."
  end try
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Set the location
    set locationCmd to "xcrun simctl location " & quoted form of deviceIdentifier & " set " & latNum & " " & lonNum
    
    try
      do shell script locationCmd
      set locationSet to true
    on error errMsg
      return "Error setting location: " & errMsg
    end try
    
    -- Try to get a location description for better context
    set locationDesc to ""
    try
      -- Use a web service to get location information (optional)
      set geocodeCmd to "curl -s 'https://nominatim.openstreetmap.org/reverse?format=json&lat=" & latNum & "&lon=" & lonNum & "&zoom=18&addressdetails=1' | grep -o '\"display_name\":\"[^\"]*' | cut -d':' -f2 | tr -d '\"'"
      set geocodeResult to do shell script geocodeCmd
      
      if geocodeResult is not "" then
        set locationDesc to "
Location appears to be: " & geocodeResult
      end if
    end try
    
    -- Command to reset location
    set resetCommand to "xcrun simctl location " & deviceIdentifier & " reset"
    
    if locationSet then
      return "Successfully set location for " & deviceIdentifier & " simulator.

Coordinates:
Latitude: " & latNum & "
Longitude: " & lonNum & "
Name: " & locationName & locationDesc & "

To reset the location to default, use:
" & resetCommand & "

Location will persist until reset or simulator restart."
    else
      return "Failed to set location for " & deviceIdentifier
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") setting simulator location: " & errMsg
  end try
end setSimulatorLocation

return my setSimulatorLocation("--MCP_INPUT:latitude", "--MCP_INPUT:longitude", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:locationName")
```