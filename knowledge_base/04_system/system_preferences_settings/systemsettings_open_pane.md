---
title: 'System Settings: Open Specific Preference Pane'
category: 04_system/system_preferences_settings
id: systemsettings_open_pane
description: >-
  Opens System Settings (or System Preferences on older macOS) to a specific
  preference pane by its ID or localized name.
keywords:
  - system settings
  - system preferences
  - open pane
  - ui scripting
  - configuration
language: applescript
isComplex: true
argumentsPrompt: >-
  Pane ID (e.g., 'com.apple.preference.network',
  'com.apple.preference.displays') as 'paneID' OR Localized Pane Name (e.g.,
  'Network', 'Displays') as 'paneName' in inputData.
notes: >
  - UI Scripting is used if direct pane ID opening fails or for older systems.

  - Pane IDs are more stable but harder to find. Localized names can change.

  - Tested on macOS [Specify Version if possible, e.g., Ventura 13.x]. Highly
  fragile across macOS versions.

  - Requires Automation & Accessibility for System Settings/Preferences.
---

```applescript
--MCP_INPUT:paneID
--MCP_INPUT:paneName

on openPreferencePane(thePaneID, thePaneName)
  set appNameToUse to "System Settings"
  if (system version of (system info)) starts with "10." or (system version of (system info)) starts with "11." or (system version of (system info)) starts with "12." then
    set appNameToUse to "System Preferences"
  end if

  tell application appNameToUse
    activate
    if thePaneID is not missing value and thePaneID is not "" then
      try
        -- Modern macOS often supports revealing panes by ID
        reveal pane id thePaneID
        return "Opened System Settings to pane ID: " & thePaneID
      on error errMsg1
        -- Fallback for older systems or if ID reveal fails
        try
          reveal anchor "com.apple.anchor." & thePaneID of pane id "com.apple.preference.system" -- General attempt
          return "Attempted to open System Settings to pane ID (anchor): " & thePaneID
        on error errMsg2
          log "Failed to open pane by ID or anchor: " & errMsg1 & " / " & errMsg2
          -- Continue to try by name if provided
        end try
      end try
    end if
    
    if thePaneName is not missing value and thePaneName is not "" then
      try
        -- This is more for older System Preferences
        set current pane to pane thePaneName
        return "Opened System Settings to pane: " & thePaneName
      on error errMsg3
        -- UI Scripting as a last resort if a name is given (very fragile)
        log "Failed to open pane by name directly: " & errMsg3 & ". Attempting UI click if possible."
        try
          tell application "System Events"
            tell process appNameToUse
              -- This requires knowing the exact UI structure (e.g., scrolling a list, clicking item)
              -- For example, if panes are in a scroll area:
              -- click (first static text whose value is thePaneName) of scroll area 1 of group 1 of window 1
              -- This is too complex for a generic example without knowing pane layout.
              return "error: UI scripting to click pane '" & thePaneName & "' is complex and not implemented generically. Try pane ID."
            end tell
          end tell
        on error uiErr
            return "error: Could not open pane '" & thePaneName & "' by name or UI scripting: " & uiErr
        end try
      end try
    end if
    
    if (thePaneID is missing value or thePaneID is "") and (thePaneName is missing value or thePaneName is "") then
      return "System Settings opened. No specific pane requested."
    else
      return "error: Could not open requested pane. PaneID: " & (thePaneID as text) & ", PaneName: " & (thePaneName as text)
    end if
  end tell
end openPreferencePane

return my openPreferencePane("--MCP_INPUT:paneID", "--MCP_INPUT:paneName")
``` 
