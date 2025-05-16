---
id: weather_get_forecast
title: Get Weather Forecast
description: Script to retrieve weather forecast for upcoming days
language: applescript
tags:
  - weather
  - api
  - network
  - forecast
  - utility
keywords:
  - weather
  - forecast
  - prediction
  - daily
  - meteorology
completion_prompt: Get weather forecast for a location
required_arguments:
  - location
optional_arguments:
  - days
  - units
arguments_sample_value:
  location: London
  days: '3'
  units: c
argument_descriptions:
  location: 'Location name or postal code (e.g., ''London'' or ''90210'')'
  days: Number of forecast days (1-7)
  units: 'Temperature units (''c'' for Celsius, ''f'' for Fahrenheit)'
category: 13_developer/weather_app
---

# Get Weather Forecast

This script retrieves a weather forecast for a specified location using the WeatherAPI service. You can specify the location, number of days, and temperature units.

```applescript
-- Get weather forecast for a location
-- Requires API key from WeatherAPI.com

-- Arguments from MCP
-- Location is a required parameter (city name or postal code)
-- Days is optional (number of forecast days, 1-7)
-- Units is optional ('c' for Celsius, 'f' for Fahrenheit)
property location : "--MCP_INPUT:location"
property days : "--MCP_INPUT:days"
property units : "--MCP_INPUT:units"

-- Set default values if not specified
if days is "" or days is "--MCP_INPUT:days" then
    set days to "3"
end if

if units is "" or units is "--MCP_INPUT:units" then
    set units to "c"
end if

-- Validate days parameter
try
    set daysNum to days as number
    if daysNum < 1 or daysNum > 7 then
        set days to "3"
    end if
on error
    set days to "3"
end try

-- Prepare API request parameters
set apiKey to "YOUR_API_KEY" -- Replace with actual API key
set encodedLocation to encodeText(location)

-- Build and execute the API request
set apiURL to "https://api.weatherapi.com/v1/forecast.json?key=" & apiKey & "&q=" & encodedLocation & "&days=" & days & "&aqi=no&alerts=no"
set weatherData to do shell script "curl -s '" & apiURL & "'"

-- Parse JSON using the system's plutil command (built into macOS)
set jsonFile to (path to temporary items folder as text) & "forecast_data.json"
do shell script "echo " & quoted form of weatherData & " > " & quoted form of jsonFile
set jsonDict to do shell script "plutil -convert xml1 -o - " & quoted form of jsonFile

-- Extract location information
set locationName to extractValue(jsonDict, "location.name")
set region to extractValue(jsonDict, "location.region")
set country to extractValue(jsonDict, "location.country")

-- Format results header
set forecastResults to "Weather Forecast for " & locationName
if region is not "" then set forecastResults to forecastResults & ", " & region
set forecastResults to forecastResults & ", " & country & "
"

-- Extract forecast days
set forecastDayCount to extractCount(jsonDict, "forecast.forecastday")
set forecastDayCount to min of forecastDayCount and (days as number)

-- Process each forecast day
repeat with i from 0 to forecastDayCount - 1
    set dateValue to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "date")
    set formattedDate to formatDate(dateValue)
    set maxTempC to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.maxtemp_c")
    set maxTempF to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.maxtemp_f")
    set minTempC to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.mintemp_c")
    set minTempF to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.mintemp_f")
    set condition to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.condition.text")
    set chanceOfRain to extractValueAtIndex(jsonDict, "forecast.forecastday", i, "day.daily_chance_of_rain")
    
    -- Determine which temperature to display based on units parameter
    set displayMaxTemp to maxTempC & "°C"
    set displayMinTemp to minTempC & "°C"
    
    if units is "f" then
        set displayMaxTemp to maxTempF & "°F"
        set displayMinTemp to minTempF & "°F"
    end if
    
    -- Add day forecast to results
    set forecastResults to forecastResults & "
" & formattedDate & ":
Conditions: " & condition & "
Temperature: " & displayMinTemp & " to " & displayMaxTemp & "
Chance of Rain: " & chanceOfRain & "%
"
end repeat

-- Clean up temporary file
do shell script "rm " & quoted form of jsonFile

-- Return the weather forecast
return forecastResults

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

-- Helper function to extract value at specific index in an array
on extractValueAtIndex(xmlText, arrayPath, index, keyPath)
    set shellCommand to "awk '/<key>" & last item of splitString(arrayPath, ".") & "<\\/key>/,/<\\/array>/' <<< " & quoted form of xmlText & " | grep -A200 '<dict>' | awk 'BEGIN{c=0} /<dict>/{c++} c==" & (index + 1) & "'"
    
    set arrayItem to do shell script shellCommand
    
    set keys to my splitString(keyPath, ".")
    set shellCommand to "grep -A1 '<key>" & item 1 of keys & "</key>' <<< " & quoted form of arrayItem
    
    repeat with i from 2 to count of keys
        set shellCommand to shellCommand & " | grep -A1 '<key>" & item i of keys & "</key>'"
    end repeat
    
    set shellCommand to shellCommand & " | grep -v '<key>' | sed -e 's/<[^>]*>//g' -e 's/^[[:space:]]*//'"
    
    try
        return do shell script shellCommand
    on error
        return ""
    end try
end extractValueAtIndex

-- Helper function to count items in an array
on extractCount(xmlText, arrayPath)
    set shellCommand to "awk '/<key>" & last item of splitString(arrayPath, ".") & "<\\/key>/,/<\\/array>/' <<< " & quoted form of xmlText & " | grep -c '<dict>'"
    
    try
        return do shell script shellCommand as number
    on error
        return 0
    end try
end extractCount

-- Helper function to split string by delimiter
on splitString(theString, theDelimiter)
    set oldDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theItems to every text item of theString
    set AppleScript's text item delimiters to oldDelimiters
    return theItems
end splitString

-- Helper function to format date (YYYY-MM-DD to Day, Month Date)
on formatDate(dateStr)
    set dateComponents to splitString(dateStr, "-")
    set yr to item 1 of dateComponents
    set mo to item 2 of dateComponents as number
    set dy to item 3 of dateComponents as number
    
    set monthNames to {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
    set monthName to item mo of monthNames
    
    set cmd to "date -j -f '%Y-%m-%d' '" & dateStr & "' +'%A'"
    set dayOfWeek to do shell script cmd
    
    return dayOfWeek & ", " & monthName & " " & dy
end formatDate
```

## Example Usage

### Get a 3-Day Forecast for London in Celsius
```applescript
set location to "London"
set days to "3"
set units to "c"
-- Execute the script to get weather forecast for London
```

### Get a 7-Day Forecast for Paris in Fahrenheit
```applescript
set location to "Paris"
set days to "7"
set units to "f"
-- Execute the script to get weather forecast for Paris
```

### Get a Forecast with Default Values
```applescript
set location to "Tokyo"
-- Days will default to 3
-- Units will default to Celsius
-- Execute the script to get weather forecast for Tokyo
```

## Notes

1. This script requires an API key from [WeatherAPI.com](https://www.weatherapi.com/). You'll need to register for a free account and replace `YOUR_API_KEY` with your actual API key.

2. The script uses macOS built-in tools for JSON parsing to avoid dependencies.

3. The free tier of WeatherAPI.com allows retrieving up to 7 days of forecast.

4. Error handling is minimal for simplicity - in a production environment, you should add more robust error handling.

5. If you intend to use this script frequently, consider storing the API key in the macOS Keychain for better security.
