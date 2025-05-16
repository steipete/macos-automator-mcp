---
title: 'Stocks: Search for Stock Symbol'
category: 09_productivity/stocks_app
id: stocks_search_symbol
description: Searches for a stock symbol or company name in the Stocks app.
keywords:
  - Stocks
  - search stock
  - stock symbol
  - company search
  - ticker search
language: applescript
argumentsPrompt: Enter the stock symbol or company name to search for
notes: >-
  Searches for a stock by symbol or company name. Results depend on what's
  available through the Stocks app.
---

```applescript
on run {searchQuery}
  tell application "Stocks"
    try
      if searchQuery is "" or searchQuery is missing value then
        set searchQuery to "--MCP_INPUT:searchQuery"
      end if
      
      activate
      
      -- Give Stocks app time to launch
      delay 1
      
      tell application "System Events"
        tell process "Stocks"
          -- Click in the search field
          if exists text field 1 of group 1 of toolbar 1 of window 1 then
            click text field 1 of group 1 of toolbar 1 of window 1
            
            -- Clear any existing search
            keystroke "a" using {command down}
            keystroke delete
            
            -- Type the search query
            keystroke searchQuery
            
            -- Wait for results
            delay 1
            
            -- Try to get search results if available
            if exists table 1 of scroll area 1 of window 1 then
              set searchResults to {}
              set rows to rows of table 1 of scroll area 1 of window 1
              
              if (count of rows) is 0 then
                -- Cancel search by pressing Escape
                keystroke (ASCII character 27) -- Escape key
                return "No stocks found matching: " & searchQuery
              end if
              
              -- Get information about the first few results
              set resultCount to count of rows
              if resultCount > 5 then set resultCount to 5
              
              repeat with i from 1 to resultCount
                set currentRow to item i of rows
                
                -- Try to get stock symbol and name
                set stockInfo to ""
                
                if exists static text 1 of currentRow then
                  set stockSymbol to value of static text 1 of currentRow
                  set stockInfo to stockSymbol
                end if
                
                if exists static text 2 of currentRow then
                  set stockName to value of static text 2 of currentRow
                  if stockInfo is not "" then
                    set stockInfo to stockInfo & " - " & stockName
                  else
                    set stockInfo to stockName
                  end if
                end if
                
                if stockInfo is not "" then
                  set end of searchResults to stockInfo
                end if
              end repeat
              
              -- Cancel search by pressing Escape
              keystroke (ASCII character 27) -- Escape key
              
              set AppleScript's text item delimiters to "\\n"
              set outputText to "Found " & (count of rows) & " results for \"" & searchQuery & "\":\\n" & (searchResults as string)
              set AppleScript's text item delimiters to ""
              
              return outputText
            else
              -- Cancel search by pressing Escape
              keystroke (ASCII character 27) -- Escape key
              return "Search completed, but unable to retrieve results."
            end if
          else
            return "Unable to access the search field. The Stocks app interface may have changed."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search for stock - " & errMsg
    end try
  end tell
end run
```
END_TIP
