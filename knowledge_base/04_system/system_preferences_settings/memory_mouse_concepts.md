---
title: 'Control Mouse, Trackpad, and Memory Settings with AppleScript'
description: >-
  Scripts for controlling mouse/trackpad tracking speed, scrolling behavior, and
  checking system memory status in macOS
author: Claude
category: 04_system
subcategory: system_preferences_settings
keywords:
  - mouse
  - trackpad
  - memory
  - system settings
  - ui scripting
  - system information
language: applescript
version: '1.0'
validated: true
---

# Control Mouse, Trackpad, and Memory Settings with AppleScript

## Mouse and Trackpad Settings

Modern macOS provides extensive customization for mouse and trackpad behavior. These settings can be controlled through UI scripting of System Settings or via the `defaults` command.

### Adjusting Mouse Tracking Speed

```applescript
tell application "System Settings"
  activate
  delay 1
  
  tell application "System Events"
    tell process "System Settings"
      -- Click on Mouse in the sidebar
      click button "Mouse" of scroll area 1 of group 1 of window 1
      delay 0.5
      
      -- Adjust tracking speed slider
      -- Find the tracking speed slider
      set trackingSlider to slider 1 of group 1 of scroll area 1 of group 1 of window 1
      
      -- Set to a specific value (range is typically 0.0 to 1.0)
      set value of trackingSlider to 0.7
      
      delay 0.5
    end tell
  end tell
  
  quit
end tell
```

### Adjusting Trackpad Settings

```applescript
tell application "System Settings"
  activate
  delay 1
  
  tell application "System Events"
    tell process "System Settings"
      -- Click on Trackpad in the sidebar
      click button "Trackpad" of scroll area 1 of group 1 of window 1
      delay 0.5
      
      -- Click on the "Point & Click" tab
      click button "Point & Click" of tab group 1 of group 1 of scroll area 1 of group 1 of window 1
      delay 0.3
      
      -- Toggle "Tap to click" checkbox
      set tapToClickCheckbox to checkbox "Tap to click" of group 1 of scroll area 1 of group 1 of window 1
      if value of tapToClickCheckbox is 0 then
        click tapToClickCheckbox
      end if
      
      -- Adjust tracking speed
      set trackingSlider to slider 1 of group 1 of scroll area 1 of group 1 of window 1
      set value of trackingSlider to 0.6
      
      delay 0.5
    end tell
  end tell
  
  quit
end tell
```

### Setting Mouse/Trackpad Options via Defaults Command

```applescript
-- Enable three finger drag
do shell script "defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true"
do shell script "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true"

-- Set tracking speed (1 is slow, 3 is fast)
do shell script "defaults write -g com.apple.mouse.scaling 2.5"

-- Apply changes
do shell script "killall cfprefsd"

display dialog "Mouse and trackpad settings updated. You may need to log out and back in for all changes to take effect."
```

## Memory and System Information

In modern macOS, memory information is available through the `vm_stat` and `sysctl` commands, rather than through a control panel.

### Getting Memory Information

```applescript
-- Get detailed memory statistics
set memStats to do shell script "vm_stat"

-- Get total physical memory
set totalMemory to do shell script "sysctl -n hw.memsize"
set totalMemoryGB to (totalMemory as number) / 1073741824 -- Convert to GB

-- Get available memory more accurately using memory pressure
set memoryPressure to do shell script "memory_pressure"

-- Display memory info in a dialog
set memoryInfo to "Total Physical Memory: " & (round (totalMemoryGB * 100) / 100 as text) & " GB" & return & return & "Memory Statistics:" & return & memStats

display dialog memoryInfo buttons {"OK"} default button "OK" with title "Memory Information"
```

### Getting Memory Pressure Information

```applescript
-- Get memory pressure information (new in modern macOS)
set memPressure to do shell script "memory_pressure | grep 'System-wide memory free percentage'"

-- Extract percentage from result
set AppleScript's text item delimiters to ": "
set memFreePercentText to text item 2 of memPressure
set AppleScript's text item delimiters to "%"
set memFreePercent to text item 1 of memFreePercentText as number
set AppleScript's text item delimiters to ""

-- Display appropriate message based on memory pressure
if memFreePercent ≥ 50 then
  set memStatus to "Memory pressure is low. System has plenty of available memory."
else if memFreePercent ≥ 25 then
  set memStatus to "Memory pressure is moderate. System is using memory efficiently."
else
  set memStatus to "Memory pressure is high. Consider closing unused applications."
end if

display dialog memStatus & return & return & "Free memory: " & memFreePercent & "%" buttons {"OK"} default button "OK" with title "Memory Pressure"
```

### Running Memory Clean-up

```applescript
-- This script can help clear inactive memory
-- NOTE: Modern macOS manages memory effectively without manual intervention,
-- but this can still be useful in some situations

-- Prompt for confirmation
set userChoice to display dialog "This will purge inactive memory. Continue?" buttons {"Cancel", "Purge Memory"} default button "Purge Memory" with icon caution

if button returned of userChoice is "Purge Memory" then
  -- This requires sudo access, so it will prompt for password
  try
    do shell script "sudo purge" with administrator privileges
    display dialog "Memory has been purged." buttons {"OK"} default button "OK"
  on error errorMsg
    display dialog "Failed to purge memory: " & errorMsg buttons {"OK"} default button "OK" with icon stop
  end try
end if
```

## Getting System Memory Usage for Applications

```applescript
-- Get memory usage for running applications
set memUsage to do shell script "ps -axm -o 'pid,%mem,command' | grep -v grep | sort -nr -k 2 | head -n 10"

-- Display top 10 memory-using processes
display dialog "Top Memory Usage:" & return & return & memUsage buttons {"OK"} default button "OK" with title "Application Memory Usage"
```

## Notes and Limitations

1. **Changing Mouse Settings**: UI scripting methods for modifying mouse and trackpad settings can break with macOS updates as the UI layout changes.

2. **Using defaults commands**: Some settings can be changed using `defaults write` commands, which are more stable than UI scripting but may still change between macOS versions.

3. **Memory Management**: Unlike older macOS versions, modern macOS manages memory automatically and efficiently. Manual memory management is rarely necessary or beneficial.

4. **Administrator Access**: Some memory operations like the `purge` command require administrator privileges.

5. **UI Element Identification**: When using UI scripting, you may need to adjust element identifiers based on your specific macOS version. Use Accessibility Inspector or UI Browser to identify the correct elements.
