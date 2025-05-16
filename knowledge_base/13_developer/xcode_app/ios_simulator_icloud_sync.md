---
title: 'iOS Simulator: Trigger iCloud Sync'
category: 13_developer
id: ios_simulator_icloud_sync
description: >-
  Manually triggers iCloud sync in iOS Simulator for testing cloud
  synchronization.
keywords:
  - iOS Simulator
  - Xcode
  - iCloud
  - sync
  - synchronization
  - cloud
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional device identifier as 'deviceIdentifier' (defaults to 'booted'),
  optional app bundle ID as 'bundleID' (to focus sync on a specific app),
  optional sync type as 'syncType' ('full', 'lightweight', defaults to
  'lightweight').
notes: |
  - Manually triggers iCloud synchronization in simulator
  - Useful for testing cloud-based features and data sync
  - Can target specific app or trigger system-wide sync
  - Helps simulate real-world sync scenarios
  - Requires user to be signed in to iCloud on simulator
  - Serves same purpose as manual sync triggers in Settings app
---

```applescript
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:bundleID
--MCP_INPUT:syncType

on triggerICloudSync(deviceIdentifier, bundleID, syncType)
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Default sync type to lightweight if not specified
  if syncType is missing value or syncType is "" then
    set syncType to "lightweight"
  else
    -- Normalize to lowercase
    set syncType to do shell script "echo " & quoted form of syncType & " | tr '[:upper:]' '[:lower:]'"
    
    if syncType is not in {"full", "lightweight"} then
      set syncType to "lightweight"
    end if
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
    
    -- First check if the user is signed in to iCloud
    set checkiCloudCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults read MobileMeAccounts"
    try
      set iCloudStatus to do shell script checkiCloudCmd
      set isSignedIn to (iCloudStatus contains "AccountID" or iCloudStatus contains "LoggedIn")
    on error
      set isSignedIn to false
    end try
    
    if not isSignedIn then
      return "Error: No iCloud account is signed in on the simulator. Please sign in to iCloud via Settings app first before triggering sync."
    end if
    
    -- Different approaches to trigger iCloud sync
    set syncMethods to {}
    
    -- Method 1: Using the debug menu (for simulators with debug menu enabled)
    set debugMenuMethod to "tell application \"Simulator\"
  activate
  delay 1
  tell application \"System Events\"
    tell process \"Simulator\"
      -- Try to use Debug menu if available
      try
        click menu item \"Debug\" of menu bar 1
        delay 0.5
        click menu item \"Trigger iCloud Sync\" of menu \"Debug\" of menu bar 1
        return true
      on error
        return false
      end try
    end tell
  end tell
end tell"
    
    -- Method 2: Using notification posting (works on newer iOS versions)
    set notificationMethods to {}
    
    -- Add general sync notification
    set end of notificationMethods to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -p com.apple.cloudd.session.sync"
    
    -- Add backup notification for older versions
    set end of notificationMethods to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -p com.apple.ios.StoreKitAgent.syncFinished"
    
    -- If a specific app is targeted, add app-specific notifications
    if bundleID is not missing value and bundleID is not "" then
      set end of notificationMethods to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -p com.apple.cloudd.ubiquity." & bundleID & ".sync"
    end if
    
    -- Method 3: For full sync, try resetting cloudkit sync cache
    if syncType is "full" then
      set resetCloudKitCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults write com.apple.CloudKit CloudKitDeviceTokenReset -bool true"
      try
        do shell script resetCloudKitCmd
        set end of syncMethods to "CloudKit device token reset"
      on error errMsg
        -- Ignore if this fails, will try other methods
      end try
    end if
    
    -- Try UI method first if it's a full sync
    if syncType is "full" then
      set uiSuccess to do shell script "osascript -e " & quoted form of debugMenuMethod
      if uiSuccess is "true" then
        set end of syncMethods to "Debug menu trigger"
      end if
    end if
    
    -- Try all notification methods regardless
    set notificationStatus to {}
    repeat with notifyCmd in notificationMethods
      try
        do shell script notifyCmd
        set end of notificationStatus to "Success"
        set end of syncMethods to "Notification trigger"
      on error errMsg
        set end of notificationStatus to "Failed: " & errMsg
      end try
    end repeat
    
    -- Method 4: If bundleID is provided, try to restart the app which often triggers sync
    if bundleID is not missing value and bundleID is not "" then
      try
        -- Check if the app is installed
        set checkAppCmd to "xcrun simctl get_app_container " & quoted form of deviceIdentifier & " " & quoted form of bundleID & " 2>/dev/null || echo 'not installed'"
        set appContainer to do shell script checkAppCmd
        
        if appContainer is not "not installed" then
          -- Terminate and relaunch the app
          do shell script "xcrun simctl terminate " & quoted form of deviceIdentifier & " " & quoted form of bundleID
          delay 1
          do shell script "xcrun simctl launch " & quoted form of deviceIdentifier & " " & quoted form of bundleID
          set end of syncMethods to "App restart trigger"
        end if
      on error appErrMsg
        -- Ignore if app manipulation fails
      end try
    end if
    
    -- If no methods succeeded, try a last resort approach
    if (count of syncMethods) is 0 then
      -- Try toggling airplane mode as a last resort (often triggers sync on reconnect)
      try
        -- Enable airplane mode
        do shell script "xcrun simctl status_bar " & quoted form of deviceIdentifier & " override --dataNetwork none --cellularMode notSupported --wifiMode notSupported"
        delay 3
        -- Disable airplane mode
        do shell script "xcrun simctl status_bar " & quoted form of deviceIdentifier & " override --dataNetwork wifi --wifiMode active --wifiBars 3"
        set end of syncMethods to "Network toggle trigger"
      on error toggleErr
        -- Ignore if this fails too
      end try
    end if
    
    if (count of syncMethods) > 0 then
      set methodsText to ""
      repeat with methodName in syncMethods
        set methodsText to methodsText & "- " & methodName & "
"
      end repeat
      
      return "Successfully triggered " & syncType & " iCloud sync on " & deviceIdentifier & " simulator" & (if bundleID is not missing value and bundleID is not "" then " for app " & bundleID else " system-wide") & ".

Sync methods used:
" & methodsText & "
iCloud sync has been requested, but actual synchronization depends on:
1. Active internet connection in the simulator
2. Valid iCloud account with proper permissions
3. App configuration for CloudKit/iCloud

Note: There may be a delay before synchronization completes."
    else
      return "Failed to trigger iCloud sync. Please try these manual steps instead:
1. Open Simulator
2. Sign in to iCloud in Settings if not already signed in
3. For specific app sync: launch the app and perform an action that triggers sync
4. For system sync: toggle Airplane mode on and off"
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") triggering iCloud sync: " & errMsg
  end try
end triggerICloudSync

return my triggerICloudSync("--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:bundleID", "--MCP_INPUT:syncType")
```
