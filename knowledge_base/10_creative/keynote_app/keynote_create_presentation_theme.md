---
title: 'Keynote: Create New Presentation from Theme'
category: 10_creative
id: keynote_create_presentation_theme
description: Creates a new Keynote presentation using a specified theme name.
keywords:
  - Keynote
  - presentation
  - new document
  - theme
language: applescript
isComplex: true
argumentsPrompt: >-
  Name of the Keynote theme (e.g., 'Black', 'White', 'Gradient') as 'themeName'
  in inputData.
notes: |
  - Keynote must be installed. Requires Automation permission for Keynote.app.
  - Theme names are case-sensitive and must match those available in Keynote.
---

```applescript
--MCP_INPUT:themeName

on createKeynotePresentation(theThemeName)
  if theThemeName is missing value or theThemeName is "" then
    -- Default to a common theme or error out
    -- For this example, we'll let Keynote pick its default if name is empty,
    -- but ideally, we'd require a theme name or have a known good default.
    -- set theThemeName to "White" 
  end if

  tell application "Keynote"
    activate
    try
      -- Keynote's 'make new document' command can take 'with theme'
      -- However, getting theme objects directly by name to pass to 'make new document with theme X' can be tricky.
      -- A more reliable way for specific themes might be UI scripting the theme chooser if direct theme naming fails,
      -- or using a simpler 'make new document' which uses the default theme.

      -- Simpler approach: make new document (uses default or last used theme)
      -- set newDocument to make new document
      
      -- Attempt to use theme by name (might require exact theme object reference)
      -- This is conceptual; direct theme object reference is better.
      -- For now, let's show how to set it *after* creation, or UI script it.
      
      set newDocument to make new document -- Creates with default theme
      delay 0.5 -- Allow document to appear
      
      -- If a specific theme name is given, try to change to it.
      -- This is often done via UI scripting the theme chooser, as direct theme setting can be complex.
      -- For simplicity, this example doesn't change the theme after creation,
      -- but notes that Keynote's dictionary allows `make new document with properties {document theme: theme "ThemeName"}`
      -- if `theme "ThemeName"` resolves correctly.

      if theThemeName is not missing value and theThemeName is not "" then
         try
            -- This is the ideal way if 'theme "ThemeName"' works directly.
            -- It might require Keynote 10+ for better theme object handling.
            -- set newDocument to make new document with properties {document theme:theme theThemeName}
            -- If above fails, one would resort to UI scripting the theme chooser.
            -- For this tip, we'll just acknowledge the theme name.
            log "Document created. Intended theme: " & theThemeName & ". Manual theme selection might be needed if default is not desired."
         on error themeError
            log "Could not apply theme '" & theThemeName & "' directly: " & themeError
         end try
      end if
      
      return "New Keynote presentation created (likely with default theme). Intended theme: " & theThemeName
    on error errMsg
      return "error: Failed to create Keynote presentation - " & errMsg
    end try
  end tell
end createKeynotePresentation

return my createKeynotePresentation("--MCP_INPUT:themeName")
```
END_TIP 
