---
title: 'Dictionary: Switch Dictionary Source'
category: 13_developer/dictionary_app
id: dictionary_switch_dictionary
description: Switches between different dictionary sources in the Dictionary app.
keywords:
  - Dictionary
  - reference source
  - thesaurus
  - Oxford
  - Apple
  - dictionary source
language: applescript
argumentsPrompt: 'Enter the dictionary source to switch to (e.g., Oxford, American, Thesaurus)'
notes: >-
  Changes the active dictionary source. Common sources include 'Oxford',
  'American', 'Apple', and 'Thesaurus', but actual sources depend on what's
  installed.
---

```applescript
on run {dictionarySource}
  tell application "Dictionary"
    try
      if dictionarySource is "" or dictionarySource is missing value then
        set dictionarySource to "--MCP_INPUT:dictionarySource"
      end if
      
      activate
      
      -- Give Dictionary time to launch
      delay 1
      
      tell application "System Events"
        tell process "Dictionary"
          -- Click the source selection popup
          if exists pop up button 1 of group 1 of group 1 of window 1 then
            click pop up button 1 of group 1 of group 1 of window 1
            delay 0.5
            
            -- Look for the requested dictionary in the menu
            set dictionaryFound to false
            
            -- Try to find and click the dictionary in the menu
            if exists menu 1 of pop up button 1 of group 1 of group 1 of window 1 then
              set menuItems to menu items of menu 1 of pop up button 1 of group 1 of group 1 of window 1
              
              repeat with menuItem in menuItems
                set itemName to name of menuItem
                
                if itemName contains dictionarySource then
                  click menuItem
                  set dictionaryFound to true
                  
                  return "Successfully switched to " & itemName & " dictionary."
                  exit repeat
                end if
              end repeat
            end if
            
            -- If we didn't find the dictionary, press Escape to close the menu
            if not dictionaryFound then
              keystroke (ASCII character 27) -- Escape key
              
              -- List available dictionaries for the user
              set availableDictionaries to {}
              repeat with menuItem in menuItems
                set end of availableDictionaries to name of menuItem
              end repeat
              
              set AppleScript's text item delimiters to ", "
              set dictionaryList to availableDictionaries as string
              set AppleScript's text item delimiters to ""
              
              return "Dictionary '" & dictionarySource & "' not found. Available dictionaries: " & dictionaryList
            end if
          else
            return "Unable to access dictionary sources. Please make sure the Dictionary app is properly installed."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to switch dictionary source - " & errMsg
    end try
  end tell
end run
```
END_TIP
