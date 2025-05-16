---
title: 'Chrome: Execute JavaScript in Console'
category: 07_browsers/chrome
id: chrome_execute_js_console
description: >-
  Executes JavaScript code in Chrome's Console with full DevTools API access and
  returns the result, supporting advanced debugging and automation functions.
keywords:
  - Chrome
  - JavaScript
  - console
  - execute
  - DevTools API
  - debug
  - automation
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Required JavaScript code as 'jsCode' in inputData. For example: { "jsCode":
  "console.log(performance.timing); return document.title;" }. You can also
  specify { "awaitPromises": true } to automatically wait for promises to
  resolve.
returnValueType: json
notes: >
  - Google Chrome must be running with at least one window and tab open.

  - Opens DevTools (if not already open) and switches to the Console panel.

  - Executes JavaScript with full access to DevTools console API.

  - Can access and manipulate DevTools programmatically.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.
---

This script executes JavaScript code in Chrome's Console panel with full access to DevTools APIs, enabling advanced debugging, monitoring, and automation capabilities.

```applescript
--MCP_INPUT:jsCode
--MCP_INPUT:awaitPromises

on executeJSInChromeConsole(javascriptCode, awaitPromises)
  if javascriptCode is missing value or javascriptCode is "" then
    return "error: No JavaScript code provided."
  end if
  
  -- Default awaitPromises to false if not provided
  if awaitPromises is missing value then
    set awaitPromises to false
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
  end tell
  
  -- First, ensure DevTools is open and console is visible
  tell application "System Events"
    tell process "Google Chrome"
      set frontmost to true
      delay 0.3
      
      -- Check if DevTools is already open (approximate detection)
      set devToolsOpen to false
      repeat with w in windows
        if description of w contains "Developer Tools" or description of w contains "Console" then
          set devToolsOpen to true
          exit repeat
        end if
      end repeat
      
      -- Open DevTools if not already open
      if not devToolsOpen then
        key code 34 using {command down, option down} -- Option+Command+I
        delay 0.7
      end if
      
      -- Switch to Console panel
      key code 38 using {command down, option down} -- Option+Command+J
      delay 0.5
    end tell
  end tell
  
  -- Prepare the JavaScript code for execution
  -- By using a unique ID, we can identify our execution result
  set uniqueID to "mcpExecute_" & (random number from 100000 to 999999) as string
  
  -- Wrap the provided code to capture its result and handle errors
  set wrappedCode to "
    (function() {
      try {
        // Make sure we're in a DevTools context
        if (typeof console === 'undefined') {
          return { 
            error: true, 
            message: 'Console not available. DevTools API may not be accessible.' 
          };
        }
        
        // Clear console for cleaner output
        console.clear();
        
        // Define a function to execute user code and handle promise results
        const executeUserCode = async () => {
          try {
            // Execute user code and capture result
            let result = (function() { " & javascriptCode & " })();
            
            " & (if awaitPromises then "
            // Handle promises if awaitPromises is true
            if (result instanceof Promise) {
              result = await result;
            }
            " else "") & "
            
            // Handle special case for undefined
            if (result === undefined) {
              return { result: null, type: 'undefined' };
            }
            
            // Convert result to serialized object with type info
            return { 
              result: result, 
              type: typeof result,
              isArray: Array.isArray(result),
              isObject: (typeof result === 'object' && result !== null)
            };
          } catch (e) {
            return { 
              error: true, 
              message: e.message,
              stack: e.stack,
              name: e.name 
            };
          }
        };
        
        // Custom handling based on whether we need to await promises
        " & (if awaitPromises then "
        // Execute code asynchronously and store result for retrieval
        executeUserCode().then(result => {
          // Store result in sessionStorage for retrieval
          window.sessionStorage.setItem('" & uniqueID & "', JSON.stringify(result));
          console.log('%cCode execution completed (" & uniqueID & ")', 'color:green;font-weight:bold');
        }).catch(err => {
          window.sessionStorage.setItem('" & uniqueID & "', JSON.stringify({ 
            error: true, 
            message: err.message,
            stack: err.stack,
            name: err.name 
          }));
          console.error('Execution error:', err);
        });
        
        return { 
          status: 'executing', 
          message: 'Code execution started. Awaiting promise resolution.',
          executionId: '" & uniqueID & "'
        };
        " else "
        // Execute code synchronously
        const result = executeUserCode();
        
        // Store result in sessionStorage for reliability
        window.sessionStorage.setItem('" & uniqueID & "', JSON.stringify(result));
        
        return result;
        ") & "
      } catch (e) {
        return { 
          error: true, 
          message: e.message,
          stack: e.stack,
          name: e.name 
        };
      }
    })();
  "
  
  tell application "Google Chrome"
    try
      -- Execute our wrapped code
      set initialResult to execute active tab of front window javascript wrappedCode
      
      -- Handle async execution (when awaiting promises)
      if awaitPromises then
        -- Check if we have a pending execution to retrieve
        if initialResult is not missing value and initialResult contains "executing" then
          set executionId to uniqueID
          
          -- Function to retrieve the result
          set getResultCode to "
            (function() {
              const resultStr = window.sessionStorage.getItem('" & executionId & "');
              if (resultStr) {
                // Clear the result from sessionStorage to avoid memory leaks
                window.sessionStorage.removeItem('" & executionId & "');
                return JSON.parse(resultStr);
              } else {
                return { status: 'pending', message: 'Result not ready yet' };
              }
            })();
          "
          
          -- Poll for the result with timeout
          set maxAttempts to 30 -- 15 seconds max wait time
          set attemptCounter to 0
          
          repeat
            delay 0.5
            set attemptCounter to attemptCounter + 1
            set resultCheck to execute active tab of front window javascript getResultCode
            
            -- If we got a result back that's not 'pending', we're done
            if resultCheck is not missing value and resultCheck does not contain "pending" then
              return resultCheck
            end if
            
            -- Timeout check
            if attemptCounter ≥ maxAttempts then
              return "{\"error\": true, \"message\": \"Execution timed out waiting for promise resolution.\"}"
            end if
          end repeat
        else
          -- Return the initial result if not an async execution
          return initialResult
        end if
      else
        -- For synchronous execution, return the result directly
        return initialResult
      end if
    on error errMsg
      return "{\"error\": true, \"message\": \"" & my escapeJSString(errMsg) & "\"}"
    end try
  end tell
end executeJSInChromeConsole

-- Helper function to escape JavaScript strings
on escapeJSString(theString)
  set resultString to ""
  repeat with i from 1 to length of theString
    set currentChar to character i of theString
    if currentChar is "\"" or currentChar is "\\" then
      set resultString to resultString & "\\" & currentChar
    else if ASCII number of currentChar is 10 then
      set resultString to resultString & "\\n"
    else if ASCII number of currentChar is 13 then
      set resultString to resultString & "\\r"
    else if ASCII number of currentChar is 9 then
      set resultString to resultString & "\\t"
    else
      set resultString to resultString & currentChar
    end if
  end repeat
  return resultString
end escapeJSString

return my executeJSInChromeConsole("--MCP_INPUT:jsCode", "--MCP_INPUT:awaitPromises")
```
END_TIP
