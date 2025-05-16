---
title: "Keynote: Start and Stop Slideshow"
category: "08_creative_and_document_apps"
id: keynote_slideshow_control
description: "Starts or stops the slideshow for the frontmost Keynote presentation."
keywords: ["Keynote", "slideshow", "play", "start", "stop", "presentation mode"]
language: applescript
isComplex: true
argumentsPrompt: "Action to perform: 'start' or 'stop' as 'slideshowAction' in inputData."
notes: |
  - A Keynote presentation must be open.
  - `start` and `stop` are direct commands if Keynote's dictionary supports them for the document or application.
  - `show` and `stop slideshow` are common dictionary terms.
  - UI scripting can be a fallback if direct commands are problematic.
  - Requires Automation permission for Keynote.app.
---

```applescript
--MCP_INPUT:slideshowAction

on controlKeynoteSlideshow(action)
  if action is missing value or (action is not "start" and action is not "stop") then
    return "error: Invalid action. Use 'start' or 'stop'."
  end if

  tell application "Keynote"
    if not running then return "error: Keynote is not running."
    if (count of documents) is 0 then return "error: No Keynote presentation is open."
    activate
    
    try
      if action is "start" then
        -- Keynote dictionary uses 'show' for the document or 'play' for the application
        -- 'play front document' or just 'play' if a document is open often works.
        -- 'show front document' is also a possibility.
        
        -- Check if already playing to avoid issues
        if playing is false then
          play front document -- Or simply 'play'
          return "Keynote slideshow started."
        else
          return "Keynote slideshow is already playing."
        end if
        
      else if action is "stop" then
        -- Keynote dictionary uses 'stop slideshow' or just 'stop'
        if playing is true then
          stop slideshow -- Or simply 'stop'
          return "Keynote slideshow stopped."
        else
          return "Keynote slideshow is not currently playing."
        end if
      end if
    on error errMsg
      -- Fallback to UI scripting if direct commands fail (especially for older Keynote versions or complex setups)
      if action is "start" then
        log "Direct start command failed: " & errMsg & " - Attempting UI Scripting for Play."
        try
          tell application "System Events" to tell process "Keynote"
            click menu item "Play Slideshow" of menu 1 of menu bar item "Play" of menu bar 1
          end tell
          return "Keynote slideshow started (via UI scripting)."
        on error uiErr
          return "error: Failed to start slideshow via direct command or UI scripting - " & uiErr
        end try
      else if action is "stop" then
        log "Direct stop command failed: " & errMsg & " - Attempting UI Scripting for Stop (Escape key)."
        try
          tell application "System Events" to tell process "Keynote" 
            key code 53 -- Escape key
          end tell
          return "Keynote slideshow stopped (via UI scripting - Escape key)."
        on error uiErr2
          return "error: Failed to stop slideshow via direct command or UI scripting - " & uiErr2
        end try
      end if
      return "error: Failed to " & action & " slideshow in Keynote - " & errMsg
    end try
  end tell
end controlKeynoteSlideshow

return my controlKeynoteSlideshow("--MCP_INPUT:slideshowAction")
```
END_TIP 