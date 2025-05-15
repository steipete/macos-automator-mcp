---
title: "StandardAdditions: ASCII Character/Number"
category: "01_applescript_core" # Subdir: scripting_additions_osax
id: osax_ascii_char_num
description: "Converts between ASCII character codes (integers) and their corresponding characters."
keywords: ["StandardAdditions", "ASCII character", "ASCII number", "character code", "ord", "chr", "osax"]
language: applescript
notes: |
  - `ASCII number "A"` returns the ASCII code (e.g., 65 for "A").
  - `ASCII character 65` returns the character (e.g., "A" for 65).
  - Only works for standard ASCII characters (0-127). For extended characters or Unicode, other methods are needed.
---

These commands convert between characters and their ASCII integer codes.

```applescript
-- ASCII number: Get code from character
set charA_code to ASCII number "A" -- 65
set charZ_code to ASCII number "Z" -- 90
set char0_code to ASCII number "0" -- 48
set charSpace_code to ASCII number " " -- 32

-- ASCII character: Get character from code
set code66_char to ASCII character 66 -- "B"
set code97_char to ASCII character 97 -- "a"
set code49_char to ASCII character 49 -- "1"

-- Example: Incrementing a character (simple wrap-around for uppercase letters)
on incrementChar(theChar)
  if length of theChar is not 1 then return "Error: Input must be a single character."
  set charCode to ASCII number theChar
  if charCode < (ASCII number "A") or charCode > (ASCII number "Z") then
    return "Error: Character is not an uppercase letter."
  end if
  set nextCode to charCode + 1
  if nextCode > (ASCII number "Z") then
    set nextCode to ASCII number "A"
  end if
  return ASCII character nextCode
end incrementChar

set nextAfterC to incrementChar("C") -- "D"
set nextAfterZ to incrementChar("Z") -- "A"

-- Error handling for invalid input
set errorResultNum to "No error."
try
  set invalidCharNum to ASCII number "Hello" -- Will error, input must be single character
on error msg
  set errorResultNum to "Error (ASCII number): " & msg
end try

set errorResultChar to "No error."
try
  set invalidNumChar to ASCII character 300 -- Will error, code out of typical ASCII range
on error msg
  set errorResultChar to "Error (ASCII character): " & msg
end try


return "ASCII code for 'A': " & charA_code & ¬
  "\nCharacter for code 97: " & code97_char & ¬
  "\nNext after 'C': " & nextAfterC & ¬
  "\nNext after 'Z': " & nextAfterZ & ¬
  "\nError (ASCII num): " & errorResultNum & ¬
  "\nError (ASCII char): " & errorResultChar
```
END_TIP 