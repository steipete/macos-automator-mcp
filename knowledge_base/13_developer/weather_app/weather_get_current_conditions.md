---
id: weather_get_current_conditions
title: Get Current Weather Conditions
description: Script to retrieve current weather conditions using a weather API
language: applescript
tags: ['weather', 'api', 'network', 'utility']
keywords: ['weather', 'conditions', 'temperature', 'forecast', 'weatherapi']
completion_prompt: Get current weather conditions for a location
required_arguments: ['location']
optional_arguments: ['units']
arguments_sample_value:
  location: "New York"
  units: "c"
argument_descriptions:
  location: "Location name or postal code (e.g., 'San Francisco' or '94105')"
  units: "Temperature units ('c' for Celsius, 'f' for Fahrenheit)"
---

# Get Current Weather Conditions

This script retrieves current weather conditions for a specified location using the WeatherAPI service. You can specify the location and temperature units (Celsius or Fahrenheit).

```applescript
-- Get current weather for a location
-- Requires API key from WeatherAPI.com

-- Arguments from MCP
-- Location is a required parameter (city name or postal code)
-- Units is optional ('c' for Celsius, 'f' for Fahrenheit)
property location : "--MCP_INPUT:location"
property units : "--MCP_INPUT:units"

-- Set default units if not specified
if units is "" or units is "--MCP_INPUT:units" then
    set units to "c"
end if

-- Prepare API request parameters
set apiKey to "YOUR_API_KEY" -- Replace with actual API key
set encodedLocation to encodeText(location)

-- Build and execute the API request
set apiURL to "https://api.weatherapi.com/v1/current.json?key=" & apiKey & "&q=" & encodedLocation & "&aqi=no"
set weatherData to do shell script "curl -s '" & apiURL & "'"

-- Parse JSON using the system's plutil command (built into macOS)
set jsonFile to (path to temporary items folder as text) & "weather_data.json"
do shell script "echo " & quoted form of weatherData & " > " & quoted form of jsonFile
set jsonDict to do shell script "plutil -convert xml1 -o - " & quoted form of jsonFile

-- Extract weather information
set locationName to extractValue(jsonDict, "location.name")
set region to extractValue(jsonDict, "location.region")
set country to extractValue(jsonDict, "location.country")
set tempC to extractValue(jsonDict, "current.temp_c")
set tempF to extractValue(jsonDict, "current.temp_f")
set condition to extractValue(jsonDict, "current.condition.text")
set humidity to extractValue(jsonDict, "current.humidity")
set windKph to extractValue(jsonDict, "current.wind_kph")
set windMph to extractValue(jsonDict, "current.wind_mph")
set windDirection to extractValue(jsonDict, "current.wind_dir")
set feelsLikeC to extractValue(jsonDict, "current.feelslike_c")
set feelsLikeF to extractValue(jsonDict, "current.feelslike_f")

-- Determine which temperature to display based on units parameter
set displayTemp to tempC & "°C"
set displayFeelsLike to feelsLikeC & "°C"
set displayWind to windKph & " km/h"

if units is "f" then
    set displayTemp to tempF & "°F"
    set displayFeelsLike to feelsLikeF & "°F"
    set displayWind to windMph & " mph"
end if

-- Format results
set weatherResults to "Weather for " & locationName
if region is not "" then set weatherResults to weatherResults & ", " & region
set weatherResults to weatherResults & ", " & country & "
Current Conditions: " & condition & "
Temperature: " & displayTemp & " (Feels like: " & displayFeelsLike & ")
Humidity: " & humidity & "%
Wind: " & displayWind & " " & windDirection

-- Clean up temporary file
do shell script "rm " & quoted form of jsonFile

-- Return the weather information
return weatherResults

-- Helper function to encode text for URL
on encodeText(theText)
    set allowedChars to "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    set encodedText to ""
    repeat with charIndex from 1 to length of theText
        set currentChar to character charIndex of theText
        if allowedChars contains currentChar then
            set encodedText to encodedText & currentChar
        else if currentChar is space then
            set encodedText to encodedText & "+"
        else
            set asciiValue to ASCII number currentChar
            set hexValue to do shell script "printf '%02X' " & asciiValue
            set encodedText to encodedText & "%" & hexValue
        end if
    end repeat
    return encodedText
end encodeText

-- Helper function to extract values from XML representation of JSON
on extractValue(xmlText, keyPath)
    set keys to my splitString(keyPath, ".")
    set shellCommand to "grep -A1 '<key>" & item 1 of keys & "</key>' <<< " & quoted form of xmlText
    
    repeat with i from 2 to count of keys
        set shellCommand to shellCommand & " | grep -A1 '<key>" & item i of keys & "</key>'"
    end repeat
    
    set shellCommand to shellCommand & " | grep -v '<key>' | sed -e 's/<[^>]*>//g' -e 's/^[[:space:]]*//'"
    
    try
        return do shell script shellCommand
    on error
        return ""
    end try
end extractValue

-- Helper function to split string by delimiter
on splitString(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theItems to every text item of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theItems
end splitString
```

## Example Usage

### Get Weather for San Francisco in Celsius
```applescript
set location to "San Francisco"
set units to "c"
-- Execute the script to get weather for San Francisco in Celsius
```

### Get Weather for New York in Fahrenheit
```applescript
set location to "New York"
set units to "f"
-- Execute the script to get weather for New York in Fahrenheit
```

### Get Weather for Tokyo with Default Units
```applescript
set location to "Tokyo"
-- Units will default to Celsius
-- Execute the script to get weather for Tokyo
```

## Notes

1. This script requires an API key from [WeatherAPI.com](https://www.weatherapi.com/). You'll need to register for a free account and replace `YOUR_API_KEY` with your actual API key.

2. The script uses macOS built-in tools for JSON parsing to avoid dependencies.

3. Error handling is minimal for simplicity - in a production environment, you should add more robust error handling.

4. If you intend to use this script frequently, consider storing the API key in the macOS Keychain for better security.