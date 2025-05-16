---
title: 'Dictionary: Look Up Word'
category: 13_developer
id: dictionary_look_up_word
description: Looks up a word in the macOS Dictionary app.
keywords:
  - Dictionary
  - word lookup
  - definition
  - thesaurus
  - lexicon
language: applescript
argumentsPrompt: Enter the word to look up
notes: Searches for a word in the Dictionary app using all available dictionaries.
---

```applescript
on run {wordToLookup}
  tell application "Dictionary"
    try
      if wordToLookup is "" or wordToLookup is missing value then
        set wordToLookup to "--MCP_INPUT:wordToLookup"
      end if
      
      activate
      
      -- Give Dictionary time to launch
      delay 1
      
      -- Look up the word
      tell application "System Events"
        tell process "Dictionary"
          -- Click in the search field
          click text field 1 of group 1 of toolbar 1 of window 1
          
          -- Clear any existing search
          keystroke "a" using {command down}
          keystroke delete
          
          -- Type the word and initiate search
          keystroke wordToLookup
          keystroke return
          
          -- Wait for results to load
          delay 1
          
          -- Try to get definition from the content view
          set definitionFound to false
          set definitionText to "Definition not found for: " & wordToLookup
          
          if exists group 1 of scroll area 1 of group 1 of window 1 then
            if exists static text 1 of group 1 of scroll area 1 of group 1 of window 1 then
              -- We likely have a definition, get what we can
              set definitionFound to true
              
              -- Try to get word form and pronunciation if available
              set wordForm to ""
              set pronunciation to ""
              
              if exists static text 1 of group 1 of scroll area 1 of group 1 of window 1 then
                set wordForm to value of static text 1 of group 1 of scroll area 1 of group 1 of window 1
              end if
              
              if exists static text 2 of group 1 of scroll area 1 of group 1 of window 1 then
                set pronunciation to value of static text 2 of group 1 of scroll area 1 of group 1 of window 1
              end if
              
              set definitionText to "Word: " & wordToLookup
              
              if wordForm is not "" then
                set definitionText to definitionText & "\\nForm: " & wordForm
              end if
              
              if pronunciation is not "" then
                set definitionText to definitionText & "\\nPronunciation: " & pronunciation
              end if
              
              set definitionText to definitionText & "\\n\\nDefinition found in Dictionary. Please refer to the Dictionary app for the complete definition."
            end if
          end if
          
          -- Return the result
          if definitionFound then
            return definitionText
          else
            return "No definition found for: " & wordToLookup
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to look up word - " & errMsg
    end try
  end tell
end run
```
END_TIP
