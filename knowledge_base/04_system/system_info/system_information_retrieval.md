---
title: System Information Retrieval
category: 04_system/system_info
id: system_information_retrieval
description: >-
  Retrieves various system information including macOS version, hardware
  details, storage info, and more
keywords:
  - system info
  - macOS version
  - hardware
  - storage
  - memory
  - battery
  - network
  - System Events
language: applescript
notes: >-
  Different information requires different permissions. Some functions use shell
  commands for data that isn't directly accessible through AppleScript.
---

```applescript
-- Get macOS version information
on getOSVersion()
  set osVersionDict to (system info)
  set osVersionString to system version of osVersionDict
  set osVersionName to (do shell script "sw_vers -productName")
  set osBuildNumber to (do shell script "sw_vers -buildVersion")
  
  return {version:osVersionString, name:osVersionName, build:osBuildNumber}
end getOSVersion

-- Get system hardware information
on getHardwareInfo()
  set computerName to computer name of (system info)
  
  -- Get processor info via shell command
  set cpuInfo to do shell script "sysctl -n machdep.cpu.brand_string"
  
  -- Get memory info
  set totalRAM to (do shell script "sysctl -n hw.memsize") as number
  set totalRAMGB to totalRAM / 1073741824 -- Convert bytes to GB
  set totalRAMGB to round(totalRAMGB * 10) / 10 -- Round to 1 decimal place
  
  -- Get model identifier
  set modelIdentifier to do shell script "sysctl -n hw.model"
  
  -- Get more readable model name
  set modelName to do shell script "system_profiler SPHardwareDataType | awk '/Model Name/ {print $3,$4,$5,$6,$7}' | sed 's/^ *//;s/ *$//'"
  
  -- Get serial number
  set serialNumber to do shell script "system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'"
  
  return {computerName:computerName, cpuInfo:cpuInfo, ramGB:totalRAMGB, modelIdentifier:modelIdentifier, modelName:modelName, serialNumber:serialNumber}
end getHardwareInfo

-- Get storage information
on getStorageInfo()
  -- Get boot volume info
  set bootVolume to startup disk
  
  -- Get disk usage via shell
  set diskInfo to paragraphs of (do shell script "df -h /")
  set diskUsage to paragraph 2 of diskInfo
  
  -- Parse the disk usage information
  set AppleScript's text item delimiters to space
  set diskFields to text items of diskUsage
  set AppleScript's text item delimiters to ""
  
  set totalSize to item 2 of diskFields
  set usedSpace to item 3 of diskFields
  set availableSpace to item 4 of diskFields
  set capacityPercentage to item 5 of diskFields
  
  return {bootVolume:bootVolume, totalSize:totalSize, usedSpace:usedSpace, availableSpace:availableSpace, capacityPercentage:capacityPercentage}
end getStorageInfo

-- Get network configuration
on getNetworkInfo()
  -- Get current Wi-Fi network name
  set currentWiFi to do shell script "networksetup -getairportnetwork en0 | awk '{print $4}'"
  
  -- Get IP addresses
  set ipAddresses to paragraphs of (do shell script "ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'")
  
  -- Get primary network service
  set primaryService to do shell script "networksetup -listnetworkserviceorder | grep '(1)' | cut -d')' -f2 | cut -d, -f1 | sed 's/^ *//;s/ *$//'"
  
  return {wifiNetwork:currentWiFi, ipAddresses:ipAddresses, primaryService:primaryService}
end getNetworkInfo

-- Get battery information (MacBooks only)
on getBatteryInfo()
  try
    set batteryInfo to do shell script "pmset -g batt"
    
    -- Check if there's a battery
    if batteryInfo contains "Battery" then
      -- Extract charging status and percentage
      set batteryPercentage to do shell script "echo '" & batteryInfo & "' | grep -o '[0-9]*%' | cut -d% -f1"
      
      -- Determine charging status
      set chargingStatus to "unknown"
      if batteryInfo contains "charging" then
        set chargingStatus to "charging"
      else if batteryInfo contains "discharging" then
        set chargingStatus to "discharging"
      else if batteryInfo contains "charged" then
        set chargingStatus to "fully charged"
      end if
      
      -- Extract time remaining if available
      set timeRemaining to "unknown"
      if batteryInfo contains ";" then
        set timeRemaining to do shell script "echo '" & batteryInfo & "' | grep -o '[0-9]*:[0-9]*' | head -1"
      end if
      
      return {percentage:batteryPercentage, status:chargingStatus, timeRemaining:timeRemaining, hasBattery:true}
    else
      return {hasBattery:false}
    end if
  on error
    return {hasBattery:false, error:"Unable to get battery information"}
  end try
end getBatteryInfo

-- Example usage: Get all system information
on getAllSystemInfo()
  set osInfo to getOSVersion()
  set hwInfo to getHardwareInfo()
  set storageInfo to getStorageInfo()
  set networkInfo to getNetworkInfo()
  set batteryInfo to getBatteryInfo()
  
  -- Format a summary of the information
  set summary to "System Information Summary:" & return & return
  
  -- OS Info
  set summary to summary & "macOS: " & osInfo's name & " " & osInfo's version & " (" & osInfo's build & ")" & return & return
  
  -- Hardware Info
  set summary to summary & "Hardware:" & return
  set summary to summary & "• Computer Name: " & hwInfo's computerName & return
  set summary to summary & "• Model: " & hwInfo's modelName & " (" & hwInfo's modelIdentifier & ")" & return
  set summary to summary & "• Processor: " & hwInfo's cpuInfo & return
  set summary to summary & "• Memory: " & hwInfo's ramGB & " GB" & return
  set summary to summary & "• Serial Number: " & hwInfo's serialNumber & return & return
  
  -- Storage Info
  set summary to summary & "Storage:" & return
  set summary to summary & "• Boot Volume: " & storageInfo's bootVolume & return
  set summary to summary & "• Total Size: " & storageInfo's totalSize & return
  set summary to summary & "• Used Space: " & storageInfo's usedSpace & " (" & storageInfo's capacityPercentage & ")" & return
  set summary to summary & "• Available Space: " & storageInfo's availableSpace & return & return
  
  -- Network Info
  set summary to summary & "Network:" & return
  set summary to summary & "• Wi-Fi Network: " & networkInfo's wifiNetwork & return
  set summary to summary & "• IP Addresses: " & networkInfo's ipAddresses & return
  set summary to summary & "• Primary Service: " & networkInfo's primaryService & return & return
  
  -- Battery Info (if available)
  if batteryInfo's hasBattery then
    set summary to summary & "Battery:" & return
    set summary to summary & "• Charge: " & batteryInfo's percentage & "%" & return
    set summary to summary & "• Status: " & batteryInfo's status & return
    if batteryInfo's timeRemaining is not "unknown" then
      set summary to summary & "• Time Remaining: " & batteryInfo's timeRemaining & return
    end if
  end if
  
  return summary
end getAllSystemInfo

-- Run the full system information retrieval
getAllSystemInfo()
```

This script provides comprehensive system information retrieval through several specialized handlers:

1. `getOSVersion()` - Retrieves macOS version information including the numeric version, product name, and build number.

2. `getHardwareInfo()` - Gathers hardware details including:
   - Computer name
   - CPU information
   - Total RAM (in GB)
   - Model identifier and friendly name
   - Serial number

3. `getStorageInfo()` - Gets storage information for the boot volume:
   - Volume name
   - Total size
   - Used space
   - Available space
   - Capacity percentage

4. `getNetworkInfo()` - Retrieves network configuration:
   - Current Wi-Fi network name
   - IP addresses
   - Primary network service

5. `getBatteryInfo()` - For MacBooks, gets battery information:
   - Charge percentage
   - Charging status
   - Time remaining (if available)

6. `getAllSystemInfo()` - Combines all the above functions to generate a comprehensive report.

You can use individual functions for specific information or the complete report function. Each handler is designed to handle errors gracefully if specific information isn't available.
