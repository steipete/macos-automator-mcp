---
title: "Xcode: Open Project or Workspace"
category: "09_developer_and_utility_apps"
id: xcode_open_project
description: "Opens an Xcode project or workspace file."
keywords: ["Xcode", "open", "project", "workspace", "developer", "iOS", "macOS"]
language: applescript
isComplex: false
argumentsPrompt: "Absolute POSIX path to .xcodeproj or .xcworkspace in 'projectPath'"
notes: |
  - Works with both .xcodeproj and .xcworkspace files
  - Handles already opened projects gracefully
  - Activates Xcode window after opening
---

```applescript
--MCP_INPUT:projectPath

on openXcodeProject(projectPath)
  if projectPath is missing value or projectPath is "" then
    return "error: Project path not provided."
  end if
  
  if not (projectPath ends with ".xcodeproj" or projectPath ends with ".xcworkspace") then
    return "error: Path must be an Xcode project (.xcodeproj) or workspace (.xcworkspace) file."
  end if
  
  try
    tell application "Xcode"
      open projectPath
      activate
      
      -- Wait for project to open
      delay 1
      
      return "Successfully opened project: " & projectPath
    end tell
  on error errMsg number errNum
    return "error (" & errNum & ") opening Xcode project: " & errMsg
  end try
end openXcodeProject

return my openXcodeProject("--MCP_INPUT:projectPath")
```