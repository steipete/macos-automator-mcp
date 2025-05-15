---
title: "Core: Boolean Data Type"
category: "01_applescript_core" # Subdir: variables_and_data_types
id: core_datatype_boolean
description: "Working with boolean (true/false) values in AppleScript."
keywords: ["boolean", "true", "false", "data type", "logical", "condition"]
language: applescript
notes: |
  - Booleans are fundamental for conditional logic and flow control.
  - Result from comparisons or logical operations.
---

Booleans represent logical `true` or `false` values.

```applescript
-- Declaration
set isReady to true
set hasFailed to false

-- Usage in conditions
set message to ""
if isReady then
  set message to "System is Ready."
else
  set message to "System is not Ready."
end if

-- Result of comparisons
set a to 10
set b to 5
set isGreater to a > b -- isGreater will be true

-- Logical operations
set bothTrue to isReady and isGreater
set oneOrOtherTrue to isReady or hasFailed
set isNotFailed to not hasFailed

-- Coercion
set boolAsString to true as string -- "true"
set boolAsInteger to false as integer -- 0 (true is 1)

-- Note: Strings "true" or "false" can often be coerced back, but direct comparison is safer.
-- set stringAsBool to "true" as boolean -- This works

return "Message: " & message & "\nIs Greater: " & isGreater & "\nBoth True: " & bothTrue & "\nNot Failed: " & isNotFailed & "\nAs String: " & boolAsString & "\nAs Integer: " & boolAsInteger
```
END_TIP 