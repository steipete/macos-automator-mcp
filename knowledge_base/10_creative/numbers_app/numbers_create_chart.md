---
title: 'Numbers: Create Chart from Data'
category: 10_creative
id: numbers_create_chart
description: Creates a chart from data in a Numbers spreadsheet.
keywords:
  - Numbers
  - create chart
  - data visualization
  - chart
  - graph
language: applescript
argumentsPrompt: 'Enter the file path, sheet name, data range, and chart type'
notes: >-
  Creates a chart in a Numbers spreadsheet based on the specified data range.
  Chart types include 'column', 'bar', 'line', 'area', 'pie', and 'scatter'.
---

```applescript
on run {filePath, sheetName, dataRange, chartType}
  tell application "Numbers"
    try
      -- Handle placeholder substitution
      if filePath is "" or filePath is missing value then
        set filePath to "--MCP_INPUT:filePath"
      end if
      
      if sheetName is "" or sheetName is missing value then
        set sheetName to "--MCP_INPUT:sheetName"
      end if
      
      if dataRange is "" or dataRange is missing value then
        set dataRange to "--MCP_INPUT:dataRange"
      end if
      
      if chartType is "" or chartType is missing value then
        set chartType to "--MCP_INPUT:chartType"
      end if
      
      -- Validate file path
      if filePath does not start with "/" then
        return "Error: File path must be a valid absolute POSIX path starting with /"
      end if
      
      -- Normalize chart type to lowercase
      set chartType to my toLowerCase(chartType)
      
      -- Validate chart type
      set validChartTypes to {"column", "bar", "line", "area", "pie", "scatter"}
      set chartTypeValid to false
      
      repeat with validType in validChartTypes
        if chartType is validType then
          set chartTypeValid to true
          exit repeat
        end if
      end repeat
      
      if not chartTypeValid then
        return "Error: Invalid chart type. Please use one of: column, bar, line, area, pie, scatter."
      end if
      
      -- Open the Numbers file
      set targetDocument to open POSIX file filePath
      
      -- Access the specified sheet
      tell targetDocument
        -- Check if the sheet exists
        set sheetFound to false
        set targetSheet to missing value
        
        repeat with s in sheets
          if name of s is sheetName then
            set targetSheet to s
            set sheetFound to true
            exit repeat
          end if
        end repeat
        
        if not sheetFound then
          -- If sheet name not found, just use the first sheet and note this
          set targetSheet to sheet 1
          set sheetName to name of targetSheet
          set sheetWarning to "Note: Sheet \"" & sheetName & "\" was not found. Using first sheet \"" & sheetName & "\" instead."
        else
          set sheetWarning to ""
        end if
        
        -- Access the table in the sheet
        tell targetSheet
          if exists table 1 then
            -- Parse the data range
            set {startCell, endCell} to my parseDataRange(dataRange)
            
            if startCell is "ERROR" then
              return "Error: Invalid data range format. Please use format like 'A1:C10'."
            end if
            
            -- Parse start and end cells
            set {startCol, startRow} to my parseCellReference(startCell)
            set {endCol, endRow} to my parseCellReference(endCell)
            
            if startCol is "ERROR" or endCol is "ERROR" then
              return "Error: Invalid cell reference in data range."
            end if
            
            -- Convert column letters to numbers
            set startColNum to my columnLetterToNumber(startCol)
            set endColNum to my columnLetterToNumber(endCol)
            
            -- Use UI scripting to create the chart since AppleScript doesn't have direct methods
            tell application "System Events"
              tell process "Numbers"
                -- Ensure window is frontmost
                set frontmost to true
                
                -- Select the data range
                tell table 1 of targetSheet
                  -- Select the range
                  set selection range to range (cell startColNum of row startRow) to (cell endColNum of row endRow)
                end tell
                
                -- Click Insert menu
                click menu item "Chart" of menu "Insert" of menu bar 1
                delay 0.5
                
                -- Select the chart type from the submenu
                if chartType is "column" then
                  click menu item "Column" of menu "Chart" of menu "Insert" of menu bar 1
                else if chartType is "bar" then
                  click menu item "Bar" of menu "Chart" of menu "Insert" of menu bar 1
                else if chartType is "line" then
                  click menu item "Line" of menu "Chart" of menu "Insert" of menu bar 1
                else if chartType is "area" then
                  click menu item "Area" of menu "Chart" of menu "Insert" of menu bar 1
                else if chartType is "pie" then
                  click menu item "Pie" of menu "Chart" of menu "Insert" of menu bar 1
                else if chartType is "scatter" then
                  click menu item "Scatter" of menu "Chart" of menu "Insert" of menu bar 1
                end if
                
                -- Wait for chart to be created
                delay 1
                
                -- Generate success message
                set resultMessage to "Created " & chartType & " chart from data range " & dataRange & " in sheet \"" & sheetName & "\""
                
                if sheetWarning is not "" then
                  set resultMessage to resultMessage & return & return & sheetWarning
                end if
                
                return resultMessage
              end tell
            end tell
          else
            return "Error: No table found in sheet \"" & sheetName & "\"."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create chart - " & errMsg
    end try
  end tell
end run

-- Helper function to parse a data range like "A1:C10" into start and end cells
on parseDataRange(rangeText)
  if rangeText does not contain ":" then
    return {"ERROR", "ERROR"}
  end if
  
  set AppleScript's text item delimiters to ":"
  set rangeParts to text items of rangeText
  set AppleScript's text item delimiters to ""
  
  if (count of rangeParts) is not 2 then
    return {"ERROR", "ERROR"}
  end if
  
  set startCell to item 1 of rangeParts
  set endCell to item 2 of rangeParts
  
  return {startCell, endCell}
end parseDataRange

-- Helper function to parse a cell reference like "A1" into column letter and row number
on parseCellReference(cellRef)
  -- Match patterns like "A1", "BC23", etc.
  set columnLetter to ""
  set rowDigits to ""
  set foundDigit to false
  
  repeat with i from 1 to length of cellRef
    set currentChar to character i of cellRef
    
    if not foundDigit and currentChar is in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" then
      -- Still in the column part
      set columnLetter to columnLetter & currentChar
    else if currentChar is in "0123456789" then
      -- In the row part
      set rowDigits to rowDigits & currentChar
      set foundDigit to true
    else
      -- Invalid character
      return {"ERROR", "ERROR"}
    end if
  end repeat
  
  if columnLetter is "" or rowDigits is "" then
    return {"ERROR", "ERROR"}
  end if
  
  -- Convert row digits to number
  set rowNumber to rowDigits as number
  
  return {columnLetter, rowNumber}
end parseCellReference

-- Helper function to convert a column letter (A, B, C, ..., Z, AA, AB, ...) to column number
on columnLetterToNumber(columnLetter)
  set columnLetter to my toUppercase(columnLetter)
  set columnNumber to 0
  set alphabet to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  
  repeat with i from 1 to length of columnLetter
    set currentChar to character i of columnLetter
    set charValue to (offset of currentChar in alphabet)
    
    set columnNumber to columnNumber * 26 + charValue
  end repeat
  
  return columnNumber
end columnLetterToNumber

-- Helper function to convert text to uppercase
on toUppercase(inputText)
  return do shell script "echo " & quoted form of inputText & " | tr '[:lower:]' '[:upper:]'"
end toUppercase

-- Helper function to convert text to lowercase
on toLowerCase(inputText)
  return do shell script "echo " & quoted form of inputText & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase
```
END_TIP
