---
title: "File Ops (No Finder): Write Text to File (Overwrite)"
category: "03_file_system_and_finder" # Subdir: file_operations_no_finder
id: fileops_write_text_file
description: "Writes provided text content to a specified file, overwriting the file if it exists, or creating it if it doesn't. Uses StandardAdditions."
keywords: ["write file", "save file", "create file", "overwrite", "StandardAdditions"]
language: applescript
isComplex: true
argumentsPrompt: "Absolute POSIX path for the file as 'filePath', and text content as 'fileContent' in inputData."
---

```applescript
--MCP_INPUT:filePath
--MCP_INPUT:fileContent

on writeToFile(posixPath, textContent)
  if posixPath is missing value or posixPath is "" then
    return "error: File path not provided."
  end if
  if textContent is missing value then
    set textContent to "" -- Write empty content if none provided
  end if

  try
    set fileRef to open for access (POSIX file posixPath) with write permission
    set eof of fileRef to 0 -- Clear file content before writing (to overwrite)
    write textContent to fileRef as «class utf8»
    close access fileRef
    return "Content successfully written to: " & posixPath
  on error errMsg number errNum
    -- Ensure file is closed if open attempt succeeded but write failed.
    try
      close access (POSIX file posixPath)
    end try
    return "error: (" & errNum & ") Failed to write to file '" & posixPath & "': " & errMsg
  end try
end writeToFile

return my writeToFile("--MCP_INPUT:filePath", "--MCP_INPUT:fileContent")
```
END_TIP 