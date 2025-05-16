---
title: 'Safari: Inject JavaScript'
category: 07_browsers/safari
id: safari_inject_script
description: >-
  Injects custom JavaScript code or external script files into the current
  Safari webpage.
keywords:
  - Safari
  - JavaScript
  - inject
  - script
  - web development
  - DOM
  - manipulation
  - automation
  - bookmarklet
language: applescript
isComplex: true
argumentsPrompt: >-
  JavaScript code to inject as 'script' or URL of external script as 'scriptUrl'
  in inputData. Include 'persistent' flag set to 'true' to have script persist
  across page loads.
notes: >
  - Safari must be running with at least one open tab.

  - This script allows you to inject either inline JavaScript code or load
  external script files.

  - "Allow JavaScript from Apple Events" must be enabled in Safari's Develop
  menu.

  - For complex scripts, consider using a minified version to avoid issues with
  quotes and newlines.

  - The persistent option uses a MutationObserver to re-inject the script on DOM
  changes.

  - External scripts are loaded asynchronously using a dynamically created
  script tag.

  - Scripts run in the page context and have access to all page variables and
  DOM elements.

  - For debugging, errors from the injected script will be captured and
  returned.
---

This script injects custom JavaScript into the current Safari webpage, allowing DOM manipulation and automation.

```applescript
--MCP_INPUT:script
--MCP_INPUT:scriptUrl
--MCP_INPUT:persistent

on injectJavaScript(scriptCode, scriptUrl, persistent)
  -- Validate inputs
  if (scriptCode is missing value or scriptCode is "") and (scriptUrl is missing value or scriptUrl is "") then
    return "error: Either script code or script URL must be provided."
  end if
  
  -- Set default for persistent flag
  set shouldPersist to false
  if persistent is not missing value and persistent is not "" then
    if persistent is "true" or persistent is "yes" or persistent is "1" then
      set shouldPersist to true
    end if
  end if
  
  -- Prepare the JavaScript to be injected
  set injectionJS to ""
  
  -- Handle loading external script if URL is provided
  if scriptUrl is not missing value and scriptUrl is not "" then
    set injectionJS to "
      (function() {
        // Function to load external script
        function loadScript(url) {
          return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = url;
            script.onload = resolve;
            script.onerror = () => reject(new Error(`Failed to load script: ${url}`));
            document.head.appendChild(script);
          });
        }
        
        // Load the external script
        try {
          loadScript('" & scriptUrl & "')
            .then(() => {
              console.log('External script loaded successfully: " & scriptUrl & "');
            })
            .catch(error => {
              console.error(error);
            });
        } catch(e) {
          console.error('Error loading external script:', e);
          throw e;
        }
      })();
    "
  end if
  
  -- If direct script code is provided, add it to the injection
  if scriptCode is not missing value and scriptCode is not "" then
    -- Prepare the direct script code
    set injectionJS to injectionJS & "
      (function() {
        try {
          " & scriptCode & "
        } catch(e) {
          console.error('Error executing injected script:', e);
          throw e;
        }
      })();
    "
  end if
  
  -- Add persistence code if requested
  if shouldPersist then
    set persistCode to "
      // Add persistence observer
      (function setupPersistence() {
        // Create a unique ID for our injected script to avoid duplicates
        const scriptId = 'safari-injected-script-' + Math.random().toString(36).substring(2);
        
        // Create a flag on window to track if we've already set up persistence
        if (window._safariScriptInjectionObserver) {
          console.log('Persistence observer already exists');
          return;
        }
        
        // Function to re-inject our code when DOM changes
        const reInjectOnChange = function() {
          // Store our code in sessionStorage for re-injection
          sessionStorage.setItem(scriptId, `" & my escapeForJS(injectionJS) & "`);
          
          // Set up a MutationObserver to watch for DOM changes
          const observer = new MutationObserver((mutations) => {
            // Throttle execution to avoid excessive re-runs
            if (!window._safariScriptInjectionThrottled) {
              window._safariScriptInjectionThrottled = true;
              setTimeout(() => {
                try {
                  // Re-execute our stored code
                  eval(sessionStorage.getItem(scriptId));
                  console.log('Re-injected script after DOM change');
                } catch(e) {
                  console.error('Error re-injecting script:', e);
                }
                window._safariScriptInjectionThrottled = false;
              }, 1000);
            }
          });
          
          // Start observing
          observer.observe(document.body, {
            childList: true,
            subtree: true
          });
          
          // Store the observer for reference
          window._safariScriptInjectionObserver = observer;
          console.log('Persistence observer set up for injected script');
        };
        
        // Call immediately and also set up to run when page is fully loaded
        reInjectOnChange();
        if (document.readyState === 'complete') {
          reInjectOnChange();
        } else {
          window.addEventListener('load', reInjectOnChange);
        }
      })();
    "
    
    -- Add the persistence code to our injection
    set injectionJS to injectionJS & persistCode
  end if
  
  -- Execute the prepared JavaScript in Safari
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
      set jsResult to do JavaScript injectionJS in currentTab
      
      -- Handle the result
      if jsResult is missing value then
        if scriptUrl is not missing value and scriptUrl is not "" then
          set successMsg to "Successfully injected external script from: " & scriptUrl
        else
          set successMsg to "Successfully injected JavaScript code"
        end if
        
        if shouldPersist then
          return successMsg & " with persistence enabled."
        else
          return successMsg & "."
        end if
      else
        return jsResult
      end if
    on error errMsg
      return "error: Failed to inject JavaScript - " & errMsg & ". Make sure 'Allow JavaScript from Apple Events' is enabled in Safari's Develop menu."
    end try
  end tell
end injectJavaScript

-- Helper function to escape JavaScript for embedding in another JavaScript string
on escapeForJS(jsCode)
  -- Replace backslashes first
  set escapedCode to my replaceText(jsCode, "\\", "\\\\")
  -- Replace newlines
  set escapedCode to my replaceText(escapedCode, return, "\\n")
  -- Replace quotes
  set escapedCode to my replaceText(escapedCode, "\"", "\\\"")
  -- Replace backticks
  set escapedCode to my replaceText(escapedCode, "`", "\\`")
  
  return escapedCode
end escapeForJS

-- Helper function to replace text
on replaceText(theText, searchString, replacementString)
  set AppleScript's text item delimiters to searchString
  set theTextItems to every text item of theText
  set AppleScript's text item delimiters to replacementString
  set theText to theTextItems as string
  set AppleScript's text item delimiters to ""
  return theText
end replaceText

return my injectJavaScript("--MCP_INPUT:script", "--MCP_INPUT:scriptUrl", "--MCP_INPUT:persistent")
```
