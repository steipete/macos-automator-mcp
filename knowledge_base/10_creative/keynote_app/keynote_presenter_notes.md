---
title: 'Keynote: Get and Set Presenter Notes'
category: 10_creative
id: keynote_presenter_notes
description: Gets or sets the presenter notes for the current slide in Keynote.
keywords:
  - Keynote
  - presenter notes
  - notes
  - slide notes
  - presentation
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional: Text to set as presenter notes as 'notesText' in inputData. If not
  provided, it gets current notes. Assumes a presentation is open.
notes: |
  - A Keynote presentation must be open and a slide selected.
  - Requires Automation permission for Keynote.app.
---

```applescript
--MCP_INPUT:notesText

on managePresenterNotes(newNotes)
  tell application "Keynote"
    if not running then return "error: Keynote is not running."
    if (count of documents) is 0 then return "error: No Keynote presentation is open."
    activate
    
    try
      tell front document
        set currentSlide to current slide
        if currentSlide is missing value then
          return "error: No slide is currently selected."
        end if
        
        if newNotes is not missing value and newNotes is not "" and newNotes is not "--MCP_INPUT:notesText" then
          -- Set presenter notes
          set presenter notes of currentSlide to newNotes
          return "Presenter notes set for current slide: " & newNotes
        else
          -- Get presenter notes
          set currentNotes to presenter notes of currentSlide
          if currentNotes is missing value then set currentNotes to "(empty)"
          return "Current presenter notes: " & currentNotes
        end if
      end tell
    on error errMsg
      return "error: Failed to manage presenter notes in Keynote - " & errMsg
    end try
  end tell
end managePresenterNotes

return my managePresenterNotes("--MCP_INPUT:notesText")
```
END_TIP 
