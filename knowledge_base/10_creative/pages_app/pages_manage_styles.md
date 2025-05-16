---
title: "Pages: Manage Paragraph Styles"
category: "08_creative_and_document_apps"
id: pages_manage_styles
description: "Creates, modifies, and applies paragraph styles in a Pages document."
keywords: ["Pages", "styles", "paragraph styles", "text formatting", "document styling"]
language: applescript
argumentsPrompt: "Enter the style name and properties to create or modify. To apply a style, provide the text selection details."
notes: "This script allows you to create, modify, or apply paragraph styles in an open Pages document. The document must be open in Pages before running. Style properties are specified as a record."
---

```applescript
on run {styleName, styleProperties, selectionStart, selectionLength}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if styleName is "" or styleName is missing value then
        set styleName to "--MCP_INPUT:styleName"
      end if
      
      if styleProperties is "" or styleProperties is missing value then
        set styleProperties to "--MCP_INPUT:styleProperties"
      end if

      if selectionStart is "" or selectionStart is missing value then
        set selectionStart to "--MCP_INPUT:selectionStart"
      end if

      if selectionLength is "" or selectionLength is missing value then
        set selectionLength to "--MCP_INPUT:selectionLength"
      end if

      -- Convert selectionStart and selectionLength to integers if they're strings
      try
        set selectionStart to selectionStart as integer
      on error
        set selectionStart to 0
      end try
      
      try
        set selectionLength to selectionLength as integer
      on error
        set selectionLength to 0
      end try

      -- Verify if Pages is running and a document is open
      if not (exists window 1) then
        return "Error: No document is currently open in Pages."
      end if

      -- Get the frontmost document
      set theDocument to front document
      
      -- Create or modify a paragraph style
      if styleProperties is not equal to "" and styleProperties is not missing value then
        -- Parse the styleProperties string into a record
        -- Expected format: {font:"Helvetica", size:14, bold:true, italic:false, ...}
        set styleRecord to my parseStyleProperties(styleProperties)
        
        -- Check if the style already exists
        set styleExists to false
        repeat with existingStyle in paragraph styles of theDocument
          if name of existingStyle is styleName then
            set styleExists to true
            exit repeat
          end if
        end repeat
        
        if styleExists then
          -- Modify existing style
          set theStyle to paragraph style styleName of theDocument
          
          -- Apply properties from the record
          tell theStyle
            if styleRecord contains "font" then
              set font to font of styleRecord
            end if
            
            if styleRecord contains "size" then
              set font size to size of styleRecord
            end if
            
            if styleRecord contains "bold" then
              set bold to bold of styleRecord
            end if
            
            if styleRecord contains "italic" then
              set italic to italic of styleRecord
            end if
            
            if styleRecord contains "underline" then
              set underlined to underline of styleRecord
            end if
            
            if styleRecord contains "alignment" then
              set alignment to alignment of styleRecord
            end if
            
            if styleRecord contains "textColor" then
              set text color to textColor of styleRecord
            end if
            
            if styleRecord contains "backgroundColor" then
              set background color to backgroundColor of styleRecord
            end if
            
            if styleRecord contains "lineSpacing" then
              set line spacing to lineSpacing of styleRecord
            end if
          end tell
          
          return "Successfully modified paragraph style: " & styleName
        else
          -- Create new style
          make new paragraph style at theDocument with properties {name:styleName}
          set theStyle to paragraph style styleName of theDocument
          
          -- Apply properties from the record
          tell theStyle
            if styleRecord contains "font" then
              set font to font of styleRecord
            end if
            
            if styleRecord contains "size" then
              set font size to size of styleRecord
            end if
            
            if styleRecord contains "bold" then
              set bold to bold of styleRecord
            end if
            
            if styleRecord contains "italic" then
              set italic to italic of styleRecord
            end if
            
            if styleRecord contains "underline" then
              set underlined to underline of styleRecord
            end if
            
            if styleRecord contains "alignment" then
              set alignment to alignment of styleRecord
            end if
            
            if styleRecord contains "textColor" then
              set text color to textColor of styleRecord
            end if
            
            if styleRecord contains "backgroundColor" then
              set background color to backgroundColor of styleRecord
            end if
            
            if styleRecord contains "lineSpacing" then
              set line spacing to lineSpacing of styleRecord
            end if
          end tell
          
          return "Successfully created new paragraph style: " & styleName
        end if
      end if
      
      -- Apply a style to selected text
      if selectionStart > 0 and selectionLength > 0 then
        -- Check if the style exists
        set styleExists to false
        repeat with existingStyle in paragraph styles of theDocument
          if name of existingStyle is styleName then
            set styleExists to true
            exit repeat
          end if
        end repeat
        
        if not styleExists then
          return "Error: Style '" & styleName & "' does not exist in this document."
        end if
        
        -- Apply the style to the specified selection
        tell theDocument
          tell body text
            -- Create a selection based on provided start and length
            set selectionRange to {selectionStart, selectionLength}
            
            -- Apply the style to each paragraph in the selection
            repeat with i from paragraph (first item of selectionRange) to paragraph ((first item of selectionRange) + (second item of selectionRange) - 1)
              set paragraph style of i to paragraph style styleName of theDocument
            end repeat
          end tell
        end tell
        
        return "Successfully applied style '" & styleName & "' to selected text."
      end if
      
      -- If we reach here, return a list of existing styles
      set styleNames to {}
      repeat with existingStyle in paragraph styles of theDocument
        set end of styleNames to name of existingStyle
      end repeat
      
      return "Available paragraph styles: " & styleNames
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to manage styles - " & errMsg
    end try
  end tell
end run

-- Helper function to parse style properties from a string to a record
on parseStyleProperties(propString)
  -- This is a simplified parser - in a real script you would use a more robust method
  -- or require a properly formatted record string
  set styleRecord to {}
  
  -- Remove curly braces
  set propString to text 2 thru -2 of propString
  
  -- Split by commas
  set propPairs to my splitString(propString, ",")
  
  repeat with propPair in propPairs
    -- Split by colon
    set keyValue to my splitString(propPair, ":")
    if (count of keyValue) is 2 then
      set keyName to text 1 thru -1 of item 1 of keyValue
      set valueText to text 1 thru -1 of item 2 of keyValue
      
      -- Clean up key (remove quotes)
      if keyName begins with "\"" and keyName ends with "\"" then
        set keyName to text 2 thru -2 of keyName
      end if
      
      -- Clean up value (handle different types)
      if valueText is "true" then
        set valueData to true
      else if valueText is "false" then
        set valueData to false
      else if valueText begins with "\"" and valueText ends with "\"" then
        -- String value
        set valueData to text 2 thru -2 of valueText
      else
        -- Try to convert to number
        try
          set valueData to valueText as number
        on error
          set valueData to valueText
        end try
      end if
      
      -- Add to record
      set styleRecord to styleRecord & {keyName:valueData}
    end if
  end repeat
  
  return styleRecord
end parseStyleProperties

-- String split helper
on splitString(theString, theDelimiter)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theDelimiter
  set theItems to every text item of theString
  set AppleScript's text item delimiters to oldDelimiters
  return theItems
end splitString
```