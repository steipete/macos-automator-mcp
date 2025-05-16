---
title: 'Core: Reference Operator (''a reference to'')'
category: 02_as_core
id: core_operator_reference_to
description: >-
  Explains the 'a reference to' operator, which creates a pointer to an object
  or its parts.
keywords:
  - operator
  - reference
  - a reference to
  - pointer
  - indirect reference
language: applescript
notes: >
  - A reference allows indirect manipulation of data. Changes to the reference's
  target affect the original data.

  - Useful for working with items in lists, characters in strings, or properties
  of records when you want to modify them in place or pass them around.

  - `contents of` is used to get or set the value that a reference points to.
---

The `a reference to` operator creates a pointer to an object or a part of it.

```applescript
-- Reference to a variable
set myVar to 10
set refToMyVar to a reference to myVar
set contents of refToMyVar to 20 -- myVar is now 20

-- Reference to an item in a list
set myList to {100, 200, 300}
set refToListItem to a reference to item 2 of myList
set contents of refToListItem to 250 -- myList is now {100, 250, 300}

-- Reference to a character in a string (less common for modification as strings are often treated as immutable)
-- Modifying parts of strings usually involves creating new strings.
-- However, you can get a reference for examination.
set myString to "Hello"
set refToChar to a reference to character 1 of myString
set firstChar to contents of refToChar -- "H"
-- (Note: `set contents of refToChar to "J"` might not work as expected or error, string manipulation is different)

-- Reference to a property of a record
set myRecord to {name:"Apple", stock:50}
set refToStock to a reference to stock of myRecord
set contents of refToStock to (contents of refToStock) - 5 -- myRecord is now {name:"Apple", stock:45}

-- Using references in handlers
on incrementValue(aRef)
  set contents of aRef to (contents of aRef) + 1
end incrementValue

set counter to 5
set refToCounter to a reference to counter
my incrementValue(refToCounter) -- counter is now 6
incrementValue(a reference to item 1 of myList) -- myList is now {101, 250, 300}

return "myVar (after ref change): " & myVar & ¬
  "\nmyList (after ref change): " & myList & ¬
  "\nmyRecord (after ref change): " & myRecord & ¬
  "\ncounter (after ref handler): " & counter
```
END_TIP 
