---
title: 'Date, Time, and Timezone Settings'
category: 04_system
id: system_date_time_timezone
description: >-
  Control date, time, and timezone settings on macOS using AppleScript with
  shell commands or UI scripting.
keywords:
  - date
  - time
  - timezone
  - clock
  - NTP
  - systemsetup
  - System Settings
  - Date & Time
language: applescript
notes: >
  - Shell commands require administrator privileges for most date/time
  operations

  - Both shell-based and UI scripting approaches are provided

  - The UI scripting approach will need adjustment based on macOS version

  - Time zone setting via shell is more reliable than UI scripting
---

This script demonstrates how to manage date, time, and timezone settings on macOS using shell commands and UI scripting.

```applescript
-- Date, Time, and Timezone Management

-- 1. Get current date, time, and timezone information
on getDateTimeInfo()
  try
    -- Get system date and time
    set currentDate to do shell script "date"
    
    -- Get timezone settings
    set tzInfo to do shell script "systemsetup -gettimezone"
    
    -- Get network time server status
    set ntpStatus to do shell script "systemsetup -getusingnetworktime"
    
    -- Get network time server
    set ntpServer to do shell script "systemsetup -getnetworktimeserver"
    
    -- Get sleep and wake schedule if any
    set sleepInfo to do shell script "pmset -g sched"
    
    -- Combine all information
    set dateTimeReport to "Date & Time Configuration:" & return & return & ¬
      "Current Date/Time: " & currentDate & return & ¬
      tzInfo & return & ¬
      ntpStatus & return & ¬
      ntpServer & return & return & ¬
      "Sleep/Wake Schedule:" & return & sleepInfo
      
    return dateTimeReport
    
  on error errMsg
    return "Error getting date/time information: " & errMsg
  end try
end getDateTimeInfo

-- 2. Set timezone via shell command (requires administrator privileges)
on setTimezoneShell(timeZoneValue)
  if timeZoneValue is missing value or timeZoneValue is "" then
    return "error: Time zone value not provided."
  end if
  
  try
    -- List available time zones to provide examples
    set tzListCmd to "systemsetup -listtimezones | head -10"
    set tzExamples to do shell script tzListCmd
    
    -- Set the time zone (requires administrator privileges)
    set tzSetCmd to "systemsetup -settimezone " & quoted form of timeZoneValue
    
    do shell script tzSetCmd with administrator privileges
    
    -- Verify the new setting was applied
    set verifyCmd to "systemsetup -gettimezone"
    set newTzInfo to do shell script verifyCmd
    
    return "Time zone successfully set:" & return & newTzInfo & return & return & ¬
      "Example time zones:" & return & tzExamples & return & ¬
      "(Run 'systemsetup -listtimezones' to see all available time zones)"
    
  on error errMsg
    return "Error setting timezone: " & errMsg & return & return & ¬
      "Note: Valid time zone formats include:" & return & ¬
      "• America/New_York" & return & ¬
      "• Europe/London" & return & ¬
      "• Asia/Tokyo" & return & ¬
      "Run 'systemsetup -listtimezones' to see all available time zones."
  end try
end setTimezoneShell

-- 3. Set network time (NTP) settings
on configureNetworkTime(enableNTP, ntpServer)
  try
    -- Enable or disable network time synchronization
    if enableNTP is not missing value then
      set ntpCmd to "systemsetup -setusingnetworktime " & (if enableNTP then "on" else "off")
      do shell script ntpCmd with administrator privileges
      
      set ntpStatus to if enableNTP then "enabled" else "disabled"
      set resultMsg to "Network time synchronization " & ntpStatus & "." & return
    else
      set resultMsg to ""
    end if
    
    -- Set custom NTP server if provided
    if ntpServer is not missing value and ntpServer is not "" and enableNTP is true then
      set serverCmd to "systemsetup -setnetworktimeserver " & quoted form of ntpServer
      do shell script serverCmd with administrator privileges
      
      set resultMsg to resultMsg & "Network time server set to: " & ntpServer
    end if
    
    return resultMsg
  on error errMsg
    return "Error configuring network time: " & errMsg
  end try
end configureNetworkTime

-- 4. Set date and time manually (use only when not using network time)
on setDateTime(newDate, newTime)
  -- newDate format: MM:DD:YY (e.g., "01:31:22" for January 31, 2022)
  -- newTime format: HH:MM:SS (e.g., "15:30:00" for 3:30 PM)
  
  if newDate is missing value or newDate is "" then
    return "error: Date not provided (format: MM:DD:YY)."
  end if
  
  if newTime is missing value or newTime is "" then
    return "error: Time not provided (format: HH:MM:SS)."
  end if
  
  try
    -- First, disable network time if needed
    do shell script "systemsetup -setusingnetworktime off" with administrator privileges
    
    -- Set the date and time
    set dateTimeCmd to "systemsetup -setdate " & quoted form of newDate & " -settime " & quoted form of newTime
    do shell script dateTimeCmd with administrator privileges
    
    -- Verify the new date and time
    set currentDateTime to do shell script "date"
    
    return "Date and time manually set to:" & return & currentDateTime & return & return & ¬
      "Note: Network time synchronization has been disabled."
    
  on error errMsg
    return "Error setting date and time: " & errMsg & return & ¬
      "Ensure date format is MM:DD:YY and time format is HH:MM:SS."
  end try
end setDateTime

-- 5. Set timezone via UI scripting (alternative approach)
-- Note: This is more fragile and depends on macOS version/language
on setTimezoneUI(regionName)
  try
    tell application "System Settings"
      activate
      delay 1 -- Give time for app to open
      
      -- Navigate to Date & Time settings
      -- Note: Path may vary by macOS version
      tell application "System Events"
        -- Click on Date & Time in the sidebar
        click menu item "Date & Time" of menu "View" of menu bar 1 of application process "System Settings"
        delay 0.5
        
        -- Click on the Timezone tab
        click radio button "Time Zone" of tab group 1 of group 1 of window "Date & Time" of application process "System Settings"
        delay 0.5
        
        -- Click on the map near the region (this is approximate)
        -- This is very brittle and depends on screen resolution and macOS version
        -- A more reliable approach is to use the search field
        
        -- Use the search field
        set tzSearchField to text field 1 of group 1 of window "Date & Time" of application process "System Settings"
        set focused of tzSearchField to true
        keystroke regionName
        delay 1
        keystroke return
        delay 0.5
        
        -- Close System Settings
        keystroke "w" using {command down}
      end tell
      
      return "Time zone setting attempted for: " & regionName & " (via UI)"
    end tell
  on error errMsg
    return "Error with UI approach: " & errMsg & return & ¬
      "UI scripting is fragile and dependent on macOS version. Consider using the shell approach instead."
  end try
end setTimezoneUI

-- Example usage
set currentInfo to my getDateTimeInfo()
-- set tzResult to my setTimezoneShell("America/New_York")
-- set ntpResult to my configureNetworkTime(true, "time.apple.com")
-- set dateTimeResult to my setDateTime("01:31:23", "14:30:00")

return currentInfo
```

This script provides five main functions for managing date, time, and timezone settings:

1. **Get Date & Time Information**
   - Displays current date and time 
   - Shows timezone configuration
   - Indicates network time synchronization status
   - Lists any scheduled sleep or wake times

2. **Set Timezone via Shell Command**
   - Uses `systemsetup -settimezone` to change the timezone
   - Requires administrator privileges
   - Accepts standard timezone identifiers (e.g., "America/Los_Angeles")
   - Provides examples of available timezones

3. **Configure Network Time**
   - Enables or disables automatic time synchronization
   - Sets custom NTP servers if desired
   - Requires administrator privileges

4. **Set Date and Time Manually**
   - Allows manual setting of the system clock
   - Automatically disables network time synchronization
   - Uses formats MM:DD:YY for date and HH:MM:SS for time
   - Requires administrator privileges

5. **Set Timezone via UI Scripting**
   - Alternative approach using System Settings UI
   - More fragile but useful when shell access is limited
   - Searches for timezone region by name
   - Attempts to navigate through Date & Time preferences

Common use cases:
- Automating timezone changes for travelers
- Setting up consistent date/time configurations on multiple Macs
- Ensuring NTP synchronization is properly configured
- Setting custom time servers for specialized environments

Remember that most date and time operations require administrator access, as they affect system-wide settings. The shell-based approaches are generally more reliable and easier to automate than UI scripting.
END_TIP
