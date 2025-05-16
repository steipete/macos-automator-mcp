---
title: 'Safari: Manage Privacy Features'
category: 07_browsers
id: safari_privacy_features
description: >-
  Controls Safari's privacy features like private browsing, tracking prevention,
  and intelligent tracking prevention.
keywords:
  - Safari
  - privacy
  - private browsing
  - tracking
  - cookies
  - security
  - preferences
  - settings
language: applescript
isComplex: true
argumentsPrompt: >-
  Action to perform as 'action' in inputData. Values: 'private_browsing',
  'track_prevent', 'cookie_block', 'clear_history', 'status'. For toggle
  actions, include 'state' ('on'/'off') in inputData.
notes: >
  - Safari must be installed on the system.

  - This script uses UI automation via System Events, so Accessibility
  permissions are required.

  - Some operations may require Safari to be restarted to take effect.

  - Available actions:
    - 'private_browsing': Opens a new private browsing window or toggles private browsing mode
    - 'track_prevent': Toggles intelligent tracking prevention
    - 'cookie_block': Configures cookie blocking policy
    - 'clear_history': Clears browsing history
    - 'status': Returns the current status of privacy features
  - For toggle actions, specify 'state' as 'on' or 'off'

  - Cookie blocking levels: 'all' (block all), 'third_party' (block from third
  party sites), 'none' (don't block)
---

This script manages Safari's privacy features, allowing you to control private browsing, tracking prevention, cookie blocking, and more.

```applescript
--MCP_INPUT:action
--MCP_INPUT:state
--MCP_INPUT:cookiePolicy

on manageSafariPrivacy(action, state, cookiePolicy)
  -- Validate inputs
  if action is missing value or action is "" then
    return "error: Action not provided. Must be 'private_browsing', 'track_prevent', 'cookie_block', 'clear_history', or 'status'."
  end if
  
  set action to my toLowerCase(action)
  
  -- Handle each action type
  if action is "private_browsing" then
    return my handlePrivateBrowsing(state)
  else if action is "track_prevent" then
    return my handleTrackingPrevention(state)
  else if action is "cookie_block" then
    return my handleCookieBlocking(cookiePolicy)
  else if action is "clear_history" then
    return my clearBrowsingHistory()
  else if action is "status" then
    return my getPrivacyStatus()
  else
    return "error: Invalid action. Must be 'private_browsing', 'track_prevent', 'cookie_block', 'clear_history', or 'status'."
  end if
end manageSafariPrivacy

-- Handle private browsing
on handlePrivateBrowsing(state)
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  -- Determine if we're toggling or checking status
  set shouldEnable to false
  if state is not missing value and state is not "" then
    if state is "on" or state is "true" or state is "yes" then
      set shouldEnable to true
    end if
  else
    -- No state provided, just open a new private window
    tell application "System Events"
      tell process "Safari"
        try
          click menu item "New Private Window" of menu "File" of menu bar 1
          return "Successfully opened a new private browsing window."
        on error errMsg
          return "error: Failed to open private browsing window - " & errMsg
        end try
      end tell
    end tell
  end if
  
  -- Toggle or set private browsing mode
  tell application "System Events"
    tell process "Safari"
      try
        -- Open Safari preferences
        click menu item "Settings…" of menu "Safari" of menu bar 1
        delay 1
        
        -- Go to the General tab
        try
          click button "General" of toolbar 1 of window 1
        on error
          -- Try by position
          click button 1 of toolbar 1 of window 1
        end try
        delay 0.5
        
        -- Find the "Open new windows with" popup button
        set found_popup to false
        set popup_elements to pop up buttons of window 1
        repeat with popup_element in popup_elements
          try
            if description of popup_element contains "Open new windows with" or description of popup_element contains "New windows open with" then
              set found_popup to true
              
              -- Click the popup to open its menu
              click popup_element
              delay 0.5
              
              -- Find and click "Private Window" or "Start Page in a Private Window" menu item
              set menu_items to menu items of menu 1 of popup_element
              set found_private_item to false
              
              repeat with menu_item in menu_items
                try
                  if name of menu_item contains "Private" then
                    if shouldEnable then
                      click menu_item
                    end if
                    set found_private_item to true
                    exit repeat
                  end if
                end try
              end repeat
              
              if found_private_item and not shouldEnable then
                -- We want normal mode, so click the first non-private option
                click menu item 1 of menu 1 of popup_element
              end if
              
              exit repeat
            end if
          end try
        end repeat
        
        -- Close preferences
        keystroke "w" using command down
        
        if found_popup then
          if shouldEnable then
            return "Successfully enabled private browsing mode by default."
          else
            return "Successfully disabled private browsing mode by default."
          end if
        else
          return "error: Could not find private browsing setting in Safari preferences."
        end if
      on error errMsg
        return "error: Failed to modify private browsing setting - " & errMsg
      end try
    end tell
  end tell
end handlePrivateBrowsing

-- Handle tracking prevention
on handleTrackingPrevention(state)
  if state is missing value or state is "" then
    return "error: State not provided for track_prevent action. Must be 'on' or 'off'."
  end if
  
  set shouldEnable to false
  if state is "on" or state is "true" or state is "yes" then
    set shouldEnable to true
  end if
  
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  tell application "System Events"
    tell process "Safari"
      try
        -- Open Safari preferences
        click menu item "Settings…" of menu "Safari" of menu bar 1
        delay 1
        
        -- Go to the Privacy tab
        try
          click button "Privacy" of toolbar 1 of window 1
        on error
          -- Try by position (usually 3rd or 4th button)
          try
            click button 4 of toolbar 1 of window 1
          on error
            click button 3 of toolbar 1 of window 1
          end try
        end try
        delay 0.5
        
        -- Find the "Prevent cross-site tracking" checkbox
        set track_checkboxes to checkboxes of window 1
        set found_checkbox to false
        
        repeat with cb in track_checkboxes
          try
            if description of cb contains "cross-site" or description of cb contains "tracking" then
              set found_checkbox to true
              
              -- Check current state
              set isChecked to value of cb as boolean
              
              -- Toggle if needed
              if shouldEnable and not isChecked then
                click cb
              else if not shouldEnable and isChecked then
                click cb
              end if
              
              exit repeat
            end if
          end try
        end repeat
        
        -- Close preferences
        keystroke "w" using command down
        
        if found_checkbox then
          if shouldEnable then
            return "Successfully enabled intelligent tracking prevention."
          else
            return "Successfully disabled intelligent tracking prevention."
          end if
        else
          return "error: Could not find tracking prevention setting in Safari preferences."
        end if
      on error errMsg
        return "error: Failed to modify tracking prevention setting - " & errMsg
      end try
    end tell
  end tell
end handleTrackingPrevention

-- Handle cookie blocking
on handleCookieBlocking(cookiePolicy)
  if cookiePolicy is missing value or cookiePolicy is "" then
    return "error: Cookie policy not provided for cookie_block action. Must be 'all', 'third_party', or 'none'."
  end if
  
  set policy to my toLowerCase(cookiePolicy)
  if policy is not "all" and policy is not "third_party" and policy is not "none" then
    return "error: Invalid cookie policy. Must be 'all', 'third_party', or 'none'."
  end if
  
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  tell application "System Events"
    tell process "Safari"
      try
        -- Open Safari preferences
        click menu item "Settings…" of menu "Safari" of menu bar 1
        delay 1
        
        -- Go to the Privacy tab
        try
          click button "Privacy" of toolbar 1 of window 1
        on error
          -- Try by position (usually 3rd or 4th button)
          try
            click button 4 of toolbar 1 of window 1
          on error
            click button 3 of toolbar 1 of window 1
          end try
        end try
        delay 0.5
        
        -- Look for cookie blocking radio buttons or popup
        set found_cookie_control to false
        
        -- Try finding radio buttons for cookie policy
        set radio_buttons to radio buttons of window 1
        if (count of radio_buttons) > 0 then
          set found_cookie_control to true
          
          -- Determine which radio button to click
          set button_index to 1 -- Default to "none"
          
          if policy is "all" then
            set button_index to 3
          else if policy is "third_party" then
            set button_index to 2
          end if
          
          -- Click the appropriate radio button
          click radio button button_index of window 1
        else
          -- Try finding a popup for cookie policy (newer Safari versions)
          set popup_elements to pop up buttons of window 1
          repeat with popup_element in popup_elements
            try
              if description of popup_element contains "cookie" or description of popup_element contains "Cookie" then
                set found_cookie_control to true
                
                -- Click the popup to open its menu
                click popup_element
                delay 0.5
                
                -- Select the appropriate menu item
                set menu_index to 1 -- Default to "none"
                
                if policy is "all" then
                  set menu_index to 3
                else if policy is "third_party" then
                  set menu_index to 2
                end if
                
                click menu item menu_index of menu 1 of popup_element
                exit repeat
              end if
            end try
          end repeat
        end if
        
        -- Close preferences
        keystroke "w" using command down
        
        if found_cookie_control then
          if policy is "all" then
            return "Successfully set cookie policy to block all cookies."
          else if policy is "third_party" then
            return "Successfully set cookie policy to block cookies from third-party sites."
          else
            return "Successfully set cookie policy to allow all cookies."
          end if
        else
          return "error: Could not find cookie blocking settings in Safari preferences."
        end if
      on error errMsg
        return "error: Failed to modify cookie blocking setting - " & errMsg
      end try
    end tell
  end tell
end handleCookieBlocking

-- Clear browsing history
on clearBrowsingHistory()
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  tell application "System Events"
    tell process "Safari"
      try
        -- Click the History menu
        click menu "History" of menu bar 1
        delay 0.5
        
        -- Click "Clear History..." menu item
        click menu item "Clear History…" of menu "History" of menu bar 1
        delay 0.5
        
        -- Handle the confirmation dialog
        set dialog_found to false
        
        -- Look for the dialog or sheet that appears
        set dialogs to sheets of window 1
        if (count of dialogs) > 0 then
          set dialog_found to true
          
          -- Find the popup to select time range
          set popups to pop up buttons of dialogs
          if (count of popups) > 0 then
            -- Click the popup and select "all history"
            click item 1 of popups
            delay 0.5
            
            -- Select "all history" (usually the last item)
            set menu_items to menu items of menu 1 of item 1 of popups
            click item (count of menu_items) of menu items of menu 1 of item 1 of popups
            delay 0.5
          end if
          
          -- Click the "Clear History" button
          set clear_buttons to buttons of dialogs whose name contains "Clear"
          if (count of clear_buttons) > 0 then
            click item 1 of clear_buttons
          end if
        end if
        
        if dialog_found then
          return "Successfully cleared browsing history."
        else
          return "error: Could not find clear history dialog."
        end if
      on error errMsg
        return "error: Failed to clear browsing history - " & errMsg
      end try
    end tell
  end tell
end clearBrowsingHistory

-- Get current privacy status
on getPrivacyStatus()
  set status_lines to {}
  
  if not application "Safari" is running then
    tell application "Safari" to activate
    delay 1
  else
    tell application "Safari" to activate
  end if
  
  tell application "System Events"
    tell process "Safari"
      try
        -- Open Safari preferences
        click menu item "Settings…" of menu "Safari" of menu bar 1
        delay 1
        
        -- Get Private Browsing status (General tab)
        try
          click button "General" of toolbar 1 of window 1
        on error
          click button 1 of toolbar 1 of window 1
        end try
        delay 0.5
        
        -- Check for private browsing setting
        set popup_elements to pop up buttons of window 1
        repeat with popup_element in popup_elements
          try
            if description of popup_element contains "Open new windows with" or description of popup_element contains "New windows open with" then
              set popup_value to value of popup_element
              
              if popup_value contains "Private" then
                set end of status_lines to "Private Browsing: Enabled by default"
              else
                set end of status_lines to "Private Browsing: Disabled by default"
              end if
              
              exit repeat
            end if
          end try
        end repeat
        
        -- Get tracking prevention and cookie status (Privacy tab)
        try
          click button "Privacy" of toolbar 1 of window 1
        on error
          try
            click button 4 of toolbar 1 of window 1
          on error
            click button 3 of toolbar 1 of window 1
          end try
        end try
        delay 0.5
        
        -- Check tracking prevention checkbox
        set track_checkboxes to checkboxes of window 1
        repeat with cb in track_checkboxes
          try
            if description of cb contains "cross-site" or description of cb contains "tracking" then
              set isChecked to value of cb as boolean
              
              if isChecked then
                set end of status_lines to "Intelligent Tracking Prevention: Enabled"
              else
                set end of status_lines to "Intelligent Tracking Prevention: Disabled"
              end if
              
              exit repeat
            end if
          end try
        end repeat
        
        -- Check cookie blocking setting (radio buttons or popup)
        set cookie_policy to "Unknown"
        
        -- Try radio buttons first
        set radio_buttons to radio buttons of window 1
        if (count of radio_buttons) > 0 then
          repeat with i from 1 to (count of radio_buttons)
            set rb to item i of radio_buttons
            try
              if value of rb is 1 then
                if i is 1 then
                  set cookie_policy to "Allow all cookies"
                else if i is 2 then
                  set cookie_policy to "Block cookies from third-party sites"
                else if i is 3 then
                  set cookie_policy to "Block all cookies"
                end if
                exit repeat
              end if
            end try
          end repeat
        else
          -- Try popup for newer Safari versions
          set popup_elements to pop up buttons of window 1
          repeat with popup_element in popup_elements
            try
              if description of popup_element contains "cookie" or description of popup_element contains "Cookie" then
                set popup_value to value of popup_element
                set cookie_policy to popup_value
                exit repeat
              end if
            end try
          end repeat
        end if
        
        set end of status_lines to "Cookie Policy: " & cookie_policy
        
        -- Close preferences
        keystroke "w" using command down
        
        -- Format all status lines into a JSON-like object
        set result_json to "{\n"
        repeat with i from 1 to (count of status_lines)
          set line_parts to my split(item i of status_lines, ": ")
          if (count of line_parts) ≥ 2 then
            set key_name to item 1 of line_parts
            set value_text to item 2 of line_parts
            set result_json to result_json & "  \"" & key_name & "\": \"" & value_text & "\""
            if i < (count of status_lines) then
              set result_json to result_json & ","
            end if
            set result_json to result_json & "\n"
          end if
        end repeat
        set result_json to result_json & "}"
        
        return result_json
      on error errMsg
        return "error: Failed to retrieve privacy status - " & errMsg
      end try
    end tell
  end tell
end getPrivacyStatus

-- Helper function to convert text to lowercase
on toLowerCase(sourceText)
  set lowercaseText to ""
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  
  repeat with i from 1 to length of sourceText
    set currentChar to character i of sourceText
    set charPos to offset of currentChar in upperChars
    
    if charPos > 0 then
      set lowercaseText to lowercaseText & character charPos of lowerChars
    else
      set lowercaseText to lowercaseText & currentChar
    end if
  end repeat
  
  return lowercaseText
end toLowerCase

-- Helper function to split text by delimiter
on split(theText, theDelimiter)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theDelimiter
  set theArray to every text item of theText
  set AppleScript's text item delimiters to oldDelimiters
  return theArray
end split

return my manageSafariPrivacy("--MCP_INPUT:action", "--MCP_INPUT:state", "--MCP_INPUT:cookiePolicy")
```
