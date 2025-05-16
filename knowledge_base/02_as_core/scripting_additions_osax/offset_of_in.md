---
title: "StandardAdditions: offset of...in Command"
category: "01_applescript_core"
id: osax_offset_of_in
description: "Finds the position of a substring within a string or an item within a list."
keywords: ["StandardAdditions", "offset", "substring", "find", "position", "string search", "list search"]
language: applescript
notes: |
  - Returns an integer position (1-based, not 0-based)
  - Returns 0 if the substring or item is not found
  - Can be used with both strings and lists
---

The `offset of...in` command helps locate a substring within text or an item in a list.

```applescript
-- Example 1: Finding substring positions in text
set sampleText to "AppleScript is a powerful scripting language for macOS."
set searchTerm to "script" -- --MCP_INPUT:searchTerm

try
  -- Find first occurrence (case-sensitive by default)
  set firstPos to offset of searchTerm in sampleText
  
  -- Find with starting position specified
  set secondPos to offset of searchTerm in sampleText from character (firstPos + 1)
  
  -- Find with case insensitivity
  considering case
    set caseSensitivePos to offset of searchTerm in sampleText
  end considering
  
  ignoring case
    set caseInsensitivePos to offset of searchTerm in sampleText
  end ignoring
  
  -- Example 2: Finding an item in a list
  set fruitList to {"apple", "banana", "cherry", "dates", "elderberry"}
  set listItem to "cherry"
  set itemPosition to offset of listItem in fruitList
  
  -- Build result string
  set resultText to "Search results for '" & searchTerm & "':\n" & ¬
    "- First position: " & firstPos & "\n" & ¬
    "- Second position: " & (if secondPos = 0 then "Not found" else secondPos as text) & "\n" & ¬
    "- Case-sensitive position: " & caseSensitivePos & "\n" & ¬
    "- Case-insensitive position: " & caseInsensitivePos & "\n\n" & ¬
    "Position of '" & listItem & "' in fruit list: " & itemPosition
    
  return resultText
on error errMsg
  return "Error: " & errMsg
end try
```

This command is useful for:
1. Finding where text appears in a document
2. Checking if a string contains a specific substring
3. Locating an item in a list
4. Parsing structured text (like CSV or log files)

When the item isn't found, it returns 0, so you can use that for conditional checks.
END_TIP