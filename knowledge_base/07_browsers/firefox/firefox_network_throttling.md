---
title: "Firefox: Network Throttling"
category: "05_web_browsers"
id: firefox_network_throttling
description: "Controls Firefox's network throttling feature in Developer Tools to simulate various internet connection speeds."
keywords: ["Firefox", "network throttling", "web development", "performance testing", "slow connection", "bandwidth", "latency", "DevTools"]
language: applescript
notes: |
  - Firefox must be running.
  - Uses Developer Tools Network panel.
  - Requires accessibility permissions for UI scripting.
  - Can simulate various connection types from fast 4G to offline mode.
---

This script controls Firefox's network throttling feature in the Developer Tools to simulate various internet connection speeds. It's useful for testing how websites perform under different network conditions.

```applescript
on run {input, parameters}
  -- Get throttling profile to use
  set throttleProfile to "--MCP_INPUT:profile"
  
  -- Set default if not specified
  if throttleProfile is "" or throttleProfile is "--MCP_INPUT:profile" then
    set throttleProfile to "Online" -- Default to normal connection
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Open Developer Tools if not already open
  tell application "System Events"
    tell process "Firefox"
      key code 111 -- F12 to open Developer Tools
      delay 1 -- Allow DevTools to open
      
      -- Make sure we're on the Network panel
      keystroke "e" using {command down, option down}
      delay 0.5 -- Allow Network panel to activate
    end tell
  end tell
  
  -- Define throttling profiles (these are Firefox's standard options)
  -- Profile name, Display name (for UI matching)
  set throttlingProfiles to {¬
    {"offline", "Offline"}, ¬
    {"2g", "2G"}, ¬
    {"3g", "3G"}, ¬
    {"4g", "4G"}, ¬
    {"lte", "LTE"}, ¬
    {"edge", "Edge"}, ¬
    {"gprs", "GPRS"}, ¬
    {"slow", "Slow 3G"}, ¬
    {"dial", "Dial-up"}, ¬
    {"wifi", "WiFi"}, ¬
    {"online", "No throttling"}, ¬
    {"none", "No throttling"}, ¬
    {"normal", "No throttling"} ¬
  }
  
  -- Convert input to lowercase for matching
  set throttleProfileLower to do shell script "echo " & quoted form of throttleProfile & " | tr '[:upper:]' '[:lower:]'"
  
  -- Find matching profile display name
  set profileDisplayName to "No throttling" -- Default
  
  repeat with profile in throttlingProfiles
    set profileKey to item 1 of profile
    if profileKey is throttleProfileLower then
      set profileDisplayName to item 2 of profile
      exit repeat
    end if
  end repeat
  
  -- Set the throttling option via UI interaction
  tell application "System Events"
    tell process "Firefox"
      -- Look for the throttling dropdown in the Network panel
      try
        -- Find and click the throttling dropdown
        -- This is simplified and may need adjustment based on Firefox version
        
        -- Method 1: Try to find the throttling menu button
        set foundThrottlingDropdown to false
        
        -- Look for popup buttons in the toolbar
        repeat with btn in (UI elements of toolbar 1 of front window whose role is "AXPopUpButton")
          -- Check if this might be the throttling dropdown
          if description of btn contains "throttling" or name of btn contains "throttling" then
            click btn
            set foundThrottlingDropdown to true
            delay 0.5 -- Wait for dropdown to open
            exit repeat
          end if
        end repeat
        
        -- If dropdown found, try to select the profile
        if foundThrottlingDropdown then
          -- Look for menu item matching our profile name
          set foundThrottlingOption to false
          
          repeat with menuItem in (menu items of menu 1 of front window)
            if name of menuItem contains profileDisplayName then
              click menuItem
              set foundThrottlingOption to true
              exit repeat
            end if
          end repeat
          
          if not foundThrottlingOption then
            -- Close dropdown if option not found
            keystroke escape
          end if
        else
          -- Method 2: Try using the Network panel settings menu
          -- Click the Network settings (gear icon) button
          
          -- Look for a button that might be the settings
          repeat with btn in (UI elements of front window whose role is "AXButton")
            if description of btn contains "settings" or description of btn contains "gear" then
              click btn
              delay 0.5 -- Wait for menu to open
              
              -- Now look for throttling option in the menu
              repeat with menuItem in (menu items of menu 1 of front window)
                if name of menuItem contains "Throttling" then
                  click menuItem
                  delay 0.3 -- Wait for submenu
                  
                  -- Try to find our profile in the submenu
                  repeat with subMenuItem in (menu items of menu 1 of menuItem)
                    if name of subMenuItem contains profileDisplayName then
                      click subMenuItem
                      set foundThrottlingOption to true
                      exit repeat
                    end if
                  end repeat
                  
                  exit repeat
                end if
              end repeat
              
              exit repeat
            end if
          end repeat
        end if
      on error
        -- Fallback method: Use keyboard navigation
        -- Open the Network panel settings
        keystroke "," using {shift down, command down}
        delay 0.5
        
        -- Tab to throttling dropdown (may need adjustment)
        repeat 5 times
          keystroke tab
          delay 0.1
        end repeat
        
        -- Open dropdown
        keystroke space
        delay 0.3
        
        -- Navigate to desired option (highly dependent on Firefox version)
        -- This is simplified and may need customization
        if throttleProfileLower is "offline" then
          keystroke "o" -- Jump to Offline
        else if throttleProfileLower is "3g" then
          keystroke "3" -- Jump to 3G
        else if throttleProfileLower is "online" or throttleProfileLower is "none" then
          keystroke "n" -- Jump to No throttling
        end if
        
        delay 0.2
        keystroke return -- Select option
      end try
    end tell
  end tell
  
  return "Firefox network throttling set to: " & profileDisplayName
end run
```

### Alternative Implementation with Network Conditions Panel

This version uses a different approach by directly accessing Firefox's Network Conditions panel in Developer Tools:

```applescript
on run {input, parameters}
  -- Get throttling profile to use
  set throttleProfile to "--MCP_INPUT:profile"
  set customDownload to "--MCP_INPUT:downloadKbps" -- Custom download speed in Kbps
  set customUpload to "--MCP_INPUT:uploadKbps" -- Custom upload speed in Kbps
  set customLatency to "--MCP_INPUT:latencyMs" -- Custom latency in ms
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Open Developer Tools if not already open
  tell application "System Events"
    tell process "Firefox"
      key code 111 -- F12 to open Developer Tools
      delay 1 -- Allow DevTools to open
    end tell
  end tell
  
  -- Open the Network Conditions panel
  tell application "System Events"
    tell process "Firefox"
      -- Use three-dot menu to access Network Conditions
      try
        -- Find and click the three-dot menu button in DevTools
        repeat with btn in (UI elements of front window whose role is "AXButton")
          if description of btn contains "More Tools" or description of btn contains "..." then
            click btn
            delay 0.5 -- Wait for menu to open
            exit repeat
          end if
        end repeat
        
        -- Look for Network Conditions in the menu
        repeat with menuItem in (menu items of menu 1 of front window)
          if name of menuItem contains "Network Conditions" then
            click menuItem
            delay 0.5 -- Wait for panel to open
            exit repeat
          end if
        end repeat
      on error
        -- Fallback method: Try to use keyboard shortcuts
        keystroke "," using {shift down, command down} -- Open settings
        delay 0.5
        keystroke "n" -- Type 'n' to jump to network settings
        delay 0.3
        keystroke return -- Select option
      end try
    end tell
  end tell
  
  -- Use custom throttling values if provided, otherwise use profile
  if (customDownload is not "" and customDownload is not "--MCP_INPUT:downloadKbps") and ¬
     (customUpload is not "" and customUpload is not "--MCP_INPUT:uploadKbps") and ¬
     (customLatency is not "" and customLatency is not "--MCP_INPUT:latencyMs") then
    
    -- Apply custom throttling values
    tell application "System Events"
      tell process "Firefox"
        -- Find and click the "Custom" throttling option
        repeat with radioBtn in (UI elements of front window whose role is "AXRadioButton")
          if name of radioBtn contains "Custom" then
            click radioBtn
            delay 0.3
            exit repeat
          end if
        end repeat
        
        -- Set custom values
        repeat with textField in (UI elements of front window whose role is "AXTextField")
          -- Find download speed field
          if description of textField contains "Download" then
            click textField
            keystroke "a" using {command down} -- Select all
            keystroke customDownload
            keystroke tab -- Move to next field
            
            -- Assume next field is upload
            keystroke "a" using {command down} -- Select all
            keystroke customUpload
            keystroke tab -- Move to next field
            
            -- Assume next field is latency
            keystroke "a" using {command down} -- Select all
            keystroke customLatency
            keystroke return -- Apply settings
            
            exit repeat
          end if
        end repeat
      end tell
    end tell
    
    return "Firefox network throttling set to custom values: " & ¬
           "Download: " & customDownload & " Kbps, " & ¬
           "Upload: " & customUpload & " Kbps, " & ¬
           "Latency: " & customLatency & " ms"
  else
    -- Use preset throttling profile
    tell application "System Events"
      tell process "Firefox"
        -- Find and click the appropriate preset radio button
        -- Convert to lowercase for case-insensitive comparison
        set throttleProfileLower to do shell script "echo " & quoted form of throttleProfile & " | tr '[:upper:]' '[:lower:]'"
        
        set profileDisplayName to "No throttling" -- Default
        if throttleProfileLower is "offline" then
          set profileDisplayName to "Offline"
        else if throttleProfileLower is "2g" then
          set profileDisplayName to "2G"
        else if throttleProfileLower is "3g" then
          set profileDisplayName to "3G"
        else if throttleProfileLower is "4g" or throttleProfileLower is "lte" then
          set profileDisplayName to "4G/LTE"
        else if throttleProfileLower is "dsl" then
          set profileDisplayName to "DSL"
        else if throttleProfileLower is "wifi" then
          set profileDisplayName to "WiFi"
        end if
        
        -- Find and click the appropriate radio button
        set foundProfile to false
        repeat with radioBtn in (UI elements of front window whose role is "AXRadioButton")
          if name of radioBtn contains profileDisplayName then
            click radioBtn
            set foundProfile to true
            exit repeat
          end if
        end repeat
        
        -- If profile not found, revert to "No throttling"
        if not foundProfile then
          repeat with radioBtn in (UI elements of front window whose role is "AXRadioButton")
            if name of radioBtn contains "No throttling" then
              click radioBtn
              exit repeat
            end if
          end repeat
          
          set profileDisplayName to "No throttling (profile not found)"
        end if
      end tell
    end tell
    
    return "Firefox network throttling set to: " & profileDisplayName
  end if
end run
```

### Simplified Version with Predefined Profiles Only

This version has a more straightforward approach focusing only on the most common throttling presets:

```applescript
on run {input, parameters}
  -- Get throttling profile to use
  set throttleProfile to "--MCP_INPUT:profile"
  
  -- Map input to Firefox network throttling options
  -- Convert to lowercase and handle common variations
  set throttleProfileLower to do shell script "echo " & quoted form of throttleProfile & " | tr '[:upper:]' '[:lower:]'"
  
  -- Set the profile to use
  if throttleProfileLower is "offline" then
    set profileToUse to "Offline"
  else if throttleProfileLower is "slow" or throttleProfileLower contains "2g" then
    set profileToUse to "2G"
  else if throttleProfileLower contains "3g" then
    set profileToUse to "3G"
  else if throttleProfileLower contains "4g" or throttleProfileLower contains "lte" then
    set profileToUse to "4G/LTE"
  else if throttleProfileLower contains "fast" or throttleProfileLower contains "online" or throttleProfileLower contains "none" then
    set profileToUse to "No throttling"
  else
    -- Default to no throttling if unrecognized
    set profileToUse to "No throttling"
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
    
    -- Open Developer Tools if not already open
    tell application "System Events"
      key code 111 -- F12
      delay 0.8
      
      -- Go to Network panel
      keystroke "e" using {command down, option down}
      delay 0.5
    end tell
  end tell
  
  -- Set the throttling profile
  tell application "System Events"
    tell process "Firefox"
      -- Try to find throttling dropdown
      keystroke "y" using {command down, control down} -- Common shortcut for throttling in Firefox
      delay 0.3
      
      -- Type first few letters of the profile name to navigate
      keystroke (character 1 of profileToUse)
      delay 0.2
      keystroke return
    end tell
  end tell
  
  return "Firefox network throttling set to: " & profileToUse
end run
```

Note: Network throttling interfaces can vary significantly between Firefox versions. The UI scripting approach in these scripts may need adjustment based on your Firefox version. Some versions of Firefox may require enabling additional DevTools panels or preference settings to access throttling features.
END_TIP