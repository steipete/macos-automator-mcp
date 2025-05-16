---
title: "Core: Textual Comparison Operators"
category: "01_applescript_core"
id: core_operator_comparison_textual
description: "Covers textual comparison operators in AppleScript like 'comes before', 'comes after', and their negations."
keywords: ["operator", "comparison", "comes before", "comes after", "is not less than", "is not greater than", "string comparison", "lexicographical"]
language: applescript
notes: |
  - These operators primarily compare strings lexicographically (alphabetically).
  - Can also be used with numbers, where they behave like their symbolic counterparts (`<`, `>`, `>=`, `<=`).
  - `is less than`, `is greater than`, `is less than or equal to`, `is greater than or equal to` are synonyms for symbolic operators but can also be used.
---

AppleScript offers English-like comparison operators, especially useful for strings.

```applescript
-- String comparisons
set strA to "apple"
set strB to "banana"

set aBeforeB to strA comes before strB -- true
set bAfterA to strB comes after strA   -- true

set strC to "apple"
set aNotAfterC to not (strA comes after strC) -- true (equivalent to strA is not greater than strC)
set aNotBeforeC to not (strA comes before strC) -- false (equivalent to strA is not less than strC)

-- Using 'is not less than' and 'is not greater than'
set x to 10
set y to 5
set z to 10

set xNotLessThanY to x is not less than y -- true (10 is not < 5)
set yNotGreaterThanX to y is not greater than x -- true (5 is not > 10)
set xNotLessThanZ to x is not less than z -- true (10 is not < 10, i.e. 10 >= 10)
set xNotGreaterThanZ to x is not greater than z -- true (10 is not > 10, i.e. 10 <= 10)

-- Numeric comparisons (behave like symbolic operators)
set numComparison1 to 5 comes before 10 -- true (5 < 10)
set numComparison2 to 10 comes after 5  -- true (10 > 5)
set numComparison3 to 7 is not less than 7 -- true (7 >= 7)

return "strA comes before strB: " & aBeforeB & ¬
  "\nstrB comes after strA: " & bAfterA & ¬
  "\nx is not less than y: " & xNotLessThanY & ¬
  "\ny is not greater than x: " & yNotGreaterThanX & ¬
  "\nx is not less than z: " & xNotLessThanZ & ¬
  "\nx is not greater than z: " & xNotGreaterThanZ
```
END_TIP 