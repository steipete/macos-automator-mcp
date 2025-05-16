---
title: 'App Store: Open Account Page'
category: 13_developer/app_store_app
id: app_store_open_account
description: Opens the account page in the Mac App Store.
keywords:
  - App Store
  - account
  - Apple ID
  - purchased apps
  - account settings
language: applescript
notes: >-
  Opens the account page in the Mac App Store showing purchased apps,
  subscriptions, and account settings.
---

```applescript
try
  tell application "App Store"
    activate
    
    -- Give App Store time to launch
    delay 1
    
    tell application "System Events"
      tell process "App Store"
        -- Click on the Account button (recognizable by the person icon)
        if exists button 1 of group 1 of toolbar 1 of window 1 then
          click button 1 of group 1 of toolbar 1 of window 1
          
          -- Wait for account page to load
          delay 1
          
          -- Check if sign-in is required
          if exists sheet 1 of window 1 then
            -- If a sign-in sheet appears, inform the user
            return "App Store account page requires sign-in. Please sign in with your Apple ID."
          else
            return "App Store account page opened successfully. You can view your purchases, subscriptions, and account settings."
          end if
        else
          -- Alternative approach - try using the Store menu
          click menu item "Store" of menu bar 1
          delay 0.5
          
          if exists menu item "View My Account…" of menu "Store" of menu bar item "Store" of menu bar 1 then
            click menu item "View My Account…" of menu "Store" of menu bar item "Store" of menu bar 1
            delay 1
            
            if exists sheet 1 of window 1 then
              return "App Store account page requires sign-in. Please sign in with your Apple ID."
            else
              return "App Store account page opened successfully. You can view your purchases, subscriptions, and account settings."
            end if
          else
            return "Unable to access the account page. The App Store interface may have changed."
          end if
        end if
      end tell
    end tell
  end tell
  
on error errMsg number errNum
  return "Error (" & errNum & "): Failed to open App Store account page - " & errMsg
end try
```
END_TIP
