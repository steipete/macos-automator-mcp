---
title: 'StandardAdditions: File Read/Write Operations'
category: 02_as_core/scripting_additions_osax
id: osax_file_read_write
description: >-
  Covers basic file input/output operations using StandardAdditions: open for
  access, read, write, close access, get eof, and set eof.
keywords:
  - StandardAdditions
  - file access
  - read file
  - write file
  - file io
  - eof
  - open for access
  - close access
  - osax
language: applescript
notes: >
  - These commands are for low-level file access. For simple text file
  reading/writing, `read file` and `write ... to file` are often easier.

  - `open for access` requires a file path (string or alias) and optionally
  `write permission`.

  - `read` command needs a file reference number (from `open for access`).

  - `write ... to fileRef ... starting at X` allows writing at specific
  positions.

  - `set eof fileRef to 0` truncates a file.

  - Always `close access` the file reference when done.
---

Provides control over reading and writing data to files.

```applescript
set desktopPath to path to desktop
set testFilePath to (desktopPath as text) & "AppleScriptFileTest.txt"
set fileRef to 0 -- Initialize file reference
set readContent to ""
set writeStatus to ""
set eofStatus to ""

try
  -- 1. WRITE TO A FILE (Create or overwrite)
  set dataToWrite to "Hello from AppleScript!\nLine 2.\nEnd of initial write."
  try
    set fileRef to open for access file testFilePath with write permission
    set eof fileRef to 0 -- Truncate if it exists
    write dataToWrite to fileRef
    set writeStatus to "Write successful. "
  on error writeErr
    set writeStatus to "Write error: " & writeErr & ". "
  finally
    if fileRef is not 0 then
      try
        close access fileRef
        set fileRef to 0 -- Reset for next operation
      on error closeErr
        set writeStatus to writeStatus & "Close error after write: " & closeErr & ". "
      end try
    end if
  end try
  
  -- 2. READ FROM THE FILE
  try
    set fileRef to open for access file testFilePath -- Read by default
    set eofValueBeforeRead to get eof fileRef
    set readContent to read fileRef -- Reads entire file
    set eofStatus to "EOF before read: " & eofValueBeforeRead & ". "
  on error readErr
    set readContent to "Read error: " & readErr
    set eofStatus to eofStatus & "Read error occurred. "
  finally
    if fileRef is not 0 then
      try
        close access fileRef
        set fileRef to 0
      on error closeErr
        set eofStatus to eofStatus & "Close error after read: " & closeErr & ". "
      end try
    end if
  end try
  
  -- 3. APPEND TO THE FILE (Write starting at EOF)
  set appendData to "\nThis is appended data."
  try
    set fileRef to open for access file testFilePath with write permission
    set currentEOF to get eof fileRef
    write appendData to fileRef starting at eof -- or `starting at (currentEOF + 1)`
    set writeStatus to writeStatus & "Append successful."
  on error appendErr
    set writeStatus to writeStatus & "Append error: " & appendErr & ". "
  finally
    if fileRef is not 0 then
      try
        close access fileRef
        set fileRef to 0
      on error closeErr
        set writeStatus to writeStatus & "Close error after append: " & closeErr & ". "
      end try
    end if
  end try
  
  -- 4. READ AGAIN TO VERIFY APPEND
  set appendedContent to ""
  try
    set fileRef to open for access file testFilePath
    set appendedContent to read fileRef
  on error readAgainErr
    set appendedContent to "Read again error: " & readAgainErr
  finally
    if fileRef is not 0 then
      try
        close access fileRef
        set fileRef to 0
      on error closeErr
        -- ignore for final return
      end try
    end if
  end try
  
catch generalError
  return "A general error occurred: " & generalError
end try

return "Write Status: " & writeStatus & "\nEOF Status: " & eofStatus & "\nInitial Read Content: '" & readContent & "'\nAppended Read Content: '" & appendedContent & "'"

-- To clean up the test file:
-- tell application "Finder" to delete file testFilePath
```
END_TIP 
