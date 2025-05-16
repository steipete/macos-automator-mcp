---
title: System Display Brightness Control
category: 04_system
id: system_display_brightness
description: Controls the brightness of the Mac's built-in display with precise increments
keywords:
  - brightness
  - display
  - screen
  - backlight
  - System Events
  - keyboard
  - control
language: applescript
notes: >-
  Works on MacBooks and iMacs with adjustable brightness. Requires accessibility
  permissions for System Events.
---

```applescript
-- Method 1: Using System Events keyboard shortcuts
tell application "System Events"
  -- Increase brightness (simulate F2 key)
  key code 144
  
  -- Decrease brightness (simulate F1 key)
  key code 145
end tell

-- Method 2: Using brightness adjustment in small increments
-- Set brightness to a specific level (0-100%)
on setBrightness(brightnessLevel)
  set brightnessLevel to brightnessLevel as number
  if brightnessLevel < 0 then set brightnessLevel to 0
  if brightnessLevel > 100 then set brightnessLevel to 100
  
  do shell script "brightness " & brightnessLevel / 100
end setBrightness

-- Increase brightness by 10%
on increaseBrightness()
  set currentBrightness to (do shell script "brightness -l | grep brightness | awk '{print $4}'") as number
  set newBrightness to currentBrightness + 0.1
  if newBrightness > 1 then set newBrightness to 1
  do shell script "brightness " & newBrightness
end increaseBrightness

-- Decrease brightness by 10%
on decreaseBrightness()
  set currentBrightness to (do shell script "brightness -l | grep brightness | awk '{print $4}'") as number
  set newBrightness to currentBrightness - 0.1
  if newBrightness < 0 then set newBrightness to 0
  do shell script "brightness " & newBrightness
end decreaseBrightness

-- Method 3: Alternative approach with `brightness` CLI tool (if installed)
-- Note: This requires the `brightness` command-line tool to be installed
-- Install with: brew install brightness

-- Example: Set brightness to 50%
setBrightness(50)

-- Example: Increase brightness by one step
increaseBrightness()

-- Example: Decrease brightness by one step
decreaseBrightness()
```

The script demonstrates multiple approaches to control display brightness:

1. Using System Events to simulate keyboard shortcuts (F1/F2 keys)
2. Using the `brightness` command-line tool for more precise control
   - Set exact brightness level (0-100%)
   - Incrementally increase or decrease brightness by 10%

For Method 2 and 3, you need to install the brightness command-line tool:
```bash
brew install brightness
```

You can also create a smooth transition effect:

```applescript
-- Fade brightness from current to target over time
on fadeBrightness(targetPercent, durationSeconds)
  set targetPercent to targetPercent as number
  if targetPercent < 0 then set targetPercent to 0
  if targetPercent > 100 then set targetPercent to 100
  set targetBrightness to targetPercent / 100
  
  set currentBrightness to (do shell script "brightness -l | grep brightness | awk '{print $4}'") as number
  set steps to 10
  set brightnessStep to (targetBrightness - currentBrightness) / steps
  set delayTime to durationSeconds / steps
  
  repeat with i from 1 to steps
    set newBrightness to currentBrightness + (brightnessStep * i)
    if newBrightness < 0 then set newBrightness to 0
    if newBrightness > 1 then set newBrightness to 1
    do shell script "brightness " & newBrightness
    delay delayTime
  end repeat
end fadeBrightness

-- Example: Fade brightness to 75% over 2 seconds
fadeBrightness(75, 2)
```

Note: These scripts require appropriate permissions to control system settings.
