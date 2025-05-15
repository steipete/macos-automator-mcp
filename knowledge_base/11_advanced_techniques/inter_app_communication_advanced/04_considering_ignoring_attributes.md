---
title: "Advanced: 'considering/ignoring attributes' Block"
category: "11_advanced_techniques"
id: advanced_considering_ignoring_attributes
description: "Explains how the 'considering' and 'ignoring' blocks modify AppleScript's string comparison behavior for attributes like case, white space, punctuation, etc."
keywords: ["Apple Events", "considering", "ignoring", "case sensitivity", "white space", "punctuation", "diacriticals", "hyphens", "expansion", "string comparison"]
language: applescript
notes: |
  - `considering attribute1, attribute2, ... but ignoring attribute3, ... end considering` allows fine-grained control over string comparisons.
  - Attributes:
    - `case`: Distinguishes between uppercase and lowercase letters.
    - `white space`: Considers spaces, tabs, and newlines as significant.
    - `punctuation`: Considers punctuation marks (e.g., '.', ',', '!') as significant.
    - `hyphens`: Considers hyphens as significant.
    - `diacriticals`: Distinguishes characters with diacritical marks (e.g., 'é' vs 'e').
    - `numeric strings` (or `numeric_strings`): Treats sequences of digits as numbers for comparison (e.g., "Item 2" < "Item 10").
    - `expansion`: Expands ligatures (e.g., 'æ' to 'ae') before comparing.
  - `ignoring` does the opposite for the specified attributes.
  - The default behavior is often `ignoring case, white space, punctuation` but considering others.
---

`considering` and `ignoring` blocks allow you to temporarily change how AppleScript compares strings and other values, focusing on or disregarding specific attributes like case, white space, or punctuation.

This is crucial for making comparisons more or less strict as needed.

```applescript
set string1 to "Hello World!"
set string2 to "hello world"
set string3 to "HelloWorld"
set string4 to "Item 2"
set string5 to "Item 10"
set string6 to "résumé"
set string7 to "resume"

set results to {}

-- Default comparison (usually ignores case, punctuation, and leading/trailing whitespace)
set end of results to "Default: '" & string1 & "' = '" & string2 & "' is " & (string1 = string2) -- Usually true
set end of results to "Default: '" & string1 & "' = '" & string3 & "' is " & (string1 = string3) -- Usually false

-- Considering case
considering case
  set end of results to "Considering case: '" & string1 & "' = '" & string2 & "' is " & (string1 = string2) -- false
end considering

-- Ignoring white space (in addition to default ignores)
ignoring white space
  set end of results to "Ignoring white space: '" & string1 & "' = '" & string3 & "' is " & (string1 = string3) -- true
end ignoring

-- Considering punctuation (default usually ignores it for basic =)
-- but for 'contains', 'starts with', 'ends with', punctuation is usually considered.
considering punctuation
  set end of results to "Considering punctuation: '" & string1 & "' contains '!' is " & (string1 contains "!") -- true
end considering
ignoring punctuation
  set end of results to "Ignoring punctuation: '" & string1 & "' contains '!' is " & (string1 contains "!") -- This might still be true if 'contains' inherently checks for the character. Let's test equality.
  set end of results to "Ignoring punctuation: '" & string1 & "' = 'Hello World' is " & (string1 = "Hello World") -- true
end ignoring

-- Considering numeric strings
-- Default: "Item 10" comes before "Item 2" lexicographically
set end of results to "Default: '" & string4 & "' < '" & string5 & "' is " & (string4 < string5) -- false

considering numeric strings
  set end of results to "Considering numeric strings: '" & string4 & "' < '" & string5 & "' is " & (string4 < string5) -- true
end considering

-- Considering diacriticals
set end of results to "Default: '" & string6 & "' = '" & string7 & "' is " & (string6 = string7) -- Often true (ignores diacritics by default)

considering diacriticals
  set end of results to "Considering diacriticals: '" & string6 & "' = '" & string7 & "' is " & (string6 = string7) -- false
end considering

-- Combining considering and ignoring
considering case but ignoring white space
  set end of results to "Considering case, ignoring white space: 'Hello World' = 'HelloWorld' is " & ("Hello World" = "HelloWorld") -- false
  set end of results to "Considering case, ignoring white space: 'HelloWorld' = 'HelloWorld' is " & ("HelloWorld" = "HelloWorld") -- true
end considering

set output to ""
repeat with res in results
  set output to output & res & "\n"
end repeat

return output
```
END_TIP 