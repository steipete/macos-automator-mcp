---
title: System Notification Center
category: 04_system
id: system_notification_center
description: >-
  Creates and manages user notifications in macOS Notification Center using
  AppleScript and JXA
keywords:
  - notification
  - alert
  - Notification Center
  - user notification
  - JXA
  - display notification
language: applescript
notes: >-
  Shows both AppleScript and JavaScript for Automation methods for creating
  notifications. Sound names must be valid system sound names.
---

```applescript
-- Method 1: Basic AppleScript notification
-- Simple notification with title, subtitle, and sound
display notification "This is the notification message" with title "Notification Title" subtitle "Optional Subtitle" sound name "Basso"

-- Different sound options include: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink

-- Method 2: Notification with timeout and application name
-- Display for 10 seconds with custom app name
display notification "This notification will display for 10 seconds" with title "Timed Notification" subtitle "Custom Application" sound name "Glass"

-- Method 3: Fire notification after delay
delay 5 -- Wait 5 seconds
display notification "This notification appears after 5 seconds" with title "Delayed Notification"

-- Method 4: Send notification from a specific application
tell application "Calendar"
  display notification "You have an upcoming meeting" with title "Calendar Reminder"
end tell

-- Method 5: Schedule multiple notifications
on scheduleNotifications()
  -- First notification immediately
  display notification "First notification" with title "Sequence Started"
  
  -- Second notification after 5 seconds
  delay 5
  display notification "Second notification (after 5s)" with title "Sequence Continued"
  
  -- Third notification after another 5 seconds
  delay 5
  display notification "Final notification (after 10s)" with title "Sequence Completed" sound name "Glass"
end scheduleNotifications

-- Run the notification sequence
scheduleNotifications()
```

JavaScript for Automation (JXA) offers more control over notifications. Here's a JXA example for advanced notifications:

```javascript
// JXA offers more flexibility with notifications
function createAdvancedNotification() {
  // Basic notification
  app = Application.currentApplication();
  app.includeStandardAdditions = true;
  
  // Simple notification
  app.displayNotification("This is a JXA notification", {
    withTitle: "JXA Notification",
    subtitle: "More control with JXA",
    soundName: "Glass"
  });
  
  // More advanced options using specific bundleIdentifier
  let notification = {
    title: "Calendar Event",
    subtitle: "Meeting with Team",
    message: "Conference Room B at 2pm",
    soundName: "Basso",
    appIcon: "/Applications/Calendar.app/Contents/Resources/App.icns"
  };
  
  // You can use Objective-C bridge for even more control
  ObjC.import('Foundation');
  ObjC.import('AppKit');
  
  // Create a user notification
  let center = $.NSUserNotificationCenter.defaultUserNotificationCenter;
  let notification = $.NSUserNotification.alloc.init;
  
  notification.title = "Advanced Notification";
  notification.subtitle = "Using Objective-C Bridge";
  notification.informativeText = "This notification has more options";
  notification.soundName = "NSUserNotificationDefaultSoundName";
  
  // Add a custom action button (works in older macOS versions)
  notification.hasActionButton = true;
  notification.actionButtonTitle = "View";
  
  // Set delivery date for scheduled notification
  let deliveryDate = $.NSDate.dateWithTimeIntervalSinceNow(10); // 10 seconds from now
  notification.deliveryDate = deliveryDate;
  
  // Send the notification
  center.scheduleNotification(notification);
  
  return "Advanced notification scheduled";
}

// Execute the function
createAdvancedNotification();
```

To create a notification with a custom icon and action buttons (for older macOS versions):

```applescript
-- This method uses scripting additions to create more customized notifications
-- Note: Requires macOS versions that support the specific parameters

-- Notification with custom icon and bundleID (makes it look like it came from the app)
on notifyWithCustomIcon()
  set iconPath to "/Applications/Safari.app/Contents/Resources/AppIcon.icns"
  set bundleID to "com.apple.Safari"
  
  do shell script "osascript -e 'display notification \"Visit website now\" with title \"Safari Reminder\" subtitle \"Important Site Update\" sound name \"Basso\"'"
  
  -- Note: The following approach would work in earlier macOS versions with the terminal-notifier utility
  -- This is included as a reference but requires terminal-notifier to be installed
  -- do shell script "terminal-notifier -message 'Visit website now' -title 'Safari Reminder' -subtitle 'Important Site Update' -appIcon " & quoted form of iconPath & " -sound Basso -sender " & bundleID
  
  return "Custom icon notification sent"
end notifyWithCustomIcon

-- Listen for notification response (requires additional setup with NSUserNotificationCenter)
-- This is a conceptual example, as full implementation requires Objective-C bridging
on listenForNotificationResponse()
  -- This would typically be implemented using JXA with Objective-C bridge
  -- The actual implementation requires setting up a delegate for NSUserNotificationCenter
  
  return "Notification response listener would be set up here"
end listenForNotificationResponse

-- Run example
notifyWithCustomIcon()
```

These scripts demonstrate various ways to create notifications in macOS:

1. **Basic Notifications**: Simple AppleScript notifications with title, subtitle, and sound
2. **Application-Specific Notifications**: Making notifications appear to come from specific apps
3. **Scheduled Notifications**: Displaying notifications after a delay or sequence
4. **Advanced JXA Notifications**: Using JavaScript for Automation for more control
5. **Custom Actions**: Adding action buttons and custom icons (on supported macOS versions)

For the best notification experience, consider the target macOS version and whether notifications need user interaction capabilities.
