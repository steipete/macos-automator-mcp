---
title: 'Core: ''contains'' Operator'
category: 02_as_core/operators
id: core_operator_contains
description: >-
  Checks if a list, record, or string contains another item or substring.
  Returns boolean.
keywords:
  - operator
  - contains
  - is in
  - substring
  - list membership
  - record key
language: applescript
---

The `contains` operator (and its synonym `is in`) is versatile for checking inclusion.

```applescript
-- String contains substring
set myString to "Hello World"
set hasHello to myString contains "Hello" -- true
set hasEarth to myString contains "Earth" -- false

-- List contains item
set myList to {"apple", "banana", "cherry"}
set hasBanana to myList contains "banana" -- true
set hasDate to myList contains "date" -- false
set isOneInList to 1 is in {1, 2, 3} -- true (using 'is in')

-- Record contains key-value pair (less common for 'contains', usually check properties)
-- 'contains' for records checks if the right-hand record is a sub-record of the left.
set recordA to {name:"apple", color:"red", taste:"sweet"}
set recordB to {color:"red"}
set recordC to {shape:"round"}
set aContainsB to recordA contains recordB -- true
set aContainsC to recordA contains recordC -- false

return "String: " & hasHello & ", List: " & hasBanana & ", Record: " & aContainsB
```
**Note:** When checking if a list contains a record, or vice-versa, AppleScript compares based on the structure and values. For checking if a record contains a specific *key*, you usually try to access the property in a `try` block.
END_TIP 
