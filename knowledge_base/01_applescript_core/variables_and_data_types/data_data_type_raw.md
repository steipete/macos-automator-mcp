---
title: "AppleScript Raw Data Type"
category: "01_applescript_core"
id: core_datatype_data_raw
description: "Understanding and working with the 'data' data type in AppleScript for handling binary data and type information."
keywords: ["data", "raw data", "binary data", "type codes", "hexadecimal", "data conversion", "«data»"]
language: applescript
notes: |
  - The 'data' type is AppleScript's way of representing binary data with an associated type code
  - It appears in the format «data TYPExxxx» where TYPE is a four-character type code and xxxx is hexadecimal data
  - Often encountered when dealing with advanced scripting, low-level operations, and certain application APIs
  - Powerful for interacting with system-level functionality, but requires careful handling
---

The `data` data type is AppleScript's mechanism for handling raw binary data, typically represented with a four-character type code. This is crucial for working with certain low-level operations, system APIs, and application-specific data formats.

```applescript
-- Create a data object using the «data» notation
set pdfSignature to «data PDF2ABCD»
set textData to «data TEXT68656C6C6F20776F726C64» -- "hello world" as TEXT data

-- Data can also be created from text using the data specifier
set hexString to "48656C6C6F" -- "Hello" in hex
set dataFromHex to data hexString

-- Working with AppleScript's automatic type conversion
set currentDate to current date
set dateAsData to currentDate as data
set classOfData to class of dateAsData -- Will be "data"

-- Creating a JPG image file header (for demonstration)
set jpgData to «data JPEG» & "FFD8FFE000104A464946000101"

-- Examining data objects
set typeCode to first word of (dateAsData as string)
set hexContents to second word of (dateAsData as string)

-- Converting Unicode text to data and back
set unicodeText to "こんにちは" as Unicode text  -- Japanese "Hello"
set unicodeAsData to unicodeText as data
set backToText to unicodeAsData as Unicode text

-- Example of data appearing in results (Script Editor would show this)
set resultSummary to "Data representations:" & return & return & ¬
  "PDF signature: " & pdfSignature & return & ¬
  "Text as data: " & textData & return & ¬
  "Data from hex: " & dataFromHex & return & ¬
  "Date as data: " & dateAsData & return & ¬
  "JPG header: " & jpgData & return & ¬
  "Type code: " & typeCode & return & ¬
  "Hex content: " & hexContents & return & ¬
  "Unicode as data: " & unicodeAsData & return & ¬
  "Converted back: " & backToText

return resultSummary
```

Understanding data types in AppleScript:

1. **Syntax and Format:**
   - Data appears in the format `«data TYPE####»` 
   - `TYPE` is a four-character type code (like TEXT, PICT, PDF)
   - `####` is the hex representation of the binary data
   - The guillemet symbols « » (Option+\\ and Option+Shift+\\) enclose data literals

2. **Common Type Codes:**
   - `TEXT`: Plain text data
   - `utxt`: Unicode text data
   - `PICT`: Picture data
   - `PDF`: PDF format data
   - `icns`: Icon data
   - `bina`: Generic binary data

3. **Working With Data:**
   - Data can be manipulated with string operations in limited ways
   - Can be coerced to/from other types like text and Unicode text
   - Essential for interfacing with certain application APIs

4. **Unicode Text Connection:**
   - Unicode text sometimes appears as `«data utxt####»` in results
   - Converting between Unicode text and data is useful for processing multi-byte characters

5. **Use Cases:**
   - Working with binary files
   - Interfacing with low-level system functions
   - Handling image data
   - Working with legacy applications that use Apple events with custom data formats

The data type is particularly important when scripting applications that return or expect binary data, or when you need to precisely control data representation for specialized purposes.
END_TIP