---
title: 'Core: String Prefix/Suffix Operators'
category: 02_as_core
id: core_operator_string_prefix_suffix
description: 'Covers string operators like ''starts with'', ''ends with'', and their negations.'
keywords:
  - operator
  - string
  - starts with
  - ends with
  - prefix
  - suffix
  - does not start with
  - does not end with
language: applescript
notes: >-
  These operators are case-insensitive by default but can be made case-sensitive
  using a `considering case` block.
---

AppleScript provides convenient operators for checking string prefixes and suffixes.

```applescript
set myString to "AppleScript Language Guide"

-- Basic checks
set startsWithApple to myString starts with "Apple"   -- true
set endsWithGuide to myString ends with "Guide"     -- true
set startsWithScript to myString starts with "Script" -- false
set endsWithLang to myString ends with "Lang"       -- false

-- Negations
set notStartsWithX to myString does not start with "Xojo" -- true
set notEndsWithY to myString does not end with "Java"   -- true

-- Case sensitivity
set lowerString to "applescript language guide"
set startsWithAppleLower to lowerString starts with "Apple" -- true (default is case-insensitive)

considering case
  set startsWithAppleCaseSens to lowerString starts with "Apple" -- false (case-sensitive)
  set endsWithGuideCaseSens to lowerString ends with "guide"     -- true (case-sensitive)
end considering

return "Starts with Apple: " & startsWithApple & ¬
  "\nEnds with Guide: " & endsWithGuide & ¬
  "\nNot starts with Xojo: " & notStartsWithX & ¬
  "\nStarts with Apple (lower, default): " & startsWithAppleLower & ¬
  "\nStarts with Apple (lower, case-sensitive): " & startsWithAppleCaseSens & ¬
  "\nEnds with guide (lower, case-sensitive): " & endsWithGuideCaseSens
```
END_TIP 
