---
title: International and Unicode Text in AppleScript
category: 02_as_core/variables_and_data_types
id: core_datatype_international_unicode_text
description: >-
  Working with international character sets and Unicode text in AppleScript for
  multilingual applications.
keywords:
  - international text
  - Unicode text
  - localization
  - i18n
  - UTF-8
  - character encoding
  - multi-byte
  - non-Latin
language: applescript
notes: >
  - International text and Unicode text are specialized data types for handling
  non-ASCII characters

  - Modern macOS primarily uses Unicode (UTF-8/UTF-16) for text encoding

  - The distinction between these types is less relevant in modern AppleScript
  versions, but still important for compatibility
---

AppleScript provides specialized text data types for handling non-ASCII text and multilingual requirements. This is crucial for creating localized scripts and working with diverse writing systems.

```applescript
-- Basic text handling
set regularText to "Hello, world!"

-- International text example (legacy type with limited support)
set internationalGreeting to "こんにちは" as international text -- Japanese "Konnichiwa"

-- Unicode text example (recommended for all non-ASCII needs)
set unicodeGreeting to "Привет, мир!" as Unicode text -- Russian "Hello, world"
set unicodeGreeting2 to "你好，世界！" as Unicode text -- Chinese "Hello, world"
set unicodeGreeting3 to "안녕하세요!" as Unicode text -- Korean "Hello"
set unicodeEmoji to "👋🌎🚀" as Unicode text -- Emoji: waving hand, world, rocket

-- Character properties and information
set textLength to length of unicodeGreeting -- Length in characters, not bytes
set firstChar to character 1 of unicodeGreeting -- First character: "П"

-- Iterating and working with Unicode characters
set characterCount to count of characters of unicodeEmoji
set characterList to {}

repeat with i from 1 to characterCount
  set charAtPosition to character i of unicodeEmoji
  set end of characterList to charAtPosition
end repeat

-- Conversion between text types
set convertedText to unicodeGreeting as text -- In modern AppleScript, this is generally safe
set convertedBackToUnicode to convertedText as Unicode text

-- Displaying in dialog (demonstrates charset compatibility)
-- display dialog unicodeGreeting & return & unicodeGreeting2 & return & unicodeGreeting3 & return & unicodeEmoji

-- Create a summary of our text examples
set summaryText to "Text type demonstrations:" & return & return & ¬
  "Regular text: " & regularText & return & ¬
  "International text (Japanese): " & internationalGreeting & return & ¬
  "Unicode text (Russian): " & unicodeGreeting & return & ¬
  "Unicode text (Chinese): " & unicodeGreeting2 & return & ¬
  "Unicode text (Korean): " & unicodeGreeting3 & return & ¬
  "Unicode emoji: " & unicodeEmoji & return & return & ¬
  "Character count in emoji string: " & characterCount & return & ¬
  "Individual emoji characters: " & characterList

return summaryText
```

Key differences and usage notes:

1. **International Text (legacy):**
   - Designed for limited non-ASCII character support
   - Compatible with older AppleScript versions
   - Limited to certain character sets
   - Generally superseded by Unicode text

2. **Unicode Text (modern):**
   - Full support for all Unicode characters and scripts
   - Handles emoji, complex scripts, and virtually any writing system
   - Compatible with modern macOS text handling
   - Preferred for all multilingual and international text needs

3. **When to use explicit typing:**
   - When interacting with older applications that may not handle Unicode properly
   - When script needs to run on older macOS versions
   - When dealing with specialized text processing
   - When explicit character encoding control is needed

In modern AppleScript development, most text operations automatically handle Unicode correctly, but being explicit with the `Unicode text` type can ensure compatibility and proper behavior with complex scripts and special characters.

Note that length calculations and character indexing work on character boundaries (grapheme clusters), not bytes, which is especially important for complex scripts and emoji.
END_TIP
