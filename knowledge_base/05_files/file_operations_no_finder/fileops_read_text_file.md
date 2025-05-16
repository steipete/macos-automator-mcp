---
title: 'File Ops (No Finder): Read Text File Content'
category: 05_files/file_operations_no_finder
id: fileops_read_text_file
description: >-
  Reads the entire content of a specified text file using StandardAdditions.
  Returns content as a string.
keywords:
  - read file
  - file content
  - text
  - StandardAdditions
  - UTF-8
language: applescript
isComplex: true
argumentsPrompt: Absolute POSIX path of the file to read as 'filePath' in inputData.
---

```applescript
--MCP_INPUT:filePath

on readFileContent(posixPath)
  if posixPath is missing value or posixPath is "" then
    return "error: File path not provided."
  end if

  try
    set fileAlias to POSIX file posixPath as alias
    set fileContent to read fileAlias as «class utf8» -- Or 'as text' for default system encoding
    return fileContent
  on error errMsg number errNum
    return "error: (" & errNum & ") Failed to read file '" & posixPath & "': " & errMsg
  end try
end readFileContent

return my readFileContent("--MCP_INPUT:filePath")
```
END_TIP 
