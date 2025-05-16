---
title: 'JXA UI Elements Control'
category: 03_jxa_core
id: jxa_ui_elements_control
description: Interacting with buttons, fields, and other UI elements using JXA
keywords:
  - jxa
  - javascript
  - system events
  - ui elements
  - buttons
  - text fields
  - accessibility
  - ui scripting
language: javascript
---

# JXA UI Elements Control

This script demonstrates how to interact with buttons, fields, and other UI elements using JavaScript for Automation and System Events.

## Prerequisites

You need to grant accessibility permissions to your script's host application (Script Editor, Terminal, etc.) in System Settings → Privacy & Security → Accessibility.

```javascript
// Basic System Events setup
const systemEvents = Application('System Events');

// Activate app before accessing UI elements
function activateApp(appName) {
  const app = Application(appName);
  app.activate();
  delay(0.2); // Small delay to ensure app is ready
  return app;
}
```

## Working with UI Elements

```javascript
function controlUIElements() {
  // Activate System Preferences
  activateApp('System Preferences');
  
  const sysPref = systemEvents.processes.byName('System Preferences');
  
  // Click a button by its accessibility description
  const buttons = sysPref.windows[0].buttons();
  for (let i = 0; i < buttons.length; i++) {
    if (buttons[i].description() === 'Search') {
      buttons[i].click();
      break;
    }
  }
  
  // Type in a search field
  delay(0.5);
  systemEvents.keystroke('display');
  delay(1);
  
  // Press Escape to clear search
  systemEvents.keyCode(53);
}
```

## UI Element Interaction Techniques

The script demonstrates the following UI control techniques:

1. Activating an application before accessing its UI elements
2. Getting a reference to the application process
3. Accessing windows and UI elements within them
4. Finding UI elements by their properties
5. Clicking buttons and interacting with controls
6. Typing text into input fields
7. Using keyboard shortcuts to control the interface

## UI Element Hierarchy in System Events

System Events represents UI elements in the following hierarchy:

```
process
  └── window
       ├── button
       ├── checkbox
       ├── combobox
       ├── group
       ├── menu button
       ├── radio button
       ├── scrollbar
       ├── slider
       ├── static text
       ├── text field
       └── other UI elements...
```

## Common UI Element Access Methods

### Get All Elements of a Specific Type

```javascript
// Get all buttons in the front window
const buttons = process.windows[0].buttons();

// Get all text fields in the front window
const textFields = process.windows[0].textFields();

// Get all checkboxes in the front window
const checkboxes = process.windows[0].checkboxes();
```

### Find an Element by Property

```javascript
// Find a button by its name
const saveButton = process.windows[0].buttons.byName('Save');

// Find a text field by its value
const nameField = process.windows[0].textFields.whose({value: 'John'})[0];

// Find a checkbox by its description
const agreeCheckbox = process.windows[0].checkboxes.whose({description: 'I agree to the terms'})[0];
```

### Work with UI Element Properties

```javascript
// Get element properties
const buttonName = button.name();
const fieldValue = textField.value();
const isEnabled = button.enabled();
const position = button.position();
const size = button.size();

// Set element properties
textField.value = 'New value';
checkbox.value = 1; // Check a checkbox
```

### Perform Actions on UI Elements

```javascript
// Click a button
button.click();

// Double-click an item
item.click({clickCount: 2});

// Right-click an item
item.click({buttonNumber: 2});

// Set focus to a text field
textField.focused = true;
```

## Important Considerations

- UI elements and their properties may change across application versions
- Add appropriate delays when interacting with UI elements
- Use multiple properties to reliably identify UI elements
- Handle cases where UI elements may not be found
- Consider using the Accessibility Inspector app to explore the UI hierarchy
- Some applications may have security measures that prevent automated UI control