---
title: "Firefox: Responsive Design Mode"
category: "05_web_browsers"
id: firefox_responsive_design_mode
description: "Opens Firefox's Responsive Design Mode for testing websites on different screen sizes and devices."
keywords: ["Firefox", "responsive design", "mobile testing", "web development", "screen size", "viewport", "device emulation"]
language: applescript
notes: |
  - Firefox must be running.
  - Uses keyboard shortcuts to toggle Responsive Design Mode.
  - Requires accessibility permissions for UI scripting.
  - Can set specific device presets and dimensions.
---

This script controls Firefox's Responsive Design Mode, which allows developers to test how websites look and behave on different screen sizes and devices. It can toggle the mode on/off and set specific device presets or dimensions.

```applescript
on run {input, parameters}
  -- Get parameters
  set devicePreset to "--MCP_INPUT:device" -- e.g., "iPhone X", "iPad", "Galaxy S9"
  set customWidth to "--MCP_INPUT:width" -- Custom width in pixels
  set customHeight to "--MCP_INPUT:height" -- Custom height in pixels
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Toggle Responsive Design Mode with keyboard shortcut (Command+Option+M)
  tell application "System Events"
    tell process "Firefox"
      keystroke "m" using {command down, option down}
      delay 1 -- Allow Responsive Design Mode to open
    end tell
  end tell
  
  -- If no device or dimensions specified, we're done
  if (devicePreset is "" or devicePreset is "--MCP_INPUT:device") and ¬
     (customWidth is "" or customWidth is "--MCP_INPUT:width") and ¬
     (customHeight is "" or customHeight is "--MCP_INPUT:height") then
    return "Toggled Firefox Responsive Design Mode"
  end if
  
  -- Set device preset or custom dimensions if specified
  tell application "System Events"
    tell process "Firefox"
      -- First, check if we need to set a specific device preset
      if devicePreset is not "" and devicePreset is not "--MCP_INPUT:device" then
        -- Click on the device selector dropdown
        -- This part may need adjustment based on Firefox UI
        
        -- Look for the device selector dropdown in Responsive Design Mode
        delay 0.5
        
        -- Try to find and click the device type dropdown
        set deviceDropdownFound to false
        
        -- Attempt to find and click the device dropdown
        try
          -- Look for a popup button that might be the device selector
          repeat with btn in (UI elements of front window whose role is "AXPopUpButton")
            if description of btn contains "Device" or ¬
               description of btn contains "Responsive" then
              click btn
              set deviceDropdownFound to true
              delay 0.5
              exit repeat
            end if
          end repeat
          
          -- If dropdown found, try to select the device preset
          if deviceDropdownFound then
            -- Look through menu items for matching device
            set deviceFound to false
            
            repeat with menuItem in menu items of menu 1 of front window
              if name of menuItem contains devicePreset then
                click menuItem
                set deviceFound to true
                delay 0.5
                exit repeat
              end if
            end repeat
            
            if not deviceFound then
              -- Close dropdown if device not found
              keystroke escape
            end if
          end if
        end try
      end if
      
      -- Set custom dimensions if specified
      if (customWidth is not "" and customWidth is not "--MCP_INPUT:width") and ¬
         (customHeight is not "" and customHeight is not "--MCP_INPUT:height") then
        
        -- Try to find and click the custom dimensions input field
        delay 0.5
        
        -- This is a simplified version - actual UI navigation may need adjustment
        -- Try to find width input field
        try
          -- Attempt to locate input fields for width and height
          repeat with textField in (UI elements of front window whose role is "AXTextField")
            if description of textField contains "Width" then
              -- Found width field, click and enter value
              click textField
              keystroke "a" using {command down} -- Select all
              keystroke customWidth
              keystroke tab -- Move to height field
              keystroke "a" using {command down} -- Select all
              keystroke customHeight
              keystroke return -- Apply dimensions
              exit repeat
            end if
          end repeat
        end try
      end if
    end tell
  end tell
  
  -- Return appropriate message based on what was set
  if devicePreset is not "" and devicePreset is not "--MCP_INPUT:device" then
    if (customWidth is not "" and customWidth is not "--MCP_INPUT:width") and ¬
       (customHeight is not "" and customHeight is not "--MCP_INPUT:height") then
      return "Firefox Responsive Design Mode activated with device preset '" & devicePreset & "' and custom dimensions " & customWidth & "×" & customHeight
    else
      return "Firefox Responsive Design Mode activated with device preset '" & devicePreset & "'"
    end if
  else if (customWidth is not "" and customWidth is not "--MCP_INPUT:width") and ¬
          (customHeight is not "" and customHeight is not "--MCP_INPUT:height") then
    return "Firefox Responsive Design Mode activated with custom dimensions " & customWidth & "×" & customHeight
  else
    return "Firefox Responsive Design Mode activated"
  end if
end run
```

### Alternative Implementation with Common Presets

This version includes a more straightforward approach for common device presets without relying on Firefox's UI, which can change between versions:

```applescript
on run {input, parameters}
  -- Get device type or custom dimensions
  set deviceType to "--MCP_INPUT:device"
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Toggle Responsive Design Mode
  tell application "System Events"
    tell process "Firefox"
      keystroke "m" using {command down, option down}
      delay 1 -- Allow Responsive Design Mode to open
    end tell
  end tell
  
  -- If no device specified, we're done
  if deviceType is "" or deviceType is "--MCP_INPUT:device" then
    return "Toggled Firefox Responsive Design Mode"
  end if
  
  -- Define common device dimensions (width × height)
  set deviceDimensions to {¬
    {"iphone_se", 375, 667}, ¬
    {"iphone_xr", 414, 896}, ¬
    {"iphone_12", 390, 844}, ¬
    {"iphone_12_pro_max", 428, 926}, ¬
    {"pixel_5", 393, 851}, ¬
    {"samsung_galaxy_s20", 360, 800}, ¬
    {"ipad", 768, 1024}, ¬
    {"ipad_pro", 1024, 1366}, ¬
    {"desktop", 1920, 1080}, ¬
    {"laptop", 1366, 768} ¬
  }
  
  -- Convert input to lowercase and remove spaces for matching
  set deviceTypeLower to do shell script "echo " & quoted form of deviceType & " | tr '[:upper:]' '[:lower:]' | tr -d ' '"
  
  -- Find matching device
  set deviceFound to false
  set deviceWidth to 0
  set deviceHeight to 0
  
  repeat with deviceSpec in deviceDimensions
    set specName to item 1 of deviceSpec
    if specName contains deviceTypeLower then
      set deviceWidth to item 2 of deviceSpec
      set deviceHeight to item 3 of deviceSpec
      set deviceFound to true
      exit repeat
    end if
  end repeat
  
  -- If device preset found, set dimensions
  if deviceFound then
    tell application "System Events"
      tell process "Firefox"
        -- Try to find and click dimension input fields
        delay 0.5
        
        -- This is simplified - may need adjustment based on Firefox version
        -- Try to find width input field
        try
          -- Look for text fields that might be width/height inputs
          repeat with textField in (UI elements of front window whose role is "AXTextField")
            if description of textField contains "Width" then
              -- Found width field, click and enter value
              click textField
              keystroke "a" using {command down} -- Select all
              keystroke deviceWidth as string
              keystroke tab -- Move to height field
              keystroke "a" using {command down} -- Select all
              keystroke deviceHeight as string
              keystroke return -- Apply dimensions
              exit repeat
            end if
          end repeat
        end try
      end tell
    end tell
    
    return "Firefox Responsive Design Mode activated with " & deviceType & " preset (" & deviceWidth & "×" & deviceHeight & ")"
  else
    return "Firefox Responsive Design Mode activated. Device preset '" & deviceType & "' not recognized."
  end if
end run
```

### Advanced Implementation with Device Rotation

This version adds functionality to rotate the device view, which is useful for testing both portrait and landscape orientations:

```applescript
on run {input, parameters}
  -- Get parameters
  set deviceType to "--MCP_INPUT:device"
  set orientation to "--MCP_INPUT:orientation" -- "portrait" or "landscape"
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Toggle Responsive Design Mode
  tell application "System Events"
    tell process "Firefox"
      keystroke "m" using {command down, option down}
      delay 1 -- Allow Responsive Design Mode to open
    end tell
  end tell
  
  -- If no device or orientation specified, we're done
  if (deviceType is "" or deviceType is "--MCP_INPUT:device") and ¬
     (orientation is "" or orientation is "--MCP_INPUT:orientation") then
    return "Toggled Firefox Responsive Design Mode"
  end if
  
  -- If orientation is specified, rotate the view
  if orientation is not "" and orientation is not "--MCP_INPUT:orientation" then
    tell application "System Events"
      tell process "Firefox"
        -- Look for rotation button
        delay 0.5
        
        -- Try to find and click the rotation button
        try
          -- Look for a button that might be the rotation control
          set rotationButtonFound to false
          
          repeat with btn in (UI elements of front window whose role is "AXButton")
            if description of btn contains "Rotate" then
              click btn
              set rotationButtonFound to true
              delay 0.5
              exit repeat
            end if
          end repeat
          
          -- If rotation button not found, try to use keyboard shortcut
          if not rotationButtonFound then
            -- Some Firefox versions use Alt+R or Ctrl+Shift+R for rotation
            keystroke "r" using {option down}
          end if
        end try
      end tell
    end tell
  end if
  
  return "Firefox Responsive Design Mode activated" & ¬
         (if deviceType is not "" and deviceType is not "--MCP_INPUT:device" then " with " & deviceType & " preset" else "") & ¬
         (if orientation is not "" and orientation is not "--MCP_INPUT:orientation" then " in " & orientation & " orientation" else "")
end run
```

Note: The UI scripting portions of these scripts might need adjustment based on your Firefox version, as the exact structure of the Responsive Design Mode interface can change between releases. The keyboard shortcuts (Command+Option+M for toggling the mode) are generally more stable across versions.
END_TIP