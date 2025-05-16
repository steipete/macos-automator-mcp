---
title: 'Script Editor: Save Document As Application'
category: 13_developer
id: script_editor_save_as_app
description: Saves the frontmost Script Editor document as an application (applet).
keywords:
  - Script Editor
  - save script
  - applet
  - application
  - export
language: applescript
isComplex: true
argumentsPrompt: >-
  Absolute POSIX path (including .app extension) to save the applet as
  'savePath' in inputData. Optionally, boolean 'stayOpen', 'showStartupScreen'
  in inputData.
notes: |
  - Script Editor must be frontmost with a document open.
  - `savePath` should end with `.app`.
  - `stayOpen` default is false. `showStartupScreen` default is true.
---

```applescript
--MCP_INPUT:savePath
--MCP_INPUT:stayOpen
--MCP_INPUT:showStartupScreen

on saveScriptAsApp(posixSavePath, shouldStayOpen, shouldShowStartup)
  if posixSavePath is missing value or posixSavePath is "" then return "error: Save path not provided."
  if not (posixSavePath ends with ".app") then set posixSavePath to posixSavePath & ".app"
  
  set stayOpenOption to false
  if shouldStayOpen is true then set stayOpenOption to true
  
  set showStartupOption to true
  if shouldShowStartup is false then set showStartupOption to false -- Note: this is 'Never Show Startup Screen' in SE, so false means show. Confusing.
                                                                  -- Script Editor save: `startup screen (boolean)` -- If true, shows startup. Default true.
                                                                  -- So if user says `shouldShowStartup: false`, we want `startup screen: false`.
                                                                  -- Let's rename shouldShowStartup to neverShowStartupScreen for clarity.

  set fileToSave to POSIX file posixSavePath -- This creates a file object/specifier

  tell application "Script Editor"
    if not running then return "error: Script Editor is not running."
    if (count of documents) is 0 then return "error: No script document open."
    activate
    
    try
      tell front document
        save in fileToSave as "application" with stay open and startup screen
        -- The properties must be chained like this if using multiple.
        -- Example with options:
        -- save in fileToSave as "application" with stay open given (stayOpenOption) without startup screen
        -- The 'given/without' syntax or direct boolean might be more reliable.
        -- Let's use a record for properties.
        
        set saveOptions to {startup screen:showStartupOption}
        if stayOpenOption then
            set saveOptions to saveOptions & {stay open:true}
        else
            set saveOptions to saveOptions & {stay open:false}
        end if

        save in fileToSave as "application" with properties saveOptions
      end tell
      return "Script saved as application to: " & posixSavePath
    on error errMsg
      return "error: Failed to save script - " & errMsg
    end try
  end tell
end saveScriptAsApp

-- For MCP: assume input.showStartupScreen means "show it if true (default)", so map to AppleScript's `startup screen` property.
set inputNeverShowStartup to false -- Default is to show startup
if exists(inputData's showStartupScreen) and inputData's showStartupScreen is false then
    set inputNeverShowStartup to true
end if
set showStartupForAS to not inputNeverShowStartup

return my saveScriptAsApp("--MCP_INPUT:savePath", --MCP_INPUT:stayOpen, showStartupForAS)
``` 
