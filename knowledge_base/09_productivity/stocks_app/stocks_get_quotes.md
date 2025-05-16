---
title: 'Stocks: Get Stock Quotes'
category: 09_productivity/stocks_app
id: stocks_get_quotes
description: Retrieves current stock quotes from the Stocks app.
keywords:
  - Stocks
  - stock quotes
  - financial data
  - market prices
  - stock market
language: applescript
notes: >-
  Gets prices and changes for stocks in your watchlist. The information
  available may be limited due to the app's UI accessibility.
---

```applescript
tell application "Stocks"
  try
    activate
    
    -- Give Stocks app time to launch
    delay 1
    
    tell application "System Events"
      tell process "Stocks"
        -- Ensure we're viewing the main watchlist
        if exists button "Back" of window 1 then
          click button "Back" of window 1
          delay 0.5
        end if
        
        -- Try to access the stocks list
        if exists table 1 of scroll area 1 of window 1 then
          set stocksList to {}
          set rows to rows of table 1 of scroll area 1 of window 1
          
          if (count of rows) is 0 then
            return "No stocks found in your watchlist."
          end if
          
          -- Iterate through each stock row to get its details
          repeat with i from 1 to count of rows
            set currentRow to item i of rows
            
            -- Try to get stock symbol, name, price, and change
            set stockSymbol to ""
            set stockName to ""
            set stockPrice to ""
            set stockChange to ""
            
            -- Extract information based on static text elements
            if exists static text 1 of currentRow then
              set stockSymbol to value of static text 1 of currentRow
            end if
            
            if exists static text 2 of currentRow then
              set stockName to value of static text 2 of currentRow
            end if
            
            if exists static text 3 of currentRow then
              set stockPrice to value of static text 3 of currentRow
            end if
            
            if exists static text 4 of currentRow then
              set stockChange to value of static text 4 of currentRow
            end if
            
            -- Format the stock information
            set stockInfo to ""
            if stockSymbol is not "" then
              set stockInfo to stockSymbol
            end if
            
            if stockName is not "" then
              if stockInfo is not "" then
                set stockInfo to stockInfo & " - " & stockName
              else
                set stockInfo to stockName
              end if
            end if
            
            if stockPrice is not "" then
              set stockInfo to stockInfo & "\\n  Price: " & stockPrice
            end if
            
            if stockChange is not "" then
              set stockInfo to stockInfo & "\\n  Change: " & stockChange
            end if
            
            if stockInfo is not "" then
              set end of stocksList to stockInfo
            end if
          end repeat
          
          set AppleScript's text item delimiters to "\\n\\n"
          set outputText to "Stock Quotes (" & (count of stocksList) & "):\\n\\n" & (stocksList as string)
          set AppleScript's text item delimiters to ""
          
          return outputText
        else
          return "Unable to access the stocks list. The Stocks app interface may have changed."
        end if
      end tell
    end tell
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to get stock quotes - " & errMsg
  end try
end tell
```
END_TIP
