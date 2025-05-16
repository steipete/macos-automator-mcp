---
title: 'Xcode: Get Project Info (JXA)'
category: 13_developer/xcode_app
id: xcode_get_project_info_jxa
description: >-
  Retrieves information about an open Xcode project using JavaScript for
  Automation (JXA).
keywords:
  - Xcode
  - project
  - info
  - JavaScript
  - JXA
  - scheme
  - developer
  - iOS
  - macOS
language: javascript
isComplex: true
notes: |
  - Uses JavaScript for Automation (JXA) instead of AppleScript
  - Requires Xcode to be already open with a project loaded
  - Retrieves information like project name, active scheme, build configuration
  - Returns data in JSON format for easy parsing
---

```javascript
// Function to get information about the current Xcode project
function getXcodeProjectInfo() {
  try {
    // Create application objects
    const Xcode = Application('Xcode');
    Xcode.includeStandardAdditions = true;
    
    // Ensure Xcode is running
    if (!Xcode.running()) {
      return JSON.stringify({
        error: "Xcode is not running"
      });
    }
    
    // Activate Xcode
    Xcode.activate();
    
    // Get information about the workspace
    const workspaceDocument = Xcode.workspaceDocument();
    if (!workspaceDocument) {
      return JSON.stringify({
        error: "No workspace document is open"
      });
    }
    
    // Basic project info
    const projectInfo = {
      name: workspaceDocument.name(),
      filePath: workspaceDocument.file() ? workspaceDocument.file().posixPath() : "Unknown",
    };
    
    // For advanced info, we need System Events for UI interaction
    const systemEvents = Application('System Events');
    const xcodeProcess = systemEvents.processes.whose({name: 'Xcode'})[0];
    
    if (xcodeProcess) {
      try {
        // Get active scheme information
        const schemeButton = xcodeProcess.windows[0].buttons.whose({description: {_contains: 'Scheme'}})[0];
        if (schemeButton) {
          projectInfo.activeScheme = schemeButton.name();
        }
        
        // Get active configuration (Debug/Release)
        const configButton = xcodeProcess.windows[0].buttons.whose({description: {_contains: 'Configuration'}})[0];
        if (configButton) {
          projectInfo.buildConfiguration = configButton.name();
        }
        
        // Get destination (simulator/device)
        const destinationButton = xcodeProcess.windows[0].buttons.whose({description: {_contains: 'Destination'}})[0];
        if (destinationButton) {
          projectInfo.destination = destinationButton.name();
        }
      } catch (uiError) {
        projectInfo.uiInfoError = "Could not retrieve UI information: " + uiError;
      }
    }
    
    // Use osascript CLI to get bundle identifier since it can be tricky with JXA
    try {
      const Script = Application('Script Editor');
      const bundleIdScript = `
        tell application "Xcode"
          set infoPlist to info plist of active workspace document
          if infoPlist is not missing value then
            return bundle identifier of infoPlist
          else
            return "Unknown"
          end if
        end tell
      `;
      
      const result = Script.doScript(bundleIdScript, {in: "AppleScript"});
      if (result && result !== "Unknown") {
        projectInfo.bundleIdentifier = result;
      }
    } catch (bundleIdError) {
      projectInfo.bundleIdError = "Could not retrieve bundle ID: " + bundleIdError;
    }
    
    return JSON.stringify(projectInfo, null, 2);
  } catch (error) {
    return JSON.stringify({
      error: "Error getting Xcode project info: " + error
    });
  }
}

getXcodeProjectInfo();
```
