---
title: 'Core: Record Data Type'
category: 02_as_core
id: core_datatype_record
description: >-
  Working with records (objects/dictionaries) in AppleScript, which store
  key-value pairs.
keywords:
  - record
  - object
  - dictionary
  - data type
  - property
  - key-value
language: applescript
---

Records store labeled data.

```applescript
set myRecord to {name:"John Doe", age:30, city:"Cupertino"}

-- Access properties
set personName to name of myRecord
set personAge to age of myRecord

-- Set properties
set city of myRecord to "New York"

-- Add new properties (by concatenating with another record)
set myRecord to myRecord & {occupation:"Developer"}

-- Check if a property exists (less direct, often involves try block or getting all properties)
set propertiesList to properties of myRecord -- Not standard, better to get keys
-- A way to check is:
try
  set _ to occupation of myRecord
  set hasOccupation to true
on error
  set hasOccupation to false
end try

return "Name: " & personName & ", Age: " & personAge & ", City: " & city of myRecord & ", Occupation: " & occupation of myRecord & ", Has Occupation: " & hasOccupation
```
END_TIP 
