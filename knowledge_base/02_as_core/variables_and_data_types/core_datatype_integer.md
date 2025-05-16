---
title: 'Core: Integer Data Type'
category: 02_as_core/variables_and_data_types
id: core_datatype_integer
description: Working with integer (whole number) values in AppleScript.
keywords:
  - integer
  - number
  - whole number
  - data type
  - math
  - arithmetic
language: applescript
notes: Integers are exact whole numbers.
---

Integers are used for calculations involving whole numbers.

```applescript
-- Declaration
set count to 10
set score to -150
set quantity to 0

-- Arithmetic operations
set sumResult to count + 5          -- 15
set diffResult to count - 3         -- 7
set productResult to count * 2      -- 20
set divResult to count div 3        -- 3 (integer division)
set modResult to count mod 3        -- 1 (remainder)
set powerResult to 2 ^ 3            -- 8 (exponentiation)

-- Comparisons
set isPositive to count > 0
set isEqual to (score + 150) = quantity

-- Coercions
set intAsString to count as string        -- "10"
set intAsReal to count as real          -- 10.0

-- Coercion from string (if valid)
set stringAsInt to "25" as integer

return "Sum: " & sumResult & "\nDiv: " & divResult & "\nMod: " & modResult & "\nAs String: " & intAsString & "\nString as Int: " & stringAsInt
```
END_TIP 
