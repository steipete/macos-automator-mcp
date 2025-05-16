---
title: "Safari: Modify DOM"
category: "05_web_browsers"
id: safari_modify_dom
description: "Modifies the DOM of the current Safari webpage, allowing you to add, remove, or change elements, attributes, and styles."
keywords: ["Safari", "DOM", "manipulation", "web development", "HTML", "CSS", "JavaScript", "modify", "edit", "elements"]
language: applescript
isComplex: true
argumentsPrompt: "Operation type as 'operation' ('add', 'remove', 'modify', 'style', 'text'), CSS selector as 'selector', and operation-specific parameters as 'content', 'attribute', 'value', etc. in inputData."
notes: |
  - Safari must be running with at least one open tab.
  - "Allow JavaScript from Apple Events" must be enabled in Safari's Develop menu.
  - The script uses CSS selectors to target specific elements on the page.
  - Available operations:
    - 'add': Inserts new HTML content at a specified position relative to targeted elements
    - 'remove': Removes elements matching the selector
    - 'modify': Changes attributes of targeted elements
    - 'style': Modifies CSS styles of targeted elements
    - 'text': Changes the text content of targeted elements
  - For the 'add' operation, specify 'position' as 'append', 'prepend', 'before', 'after', or 'replace'
  - Changes are made directly to the live DOM and are not persisted when the page is reloaded.
  - The script returns a summary of the changes made.
  - Be cautious when modifying the DOM as it can affect page functionality.
---

This script modifies the DOM of the current Safari webpage, allowing for dynamic content manipulation.

```applescript
--MCP_INPUT:operation
--MCP_INPUT:selector
--MCP_INPUT:content
--MCP_INPUT:attribute
--MCP_INPUT:value
--MCP_INPUT:position
--MCP_INPUT:styles

on modifyDOM(operation, selector, content, attribute, value, position, styles)
  -- Validate required inputs
  if operation is missing value or operation is "" then
    return "error: Operation type not provided. Must be 'add', 'remove', 'modify', 'style', or 'text'."
  end if
  
  if selector is missing value or selector is "" then
    return "error: CSS selector not provided."
  end if
  
  -- Convert operation to lowercase for case-insensitive comparison
  set operation to my toLowerCase(operation)
  
  -- Validate operation type
  if operation is not "add" and operation is not "remove" and operation is not "modify" and operation is not "style" and operation is not "text" then
    return "error: Invalid operation type. Must be 'add', 'remove', 'modify', 'style', or 'text'."
  end if
  
  -- Validate operation-specific required parameters
  if operation is "add" and (content is missing value or content is "") then
    return "error: Content parameter is required for 'add' operation."
  end if
  
  if operation is "modify" and (attribute is missing value or attribute is "" or value is missing value) then
    return "error: Both 'attribute' and 'value' parameters are required for 'modify' operation."
  end if
  
  if operation is "text" and (content is missing value or content is "") then
    return "error: Content parameter is required for 'text' operation."
  end if
  
  if operation is "style" and (styles is missing value or styles is "") then
    return "error: Styles parameter is required for 'style' operation."
  end if
  
  -- Set default position for 'add' operation if not specified
  if operation is "add" and (position is missing value or position is "") then
    set position to "append"
  end if
  
  -- Ensure compatible parameters
  if operation is "add" then
    set position to my toLowerCase(position)
    if position is not "append" and position is not "prepend" and position is not "before" and position is not "after" and position is not "replace" then
      return "error: Invalid position for 'add' operation. Must be 'append', 'prepend', 'before', 'after', or 'replace'."
    end if
  end if
  
  -- Construct the JavaScript code for DOM manipulation
  set domJS to "
    (function() {
      // CSS selector to target elements
      const selector = '" & selector & "';
      
      // Find elements matching the selector
      const elements = document.querySelectorAll(selector);
      
      // Check if we found any elements
      if (elements.length === 0) {
        return JSON.stringify({
          error: `No elements found matching selector: ${selector}`
        });
      }
      
      // Perform the requested operation
      const operation = '" & operation & "';
      let modifiedCount = 0;
      
      try {
        switch (operation) {
          case 'add':
            // Add content relative to selected elements
            const position = '" & position & "';
            const content = `" & my escapeJSString(content) & "`;
            
            elements.forEach(element => {
              const tempDiv = document.createElement('div');
              tempDiv.innerHTML = content.trim();
              const fragment = document.createDocumentFragment();
              
              // Move nodes from temporary container to fragment
              while (tempDiv.firstChild) {
                fragment.appendChild(tempDiv.firstChild);
              }
              
              // Apply the fragment at the specified position
              switch (position) {
                case 'append':
                  element.appendChild(fragment.cloneNode(true));
                  break;
                case 'prepend':
                  element.insertBefore(fragment.cloneNode(true), element.firstChild);
                  break;
                case 'before':
                  element.parentNode.insertBefore(fragment.cloneNode(true), element);
                  break;
                case 'after':
                  element.parentNode.insertBefore(fragment.cloneNode(true), element.nextSibling);
                  break;
                case 'replace':
                  // Clear existing content first
                  element.innerHTML = '';
                  element.appendChild(fragment.cloneNode(true));
                  break;
              }
              modifiedCount++;
            });
            
            return JSON.stringify({
              success: true,
              operation: 'add',
              position: position,
              count: modifiedCount,
              message: `Added content to ${modifiedCount} element(s) matching selector: ${selector}`
            });
            
          case 'remove':
            // Remove selected elements
            elements.forEach(element => {
              element.parentNode.removeChild(element);
              modifiedCount++;
            });
            
            return JSON.stringify({
              success: true,
              operation: 'remove',
              count: modifiedCount,
              message: `Removed ${modifiedCount} element(s) matching selector: ${selector}`
            });
            
          case 'modify':
            // Modify attributes of selected elements
            const attribute = '" & attribute & "';
            const value = `" & my escapeJSString(value) & "`;
            
            elements.forEach(element => {
              // Special handling for boolean attributes
              if (value === 'true') {
                element.setAttribute(attribute, '');
              } else if (value === 'false') {
                element.removeAttribute(attribute);
              } else if (value === 'toggle') {
                // Toggle attribute presence
                if (element.hasAttribute(attribute)) {
                  element.removeAttribute(attribute);
                } else {
                  element.setAttribute(attribute, '');
                }
              } else {
                // Normal attribute setting
                element.setAttribute(attribute, value);
              }
              modifiedCount++;
            });
            
            return JSON.stringify({
              success: true,
              operation: 'modify',
              attribute: attribute,
              value: value,
              count: modifiedCount,
              message: `Modified attribute '${attribute}' on ${modifiedCount} element(s) matching selector: ${selector}`
            });
            
          case 'style':
            // Apply styles to selected elements
            const styleString = `" & my escapeJSString(styles) & "`;
            const styleObj = {};
            
            // Parse the style string (format: 'property1:value1; property2:value2')
            styleString.split(';').forEach(pair => {
              if (!pair.trim()) return;
              const [property, value] = pair.split(':').map(s => s.trim());
              if (property && value) {
                styleObj[property] = value;
              }
            });
            
            elements.forEach(element => {
              Object.entries(styleObj).forEach(([property, value]) => {
                element.style[property] = value;
              });
              modifiedCount++;
            });
            
            return JSON.stringify({
              success: true,
              operation: 'style',
              styles: styleObj,
              count: modifiedCount,
              message: `Applied styles to ${modifiedCount} element(s) matching selector: ${selector}`
            });
            
          case 'text':
            // Change text content of selected elements
            const text = `" & my escapeJSString(content) & "`;
            
            elements.forEach(element => {
              element.textContent = text;
              modifiedCount++;
            });
            
            return JSON.stringify({
              success: true,
              operation: 'text',
              count: modifiedCount,
              message: `Changed text content of ${modifiedCount} element(s) matching selector: ${selector}`
            });
        }
      } catch (error) {
        return JSON.stringify({
          error: `Error performing DOM operation: ${error.message}`
        });
      }
    })();
  "
  
  -- Execute the JavaScript in Safari
  tell application "Safari"
    if not running then
      return "error: Safari is not running."
    end if
    
    try
      if (count of windows) is 0 or (count of tabs of front window) is 0 then
        return "error: No tabs open in Safari."
      end if
      
      set currentTab to current tab of front window
      
      -- Execute the JavaScript
      set jsResult to do JavaScript domJS in currentTab
      
      return jsResult
    on error errMsg
      return "error: Failed to modify DOM - " & errMsg & ". Make sure 'Allow JavaScript from Apple Events' is enabled in Safari's Develop menu."
    end try
  end tell
end modifyDOM

-- Helper function to escape JavaScript strings
on escapeJSString(jsString)
  if jsString is missing value then
    return ""
  end if
  
  -- Replace backslashes first
  set escapedString to my replaceText(jsString, "\\", "\\\\")
  -- Replace newlines
  set escapedString to my replaceText(escapedString, return, "\\n")
  -- Replace quotes
  set escapedString to my replaceText(escapedString, "\"", "\\\"")
  -- Replace backticks
  set escapedString to my replaceText(escapedString, "`", "\\`")
  
  return escapedString
end escapeJSString

-- Helper function to replace text
on replaceText(theText, searchString, replacementString)
  set AppleScript's text item delimiters to searchString
  set theTextItems to every text item of theText
  set AppleScript's text item delimiters to replacementString
  set theText to theTextItems as string
  set AppleScript's text item delimiters to ""
  return theText
end replaceText

-- Helper function to convert text to lowercase
on toLowerCase(sourceText)
  set lowercaseText to ""
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  
  repeat with i from 1 to length of sourceText
    set currentChar to character i of sourceText
    set charPos to offset of currentChar in upperChars
    
    if charPos > 0 then
      set lowercaseText to lowercaseText & character charPos of lowerChars
    else
      set lowercaseText to lowercaseText & currentChar
    end if
  end repeat
  
  return lowercaseText
end toLowerCase

return my modifyDOM("--MCP_INPUT:operation", "--MCP_INPUT:selector", "--MCP_INPUT:content", "--MCP_INPUT:attribute", "--MCP_INPUT:value", "--MCP_INPUT:position", "--MCP_INPUT:styles")
```