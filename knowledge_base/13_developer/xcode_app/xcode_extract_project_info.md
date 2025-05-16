---
title: "Xcode: Extract Project Info from Info.plist"
category: "09_developer_and_utility_apps"
id: xcode_extract_project_info
description: "Extracts app metadata from Info.plist in an Xcode project."
keywords: ["Xcode", "Info.plist", "bundle", "identifier", "version", "metadata", "developer", "iOS", "macOS"]
language: applescript
isComplex: true
argumentsPrompt: "Absolute POSIX path to the project's Info.plist file as 'plistPath' in inputData"
notes: |
  - Does not require Xcode to be open
  - Extracts common metadata like bundle ID, version, build number, etc.
  - Uses PlistBuddy command-line tool which is built into macOS
  - Results are returned as a formatted string with key information
  - Useful for automation scripts that need to extract project metadata
---

```applescript
--MCP_INPUT:plistPath

on extractProjectInfo(plistPath)
  if plistPath is missing value or plistPath is "" then
    return "error: Info.plist path not provided."
  end if
  
  try
    -- Use PlistBuddy to extract key information
    set bundleIdCmd to "/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' " & quoted form of plistPath & " 2>/dev/null"
    set versionCmd to "/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' " & quoted form of plistPath & " 2>/dev/null"
    set buildCmd to "/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' " & quoted form of plistPath & " 2>/dev/null"
    set nameCmd to "/usr/libexec/PlistBuddy -c 'Print CFBundleName' " & quoted form of plistPath & " 2>/dev/null"
    set displayNameCmd to "/usr/libexec/PlistBuddy -c 'Print CFBundleDisplayName' " & quoted form of plistPath & " 2>/dev/null"
    set minimumOSCmd to "/usr/libexec/PlistBuddy -c 'Print MinimumOSVersion' " & quoted form of plistPath & " 2>/dev/null"
    
    -- Execute commands and get results
    set bundleId to do shell script bundleIdCmd
    if bundleId is "" then set bundleId to "Not found"
    
    set versionNumber to do shell script versionCmd
    if versionNumber is "" then set versionNumber to "Not found"
    
    set buildNumber to do shell script buildCmd
    if buildNumber is "" then set buildNumber to "Not found"
    
    set appName to do shell script nameCmd
    if appName is "" then
      try
        set appName to do shell script displayNameCmd
      on error
        set appName to "Not found"
      end try
    end if
    
    set minOS to do shell script minimumOSCmd
    if minOS is "" then set minOS to "Not found"
    
    -- Get additional useful information if available
    try
      set deviceFamilyCmd to "/usr/libexec/PlistBuddy -c 'Print UIDeviceFamily' " & quoted form of plistPath & " 2>/dev/null"
      set deviceFamilyRaw to do shell script deviceFamilyCmd
      
      -- Process device family data
      set deviceTypes to ""
      if deviceFamilyRaw contains "1" then set deviceTypes to deviceTypes & "iPhone, "
      if deviceFamilyRaw contains "2" then set deviceTypes to deviceTypes & "iPad, "
      if deviceFamilyRaw contains "3" then set deviceTypes to deviceTypes & "Apple TV, "
      if deviceFamilyRaw contains "4" then set deviceTypes to deviceTypes & "Apple Watch, "
      if deviceFamilyRaw contains "7" then set deviceTypes to deviceTypes & "Vision Pro, "
      
      -- Remove trailing comma and space if needed
      if deviceTypes ends with ", " then
        set deviceTypes to text 1 thru -3 of deviceTypes
      end if
      
      if deviceTypes is "" then set deviceTypes to "Not specified"
    on error
      set deviceTypes to "Not specified"
    end try
    
    -- Format the result
    set infoText to "
App Name: " & appName & "
Bundle Identifier: " & bundleId & "
Version: " & versionNumber & "
Build: " & buildNumber & "
Minimum OS Version: " & minOS & "
Device Types: " & deviceTypes & "
Info.plist Path: " & plistPath
    
    return infoText
  on error errMsg number errNum
    return "error (" & errNum & ") extracting project info: " & errMsg
  end try
end extractProjectInfo

return my extractProjectInfo("--MCP_INPUT:plistPath")
```