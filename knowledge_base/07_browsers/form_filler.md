---
title: Web Form Filler
category: 07_browsers
id: form_filler
description: >-
  Automates filling out web forms in Safari and Chrome browsers by providing
  form data that can be injected into web pages.
language: javascript
keywords:
  - form
  - automation
  - safari
  - chrome
  - fill
  - browser
  - input
  - submit
  - login
  - registration
---

# Web Form Filler

This script automates filling out web forms in Safari and Chrome browsers. It can be used for repetitive form tasks such as logins, data entry, or registration forms. The script operates by:

1. Opening a specified URL in the chosen browser
2. Waiting for the page to fully load
3. Identifying form elements using various selectors (ID, name, label text, etc.)
4. Filling in the form with provided data
5. Optionally submitting the form

## Usage

The script runs in JXA (JavaScript for Automation) and accepts parameters to customize the form filling process.

```javascript
// Web Form Filler
// Fills web forms with provided data in Safari or Chrome

function run(argv) {
    // Default parameters when run without arguments
    if (argv.length === 0) {
        // Launch interactive mode with UI
        return runInteractiveMode();
    }
    
    return "Please use with MCP parameters";
}

// Main handler for MCP input parameters
function processMCPParameters(params) {
    try {
        // Extract parameters
        const browser = params.browser || "safari";        // "safari" or "chrome"
        const url = params.url || "";                      // URL to open
        const formData = params.formData || {};            // Data to fill in form
        const selectors = params.selectors || {};          // Custom selectors
        const submit = params.submit === true;             // Whether to auto-submit
        const waitTime = params.waitTime || 5;             // Wait time in seconds after page load
        const fillDelay = params.fillDelay || 0.1;         // Delay between filling fields (seconds)
        
        // Validate required parameters
        if (!url) {
            return {
                success: false,
                error: "URL is required"
            };
        }
        
        if (Object.keys(formData).length === 0) {
            return {
                success: false,
                error: "Form data is required"
            };
        }
        
        // Fill the form
        return fillForm(browser, url, formData, selectors, submit, waitTime, fillDelay);
    } catch (error) {
        return {
            success: false,
            error: `Error processing parameters: ${error.message}`
        };
    }
}

// Function to run interactive mode with dialog interfaces
function runInteractiveMode() {
    try {
        const app = Application.currentApplication();
        app.includeStandardAdditions = true;
        
        // Choose browser
        const browserChoice = app.chooseFromList(
            ["Safari", "Google Chrome"], 
            {
                withPrompt: "Select browser:",
                defaultItems: ["Safari"]
            }
        );
        
        if (!browserChoice) return "Cancelled by user";
        const browser = browserChoice[0].toLowerCase().replace("google ", "");
        
        // Enter URL
        const url = app.displayDialog("Enter the website URL:", {
            defaultAnswer: "https://",
            withIcon: "note",
            buttons: ["Cancel", "Next"],
            defaultButton: "Next"
        }).textReturned;
        
        if (!url || !url.startsWith("http")) {
            return "Invalid URL. Please enter a URL starting with http:// or https://";
        }
        
        // Gather form data through dialogs
        let formData = {};
        let continueAdding = true;
        
        while (continueAdding) {
            const fieldName = app.displayDialog("Enter field name/label (or Cancel to finish):", {
                defaultAnswer: "",
                withIcon: "note",
                buttons: ["Finish", "Add Field"],
                defaultButton: "Add Field"
            });
            
            if (fieldName.buttonReturned === "Finish") {
                continueAdding = false;
                continue;
            }
            
            const fieldValue = app.displayDialog(`Enter value for "${fieldName.textReturned}":`, {
                defaultAnswer: "",
                withIcon: "note",
                buttons: ["Cancel", "Add"],
                defaultButton: "Add"
            });
            
            formData[fieldName.textReturned] = fieldValue.textReturned;
        }
        
        // Ask about submission
        const shouldSubmit = app.displayDialog("Would you like to automatically submit the form?", {
            withIcon: "note",
            buttons: ["No", "Yes"],
            defaultButton: "No"
        }).buttonReturned === "Yes";
        
        // Fill the form
        return fillForm(browser, url, formData, {}, shouldSubmit, 5, 0.5);
    } catch (error) {
        if (error.errorNumber === -128) {
            return "Cancelled by user";
        }
        return `Error in interactive mode: ${error.message}`;
    }
}

// Main function to fill a form
function fillForm(browser, url, formData, selectors, submit, waitTime, fillDelay) {
    try {
        const browserApp = Application(browser === "chrome" ? "Google Chrome" : "Safari");
        browserApp.includeStandardAdditions = true;
        
        // Activate browser
        browserApp.activate();
        
        // Open URL if provided
        if (url) {
            if (browser === "chrome") {
                browserApp.windows[0].makeNewTab({with: url});
                delay(1); // Short delay to ensure tab opens
                const tabCount = browserApp.windows[0].tabs.length;
                browserApp.windows[0].activeTabIndex = tabCount;
            } else {
                // Safari
                const doc = browserApp.Document().make();
                doc.url = url;
            }
        }
        
        // Wait for page to load
        delay(waitTime);
        
        // Get appropriate script based on browser
        const jsScript = buildFormFillScript(formData, selectors, submit, fillDelay);
        
        // Execute the JavaScript in the browser
        let result;
        if (browser === "chrome") {
            result = browserApp.windows[0].activeTab.execute({javascript: jsScript});
        } else {
            // Safari
            result = browserApp.doJavaScript(jsScript, {in: browserApp.documents[0]});
        }
        
        return {
            success: true,
            message: "Form filled successfully",
            result: result
        };
    } catch (error) {
        return {
            success: false,
            error: `Error filling form: ${error.message}`
        };
    }
}

// Create the JavaScript to run in the browser context
function buildFormFillScript(formData, selectors, submit, fillDelay) {
    const customSelectors = JSON.stringify(selectors);
    const formDataJson = JSON.stringify(formData);
    const delayMs = fillDelay * 1000;
    
    return `
    (function() {
        // Form fill function
        const formData = ${formDataJson};
        const customSelectors = ${customSelectors};
        const shouldSubmit = ${submit};
        const fieldDelay = ${delayMs};
        
        // Helper function to delay execution
        const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
        
        // Helper function to find input elements
        async function findInputElement(fieldName) {
            // First, check if we have a custom selector for this field
            if (customSelectors[fieldName]) {
                return document.querySelector(customSelectors[fieldName]);
            }
            
            // Try various selector methods to find the input
            // 1. Try by ID
            let element = document.getElementById(fieldName);
            if (element) return element;
            
            // 2. Try by name attribute
            element = document.querySelector(\`[name="\${fieldName}"]\`);
            if (element) return element;
            
            // 3. Try by placeholder text
            element = document.querySelector(\`[placeholder*="\${fieldName}"]\`);
            if (element) return element;
            
            // 4. Try by aria-label
            element = document.querySelector(\`[aria-label*="\${fieldName}"]\`);
            if (element) return element;
            
            // 5. Try finding a label element containing the field name
            const labels = Array.from(document.querySelectorAll('label'));
            for (const label of labels) {
                if (label.textContent.toLowerCase().includes(fieldName.toLowerCase())) {
                    // If label has a 'for' attribute, use it to find the input
                    if (label.htmlFor) {
                        element = document.getElementById(label.htmlFor);
                        if (element) return element;
                    }
                    
                    // Check for inputs inside the label
                    const inputInLabel = label.querySelector('input, select, textarea');
                    if (inputInLabel) return inputInLabel;
                    
                    // Check for inputs after the label
                    let sibling = label.nextElementSibling;
                    while (sibling) {
                        if (sibling.matches('input, select, textarea')) {
                            return sibling;
                        }
                        // Check for input inside the sibling
                        const nestedInput = sibling.querySelector('input, select, textarea');
                        if (nestedInput) return nestedInput;
                        
                        sibling = sibling.nextElementSibling;
                    }
                }
            }
            
            // 6. Try by class or name containing the field name
            element = document.querySelector(\`[class*="\${fieldName}"]\`) || 
                      document.querySelector(\`[name*="\${fieldName}"]\`);
            if (element) return element;
            
            // 7. Try by input type for common fields
            const commonFields = {
                'email': 'input[type="email"]',
                'password': 'input[type="password"]',
                'username': 'input[type="text"], input:not([type])',
                'search': 'input[type="search"]',
                'phone': 'input[type="tel"]',
                'date': 'input[type="date"]'
            };
            
            if (commonFields[fieldName.toLowerCase()]) {
                element = document.querySelector(commonFields[fieldName.toLowerCase()]);
                if (element) return element;
            }
            
            return null;
        }
        
        // Function to set value based on element type
        async function setValue(element, value) {
            if (!element) return false;
            
            const tagName = element.tagName.toLowerCase();
            const inputType = element.type ? element.type.toLowerCase() : '';
            
            // Handle different input types
            if (tagName === 'select') {
                // For select elements, find the option that matches the value
                const options = Array.from(element.options);
                for (const option of options) {
                    if (option.text.includes(value) || option.value.includes(value)) {
                        element.value = option.value;
                        element.dispatchEvent(new Event('change', { bubbles: true }));
                        return true;
                    }
                }
                return false;
            } 
            else if (inputType === 'checkbox' || inputType === 'radio') {
                // For checkboxes and radios
                const lowercaseValue = value.toString().toLowerCase();
                const shouldCheck = ['true', 'yes', 'on', '1'].includes(lowercaseValue);
                element.checked = shouldCheck;
                element.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            else if (tagName === 'textarea' || tagName === 'input') {
                // Clear the current value first
                element.value = '';
                element.dispatchEvent(new Event('input', { bubbles: true }));
                await sleep(50); // Small delay after clearing
                
                // Set the new value
                element.value = value;
                
                // Dispatch events to trigger any listeners
                element.dispatchEvent(new Event('input', { bubbles: true }));
                element.dispatchEvent(new Event('change', { bubbles: true }));
                return true;
            }
            else {
                // For other elements, try setting innerText or textContent
                if (typeof element.value !== 'undefined') {
                    element.value = value;
                } else {
                    element.textContent = value;
                }
                return true;
            }
        }
        
        // Main function to fill the form
        async function fillForm() {
            let results = {};
            let errors = [];
            
            for (const fieldName of Object.keys(formData)) {
                try {
                    // Find the element
                    const element = await findInputElement(fieldName);
                    
                    if (!element) {
                        errors.push(\`Could not find element for: \${fieldName}\`);
                        continue;
                    }
                    
                    // Set the value
                    const success = await setValue(element, formData[fieldName]);
                    
                    if (success) {
                        results[fieldName] = 'filled';
                    } else {
                        errors.push(\`Could not set value for: \${fieldName}\`);
                    }
                    
                    // Add delay between fields
                    if (fieldDelay > 0) {
                        await sleep(fieldDelay);
                    }
                } catch (error) {
                    errors.push(\`Error processing \${fieldName}: \${error.message}\`);
                }
            }
            
            // Submit the form if requested
            if (shouldSubmit) {
                try {
                    // Try to find the submit button
                    let submitButton = document.querySelector('button[type="submit"]') || 
                                      document.querySelector('input[type="submit"]');
                    
                    // If no submit button found, look for buttons with submit-related text
                    if (!submitButton) {
                        const buttons = Array.from(document.querySelectorAll('button, input[type="button"], a.button, .btn, [role="button"]'));
                        for (const button of buttons) {
                            const text = button.textContent.toLowerCase();
                            if (text.includes('submit') || text.includes('login') || 
                                text.includes('sign in') || text.includes('continue') ||
                                text.includes('register') || text.includes('next')) {
                                submitButton = button;
                                break;
                            }
                        }
                    }
                    
                    // If we found a submit button, click it
                    if (submitButton) {
                        submitButton.click();
                        results['formSubmitted'] = true;
                    } else {
                        // If no button found, try to submit the form directly
                        const form = document.querySelector('form');
                        if (form) {
                            form.submit();
                            results['formSubmitted'] = true;
                        } else {
                            errors.push('Could not find a submit button or form element');
                        }
                    }
                } catch (error) {
                    errors.push(\`Error submitting form: \${error.message}\`);
                }
            }
            
            return {
                success: errors.length === 0,
                filled: results,
                errors: errors
            };
        }
        
        // Execute the form filling and return the result
        return fillForm();
    })();
    `;
}

// Utility function to create a delay
function delay(seconds) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.delay(seconds);
}
```

## Example Input Parameters

When using with MCP, you can provide these parameters:

- `browser`: Browser to use - "safari" or "chrome" (default: "safari")
- `url`: URL of the webpage containing the form (required)
- `formData`: Object containing field names/labels and values to fill in (required)
- `selectors`: Optional custom CSS selectors for specific fields
- `submit`: Whether to automatically submit the form (default: false)
- `waitTime`: Time to wait in seconds after page load (default: 5)
- `fillDelay`: Delay between filling fields in seconds (default: 0.1)

## Example Usage

### Fill a login form

```json
{
  "browser": "safari",
  "url": "https://example.com/login",
  "formData": {
    "username": "myusername",
    "password": "mypassword"
  },
  "submit": true
}
```

### Fill a registration form with custom selectors

```json
{
  "browser": "chrome",
  "url": "https://example.com/register",
  "formData": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "555-123-4567",
    "accept_terms": "yes"
  },
  "selectors": {
    "firstName": "#first_name",
    "lastName": "#last_name"
  },
  "waitTime": 3,
  "fillDelay": 0.5,
  "submit": true
}
```

## Form Field Finding Strategy

The script uses several strategies to find form elements:

1. Custom selectors (if provided)
2. Element ID matching the field name
3. Name attribute matching the field name
4. Placeholder text containing the field name
5. ARIA label containing the field name
6. Label text containing the field name
7. Class or name attributes containing the field name
8. Common field types (email, password, etc.)

This multi-strategy approach makes the script robust against different form designs and structures.

## Security Note

This script is designed for automating repetitive form-filling tasks. Use responsibly and avoid storing sensitive information like passwords in scripts or MCP parameters unless proper security measures are in place.
