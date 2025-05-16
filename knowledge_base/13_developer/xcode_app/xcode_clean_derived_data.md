---
title: 'Xcode: Clean Derived Data and Module Cache'
category: 13_developer
id: xcode_clean_derived_data
description: Cleans Xcode's derived data and module cache to fix common build issues.
keywords:
  - Xcode
  - derived data
  - module cache
  - clean
  - troubleshooting
  - performance
  - developer
  - iOS
  - macOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional boolean 'keepDocumentation' to preserve documentation or clean that
  too (default is true - keep documentation)
notes: |
  - Forces Xcode to quit before cleaning caches
  - Removes derived data which contains build artifacts and project indexes
  - Cleans module cache to fix code completion issues
  - Optionally preserves documentation caches to avoid lengthy rebuilding
  - Uses shell script commands to clean caches directly
  - This script helps resolve many common Xcode issues
---

```applescript
--MCP_INPUT:keepDocumentation

on cleanXcodeDerivedData(keepDocumentation)
  -- Default to keeping documentation unless explicitly set to false
  if keepDocumentation is missing value or keepDocumentation is "" then
    set keepDocumentation to true
  else if keepDocumentation is "false" then
    set keepDocumentation to false
  end if
  
  -- Quit Xcode if it's running
  set isXcodeRunning to false
  try
    tell application "System Events"
      if exists (process "Xcode") then
        set isXcodeRunning to true
      end if
    end tell
    
    if isXcodeRunning then
      tell application "Xcode" to quit
      delay 2 -- Wait for Xcode to quit properly
    end if
  on error errMsg
    display dialog "Error checking if Xcode is running: " & errMsg
  end try
  
  -- Build the paths to clean
  set derivedDataPath to (path to home folder as text) & "Library:Developer:Xcode:DerivedData"
  set modulesCachePath to (path to home folder as text) & "Library:Developer:Xcode:DerivedData:ModuleCache"
  
  -- Clean Derived Data
  try
    do shell script "rm -rf " & quoted form of (POSIX path of derivedDataPath)
    set deletedDerivedData to true
  on error errMsg
    set deletedDerivedData to false
    display dialog "Error deleting Derived Data: " & errMsg
  end try
  
  -- Clean Module Cache
  try
    do shell script "rm -rf " & quoted form of (POSIX path of modulesCachePath)
    set deletedModuleCache to true
  on error errMsg
    set deletedModuleCache to false
    display dialog "Error deleting Module Cache: " & errMsg
  end try
  
  -- Clean the LLVM module cache as well
  try
    do shell script "rm -rf \"$(getconf DARWIN_USER_CACHE_DIR)/org.llvm.clang/ModuleCache\""
    set deletedLLVMCache to true
  on error errMsg
    set deletedLLVMCache to false
    display dialog "Error deleting LLVM Module Cache: " & errMsg
  end try
  
  -- Optionally clean documentation cache
  set deletedDocsCache to "skipped (per user request)"
  if not keepDocumentation then
    try
      set docCachePath to (path to home folder as text) & "Library:Developer:Xcode:DocumentationCache"
      do shell script "rm -rf " & quoted form of (POSIX path of docCachePath)
      set deletedDocsCache to true
    on error errMsg
      set deletedDocsCache to false
      display dialog "Error deleting Documentation Cache: " & errMsg
    end try
  end if
  
  -- Return results summary
  set resultText to "
Xcode Cleanup Results:
---------------------
Derived Data: " & deletedDerivedData & "
Module Cache: " & deletedModuleCache & "
LLVM Cache: " & deletedLLVMCache & "
Documentation Cache: " & deletedDocsCache & "

If Xcode was running, it has been closed and you'll need to relaunch it.
The next time you open a project, Xcode will rebuild its indexes."
  
  return resultText
end cleanXcodeDerivedData

return my cleanXcodeDerivedData("--MCP_INPUT:keepDocumentation")
```
