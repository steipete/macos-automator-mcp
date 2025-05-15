---
title: "Core: Logical Operators (and, or, not)"
category: "01_applescript_core" # Subdir: operators
id: core_operator_logical
description: "Explains the logical operators 'and', 'or', and 'not' for combining boolean expressions."
keywords: ["operator", "logical", "and", "or", "not", "boolean logic", "condition"]
language: applescript
notes: "Logical operators are fundamental for building complex conditional statements."
---

Logical operators combine boolean values to produce a single boolean result.

```applescript
set a to true
set b to false
set c to true

-- AND operator (true if all operands are true)
set result_a_and_b to a and b -- false
set result_a_and_c to a and c -- true

-- OR operator (true if at least one operand is true)
set result_a_or_b to a or b   -- true
set result_b_or_false to b or false -- false

-- NOT operator (reverses the boolean value)
set result_not_a to not a     -- false
set result_not_b to not b     -- true

-- Combining operators (parentheses for clarity and precedence)
set complexResult1 to (a and c) or b  -- (true and true) or false -> true or false -> true
set complexResult2 to not (b or (a and false)) -- not (false or (true and false)) -> not (false or false) -> not false -> true

-- Example in an if statement
set age to 25
set hasLicense to true
set canDrive to "Cannot Drive"

if age > 18 and hasLicense then
  set canDrive to "Can Drive"
end if

if (age < 16 or not hasLicense) then
  -- Additional logic for very young or unlicensed
end if

return "a AND b: " & result_a_and_b & ¬
  "\na AND c: " & result_a_and_c & ¬
  "\na OR b: " & result_a_or_b & ¬
  "\nNOT a: " & result_not_a & ¬
  "\nComplex Result 1: " & complexResult1 & ¬
  "\nCan Drive Status: " & canDrive
```
END_TIP 