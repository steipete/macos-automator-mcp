---
title: 'Safari: Get DOM Information'
category: 07_browsers/safari
id: safari_get_dom_info
description: >-
  Extracts information from the DOM of the current Safari webpage including
  elements, attributes, styles, and computed metrics.
keywords:
  - Safari
  - DOM
  - web scraping
  - HTML
  - CSS
  - elements
  - web development
  - extraction
  - selectors
language: applescript
isComplex: true
argumentsPrompt: >-
  CSS selector as 'selector' in inputData, optionally include attribute names to
  extract as 'attributes' (comma-separated list), and extraction mode as 'mode'
  ('text', 'html', or 'json').
notes: >
  - Safari must be running with at least one open tab.

  - "Allow JavaScript from Apple Events" must be enabled in Safari's Develop
  menu.

  - The script uses CSS selectors to target specific elements on the page.

  - Three extraction modes are available:
    - 'text': Extracts only the text content of selected elements
    - 'html': Extracts the HTML markup of selected elements
    - 'json': Returns detailed information including attributes, styles, and metrics in JSON format
  - You can specify particular attributes to extract (e.g., "href,src,data-id")

  - The script handles iframes by attempting to access their content when
  possible.

  - Results for multiple elements are returned as an array in JSON format.

  - For large pages or many elements, the response might be truncated.
---

This script extracts information from DOM elements on the current Safari webpage using CSS selectors.

```applescript
--MCP_INPUT:selector
--MCP_INPUT:attributes
--MCP_INPUT:mode

on getDOMInfo(selector, attributesToGet, extractionMode)
  -- Validate inputs
  if selector is missing value or selector is "" then
    return "error: CSS selector not provided."
  end if
  
  -- Set default mode if not specified
  if extractionMode is missing value or extractionMode is "" then
    set extractionMode to "json"
  else
    set extractionMode to my toLowerCase(extractionMode)
    if extractionMode is not "text" and extractionMode is not "html" and extractionMode is not "json" then
      return "error: Invalid extraction mode. Must be 'text', 'html', or 'json'."
    end if
  end if
  
  -- Prepare the list of attributes to extract
  set attributeList to "[]"
  if attributesToGet is not missing value and attributesToGet is not "" then
    -- Convert comma-separated list to JavaScript array
    set attributeList to "[" & my convertToJSStringArray(attributesToGet) & "]"
  end if
  
  -- Build the JavaScript to extract DOM info
  set domExtractionJS to "
    (function() {
      // CSS selector to use
      const selector = '" & selector & "';
      
      // Attributes to extract (if specified)
      const attributesToGet = " & attributeList & ";
      
      // Function to get computed styles in simplified object form
      function getComputedStylesForElement(element) {
        const computedStyle = window.getComputedStyle(element);
        const styles = {};
        
        // Filter for the most useful style properties
        const keyProperties = [
          'display', 'visibility', 'position', 'width', 'height', 
          'top', 'right', 'bottom', 'left', 'margin', 'padding',
          'color', 'background-color', 'font-size', 'font-family',
          'z-index', 'opacity', 'border', 'overflow'
        ];
        
        keyProperties.forEach(prop => {
          // For shorthand properties like 'margin', try individual sides as well
          if (prop === 'margin' || prop === 'padding' || prop === 'border') {
            ['top', 'right', 'bottom', 'left'].forEach(side => {
              styles[`${prop}-${side}`] = computedStyle.getPropertyValue(`${prop}-${side}`);
            });
          } else {
            styles[prop] = computedStyle.getPropertyValue(prop);
          }
        });
        
        return styles;
      }
      
      // Function to get element metrics/dimensions
      function getElementMetrics(element) {
        const rect = element.getBoundingClientRect();
        return {
          x: rect.x,
          y: rect.y,
          width: rect.width,
          height: rect.height,
          top: rect.top,
          right: rect.right,
          bottom: rect.bottom,
          left: rect.left,
          inViewport: (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= window.innerHeight &&
            rect.right <= window.innerWidth
          )
        };
      }
      
      // Function to get all attributes of an element
      function getElementAttributes(element, specificAttributes = []) {
        const attributes = {};
        const attrs = element.attributes;
        
        if (attrs && attrs.length > 0) {
          // If specific attributes requested, only get those
          if (specificAttributes.length > 0) {
            specificAttributes.forEach(attrName => {
              if (element.hasAttribute(attrName)) {
                attributes[attrName] = element.getAttribute(attrName);
              }
            });
          } else {
            // Otherwise get all attributes
            for (let i = 0; i < attrs.length; i++) {
              attributes[attrs[i].name] = attrs[i].value;
            }
          }
        }
        
        return attributes;
      }
      
      // Function to extract comprehensive info about an element
      function extractElementInfo(element, mode, specificAttributes) {
        // For text mode, just return the text content
        if (mode === 'text') {
          return element.textContent.trim();
        }
        
        // For HTML mode, return the outer HTML
        if (mode === 'html') {
          return element.outerHTML;
        }
        
        // For JSON mode, return detailed information
        return {
          tagName: element.tagName.toLowerCase(),
          id: element.id || null,
          className: element.className || null,
          textContent: element.textContent.trim(),
          attributes: getElementAttributes(element, specificAttributes),
          styles: getComputedStylesForElement(element),
          metrics: getElementMetrics(element),
          // Include simplified HTML for reference
          html: element.outerHTML.length > 500 
            ? element.outerHTML.substring(0, 500) + '...' 
            : element.outerHTML
        };
      }
      
      // Find elements matching the selector
      let elements = [];
      try {
        elements = Array.from(document.querySelectorAll(selector));
        
        // If no elements found in main document, try looking in frames
        if (elements.length === 0 && window.frames.length > 0) {
          for (let i = 0; i < window.frames.length; i++) {
            try {
              const frameElements = Array.from(window.frames[i].document.querySelectorAll(selector));
              if (frameElements.length > 0) {
                elements = frameElements;
                break;
              }
            } catch (frameError) {
              // Ignore errors accessing frames (could be cross-origin)
            }
          }
        }
      } catch (err) {
        return JSON.stringify({
          error: `Invalid selector: ${err.message}`
        });
      }
      
      // Check if we found any elements
      if (elements.length === 0) {
        return JSON.stringify({
          error: `No elements found matching selector: ${selector}`
        });
      }
      
      // Extract information based on mode
      const extractionMode = '" & extractionMode & "';
      const results = elements.map(el => extractElementInfo(el, extractionMode, attributesToGet));
      
      // Format the response based on extraction mode and number of elements
      if (extractionMode === 'text' || extractionMode === 'html') {
        // For text/html modes with single element, return the content directly
        if (elements.length === 1) {
          return results[0];
        }
        // Otherwise return as JSON array
        return JSON.stringify(results);
      } else {
        // For JSON mode, always return a structured object
        return JSON.stringify({
          selector: selector,
          count: elements.length,
          elements: results
        }, null, 2);
      }
    })();
  "
  
  tell application "Safari"
    if not running then
      return "error: Safari is not running."
    end if
    
    try
      if (count of windows) is 0 or (count of tabs of front window) is 0 then
        return "error: No tabs open in Safari."
      end if
      
      set currentTab to current tab of front window
      set pageUrl to URL of currentTab
      
      -- Execute the JavaScript
      set jsResult to do JavaScript domExtractionJS in currentTab
      
      return jsResult
    on error errMsg
      return "error: Failed to extract DOM information - " & errMsg & ". Make sure 'Allow JavaScript from Apple Events' is enabled in Safari's Develop menu."
    end try
  end tell
end getDOMInfo

-- Helper function to convert comma-separated list to JavaScript string array
on convertToJSStringArray(commaList)
  set AppleScript's text item delimiters to ","
  set theItems to every text item of commaList
  set AppleScript's text item delimiters to ""
  
  set jsArray to ""
  repeat with i from 1 to count of theItems
    set theItem to item i of theItems
    set theItem to my trimText(theItem)
    if theItem is not "" then
      set jsArray to jsArray & "\"" & theItem & "\""
      if i < count of theItems then set jsArray to jsArray & ", "
    end if
  end repeat
  
  return jsArray
end convertToJSStringArray

-- Helper function to trim whitespace
on trimText(theText)
  -- Remove leading and trailing whitespace
  set theText to my trimLeadingSpace(theText)
  set theText to my trimTrailingSpace(theText)
  return theText
end trimText

-- Helper function to remove leading whitespace
on trimLeadingSpace(theText)
  repeat while theText begins with " " or theText begins with tab
    set theText to text 2 thru end of theText
  end repeat
  return theText
end trimLeadingSpace

-- Helper function to remove trailing whitespace
on trimTrailingSpace(theText)
  repeat while theText ends with " " or theText ends with tab
    set theText to text 1 thru ((length of theText) - 1) of theText
  end repeat
  return theText
end trimTrailingSpace

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

return my getDOMInfo("--MCP_INPUT:selector", "--MCP_INPUT:attributes", "--MCP_INPUT:mode")
```
