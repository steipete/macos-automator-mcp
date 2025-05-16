---
title: 'iOS Simulator: Manage App Privacy Permissions'
category: 13_developer
id: ios_simulator_privacy_permissions
description: Manages privacy permissions for an app in the iOS Simulator.
keywords:
  - iOS Simulator
  - Xcode
  - privacy
  - permissions
  - camera
  - photos
  - location
  - contacts
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  App bundle ID as 'bundleID', permission type as 'permissionType' (e.g.,
  'photos', 'camera', 'location', 'contacts', 'calendar', 'microphone', or
  'all'), action as 'action' ('grant', 'revoke', or 'reset'), and optional
  device identifier as 'deviceIdentifier' (defaults to 'booted').
notes: >
  - Manages app privacy permissions without manual interaction

  - Available permission types: photos, camera, location, contacts, calendar,
  microphone, etc.

  - Supports grant, revoke, and reset actions

  - Reset action returns permission to "undefined" state, showing prompt again

  - Useful for testing permission flows and different permission states

  - Requires the app to be installed on the simulator
---

```applescript
--MCP_INPUT:bundleID
--MCP_INPUT:permissionType
--MCP_INPUT:action
--MCP_INPUT:deviceIdentifier

on manageAppPrivacyPermissions(bundleID, permissionType, action, deviceIdentifier)
  if bundleID is missing value or bundleID is "" then
    return "error: Bundle ID not provided. Specify the app's bundle identifier."
  end if
  
  if permissionType is missing value or permissionType is "" then
    return "error: Permission type not provided. Available types: photos, camera, location, contacts, calendar, microphone, media-library, reminders, motion, speech-recognition, all"
  end if
  
  if action is missing value or action is "" then
    return "error: Action not provided. Available actions: grant, revoke, reset"
  end if
  
  -- Convert to lowercase for consistent comparison
  set permissionType to do shell script "echo " & quoted form of permissionType & " | tr '[:upper:]' '[:lower:]'"
  set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Validate action
  if action is not in {"grant", "revoke", "reset"} then
    return "error: Invalid action. Must be 'grant', 'revoke', or 'reset'."
  end if
  
  -- Validate permission type
  set validPermissions to {"photos", "camera", "location", "contacts", "calendar", "microphone", "media-library", "reminders", "motion", "speech-recognition", "all"}
  
  -- Allow common variations and typos
  if permissionType is "photo" then set permissionType to "photos"
  if permissionType is "contact" then set permissionType to "contacts"
  if permissionType is "mic" then set permissionType to "microphone"
  if permissionType is "media" then set permissionType to "media-library"
  if permissionType is "reminder" then set permissionType to "reminders"
  if permissionType is "speech" then set permissionType to "speech-recognition"
  
  if permissionType is not in validPermissions then
    return "error: Invalid permission type. Available types: photos, camera, location, contacts, calendar, microphone, media-library, reminders, motion, speech-recognition, all"
  end if
  
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
    
    -- Execute the privacy permission command
    set privacyCmd to "xcrun simctl privacy " & quoted form of deviceIdentifier & " " & action & " " & permissionType & " " & quoted form of bundleID
    
    try
      do shell script privacyCmd
      set permissionUpdated to true
    on error errMsg
      return "Error managing privacy permission: " & errMsg
    end try
    
    if permissionUpdated then
      set actionVerb to ""
      if action is "grant" then
        set actionVerb to "granted"
      else if action is "revoke" then
        set actionVerb to "revoked"
      else if action is "reset" then
        set actionVerb to "reset"
      end if
      
      set permissionName to ""
      if permissionType is "all" then
        set permissionName to "all privacy permissions"
      else
        set permissionName to permissionType & " permission"
      end if
      
      return "Successfully " & actionVerb & " " & permissionName & " for " & bundleID & " on " & deviceIdentifier & " simulator.

Command executed:
" & privacyCmd & "

Notes:
- If this was a 'reset' action, the app will prompt for permission again next time
- Permission changes take effect immediately"
    else
      return "Failed to " & action & " " & permissionType & " permission for " & bundleID
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") managing privacy permissions: " & errMsg
  end try
end manageAppPrivacyPermissions

return my manageAppPrivacyPermissions("--MCP_INPUT:bundleID", "--MCP_INPUT:permissionType", "--MCP_INPUT:action", "--MCP_INPUT:deviceIdentifier")
```
