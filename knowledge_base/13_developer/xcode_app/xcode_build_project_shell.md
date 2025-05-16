---
title: 'Xcode: Build Project via xcodebuild Shell Command'
category: 13_developer/xcode_app
id: xcode_build_project_shell
description: Builds an Xcode project or workspace using the 'xcodebuild' command-line tool.
keywords:
  - Xcode
  - build
  - compile
  - xcodebuild
  - shell
  - developer
language: applescript
isComplex: true
argumentsPrompt: >-
  Absolute POSIX path to .xcodeproj or .xcworkspace as 'projectPath', and scheme
  name as 'schemeName' in inputData. Optionally, configuration (e.g., 'Debug',
  'Release') as 'configName'.
notes: >
  - This method is generally more reliable than UI scripting Xcode for builds.

  - The output of `xcodebuild` is returned, which can be extensive.

  - Ensure `xcodebuild` command-line tools are installed and configured
  (`xcode-select -p`).
---

```applescript
--MCP_INPUT:projectPath
--MCP_INPUT:schemeName
--MCP_INPUT:configName

on buildXcodeProject(theProjectPath, theSchemeName, theConfigName)
  if theProjectPath is missing value or theProjectPath is "" then return "error: Project path not provided."
  if theSchemeName is missing value or theSchemeName is "" then return "error: Scheme name not provided."

  set projectOrWorkspaceFlag to "-project"
  if theProjectPath ends with ".xcworkspace" then
    set projectOrWorkspaceFlag to "-workspace"
  end if
  
  set command to "xcodebuild " & projectOrWorkspaceFlag & " " & quoted form of theProjectPath & ¬
    " -scheme " & quoted form of theSchemeName
    
  if theConfigName is not missing value and theConfigName is not "" then
    set command to command & " -configuration " & quoted form of theConfigName
  end if
  
  set command to command & " build" -- Or "clean build", "archive", etc.
  
  try
    -- Change to project directory first if build requires relative paths
    -- Extract directory path from the project path directly
    set projectDir to do shell script "dirname " & quoted form of theProjectPath
    return do shell script "cd " & quoted form of projectDir & " && " & command
  on error errMsg number errNum
    return "error (" & errNum & ") building Xcode project: " & errMsg
  end try
end buildXcodeProject

return my buildXcodeProject("--MCP_INPUT:projectPath", "--MCP_INPUT:schemeName", "--MCP_INPUT:configName")
```
END_TIP 
