---
title: 'Core: Concatenation Operator (&)'
category: 02_as_core/operators
id: core_operator_concat
description: >-
  The ampersand (&) operator is used to concatenate (join) strings, lists, or
  add properties to records.
keywords:
  - operator
  - concatenate
  - join
  - string
  - list
  - record
  - '&'
language: applescript
---

```applescript
-- String concatenation
set str1 to "Hello"
set str2 to "World"
set combinedString to str1 & " " & str2 & "!" -- "Hello World!"

-- List concatenation
set list1 to {1, 2}
set list2 to {3, 4}
set combinedList to list1 & list2 -- {1, 2, 3, 4}
set combinedListAndItem to list1 & 5 -- {1, 2, 5}

-- Record concatenation (adds/overwrites properties)
set record1 to {name:"Apple"}
set record2 to {color:"Red"}
set combinedRecord to record1 & record2 -- {name:"Apple", color:"Red"}
set record3 to {name:"Banana", type:"Fruit"}
set updatedRecord1 to record1 & record3 -- {name:"Banana", type:"Fruit"} (name is overwritten)

return "String: " & combinedString & "\\nList: " & (combinedList as string) & "\\nRecord: " & (text 1 thru 30 of (combinedRecord as string)) -- Coercing record to string is verbose
``` 
