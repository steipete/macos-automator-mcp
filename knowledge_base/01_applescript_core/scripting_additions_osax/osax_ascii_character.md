---
title: "StandardAdditions: ASCII character Command"
category: "01_applescript_core" # Subdir: scripting_additions_osax
id: osax_ascii_character
description: "Converts an ASCII number (0-255) to its corresponding character."
keywords: ["StandardAdditions", "ASCII character", "character code", "ASCII to char", "osax"]
language: applescript
notes: |
  - Input must be an integer between 0 and 255 (inclusive).
  - Useful for generating characters that are hard to type or for specific control characters (though many control characters won't have a visible representation).
---

```applescript
-- Convert ASCII numbers to characters
set char_A to ASCII character 65
set char_a to ASCII character 97
set char_0 to ASCII character 48
set char_space to ASCII character 32
set char_newline to ASCII character 10 -- (line feed)
set char_tab to ASCII character 9 -- (horizontal tab)

-- Example with a loop (first few printable characters)
set resultList to {}
repeat with i from 32 to 47 -- Space to /
  set end of resultList to "ASCII " & i & ": " & (ASCII character i)
end repeat

return "A: " & char_A & "\na: " & char_a & "\n0: " & char_0 & "\nSpace: '" & char_space & "'\nNewline (conceptual): " & char_newline & "\nTab (conceptual): " & char_tab & "\n\n" & resultList
``` 