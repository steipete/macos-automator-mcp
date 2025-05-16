---
title: 'Pages: Table Operations'
category: 10_creative/pages_app
id: pages_table_operations
description: Create and manipulate tables in Pages documents with formatting options.
keywords:
  - Pages
  - table
  - cells
  - formatting
  - borders
  - colors
  - document
language: applescript
argumentsPrompt: >-
  Enter the document path, table dimensions (rows and columns), and optional
  formatting parameters
notes: >-
  Creates or modifies tables in Pages documents. The document path should be a
  full POSIX path to an existing .pages file.
---

```applescript
on run {documentPath, rows, columns, headerRow, tableName, borderColor, headerBackgroundColor}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if documentPath is "" or documentPath is missing value then
        set documentPath to "--MCP_INPUT:documentPath"
      end if
      
      if rows is "" or rows is missing value then
        set rows to "--MCP_INPUT:rows"
      end if
      
      if columns is "" or columns is missing value then
        set columns to "--MCP_INPUT:columns"
      end if
      
      if headerRow is "" or headerRow is missing value then
        set headerRow to "--MCP_INPUT:headerRow"
      end if
      
      if tableName is "" or tableName is missing value then
        set tableName to "--MCP_INPUT:tableName"
      end if
      
      if borderColor is "" or borderColor is missing value then
        set borderColor to "--MCP_INPUT:borderColor"
      end if
      
      if headerBackgroundColor is "" or headerBackgroundColor is missing value then
        set headerBackgroundColor to "--MCP_INPUT:headerBackgroundColor"
      end if
      
      -- Convert numeric strings to numbers
      try
        set rows to rows as integer
        set columns to columns as integer
      on error
        return "Error: Rows and columns must be integer values."
      end try
      
      -- Verify document path format
      if documentPath does not start with "/" then
        return "Error: Document path must be a valid absolute POSIX path starting with /"
      end if
      
      if documentPath does not end with ".pages" then
        set documentPath to documentPath & ".pages"
      end if
      
      -- Open the document
      set docFile to POSIX file documentPath
      
      -- Check if file exists
      tell application "System Events"
        if not (exists file documentPath) then
          return "Error: The specified document does not exist at path: " & documentPath
        end if
      end tell
      
      open docFile
      
      -- Get the current document
      set currentDocument to front document
      
      -- Create the table
      tell currentDocument
        -- Position the cursor at the end of the document
        tell body text
          select (last paragraph)
          set selection to end of last paragraph
        end tell
        
        -- Insert a paragraph to ensure table is on its own line
        tell body text
          set selection to end of last paragraph
          type text return
        end tell
        
        -- Create the table
        make new table with properties {row count:rows, column count:columns, name:tableName}
        
        -- Get the newly created table
        set newTable to last table
        
        -- Apply header row if requested
        if headerRow is true or headerRow is "true" or headerRow is "yes" then
          tell newTable
            set header row count to 1
            
            -- Apply header background color if specified
            if headerBackgroundColor is not missing value and headerBackgroundColor is not "" then
              set cellRange to every cell of row 1
              repeat with aCell in cellRange
                tell aCell
                  -- Parse color string (assuming format is "r,g,b" with values 0-255)
                  try
                    set colorComponents to my parseColorString(headerBackgroundColor)
                    set background color to {red:item 1 of colorComponents, green:item 2 of colorComponents, blue:item 3 of colorComponents}
                  on error
                    -- Use default blue color if parsing fails
                    set background color to {red:0.0, green:0.35, blue:0.74}
                  end try
                end tell
              end repeat
            end if
          end tell
        end if
        
        -- Apply border color if specified
        if borderColor is not missing value and borderColor is not "" then
          tell newTable
            try
              set colorComponents to my parseColorString(borderColor)
              set border color to {red:item 1 of colorComponents, green:item 2 of colorComponents, blue:item 3 of colorComponents}
            on error
              -- Use default black color if parsing fails
              set border color to {red:0.0, green:0.0, blue:0.0}
            end try
          end tell
        end if
        
        -- Fill in sample data in the first cell
        tell newTable
          tell cell 1 of row 1
            set value to "Double-click to edit"
          end tell
        end tell
      end tell
      
      -- Save the document
      save currentDocument
      
      return "Successfully created table with " & rows & " rows and " & columns & " columns in document: " & documentPath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create table - " & errMsg
    end try
  end tell
end run

-- Helper function to parse color string ("r,g,b" format with values 0-255)
on parseColorString(colorStr)
  set AppleScript's text item delimiters to ","
  set colorParts to text items of colorStr
  
  if (count of colorParts) is not 3 then
    error "Invalid color format. Expected 'r,g,b' (values 0-255)."
  end if
  
  -- Convert from 0-255 range to 0-1 range
  set r to ((item 1 of colorParts) as number) / 255
  set g to ((item 2 of colorParts) as number) / 255
  set b to ((item 3 of colorParts) as number) / 255
  
  return {r, g, b}
end parseColorString

-- Example usage:
-- 1. Create a new table with 3 rows and 4 columns, with header row and custom colors
-- documentPath: "/Users/username/Documents/MyDocument.pages"
-- rows: 3
-- columns: 4
-- headerRow: true 
-- tableName: "Sample Table"
-- borderColor: "0,0,0" (black)
-- headerBackgroundColor: "230,230,230" (light gray)
```

This script allows users to work with tables in Pages documents by providing functionality to:

1. Create new tables with specified dimensions (rows and columns)
2. Customize tables with a header row
3. Apply formatting including border colors and header background colors
4. Name tables for easier reference in more complex documents
5. Add sample text to guide users

The script includes robust error handling to validate inputs and provide helpful error messages if issues occur. It also includes a helper function for parsing color values, making it easier for users to specify colors in a standard RGB format.

Advanced users could extend this script to:
- Add cell formatting options (text alignment, font styles)
- Populate the table with data from external sources
- Add table footers or specific column formatting
- Create formulas in cells (for Pages spreadsheet functionality)
