---
title: 'JXA Keyboard Input'
category: 03_jxa_core
id: jxa_keystrokes
description: Sending keystrokes and key combinations to applications using JXA
keywords:
  - jxa
  - javascript
  - system events
  - keystrokes
  - keyboard input
  - key combinations
  - keyboard shortcuts
language: javascript
---

# JXA Keyboard Input

This script demonstrates how to send keystrokes and keyboard combinations to applications using JavaScript for Automation and System Events.

## Prerequisites

You need to grant accessibility permissions to your script's host application (Script Editor, Terminal, etc.) in System Settings → Privacy & Security → Accessibility.

```javascript
// Basic System Events setup
const systemEvents = Application('System Events');

// Activate app before sending input
function activateApp(appName) {
  const app = Application(appName);
  app.activate();
  delay(0.2); // Small delay to ensure app is ready
  return app;
}
```

## Sending Keystrokes

```javascript
function sendKeystrokes() {
  // Activate TextEdit
  activateApp('TextEdit');
  
  // Type text
  systemEvents.keystroke('Hello from JXA!');
  
  // Press Enter/Return (keycode 36)
  systemEvents.keyCode(36);
  
  // Special key combinations
  systemEvents.keystroke('a', {using: 'command down'}); // Select all (Cmd+A)
  systemEvents.keystroke('c', {using: 'command down'}); // Copy (Cmd+C)
  
  // Multiple modifier keys
  systemEvents.keystroke(' ', {using: ['option down', 'command down']}); // Opt+Cmd+Space
}
```

## Key Methods

The script demonstrates the following keyboarding techniques:

1. Activating an application before sending keyboard input
2. Typing text with `keystroke()`
3. Pressing special keys using key codes with `keyCode()`
4. Executing keyboard shortcuts with modifier keys
5. Using multiple modifier keys simultaneously

## Common Keyboard Functions

### Typing Text

The basic method for typing text is:

```javascript
systemEvents.keystroke('Text to type');
```

### Keyboard Shortcuts

To use keyboard shortcuts with modifier keys:

```javascript
// Single modifier key
systemEvents.keystroke('a', {using: 'command down'}); // Cmd+A (Select All)
systemEvents.keystroke('s', {using: 'command down'}); // Cmd+S (Save)
systemEvents.keystroke('z', {using: 'command down'}); // Cmd+Z (Undo)

// Multiple modifier keys
systemEvents.keystroke('s', {using: ['command down', 'shift down']}); // Cmd+Shift+S (Save As)
systemEvents.keystroke('z', {using: ['command down', 'shift down']}); // Cmd+Shift+Z (Redo)
```

### Common Key Codes

For special keys that don't have a character representation, use `keyCode()`:

```javascript
systemEvents.keyCode(36);  // Return/Enter
systemEvents.keyCode(53);  // Escape
systemEvents.keyCode(123); // Left arrow
systemEvents.keyCode(124); // Right arrow
systemEvents.keyCode(125); // Down arrow
systemEvents.keyCode(126); // Up arrow
systemEvents.keyCode(48);  // Tab
systemEvents.keyCode(49);  // Space
systemEvents.keyCode(51);  // Delete (Backward)
systemEvents.keyCode(117); // Delete (Forward)
systemEvents.keyCode(76);  // Enter (Numpad)
```

You can also use key codes with modifier keys:

```javascript
systemEvents.keyCode(123, {using: 'option down'}); // Option+Left Arrow (Move by word)
```

## Important Considerations

- Always activate the target application before sending keystrokes
- Add small delays when needed to allow the UI to catch up
- Different applications may respond differently to the same keyboard input
- Some applications may have security measures that prevent automated keyboard input
- Be cautious when automating with keyboard shortcuts as they can vary across system languages and keyboard layouts