---
title: 'Keynote: Add New Slide with Master'
category: 10_creative/keynote_app
id: keynote_add_slide_master
description: >-
  Adds a new slide to the current Keynote presentation using a specified master
  slide name.
keywords:
  - Keynote
  - slide
  - new slide
  - master slide
  - presentation
language: applescript
isComplex: true
argumentsPrompt: >-
  Name of the master slide (e.g., 'Title & Bullets', 'Photo') as
  'masterSlideName' in inputData. Assumes a presentation is open.
notes: |
  - A Keynote presentation must be open and frontmost.
  - Master slide names are theme-dependent and case-sensitive.
  - Requires Automation permission for Keynote.app.
---

```applescript
--MCP_INPUT:masterSlideName

on addKeynoteSlide(theMasterSlideName)
  if theMasterSlideName is missing value or theMasterSlideName is "" then return "error: Master slide name required."

  tell application "Keynote"
    if not running then return "error: Keynote is not running."
    if (count of documents) is 0 then return "error: No Keynote presentation is open."
    activate
    
    try
      tell front document
        -- Get the master slide object by name
        set targetMaster to first master slide whose name is theMasterSlideName
        if targetMaster is missing value then
          return "error: Master slide '" & theMasterSlideName & "' not found in current theme. Available masters: " & (name of master slides)
        end if
        
        make new slide with properties {base slide:targetMaster}
      end tell
      return "New slide added using master '" & theMasterSlideName & "'."
    on error errMsg
      return "error: Failed to add slide in Keynote - " & errMsg
    end try
  end tell
end addKeynoteSlide

return my addKeynoteSlide("--MCP_INPUT:masterSlideName")
```
END_TIP 
