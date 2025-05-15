---
title: "File Extension Associations in Modern macOS"
description: "Understanding and managing file extension to application associations in modern macOS with AppleScript"
author: "Claude"
category: "03_file_system_and_finder"
subcategory: "metadata_and_attributes_finder"
tags: ["file extension", "file association", "default application", "file types", "duti", "lsregister"]
language: "applescript"
version: "1.0"
validated: true
---

# File Extension Associations in Modern macOS

In modern macOS, file type associations (which application opens which file type) are handled through the Launch Services database rather than the legacy File Exchange Control Panel. This article explains how to view and modify these associations using AppleScript and shell commands.

## Viewing Current File Associations

### Using Finder's Get Info Dialog

```applescript
-- This script will open the Get Info panel for a selected file,
-- which allows viewing the current application association and changing it

tell application "Finder"
  if selection is {} then
    display dialog "Please select a file first" buttons {"OK"} default button "OK" with icon stop
    return
  end if
  
  set selectedFile to item 1 of selection
  open information window of selectedFile
end tell
```

### Listing File Associations via Shell Commands

```applescript
-- Get file associations for a specific extension using lsregister
on getFileAssociations(fileExtension)
  set theExtension to fileExtension
  -- Remove leading period if present
  if character 1 of theExtension is "." then
    set theExtension to text 2 thru -1 of theExtension
  end if
  
  -- Query Launch Services for this extension
  set shellCmd to "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -A 5 -B 5 -E '\\.(" & theExtension & ")$' | grep bindings"
  
  try
    set associationInfo to do shell script shellCmd
    return associationInfo
  on error
    return "No associations found for ." & theExtension
  end try
end getFileAssociations

-- Example usage
set results to getFileAssociations("pdf")
display dialog "Associations for .pdf files:" & return & return & results buttons {"OK"} default button "OK"
```

### Get Default Application for a File Type

```applescript
-- Get the default application for a given file extension
on getDefaultAppForExtension(fileExtension)
  set theExtension to fileExtension
  -- Remove leading period if present
  if character 1 of theExtension is "." then
    set theExtension to text 2 thru -1 of theExtension
  end if
  
  -- Use mdls to query the default handler
  set shellCmd to "mdls -name kMDItemContentType -name kMDItemContentTypeTree /tmp/test." & theExtension & " 2>/dev/null || echo 'Unknown'"
  
  try
    do shell script "touch /tmp/test." & theExtension
    set contentTypeInfo to do shell script shellCmd
    do shell script "rm /tmp/test." & theExtension
    
    -- Now get the default handler for this content type
    -- Extract the content type from mdls output (first line)
    set AppleScript's text item delimiters to "\""
    set contentTypeItems to text items of contentTypeInfo
    if (count of contentTypeItems) > 2 then
      set contentType to item 2 of contentTypeItems
      set defaultAppCmd to "defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A 3 '" & contentType & "' | grep LSHandlerRoleAll | awk -F'=' '{print $2}' | sed 's/;//'"
      try
        set defaultApp to do shell script defaultAppCmd
        if defaultApp is "" then
          return "No default application set for ." & theExtension
        else
          return "Default application for ." & theExtension & ": " & defaultApp
        end if
      on error
        return "No default application found for ." & theExtension
      end try
    else
      return "Could not determine content type for ." & theExtension
    end if
  on error errMsg
    return "Error: " & errMsg
  end try
end getDefaultAppForExtension

-- Example usage
set defaultApp to getDefaultAppForExtension("txt")
display dialog defaultApp buttons {"OK"} default button "OK"
```

## Setting File Associations

### Using Finder UI Scripting

```applescript
-- This script changes the default application for files with a specific extension
-- by UI scripting the Finder's Get Info panel

on setDefaultAppForExtension(fileExtension, appName)
  -- Create a temporary file with the given extension
  set tempFile to "/tmp/temp_file_for_extension_setting." & fileExtension
  
  do shell script "touch " & quoted form of tempFile
  
  tell application "Finder"
    set theFile to POSIX file tempFile as alias
    open information window of theFile
    
    tell application "System Events"
      tell process "Finder"
        delay 1 -- Wait for the info window to fully load
        
        -- Click the "Open with:" disclosure triangle if it's not already expanded
        set disclosureTriangle to (first disclosure triangle of (first window whose title contains "Info"))
        if value of disclosureTriangle is false then
          click disclosureTriangle
          delay 0.5
        end if
        
        -- Click the application popup
        click pop up button 1 of (first window whose title contains "Info")
        delay 0.5
        
        -- Click on the specified application in the popup menu
        click menu item appName of menu 1 of pop up button 1 of (first window whose title contains "Info")
        delay 0.5
        
        -- Click the "Change All..." button
        click button "Change All…" of (first window whose title contains "Info")
        delay 0.5
        
        -- Confirm the change
        click button "Continue" of sheet 1 of (first window whose title contains "Info")
        delay 0.5
      end tell
    end tell
    
    -- Close the info window
    close information window of theFile
  end tell
  
  -- Delete the temporary file
  do shell script "rm " & quoted form of tempFile
  
  return "Successfully set " & appName & " as the default application for ." & fileExtension & " files"
end setDefaultAppForExtension

-- Example usage (be sure the application exists on your system)
setDefaultAppForExtension("txt", "TextEdit")
```

### Using the Duti Tool via Shell Script

Duti is a third-party command-line tool that makes it easier to set file associations.

```applescript
-- This script sets the default application for a file extension using the 'duti' tool
-- Note: duti must be installed first (e.g., via Homebrew: brew install duti)

on setFileAssociationWithDuti(fileExtension, appBundleId)
  set theExtension to fileExtension
  -- Remove leading period if present
  if character 1 of theExtension is "." then
    set theExtension to text 2 thru -1 of theExtension
  end if
  
  -- Check if duti is installed
  try
    do shell script "which duti"
  on error
    return "Duti is not installed. Please install it with 'brew install duti'"
  end try
  
  -- Set the file association
  try
    do shell script "duti -s " & appBundleId & " ." & theExtension & " all"
    return "Successfully set " & appBundleId & " as the default application for ." & theExtension & " files"
  on error errMsg
    return "Error setting file association: " & errMsg
  end try
end setFileAssociationWithDuti

-- Example usage
setFileAssociationWithDuti("txt", "com.apple.TextEdit")
```

## Viewing All File Associations and UTI Information

```applescript
-- This script shows UTI (Uniform Type Identifier) information for a file,
-- which is how macOS categorizes file types under the hood

on getUTIInfo(filePath)
  try
    set posixPath to quoted form of POSIX path of filePath
    set utiInfo to do shell script "mdls -name kMDItemContentType -name kMDItemContentTypeTree " & posixPath
    
    return "UTI Information for " & filePath & ":" & return & return & utiInfo
  on error errMsg
    return "Error getting UTI information: " & errMsg
  end try
end getUTIInfo

-- Example usage
tell application "Finder"
  if selection is {} then
    display dialog "Please select a file" buttons {"OK"} default button "OK" with icon stop
    return
  end if
  
  set selectedFile to item 1 of selection as alias
  set utiInfo to getUTIInfo(selectedFile)
  display dialog utiInfo buttons {"OK"} default button "OK"
end tell
```

## Refreshing the Launch Services Database

```applescript
-- This script refreshes the Launch Services database, which can help if 
-- file associations aren't behaving correctly

on refreshLaunchServices()
  try
    -- Use lsregister to rebuild the Launch Services database
    set cmd to "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
    
    set result to do shell script cmd
    
    -- Also kill Finder to ensure changes take effect
    do shell script "killall Finder"
    
    return "Launch Services database has been refreshed and Finder restarted."
  on error errMsg
    return "Error refreshing Launch Services: " & errMsg
  end try
end refreshLaunchServices

-- Run the function
display dialog refreshLaunchServices() buttons {"OK"} default button "OK"
```

## Notes and Limitations

1. **Modern System**: In modern macOS, file extension associations are managed through Launch Services and UTIs (Uniform Type Identifiers) rather than the legacy File Exchange Control Panel.

2. **UI Scripting Reliability**: UI scripting methods for setting file associations depend on the Finder's UI layout, which can change between macOS versions.

3. **Command-Line Tools**: For more reliable scripting, third-party tools like `duti` provide a command-line interface for setting file associations.

4. **Admin Privileges**: Some operations may require administrator privileges, especially when modifying system-wide settings.

5. **UTI System**: Understanding Apple's UTI (Uniform Type Identifier) system is helpful when working with file types in modern macOS.

6. **Legacy Compatibility**: While modern macOS still maintains compatibility with traditional file extensions, it primarily uses UTIs internally for type identification.