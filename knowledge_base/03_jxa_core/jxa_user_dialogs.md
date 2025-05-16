---
id: jxa_user_dialogs
title: User Dialogs with JXA
description: Create interactive dialog boxes using JavaScript for Automation
language: javascript
keywords:
  - dialog
  - user input
  - alerts
  - forms
  - UI interaction
category: 03_jxa_core
---

# User Dialogs with JXA

JavaScript for Automation (JXA) provides several methods to create interactive dialog boxes for user interaction.

## Prerequisites

First, make sure to include the Standard Additions library:

```javascript
// Get the current application and include standard additions
const app = Application.currentApplication();
app.includeStandardAdditions = true;
```

## Simple Alert Dialog

To display a basic informational alert:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

app.displayAlert("Operation completed successfully!", {
    // Optional parameters
    buttons: ["OK"],
    defaultButton: "OK",
    cancelButton: "OK",
    givingUpAfter: 15 // Auto-dismiss after 15 seconds
});
```

## Alert with Multiple Buttons

Create an alert with multiple buttons and handle the user's choice:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const result = app.displayAlert("Do you want to save your changes?", {
        buttons: ["Don't Save", "Cancel", "Save"], 
        defaultButton: "Save",
        cancelButton: "Cancel",
        withIcon: "caution" // "stop", "note", "caution"
    });
    
    // Handle the result based on the button clicked
    switch (result.buttonReturned) {
        case "Save":
            console.log("User chose to save changes");
            // Code to save changes
            break;
        case "Don't Save":
            console.log("User chose not to save changes");
            // Code to discard changes
            break;
    }
} catch (error) {
    // User clicked Cancel or closed the dialog
    console.log("Operation cancelled by user");
}
```

## Text Input Dialog

To get text input from the user:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const result = app.displayDialog("Please enter your name:", {
        defaultAnswer: "",
        buttons: ["Cancel", "OK"],
        defaultButton: "OK",
        cancelButton: "Cancel",
        withTitle: "User Information",
        withIcon: "note"
    });
    
    const userInput = result.textReturned;
    console.log(`User entered: ${userInput}`);
    
    // Now you can use the input...
    
} catch (error) {
    console.log("User cancelled the input dialog");
}
```

## Password Input Dialog (Hidden Text)

For sensitive information like passwords:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

try {
    const result = app.displayDialog("Enter your password:", {
        defaultAnswer: "",
        buttons: ["Cancel", "OK"],
        defaultButton: "OK",
        cancelButton: "Cancel",
        withTitle: "Authentication Required",
        withIcon: "caution",
        hiddenAnswer: true // This hides the text as it's typed
    });
    
    const password = result.textReturned;
    // Process the password (careful not to log it)
    if (password.length > 0) {
        // Authenticate with the password...
        console.log("Password received, authenticating...");
    }
    
} catch (error) {
    console.log("Authentication cancelled");
}
```

## Choose from List Dialog

To let the user choose from a predefined list of options:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

const fruits = ["Apple", "Banana", "Orange", "Mango", "Pineapple"];

try {
    const selection = app.chooseFromList(fruits, {
        withPrompt: "Select your favorite fruit:",
        defaultItems: ["Apple"],
        okButtonName: "Select",
        cancelButtonName: "Cancel",
        multipleSelectionsAllowed: false,
        emptySelectionAllowed: false
    });
    
    if (selection === false) {
        // User cancelled
        console.log("No selection made");
    } else {
        console.log(`User selected: ${selection}`);
        
        // Process the selection...
        if (selection.length > 0) {
            app.displayNotification(`You selected: ${selection[0]}`, {
                withTitle: "Fruit Selection"
            });
        }
    }
} catch (error) {
    console.log(`An error occurred: ${error}`);
}
```

## Multi-Selection List Dialog

To allow the user to select multiple items:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

const toppings = ["Cheese", "Pepperoni", "Mushrooms", "Onions", "Peppers", "Sausage", "Bacon"];

try {
    const selections = app.chooseFromList(toppings, {
        withPrompt: "Select pizza toppings:",
        defaultItems: ["Cheese"],
        okButtonName: "Add to Order",
        cancelButtonName: "Cancel",
        multipleSelectionsAllowed: true,
        emptySelectionAllowed: false
    });
    
    if (selections === false) {
        console.log("No toppings selected");
    } else {
        console.log(`Selected toppings: ${selections.join(", ")}`);
        
        // Process the selections...
        if (selections.length > 0) {
            app.displayDialog(`You selected ${selections.length} toppings: ${selections.join(", ")}`, {
                withTitle: "Pizza Order",
                buttons: ["Continue"],
                defaultButton: "Continue"
            });
        }
    }
} catch (error) {
    console.log(`An error occurred: ${error}`);
}
```

## JavaScript-Style Alert, Confirm and Prompt Shims

Create web-style dialog functions that mimic browser JavaScript:

```javascript
const app = Application.currentApplication();
app.includeStandardAdditions = true;

// Alert function - display a simple message with OK button
function alert(message, informationalText) {
    const options = {};
    if (informationalText) options.message = informationalText;
    
    app.displayAlert(message, options);
}

// Confirm function - ask a yes/no question
function confirm(message, informationalText) {
    const options = {
        buttons: ["No", "Yes"],
        defaultButton: "Yes",
        cancelButton: "No"
    };
    if (informationalText) options.message = informationalText;
    
    try {
        const result = app.displayAlert(message, options);
        return result.buttonReturned === "Yes";
    } catch (error) {
        return false;
    }
}

// Prompt function - get text input from user
function prompt(message, defaultText, informationalText) {
    const options = {
        defaultAnswer: defaultText || "",
        buttons: ["Cancel", "OK"],
        defaultButton: "OK",
        cancelButton: "Cancel"
    };
    if (informationalText) options.withTitle = informationalText;
    
    try {
        const result = app.displayDialog(message, options);
        return result.textReturned;
    } catch (error) {
        return null;
    }
}

// Examples of using these functions
if (confirm("Do you want to continue?", "Warning")) {
    const name = prompt("Please enter your name:", "");
    if (name) {
        alert(`Hello, ${name}!`, "Greeting");
    }
}
```

## Complex Form Dialog

This example combines multiple inputs into a form-like dialog sequence:

```javascript
function getUserInfo() {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    
    // Get user's name
    let name;
    try {
        const nameResult = app.displayDialog("Please enter your name:", {
            defaultAnswer: "",
            buttons: ["Cancel", "Continue"],
            defaultButton: "Continue",
            cancelButton: "Cancel",
            withTitle: "Personal Information"
        });
        name = nameResult.textReturned;
    } catch (error) {
        return null; // User cancelled
    }
    
    // Get user's age
    let age;
    try {
        const ageResult = app.displayDialog("Please enter your age:", {
            defaultAnswer: "",
            buttons: ["Cancel", "Continue"],
            defaultButton: "Continue",
            cancelButton: "Cancel",
            withTitle: "Personal Information"
        });
        age = parseInt(ageResult.textReturned, 10);
        if (isNaN(age)) {
            app.displayAlert("Please enter a valid number for age.", {
                buttons: ["OK"],
                defaultButton: "OK"
            });
            return null; // Invalid input
        }
    } catch (error) {
        return null; // User cancelled
    }
    
    // Get user's preferred contact method
    let contactMethod;
    try {
        const methods = ["Email", "Phone", "Mail"];
        const methodResult = app.chooseFromList(methods, {
            withPrompt: "How should we contact you?",
            defaultItems: ["Email"],
            okButtonName: "Select",
            cancelButtonName: "Cancel"
        });
        
        if (methodResult === false) {
            return null; // User cancelled
        }
        
        contactMethod = methodResult[0];
    } catch (error) {
        return null; // Error occurred
    }
    
    // Return collected information
    return {
        name: name,
        age: age,
        contactMethod: contactMethod
    };
}

// Use the function to collect user information
const userInfo = getUserInfo();

if (userInfo) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    
    // Show a summary of collected information
    app.displayDialog(
        `Name: ${userInfo.name}\nAge: ${userInfo.age}\nPreferred Contact: ${userInfo.contactMethod}`, 
        {
            withTitle: "Information Summary",
            buttons: ["OK"],
            defaultButton: "OK"
        }
    );
    
    // Process the information...
} else {
    console.log("User cancelled or provided invalid information");
}
```

This collection of dialog examples demonstrates the many ways JXA can interact with users through the macOS interface, providing both basic and complex user interaction capabilities.
