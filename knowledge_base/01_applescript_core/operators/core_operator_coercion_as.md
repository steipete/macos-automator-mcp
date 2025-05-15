---
title: "Core: Coercion Operator ('as')"
category: "01_applescript_core" # Subdir: operators
id: core_operator_coercion_as
description: "Explains the 'as' operator for explicit data type coercion (conversion)."
keywords: ["operator", "coercion", "as", "type conversion", "data type", "cast"]
language: applescript
notes: |
  - Coercion attempts to convert a value from one data type to another.
  - Not all coercions are possible and may result in an error if the conversion is invalid.
  - Common uses: string to number, number to string, date to string, alias to string.
---

The `as` operator is used to explicitly change the data type of a value.

```applescript
-- String to Number
set numStr to "123.45"
set myInt to "100" as integer      -- 100 (integer)
set myReal to numStr as real        -- 123.45 (real)
set myNum to numStr as number       -- 123.45 (number, often results in real for decimal strings)

-- Number to String
set anInt to 789
set anReal to 3.14159
set intAsStr to anInt as string    -- "789"
set realAsStr to anReal as string  -- "3.14159"

-- List to String
set myList to {1, "apple", true}
set listAsStr to myList as string  -- "1appletrue" (simple concatenation, often not desired)
-- For better list to string, use text item delimiters:
saveTID = AppleScript's text item delimiters
set AppleScript's text item delimiters to ", "
set formattedListStr to myList as string -- "1, apple, true"
set AppleScript's text item delimiters to saveTID

-- Date to String
set today to current date
set dateAsStr to today as string   -- e.g., "Sunday, 7 July 2024 at 14:30:00"

-- Boolean to String/Integer
set boolTrue to true
set boolTrueAsStr to boolTrue as string     -- "true"
set boolTrueAsInt to boolTrue as integer    -- 1
set boolFalseAsInt to false as integer   -- 0

-- Alias to String (POSIX Path)
-- set myFile to choose file -- Uncomment to test
-- if myFile is not missing value then
--   set aliasAsPosix to POSIX path of myFile
--   set aliasAsHFS to myFile as string
-- else
--   set aliasAsPosix to "(No file chosen)"
--   set aliasAsHFS to "(No file chosen)"
-- end if

-- Invalid Coercion (will error)
-- try
--   set problematic to "hello" as integer
-- on error errMsg
--   set problematic to "Error: " & errMsg
-- end try

return "String to Integer: " & myInt & ¬
  "\nNumber to String: " & intAsStr & ¬
  "\nFormatted List as String: " & formattedListStr & ¬
  "\nDate as String: " & dateAsStr & ¬
  "\nBoolean as Integer: " & boolTrueAsInt
  -- "\nAlias as POSIX: " & aliasAsPosix & ¬
  -- "\nProblematic: " & problematic
```
END_TIP 