---
title: "Books: Get Current Book Info"
category: "08_creative_and_document_apps"
id: books_get_current_book
description: "Retrieves information about the currently open book in the Books app."
keywords: ["Books", "Apple Books", "ebook", "current book", "reading progress"]
language: applescript
notes: "Requires the Books app to be open with a book already loaded."
---

```applescript
tell application "Books"
  try
    activate
    
    -- Check if a book is currently open
    if not (exists window 1) then
      return "No book is currently open in the Books app."
    end if
    
    -- Get information about the current book
    tell application "System Events"
      tell process "Books"
        -- Extract book title from window title
        set windowTitle to name of window 1
        
        -- Check if we're in reading mode by looking for reader view
        if exists group 1 of window 1 then
          -- We're likely in reading mode with a book open
          
          -- Get book title from window title (remove " - Books" suffix)
          if windowTitle ends with " - Books" then
            set bookTitle to text 1 thru -9 of windowTitle
          else
            set bookTitle to windowTitle
          end if
          
          -- Try to get current page info if available
          set pageInfo to ""
          if exists static text 1 of group 1 of group 1 of window 1 then
            set pageText to value of static text 1 of group 1 of group 1 of window 1
            if pageText contains "of" then
              set pageInfo to "Page: " & pageText
            end if
          end if
          
          -- Format output
          set bookInfo to "Current Book: " & bookTitle
          if pageInfo is not "" then
            set bookInfo to bookInfo & "\\n" & pageInfo
          end if
          
          return bookInfo
        else
          -- We might be in library view or no book is open
          return "Books app is open, but no book appears to be in reading mode."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get current book info - " & errMsg
  end try
end tell
```
END_TIP