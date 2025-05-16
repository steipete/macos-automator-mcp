---
title: "JXA: Objective-C Bridge"
category: "10_jxa_basics"
id: jxa_objc_bridge
description: "Demonstrates how to use the Objective-C bridge in JXA to access macOS frameworks and native functionality."
keywords: ["jxa", "javascript", "objective-c", "objc bridge", "foundation", "appkit", "cocoa"]
language: javascript
notes: "The ObjC bridge provides access to powerful macOS APIs but may require deeper understanding of the Cocoa frameworks."
---

```javascript
// JXA Objective-C Bridge Examples

// EXAMPLE 1: Basic ObjC Bridge Usage
function basicObjCBridge() {
  // Import Foundation framework
  ObjC.import('Foundation');
  
  // Access NSUserDefaults
  const defaults = $.NSUserDefaults.standardUserDefaults;
  
  // Read some system preferences
  const computerName = defaults.objectForKey('ComputerName');
  const locale = $.NSLocale.currentLocale.localeIdentifier;
  const timeZone = $.NSTimeZone.localTimeZone.name;
  
  // Create and manipulate an NSDate object
  const now = $.NSDate.date;
  const dateFormatter = $.NSDateFormatter.alloc.init;
  dateFormatter.dateStyle = $.NSDateFormatterFullStyle;
  dateFormatter.timeStyle = $.NSDateFormatterMediumStyle;
  const formattedDate = dateFormatter.stringFromDate(now);
  
  // Create alert with information
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  app.displayDialog(
    "System Information via ObjC Bridge:\n\n" +
    "Computer Name: " + computerName.js + "\n" +
    "Locale: " + locale.js + "\n" +
    "Time Zone: " + timeZone.js + "\n" +
    "Current Date: " + formattedDate.js
  );
}

// EXAMPLE 2: Working with Filesystem via NSFileManager
function fileManagerOperations() {
  // Import Foundation
  ObjC.import('Foundation');
  
  // Get NSFileManager
  const fileManager = $.NSFileManager.defaultManager;
  
  // Get home directory
  const homeDirectory = fileManager.homeDirectoryForCurrentUser.path.js;
  
  // Get Documents directory
  const documentsURL = fileManager.URLsForDirectory($.NSDocumentDirectory, $.NSUserDomainMask).firstObject;
  const documentsPath = documentsURL.path.js;
  
  // Get attributes of a file
  const fileAttributes = fileManager.attributesOfItemAtPathError(homeDirectory + "/.zshrc", null);
  
  // Format file size
  let fileSize = "File not found";
  if (fileAttributes) {
    const fileSizeNumber = fileAttributes.objectForKey($.NSFileSize);
    const byteCountFormatter = $.NSByteCountFormatter.alloc.init;
    fileSize = byteCountFormatter.stringFromByteCount(fileSizeNumber);
  }
  
  // Get temporary directory
  const tempDir = $.NSTemporaryDirectory().js;
  
  // List files in a directory
  const desktopPath = homeDirectory + "/Desktop";
  const desktopContents = fileManager.contentsOfDirectoryAtPathError(desktopPath, null);
  
  let fileList = "Files on Desktop:\n";
  if (desktopContents) {
    for (let i = 0; i < desktopContents.count; i++) {
      const fileName = desktopContents.objectAtIndex(i).js;
      fileList += fileName + "\n";
      if (i >= 9) { // Only show first 10 files
        fileList += "... and more";
        break;
      }
    }
  }
  
  // Display results
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  app.displayDialog(
    "File System Information via NSFileManager:\n\n" +
    "Home Directory: " + homeDirectory + "\n" +
    "Documents Directory: " + documentsPath + "\n" +
    "Temp Directory: " + tempDir + "\n" +
    ".zshrc Size: " + fileSize.js + "\n\n" +
    fileList
  );
}

// EXAMPLE 3: System Information with ObjC
function systemInformation() {
  // Import necessary frameworks
  ObjC.import('Foundation');
  ObjC.import('AppKit');
  
  // Get system information
  const processInfo = $.NSProcessInfo.processInfo;
  
  // OS Version information
  const osVersion = processInfo.operatingSystemVersion;
  const majorVersion = osVersion.majorVersion;
  const minorVersion = osVersion.minorVersion;
  const patchVersion = osVersion.patchVersion;
  
  // System uptime
  const uptime = processInfo.systemUptime;
  const uptimeHours = Math.floor(uptime / 3600);
  const uptimeMinutes = Math.floor((uptime % 3600) / 60);
  
  // Process information
  const processID = processInfo.processIdentifier;
  const processName = processInfo.processName.js;
  
  // Screen information
  const mainScreen = $.NSScreen.mainScreen;
  const screenFrame = mainScreen.frame;
  const screenWidth = screenFrame.size.width;
  const screenHeight = screenFrame.size.height;
  
  // Current user information
  const fullUserName = $.NSFullUserName().js;
  const userName = $.NSUserName().js;
  
  // Device information
  const host = $.NSHost.currentHost;
  const hostNames = host.names.js;
  
  // Display all information
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  app.displayDialog(
    "System Information via ObjC Bridge:\n\n" +
    "macOS Version: " + majorVersion + "." + minorVersion + "." + patchVersion + "\n" +
    "System Uptime: " + uptimeHours + "h " + uptimeMinutes + "m\n" +
    "Process ID: " + processID + "\n" +
    "Process Name: " + processName + "\n" +
    "Screen Resolution: " + screenWidth + " × " + screenHeight + "\n" +
    "User Name: " + userName + "\n" +
    "Full User Name: " + fullUserName + "\n" +
    "Host Names: " + hostNames.join(", ")
  );
}

// EXAMPLE 4: Working with NSNotificationCenter
function notificationCenter() {
  // Import necessary frameworks
  ObjC.import('Foundation');
  ObjC.import('stdlib');
  
  // Setup notification callback
  const app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  // Setup a notification block that will be called when a notification is received
  const workspaceNC = $.NSWorkspace.sharedWorkspace.notificationCenter;
  
  // Create a JavaScript function to handle notifications
  function handleNotification(notification) {
    const noteName = notification.name.js;
    const userInfo = notification.userInfo;
    
    let infoText = "Received: " + noteName + "\n";
    
    if (userInfo) {
      if (noteName.includes("DidLaunchApplication") || 
          noteName.includes("DidTerminateApplication")) {
        const appInfo = userInfo.objectForKey("NSWorkspaceApplicationKey");
        if (appInfo) {
          infoText += "Application: " + appInfo.localizedName.js + "\n";
          infoText += "Bundle ID: " + appInfo.bundleIdentifier.js + "\n";
        }
      }
    }
    
    app.displayNotification(infoText, {
      withTitle: "App Activity Monitor",
      subtitle: noteName
    });
  }
  
  // Create block handler from the function
  const block = $(handleNotification);
  
  // Setup observers for application launch/terminate events
  const launchObserver = workspaceNC.addObserverForNameObjectQueueUsingBlock(
    $.NSWorkspaceDidLaunchApplicationNotification,
    null,
    null,
    block
  );
  
  const terminateObserver = workspaceNC.addObserverForNameObjectQueueUsingBlock(
    $.NSWorkspaceDidTerminateApplicationNotification,
    null,
    null,
    block
  );
  
  app.displayDialog(
    "Now monitoring application launches and terminations.\n" +
    "This script will display notifications when apps are launched or terminated.\n\n" +
    "Note: In a real script, you would need to keep the script running with a run loop."
  );
  
  // In a real application, you would start a run loop here to keep the script active
  // For demo purposes, we'll just wait a short time
  delay(30); // Wait 30 seconds
  
  // Clean up by removing observers
  workspaceNC.removeObserver(launchObserver);
  workspaceNC.removeObserver(terminateObserver);
  
  return "Notification monitoring complete.";
}

// Uncomment one of these to run the examples
// basicObjCBridge();
// fileManagerOperations();
// systemInformation();
// notificationCenter();

"Objective-C bridge examples completed.";
```