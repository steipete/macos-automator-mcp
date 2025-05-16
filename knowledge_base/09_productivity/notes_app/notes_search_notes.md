---
title: 'Notes: Search for Notes'
category: 09_productivity
id: notes_search_notes
description: Searches for notes containing specific text in the Notes app.
keywords:
  - Notes
  - search
  - find notes
  - note search
  - text search
language: applescript
argumentsPrompt: Enter the search text to find in notes
notes: >-
  Searches for notes containing the specified text in their title or body across
  all folders in Notes app.
---

```applescript
on run {searchText}
  tell application "Notes"
    try
      -- Handle placeholder substitution
      if searchText is "" or searchText is missing value then
        set searchText to "--MCP_INPUT:searchText"
      end if
      
      -- Get all notes from all folders
      set allNotes to {}
      set allFolders to every folder
      
      -- Collect all notes from each folder
      repeat with currentFolder in allFolders
        set folderName to name of currentFolder
        
        -- Skip certain system folders
        if folderName is not "Recently Deleted" then
          try
            tell currentFolder
              set folderNotes to every note
              
              repeat with currentNote in folderNotes
                set noteTitle to name of currentNote
                set noteId to id of currentNote
                
                -- Track the folder alongside each note
                set end of allNotes to {theNote:currentNote, title:noteTitle, id:noteId, folder:folderName}
              end repeat
            end tell
          end try
        end if
      end repeat
      
      -- Check if we have any notes to search
      if (count of allNotes) is 0 then
        return "No notes found to search."
      end if
      
      -- Search for the text in each note
      set matchingNotes to {}
      
      repeat with noteInfo in allNotes
        set currentNote to theNote of noteInfo
        set noteTitle to title of noteInfo
        set noteFolderName to folder of noteInfo
        
        -- Check if the search text is in the title (case-insensitive)
        set titleMatch to my textContainsIgnoringCase(noteTitle, searchText)
        
        -- Check if the search text is in the body
        set bodyMatch to false
        
        try
          set noteBody to body of currentNote
          set bodyMatch to my textContainsIgnoringCase(noteBody, searchText)
        end try
        
        -- If either title or body matches, add to results
        if titleMatch or bodyMatch then
          -- For better performance, truncate the matched content for display
          set noteSnippet to ""
          
          if bodyMatch then
            try
              set noteBody to body of currentNote
              
              -- Try to get a snippet around the match
              set lowerBody to my toLowerCase(noteBody)
              set lowerSearch to my toLowerCase(searchText)
              
              set matchPosition to offset of lowerSearch in lowerBody
              
              if matchPosition > 0 then
                -- Determine snippet range
                set snippetStart to matchPosition - 40
                if snippetStart < 1 then set snippetStart to 1
                
                set snippetEnd to matchPosition + 80
                if snippetEnd > (length of noteBody) then set snippetEnd to length of noteBody
                
                -- Extract snippet
                set noteSnippet to text snippetStart thru snippetEnd of noteBody
                
                -- Add ellipsis if needed
                if snippetStart > 1 then set noteSnippet to "..." & noteSnippet
                if snippetEnd < (length of noteBody) then set noteSnippet to noteSnippet & "..."
              else
                -- Fallback to just the beginning of the note
                set noteSnippet to text 1 thru (min of 100 and (length of noteBody)) of noteBody
                if length of noteBody > 100 then set noteSnippet to noteSnippet & "..."
              end if
              
            on error
              set noteSnippet to "[Content preview not available]"
            end try
          end if
          
          -- Add to matching notes
          set end of matchingNotes to {title:noteTitle, folder:noteFolderName, snippet:noteSnippet}
        end if
      end repeat
      
      -- Generate results
      if (count of matchingNotes) is 0 then
        return "No notes found containing \"" & searchText & "\"."
      else
        set resultText to "Found " & (count of matchingNotes) & " notes containing \"" & searchText & "\":" & return & return
        
        repeat with i from 1 to count of matchingNotes
          set noteInfo to item i of matchingNotes
          set noteTitle to title of noteInfo
          set noteFolderName to folder of noteInfo
          set noteSnippet to snippet of noteInfo
          
          -- Add note details to result
          set resultText to resultText & i & ". \"" & noteTitle & "\" in folder \"" & noteFolderName & "\"" & return
          
          if noteSnippet is not "" then
            set resultText to resultText & "   " & noteSnippet & return
          end if
          
          set resultText to resultText & return
        end repeat
        
        return resultText
      end if
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search notes - " & errMsg
    end try
  end tell
end run

-- Helper function to check if text contains a substring (case-insensitive)
on textContainsIgnoringCase(theText, searchString)
  set lowerText to my toLowerCase(theText)
  set lowerSearch to my toLowerCase(searchString)
  
  return lowerText contains lowerSearch
end textContainsIgnoringCase

-- Helper function to convert text to lowercase
on toLowerCase(theText)
  return do shell script "echo " & quoted form of theText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```
END_TIP
