---
id: jxa_display_notification
title: Display Notifications with JXA
description: Show macOS Notification Center messages using JavaScript for Automation
language: javascript
keywords:
  - notification
  - alert
  - user interface
  - system integration
  - feedback
category: 03_jxa_core
---

# Display Notifications with JXA

JavaScript for Automation (JXA) provides a straightforward way to display notifications via macOS Notification Center.

## Basic Notification

To display a simple notification:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Display a basic notification
app.displayNotification('This is a notification message');
```

## Advanced Notification with Title, Subtitle, and Sound

For more control over your notifications:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Display a notification with additional parameters
app.displayNotification('Task completed successfully!', {
    withTitle: 'Automation Script',
    subtitle: 'The process is complete',
    soundName: 'Ping' // Other options: 'Basso', 'Blow', 'Bottle', 'Frog', 'Funk', 'Glass', 'Hero', 'Morse', 'Pop', 'Purr', 'Sosumi', 'Submarine', 'Tink'
});
```

## Notification with Automatic Timeout

This example shows a notification that will automatically disappear after a few seconds:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Display a notification that will automatically disappear
app.displayNotification('This message will disappear shortly', {
    withTitle: 'Auto-dismiss Notification'
    // No sound to minimize distraction
});
```

## Notes

- How notifications appear depends on the user's System Settings > Notifications preferences
- If the user has disabled notification sounds, no sound will play even if specified
- Notifications from JXA scripts don't support user interaction or callbacks
- Use notifications for non-critical information that doesn't require immediate user action

## Usage Example: Notification after Completing a Task

```javascript
function performLongTask() {
    // Simulate a long-running task
    for (let i = 0; i < 1000000; i++) {
        // Processing...
    }
    return "Completed successfully";
}

const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Perform a task and notify upon completion
const result = performLongTask();
app.displayNotification(result, {
    withTitle: 'Task Status',
    subtitle: new Date().toLocaleTimeString(),
    soundName: 'Ping'
});
```

This script is useful for notifying users of background task completion without interrupting their workflow with more intrusive dialogs.
