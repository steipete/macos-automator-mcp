---
title: "Keynote: Set Title and Body Text of Current Slide"
category: "10_creative_and_document_apps" # Subdir: keynote_app
id: keynote_set_slide_text
description: "Sets the title and body text content of the current slide in the frontmost Keynote presentation."
keywords: ["Keynote", "slide text", "title", "body", "content", "text item", "presentation"]
language: applescript
isComplex: true
argumentsPrompt: "Title text as 'titleText' and body text as 'bodyText' for the current slide in inputData. Assumes a presentation is open and has a slide selected."
notes: |
  - A Keynote presentation must be open and a slide selected.
  - This script attempts to set the object text of the slide's placeholder text items for title and body.
  - This relies on the current slide having conventional placeholder items for title and body. If the master slide is blank or uses non-standard placeholders, this may not work as expected.
  - Requires Automation permission for Keynote.app.
---

```applescript
--MCP_INPUT:titleText
--MCP_INPUT:bodyText

on setKeynoteSlideText(theTitle, theBody)
  if (theTitle is missing value or theTitle is "") and (theBody is missing value or theBody is "") then
    return "error: Both title and body text are missing. Nothing to set."
  end if

  tell application "Keynote"
    if not running then return "error: Keynote is not running."
    if (count of documents) is 0 then return "error: No Keynote presentation is open."
    activate
    
    try
      tell front document
        set currentSlide to current slide
        if currentSlide is missing value then
          return "error: No slide is currently selected or available."
        end if
        
        -- Setting title (assuming the first text item is the title placeholder)
        if theTitle is not missing value and theTitle is not "" then
          try
            set object text of first text item of currentSlide to theTitle
            log "Title set to: " & theTitle
          on error titleErr
            log "Could not set title. Slide might not have a standard title placeholder. Error: " & titleErr
            return "error: Could not set title text. " & titleErr
          end try
        end if
        
        -- Setting body (assuming the second text item is the body placeholder)
        -- This is a common convention but might not always hold true for all master slides.
        if theBody is not missing value and theBody is not "" then
          try
            -- Find a placeholder intended for body text. Often the largest one after the title.
            -- This is a heuristic. A more robust way would be to identify it by type if possible (e.g., 'body placeholder').
            set bodyPlaceholders to text items of currentSlide whose object text is not theTitle
            if (count of bodyPlaceholders) > 0 then
              set object text of item 1 of bodyPlaceholders to theBody
              log "Body set to: " & theBody
            else
              log "Could not find a distinct body placeholder to set."
              return "error: Could not find a suitable body placeholder."
            end if
          on error bodyErr
            log "Could not set body. Slide might not have a standard body placeholder or issue with identification. Error: " & bodyErr
            return "error: Could not set body text. " & bodyErr
          end try
        end if
        
      end tell
      return "Slide text set (if placeholders were found and settable). Title: '" & theTitle & "', Body: '" & theBody & "'"
    on error errMsg
      return "error: Failed to set text in Keynote slide - " & errMsg
    end try
  end tell
end setKeynoteSlideText

return my setKeynoteSlideText("--MCP_INPUT:titleText", "--MCP_INPUT:bodyText")
```
END_TIP 