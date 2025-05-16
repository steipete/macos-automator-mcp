---
title: 'iOS Simulator: Change Language and Region'
category: 13_developer/xcode_app
id: ios_simulator_change_language
description: Changes the language and region settings of an iOS Simulator device.
keywords:
  - iOS Simulator
  - Xcode
  - language
  - locale
  - region
  - internationalization
  - localization
  - i18n
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Language code as 'languageCode' (e.g., 'en-US', 'fr-FR', 'ja-JP'), optional
  region code as 'regionCode' (defaults to match language if not specified),
  optional device identifier as 'deviceIdentifier' (defaults to 'booted'), and
  optional boolean to restart simulator as 'restartSimulator' (default is true).
notes: |
  - Changes simulator language and region settings
  - Useful for testing app localization without manual setting changes
  - Avoids tedious navigation through Settings app
  - Language and region changes take effect after simulator restart
  - Supports all iOS language and region codes
  - The simulator must be booted initially, but will restart if required
---

```applescript
--MCP_INPUT:languageCode
--MCP_INPUT:regionCode
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:restartSimulator

on changeSimulatorLanguage(languageCode, regionCode, deviceIdentifier, restartSimulator)
  if languageCode is missing value or languageCode is "" then
    return "error: Language code not provided. Specify a valid language code like 'en-US', 'fr-FR', 'ja-JP', etc."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default region to match language if not specified
  if regionCode is missing value or regionCode is "" then
    if languageCode contains "-" then
      -- Extract region from language code if it has a region component
      set dash_pos to offset of "-" in languageCode
      set regionCode to text (dash_pos + 1) thru -1 of languageCode
    else
      -- Default to same as language code (might not be valid for all languages)
      set regionCode to text 1 thru 2 of languageCode
    end if
  end if
  
  -- Default restart to true if not specified
  if restartSimulator is missing value or restartSimulator is "" then
    set restartSimulator to true
  else if restartSimulator is "false" then
    set restartSimulator to false
  end if
  
  try
    -- Get UUID of the device (if name was provided)
    set deviceUUID to deviceIdentifier
    if deviceIdentifier is not "booted" and deviceIdentifier does not contain "-" then
      -- Probably a name, get the UUID
      set getUUIDCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "' | head -1 | sed -E 's/.*\\(([A-Z0-9-]+)\\).*/\\1/'"
      try
        set deviceUUID to do shell script getUUIDCmd
        if deviceUUID is "" then
          return "error: Could not find device with name '" & deviceIdentifier & "'. Check available devices."
        end if
      on error
        return "error: Could not determine UUID for device '" & deviceIdentifier & "'."
      end try
    end if
    
    -- Get the data directory for the device
    set deviceDataDirCmd to "xcrun simctl getenv " & quoted form of deviceIdentifier & " SIMULATOR_SHARED_RESOURCES_DIRECTORY 2>/dev/null || echo ''"
    set deviceDataDir to do shell script deviceDataDirCmd
    
    if deviceDataDir is "" then
      -- Alternative method for older Xcode versions
      set deviceDataDirCmd to "xcrun simctl list devices -j | grep -A 2 '" & deviceUUID & "' | grep 'dataPath' | sed -E 's/.*\"dataPath\" : \"(.*)\".*/\\1/'"
      try
        set deviceDataDir to do shell script deviceDataDirCmd
      on error
        return "error: Could not determine data directory for device. Make sure the simulator is booted."
      end try
    end if
    
    if deviceDataDir is "" then
      return "error: Unable to locate simulator data directory. Make sure the device is booted."
    end if
    
    -- Path to preferences file
    set prefsPath to deviceDataDir & "/Library/Preferences/.GlobalPreferences.plist"
    
    -- Check if the preferences file exists
    set checkPrefsCmd to "test -f " & quoted form of prefsPath & " && echo 'exists' || echo 'not found'"
    set prefsExist to do shell script checkPrefsCmd
    
    if prefsExist is "not found" then
      return "error: Preferences file not found at " & prefsPath & ". Make sure the simulator is properly initialized."
    end if
    
    -- Update language and region settings
    set updateLangCmd to "plutil -replace AppleLanguages -json '[ \"" & languageCode & "\" ]' " & quoted form of prefsPath
    set updateRegionCmd to "plutil -replace AppleLocale -string " & quoted form of regionCode & " " & quoted form of prefsPath
    
    try
      do shell script updateLangCmd
      do shell script updateRegionCmd
      set settingsUpdated to true
    on error errMsg
      return "Error updating language settings: " & errMsg
    end try
    
    -- Restart simulator if requested
    if restartSimulator and settingsUpdated then
      try
        -- Shut down and restart the simulator
        do shell script "xcrun simctl shutdown " & quoted form of deviceIdentifier
        delay 2
        do shell script "xcrun simctl boot " & quoted form of deviceUUID
        
        -- Launch Simulator app to show the device
        tell application "Simulator" to activate
        
        set restartedSimulator to true
      on error errMsg
        set restartedSimulator to false
      end try
    end if
    
    if settingsUpdated then
      return "Successfully updated language to '" & languageCode & "' and region to '" & regionCode & "' for " & deviceIdentifier & " simulator.
" & (if restartSimulator then "
Simulator " & (if restartedSimulator then "was" else "could not be") & " restarted.
" else "
Note: Changes will take effect after restarting the simulator.
To restart manually, run:
xcrun simctl shutdown " & deviceIdentifier & " && xcrun simctl boot " & deviceIdentifier) & "

The simulator will now use " & languageCode & " for all system text and appropriate region formatting."
    else
      return "Failed to update language and region settings for " & deviceIdentifier
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") changing simulator language: " & errMsg
  end try
end changeSimulatorLanguage

return my changeSimulatorLanguage("--MCP_INPUT:languageCode", "--MCP_INPUT:regionCode", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:restartSimulator")
```
