---
title: 'Chrome: Inspect Element by Selector'
category: 07_browsers/chrome
id: chrome_inspect_element
description: >-
  Inspects a specific DOM element in Chrome DevTools using CSS selector or
  XPath, highlighting and selecting it in the Elements panel.
keywords:
  - Chrome
  - DevTools
  - inspect
  - elements
  - DOM
  - selector
  - XPath
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Required selector in inputData. For example: { "selector": "#main-content" }
  for CSS selector or { "selector": "//div[@id='main-content']" } for XPath
  (detected automatically). Can also provide { "selectorType": "css" } or {
  "selectorType": "xpath" } to force a specific selector type.
notes: >
  - Google Chrome must be running with at least one window and tab open.

  - Opens DevTools (if not already open) and switches to the Elements panel.

  - Use either CSS selectors or XPath expressions to target elements.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.
---

This script inspects a specific DOM element using a CSS selector or XPath expression, highlighting it in the Chrome DevTools Elements panel.

```applescript
--MCP_INPUT:selector
--MCP_INPUT:selectorType

on inspectElementInChrome(elementSelector, selectorType)
  if elementSelector is missing value or elementSelector is "" then
    return "error: No element selector provided. Please provide a CSS selector or XPath expression."
  end if
  
  -- If selectorType not provided, try to auto-detect based on selector format
  if selectorType is missing value or selectorType is "" then
    -- XPath expressions often start with // or contain [@ ]
    if elementSelector starts with "//" or elementSelector contains "[@" then
      set selectorType to "xpath"
    else
      set selectorType to "css"
    end if
  else
    -- Convert to lowercase for consistency
    set selectorType to my toLowerCase(selectorType)
    if selectorType is not "css" and selectorType is not "xpath" then
      return "error: Invalid selectorType. Use 'css' or 'xpath'."
    end if
  end if
  
  -- Make sure Chrome is running
  tell application "Google Chrome"
    if not running then
      return "error: Google Chrome is not running."
    end if
    
    if (count of windows) is 0 then
      return "error: No Chrome windows open."
    end if
    
    if (count of tabs of front window) is 0 then
      return "error: No tabs in front Chrome window."
    end if
    
    -- Activate Chrome to ensure keyboard shortcuts work
    activate
    
    -- Generate JavaScript to select the element, get its path, and store it in sessionStorage
    set jsScript to "
      (function() {
        let element;
        let selectorType = '" & selectorType & "';
        let selector = '" & my escapeJSString(elementSelector) & "';
        
        try {
          if (selectorType === 'css') {
            element = document.querySelector(selector);
          } else if (selectorType === 'xpath') {
            const result = document.evaluate(selector, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
            element = result.singleNodeValue;
          }
          
          if (!element) {
            return 'error: No element found with the provided ' + selectorType + ' selector.';
          }
          
          // Store a reference to the element in sessionStorage
          window._lastInspectedElement = element;
          
          // Function to get element path
          function getElementPath(el) {
            let path = '';
            while (el && el.nodeType === Node.ELEMENT_NODE) {
              let selector = el.nodeName.toLowerCase();
              if (el.id) {
                selector += '#' + el.id;
                path = ' > ' + selector + path;
                break;
              } else {
                let sib = el;
                let nth = 1;
                while (sib = sib.previousElementSibling) {
                  if (sib.nodeName.toLowerCase() === selector) nth++;
                }
                if (nth !== 1) selector += ':nth-of-type(' + nth + ')';
              }
              path = ' > ' + selector + path;
              el = el.parentNode;
            }
            return path.substring(3);
          }
          
          // Get path for display
          const elementPath = getElementPath(element);
          
          // Create a script to find the element in DevTools
          const inspectScript = `
            (function() {
              const el = window._lastInspectedElement;
              if (el) {
                inspect(el);
                console.log('Inspecting element:', el);
                return 'Element found and selected in DevTools';
              } else {
                return 'error: Stored element reference not found';
              }
            })();
          `;
          
          // Store the inspect script in sessionStorage for execution after DevTools opens
          sessionStorage.setItem('_mcpInspectScript', inspectScript);
          
          return 'Element found: ' + elementPath;
        } catch (err) {
          return 'error: ' + err.message;
        }
      })();
    "
    
    -- Execute the first script to find the element and store the reference
    set findResult to execute active tab of front window javascript jsScript
    
    -- If the element wasn't found, return the error
    if findResult starts with "error:" then
      return findResult
    end if
  end tell
  
  -- Open DevTools with Elements panel
  tell application "System Events"
    tell process "Google Chrome"
      set frontmost to true
      delay 0.3
      
      -- First check if DevTools is already open by looking for its window
      set devToolsOpen to false
      
      -- Try to locate DevTools window by looking for characteristic elements
      -- This is approximate since there's no definitive way to detect if DevTools is open
      repeat with w in windows
        if description of w contains "Developer Tools" or description of w contains "Elements" then
          set devToolsOpen to true
          exit repeat
        end if
      end repeat
      
      -- Open DevTools if not already open (Option+Command+I / key code 34 is 'i')
      if not devToolsOpen then
        key code 34 using {command down, option down}
        delay 0.7  -- Give DevTools more time to open
      end if
      
      -- Ensure Elements panel is active (Option+Command+C / key code 8 is 'c')
      key code 8 using {command down, option down}
      delay 0.5
    end tell
  end tell
  
  -- Now execute the stored inspection script
  tell application "Google Chrome"
    set inspectScript to "
      (function() {
        const script = sessionStorage.getItem('_mcpInspectScript');
        if (script) {
          sessionStorage.removeItem('_mcpInspectScript');
          return eval(script);
        } else {
          return 'error: Inspection script not found in sessionStorage';
        }
      })();
    "
    
    set inspectResult to execute active tab of front window javascript inspectScript
    
    if inspectResult starts with "error:" then
      return "Element found but failed to inspect: " & inspectResult
    else
      return findResult & " - Successfully opened in DevTools inspector"
    end if
  end tell
end inspectElementInChrome

-- Helper function to convert string to lowercase
on toLowerCase(inputString)
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  set outputString to ""
  
  repeat with i from 1 to length of inputString
    set currentChar to character i of inputString
    set charIndex to offset of currentChar in upperChars
    
    if charIndex > 0 then
      set outputString to outputString & character charIndex of lowerChars
    else
      set outputString to outputString & currentChar
    end if
  end repeat
  
  return outputString
end toLowerCase

-- Helper function to escape JavaScript strings
on escapeJSString(theString)
  set resultString to ""
  repeat with i from 1 to length of theString
    set currentChar to character i of theString
    if currentChar is "'" or currentChar is "\"" or currentChar is "\\" then
      set resultString to resultString & "\\" & currentChar
    else
      set resultString to resultString & currentChar
    end if
  end repeat
  return resultString
end escapeJSString

return my inspectElementInChrome("--MCP_INPUT:selector", "--MCP_INPUT:selectorType")
```
END_TIP
