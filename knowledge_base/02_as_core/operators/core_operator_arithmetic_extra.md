---
title: 'Core: Arithmetic Operators (div, mod, ^)'
category: 02_as_core
id: core_operator_arithmetic_extra
description: >-
  Covers the integer division (div), modulo (mod), and exponentiation (^)
  operators.
keywords:
  - operator
  - arithmetic
  - div
  - mod
  - power
  - exponentiation
  - integer division
  - remainder
language: applescript
notes: |
  - `div` performs integer division, truncating any fractional part.
  - `mod` returns the remainder of an integer division.
  - `^` raises a number to a power.
---

These operators handle specific mathematical operations.

```applescript
-- Integer Division (div)
set intResult1 to 10 div 3  -- Result: 3 (10 / 3 = 3.33..., truncated)
set intResult2 to 9 div 3   -- Result: 3
set intResult3 to 7 div 2   -- Result: 3
set intResult4 to -10 div 3 -- Result: -3

-- Modulo (mod) - Remainder
set modResult1 to 10 mod 3  -- Result: 1 (10 = 3*3 + 1)
set modResult2 to 9 mod 3   -- Result: 0
set modResult3 to 7 mod 2   -- Result: 1
set modResult4 to -10 mod 3 -- Result: -1 (AppleScript's mod can be tricky with negative numbers, it's often `a mod n = a - n * (a div n)`)
-- For a positive remainder with negative numbers, you might need: `set positiveMod to ((-10 mod 3) + 3) mod 3` which gives 2

-- Exponentiation (^)
set powerResult1 to 2 ^ 3   -- Result: 8 (2 * 2 * 2)
set powerResult2 to 10 ^ 2  -- Result: 100
set powerResult3 to 5 ^ 0.5 -- Result: 2.2360679775 (square root)
set powerResult4 to 4 ^ -1  -- Result: 0.25 (1/4)

return "10 div 3: " & intResult1 & ¬
  "\n-10 div 3: " & intResult4 & ¬
  "\n10 mod 3: " & modResult1 & ¬
  "\n-10 mod 3: " & modResult4 & ¬
  "\n2 ^ 3: " & powerResult1 & ¬
  "\n5 ^ 0.5: " & powerResult3
```
END_TIP 
