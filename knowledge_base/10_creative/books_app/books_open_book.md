---
title: "Books: Open Book by Title"
category: "08_creative_and_document_apps"
id: books_open_book
description: "Opens a book by title in the Books app."
keywords: ["Books", "Apple Books", "open book", "ebook", "read book"]
language: applescript
argumentsPrompt: "Enter the title of the book to open"
notes: "Searches for a book by title in your library. Requires the Books app to be configured with your Apple ID and library."
---

```applescript
on run {bookTitle}
  tell application "Books"
    try
      if bookTitle is "" or bookTitle is missing value then
        set bookTitle to "--MCP_INPUT:bookTitle"
      end if
      
      activate
      
      -- Give the Books app a moment to launch
      delay 1
      
      tell application "System Events"
        tell process "Books"
          -- Make sure we're in library view
          -- Try to click "Library" in the sidebar if it exists
          if exists row "Library" of table 1 of scroll area 1 of group 1 of window 1 then
            click row "Library" of table 1 of scroll area 1 of group 1 of window 1
            delay 0.5
          end if
          
          -- Click in the search field
          click text field 1 of group 1 of toolbar 1 of window 1
          
          -- Clear any existing text
          keystroke "a" using {command down}
          keystroke delete
          
          -- Search for the book
          keystroke bookTitle
          delay 1
          keystroke return
          delay 2
          
          -- Try to open the first search result if it exists
          if exists row 1 of table 1 of scroll area 1 of group 1 of group 1 of window 1 then
            click row 1 of table 1 of scroll area 1 of group 1 of group 1 of window 1
            delay 0.5
            
            -- Double-click to open the book
            click row 1 of table 1 of scroll area 1 of group 1 of group 1 of window 1
            delay 0.1
            click row 1 of table 1 of scroll area 1 of group 1 of group 1 of window 1
            
            return "Opened book: " & bookTitle
          else
            return "No books found matching: " & bookTitle
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to open book - " & errMsg
    end try
  end tell
end run
```
END_TIP