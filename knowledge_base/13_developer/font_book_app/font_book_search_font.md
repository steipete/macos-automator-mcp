---
title: "Font Book: Search for Font"
category: "developer"
id: font_book_search_font
description: "Searches for a specific font in Font Book."
keywords: ["Font Book", "search font", "find typeface", "font lookup", "font search"]
language: applescript
argumentsPrompt: "Enter the name of the font to search for"
notes: "Searches for a font by name and returns information about matching fonts."
---

```applescript
on run {fontName}
  tell application "Font Book"
    try
      if fontName is "" or fontName is missing value then
        set fontName to "--MCP_INPUT:fontName"
      end if
      
      activate
      
      -- Search for fonts matching the provided name
      set matchingFonts to every font whose name contains fontName or family name contains fontName
      
      if (count of matchingFonts) is 0 then
        return "No fonts found matching: " & fontName
      end if
      
      -- Create a list of matching font details
      set fontDetails to {}
      
      repeat with thisFont in matchingFonts
        set fontFullName to name of thisFont
        set fontFamilyName to family name of thisFont
        set fontPostScriptName to PostScript name of thisFont
        
        -- Get enabled status
        set fontStatus to "Enabled"
        if not (enabled of thisFont) then
          set fontStatus to "Disabled"
        end if
        
        -- Create detail string
        set fontDetail to "Font: " & fontFullName & "\\n" & ¬
                        "  Family: " & fontFamilyName & "\\n" & ¬
                        "  PostScript Name: " & fontPostScriptName & "\\n" & ¬
                        "  Status: " & fontStatus
        
        set end of fontDetails to fontDetail
      end repeat
      
      set AppleScript's text item delimiters to "\\n\\n"
      set outputString to "Matching Fonts (" & (count of matchingFonts) & "):\\n\\n" & (fontDetails as string)
      set AppleScript's text item delimiters to ""
      
      -- Try to select the first matching font in the Font Book interface
      if (count of matchingFonts) > 0 then
        select first item of matchingFonts
      end if
      
      return outputString
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search for fonts - " & errMsg
    end try
  end tell
end run
```
END_TIP