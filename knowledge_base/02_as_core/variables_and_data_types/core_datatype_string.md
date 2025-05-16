---
title: "Core: String Data Type"
category: "01_applescript_core"
id: core_datatype_string
description: "Working with strings (text) in AppleScript, including properties like length, and elements like characters, words, paragraphs."
keywords: ["string", "text", "data type", "length", "character", "word", "paragraph", "concatenation"]
language: applescript
notes: |
  - Strings are delimited by double quotes (`""`).
  - Use `&` for concatenation.
  - `text item delimiters` are crucial for splitting/joining strings.
---

Strings are fundamental for handling text.

```applescript
set myString to "Hello, AppleScript World!"

-- Get length
set strLength to length of myString

-- Get elements
set firstChar to character 1 of myString
set firstWord to word 1 of myString
set allWords to words of myString -- returns a list

-- Concatenation
set greeting to "Greetings: " & myString

-- Coercion
set numAsString to "123"
set myNum to numAsString as integer

return "Length: " & strLength & "\\nFirst Char: " & firstChar & "\\nFirst Word: " & firstWord & "\\nGreeting: " & greeting & "\\nNumber: " & myNum
```
END_TIP 