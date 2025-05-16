---
title: Legacy File Types and Creator Codes in macOS
description: >-
  Understanding and working with legacy file types and creator codes in modern
  macOS using AppleScript
author: Claude
category: 05_files
subcategory: metadata_and_attributes_finder
keywords:
  - file type
  - creator code
  - legacy
  - metadata
  - finder
  - uti
  - resource fork
language: applescript
version: '1.0'
validated: true
---

# Legacy File Types and Creator Codes in macOS

## Overview of File Types and Creator Codes

In classic Mac OS through early macOS versions, files were identified by two four-character codes:

1. **File Type**: Identified the format of the file (e.g., 'TEXT' for text files, 'PICT' for picture files)
2. **Creator Code**: Identified the application that created the file (e.g., 'ttxt' for TextEdit, 'MACS' for MacWrite)

While modern macOS primarily uses file extensions and Uniform Type Identifiers (UTIs), legacy file type and creator codes still exist in the system and can be accessed via AppleScript, particularly when working with older files or applications.

## Viewing File Type and Creator Code

```applescript
-- View file type and creator code for a selected file in Finder
tell application "Finder"
  if selection is {} then
    display dialog "Please select a file first" buttons {"OK"} default button "OK" with icon stop
    return
  end if
  
  set theFile to item 1 of selection
  
  try
    set fileTypeCode to file type of theFile
  on error
    set fileTypeCode to "none"
  end try
  
  try
    set creatorCode to creator type of theFile
  on error
    set creatorCode to "none"
  end try
  
  set fileInfo to "File: " & name of theFile & return
  set fileInfo to fileInfo & "File Type: " & fileTypeCode & return
  set fileInfo to fileInfo & "Creator Code: " & creatorCode
  
  display dialog fileInfo buttons {"OK"} default button "OK" with title "File Type & Creator Info"
end tell
```

## Setting File Type and Creator Code

```applescript
-- Set file type and creator code for a selected file
on setFileTypeAndCreator(theFile, newFileType, newCreator)
  tell application "Finder"
    try
      set file type of theFile to newFileType
      set creator type of theFile to newCreator
      return "File type set to '" & newFileType & "' and creator set to '" & newCreator & "'"
    on error errMsg
      return "Error setting file type and creator: " & errMsg
    end try
  end tell
end setFileTypeAndCreator

-- Example usage
tell application "Finder"
  if selection is {} then
    display dialog "Please select a file first" buttons {"OK"} default button "OK" with icon stop
    return
  end if
  
  set theFile to item 1 of selection
  set result to setFileTypeAndCreator(theFile, "TEXT", "ttxt")
  display dialog result buttons {"OK"} default button "OK"
end tell
```

## Finding Files by Type or Creator

```applescript
-- Find files with a specific file type or creator code
on findFilesByTypeOrCreator(searchType, searchCreator)
  set fileList to {}
  
  tell application "Finder"
    if searchType is not "" and searchCreator is not "" then
      -- Search by both type and creator
      set fileList to files of entire contents of home folder whose file type is searchType and creator type is searchCreator
    else if searchType is not "" then
      -- Search by type only
      set fileList to files of entire contents of home folder whose file type is searchType
    else if searchCreator is not "" then
      -- Search by creator only
      set fileList to files of entire contents of home folder whose creator type is searchCreator
    end if
  end tell
  
  return fileList
end findFilesByTypeOrCreator

-- Example: Find all text files created by TextEdit
set textFiles to findFilesByTypeOrCreator("TEXT", "ttxt")

-- Display results
if (count of textFiles) is 0 then
  display dialog "No files found matching the criteria" buttons {"OK"} default button "OK"
else
  set fileNames to ""
  repeat with aFile in textFiles
    tell application "Finder"
      set fileNames to fileNames & name of aFile & return
    end tell
  end repeat
  
  display dialog "Found " & (count of textFiles) & " files:" & return & return & fileNames buttons {"OK"} default button "OK"
end if
```

## Using Shell Tools to View Type and Creator Codes

```applescript
-- Use mdls (metadata listing) tool to get file type and creator via shell
on getFileMetadataWithMdls(filePath)
  set posixPath to quoted form of POSIX path of filePath
  set metadataCmd to "mdls " & posixPath & " | grep -E 'kMDItemFSContentType|kMDItemFSCreatorCode|kMDItemFSTypeCode'"
  
  try
    set metadata to do shell script metadataCmd
    return metadata
  on error errMsg
    return "Error getting metadata: " & errMsg
  end try
end getFileMetadataWithMdls

-- Get file type and creator via file utility
on getTypeCreatorWithFile(filePath)
  set posixPath to quoted form of POSIX path of filePath
  set fileCmd to "file -l " & posixPath
  
  try
    set fileOutput to do shell script fileCmd
    return fileOutput
  on error errMsg
    return "Error getting file info: " & errMsg
  end try
end getTypeCreatorWithFile

-- Example usage
tell application "Finder"
  if selection is {} then
    display dialog "Please select a file first" buttons {"OK"} default button "OK" with icon stop
    return
  end if
  
  set theFile to item 1 of selection as alias
  
  set mdlsInfo to getFileMetadataWithMdls(theFile)
  set fileInfo to getTypeCreatorWithFile(theFile)
  
  display dialog "File Metadata:" & return & return & mdlsInfo & return & return & "File Utility Output:" & return & fileInfo buttons {"OK"} default button "OK" with title "Extended File Type Info"
end tell
```

## Getting UTI from File Type and Creator

```applescript
-- Convert legacy file type and creator to UTI using Launch Services
on getUTIFromTypeAndCreator(fileType, creatorCode)
  -- Create a temporary file with the given type and creator
  set tempFilePath to "/tmp/temp_type_creator_test"
  
  try
    -- Create an empty file
    do shell script "touch " & quoted form of tempFilePath
    
    -- Set type and creator
    tell application "Finder"
      set theFile to POSIX file tempFilePath as alias
      set file type of theFile to fileType
      set creator type of theFile to creatorCode
    end tell
    
    -- Get UTI using mdls
    set utiCmd to "mdls -name kMDItemContentType " & quoted form of tempFilePath
    set utiOutput to do shell script utiCmd
    
    -- Clean up
    do shell script "rm " & quoted form of tempFilePath
    
    -- Extract UTI from output
    set AppleScript's text item delimiters to "\""
    set utiParts to text items of utiOutput
    if (count of utiParts) ≥ 2 then
      set uti to text item 2 of utiParts
      return "UTI for " & fileType & "/" & creatorCode & ": " & uti
    else
      return "Unable to determine UTI"
    end if
    
  on error errMsg
    do shell script "rm " & quoted form of tempFilePath
    return "Error determining UTI: " & errMsg
  end try
end getUTIFromTypeAndCreator

-- Example usage
set utiInfo to getUTIFromTypeAndCreator("TEXT", "ttxt")
display dialog utiInfo buttons {"OK"} default button "OK"
```

## Common Legacy Type and Creator Codes

```applescript
-- This script shows a list of common legacy type and creator codes
-- This is primarily for historical reference

set typeCreatorInfo to "Common File Types:
TEXT - Plain text
PICT - Picture file
GIFf - GIF image
JPEG - JPEG image
PDF  - PDF document
RTF  - Rich Text Format
EPSF - Encapsulated PostScript
MP3  - MP3 audio
AIFF - AIFF audio
MOOV - QuickTime movie

Common Creator Codes:
ttxt - TextEdit
MSWD - Microsoft Word
XCEL - Microsoft Excel
PPNT - Microsoft PowerPoint
8BIM - Adobe Photoshop
MACS - MacWrite
CARO - Adobe Acrobat
SIT! - StuffIt
R*ch - BBEdit
TVOD - QuickTime Player"

display dialog typeCreatorInfo buttons {"OK"} default button "OK" with title "Common Legacy Type & Creator Codes"
```

## Getting Type and Creator Codes from UTI

```applescript
-- This script demonstrates getting legacy type and creator from a UTI
-- Note: Not all UTIs have corresponding type/creator codes

on getTypeCreatorFromUTI(uti)
  set utQueryCmd to "mdimport -A | grep -B 1 -A 3 " & quoted form of uti & " | grep -E 'extension|typeCode|creatorCode'"
  
  try
    set result to do shell script utQueryCmd
    return "UTI: " & uti & return & result
  on error
    return "No type/creator information found for UTI: " & uti
  end try
end getTypeCreatorFromUTI

-- Example usage
set result to getTypeCreatorFromUTI("public.plain-text")
display dialog result buttons {"OK"} default button "OK" with title "UTI to Type/Creator"
```

## Setting Legacy Type/Creator Versus Modern File Extension

```applescript
-- This script demonstrates the interactions between file extensions and type/creator codes
-- and shows how to use both approaches

on demonstrateExtensionVsTypeCreator(filePath, newExtension, fileType, creatorCode)
  tell application "Finder"
    set theFile to POSIX file filePath as alias
    
    -- First get current info
    set originalName to name of theFile
    set originalExtension to name extension of theFile
    
    try
      set originalFileType to file type of theFile
    on error
      set originalFileType to "none"
    end try
    
    try
      set originalCreator to creator type of theFile
    on error
      set originalCreator to "none"
    end try
    
    -- Apply changes
    if newExtension is not "" then
      set name extension of theFile to newExtension
    end if
    
    if fileType is not "" then
      set file type of theFile to fileType
    end if
    
    if creatorCode is not "" then
      set creator type of theFile to creatorCode
    end if
    
    -- Return summary of changes
    set changes to "Original:" & return
    set changes to changes & "  Name: " & originalName & return
    set changes to changes & "  Extension: " & originalExtension & return
    set changes to changes & "  File Type: " & originalFileType & return
    set changes to changes & "  Creator: " & originalCreator & return & return
    
    set changes to changes & "New:" & return
    set changes to changes & "  Name: " & name of theFile & return
    set changes to changes & "  Extension: " & name extension of theFile & return
    
    try
      set changes to changes & "  File Type: " & file type of theFile & return
    on error
      set changes to changes & "  File Type: none" & return
    end try
    
    try
      set changes to changes & "  Creator: " & creator type of theFile
    on error
      set changes to changes & "  Creator: none"
    end try
    
    return changes
  end tell
end demonstrateExtensionVsTypeCreator

-- Example usage (make sure to use a file path that exists)
set result to demonstrateExtensionVsTypeCreator("/path/to/file.txt", "rtf", "TEXT", "ttxt")
display dialog result buttons {"OK"} default button "OK" with title "Extension vs. Type/Creator"
```

## Notes and Limitations

1. **Legacy System**: File types and creator codes are legacy features from the Classic Mac OS era, which have been superseded by file extensions and UTIs in modern macOS.

2. **Limited Support**: While macOS maintains backward compatibility for these codes, fewer applications actively use or set them, and some macOS features may not properly recognize them.

3. **Resource Forks**: Type and creator codes were traditionally stored in the resource fork of files, which are also legacy features that modern file systems like APFS handle differently.

4. **Modern Alternative**: The modern equivalent is the Uniform Type Identifier (UTI) system, which provides a more hierarchical and extensible type system.

5. **Interaction with File Extensions**: In modern macOS, file extensions generally take precedence over type and creator codes for determining file associations.

6. **Historical Significance**: Understanding these codes can be valuable when working with older macOS applications or files, or when writing scripts to support legacy workflows.
