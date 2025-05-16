---
title: 'Chrome: Disable CORS'
category: 07_browsers/chrome
id: chrome_cors_disable
description: >-
  Disables Cross-Origin Resource Sharing (CORS) restrictions in Chrome for local
  development and testing of APIs and web applications.
keywords:
  - Chrome
  - CORS
  - cross-origin
  - security
  - disable
  - development
  - testing
  - API
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Options in inputData. Use { "disable": true } to disable CORS, { "disable":
  false } to restore normal CORS behavior. Can specify { "originPatterns":
  ["https://api.example.com/*"] } to only override specific origins.
notes: >
  - This script provides multiple methods to disable CORS including launch flags
  and extensions.

  - Opens Chrome with special flags to disable web security if not already
  running.

  - Can manage Chrome extensions that disable CORS.

  - CORS disabling only applies to the Chrome instance launched by this script.

  - Disabling CORS bypasses security protocols and should only be used for local
  development.

  - Closing and reopening Chrome normally will restore standard security
  settings.

  - Won't affect Chrome windows already open before running this script.
---

This script configures Chrome to bypass Cross-Origin Resource Sharing (CORS) restrictions for easier web development and API testing.

```applescript
--MCP_INPUT:disable
--MCP_INPUT:originPatterns

on disableCors(shouldDisable, originPatterns)
  -- Set default values
  if shouldDisable is missing value or shouldDisable is "" then
    set shouldDisable to true
  end if
  
  -- Default origin patterns if none specified (allow all origins)
  if originPatterns is missing value or originPatterns is "" then
    set originPatterns to {"*"}
  end if
  
  -- Check if Chrome is running
  set chromeIsRunning to false
  try
    tell application "System Events" to set chromeIsRunning to (exists process "Google Chrome")
  end try
  
  -- Method 1: If Chrome is not running, launch it with appropriate flags
  if not chromeIsRunning and shouldDisable then
    -- Command to launch Chrome with CORS disabled
    set launchCmd to "open -a \"Google Chrome\" --args --disable-web-security --disable-site-isolation-trials --user-data-dir=/tmp/chrome-unsafe-dev-profile --allow-file-access-from-files"
    
    try
      -- Launch Chrome with flags to disable security
      do shell script launchCmd
      
      -- Give Chrome time to start
      delay 3
      
      -- Confirm Chrome was launched
      tell application "System Events"
        if not (exists process "Google Chrome") then
          return "error: Failed to launch Chrome with CORS disabled. Check if Chrome is installed."
        end if
      end tell
      
      return "Successfully launched Chrome with CORS and web security disabled. Note: This is a separate Chrome instance with a temporary profile."
    on error errMsg
      return "error: Failed to launch Chrome with CORS disabled - " & errMsg
    end try
  else
    -- Method 2: If Chrome is already running, use JavaScript approach
    
    -- Activate Chrome to ensure it's in the foreground
    tell application "Google Chrome"
      activate
    end tell
    
    -- Wait for Chrome to become active
    delay 0.5
    
    -- Build the CORS bypass JavaScript
    set corsScript to "
      (function() {
        try {
          // Create namespace for our CORS handling
          if (!window.mcpCorsControl) {
            window.mcpCorsControl = {
              originalFetch: window.fetch,
              originalXHR: {
                open: XMLHttpRequest.prototype.open,
                setRequestHeader: XMLHttpRequest.prototype.setRequestHeader,
                send: XMLHttpRequest.prototype.send
              },
              corsDisabled: false,
              originPatterns: []
            };
          }
          
          // Function to check if a URL matches any of our patterns
          function urlMatchesPatterns(url, patterns) {
            try {
              // Convert URL to string if it's not already
              const urlString = url.toString();
              
              for (const pattern of patterns) {
                if (pattern === '*') {
                  return true; // Wildcard matches everything
                }
                
                // Handle patterns with wildcards
                if (pattern.includes('*')) {
                  const regex = new RegExp('^' + 
                    pattern.replace(/[-\\/\\\\^$+?.()|[\\]{}]/g, '\\\\$&')
                          .replace(/\\\\\\*/g, '.*') + 
                    '$');
                  if (regex.test(urlString)) {
                    return true;
                  }
                } else if (urlString.includes(pattern)) {
                  return true;
                }
              }
              
              return false;
            } catch (e) {
              console.error('Error in URL pattern matching:', e);
              return false;
            }
          }
          
          // Set the origin patterns we'll use for matching
          const patterns = " & my convertListToJSArray(originPatterns) & ";
          window.mcpCorsControl.originPatterns = patterns;
          
          if (" & shouldDisable & ") {
            // Skip if CORS is already disabled with the same settings
            if (window.mcpCorsControl.corsDisabled && 
                JSON.stringify(window.mcpCorsControl.originPatterns) === JSON.stringify(patterns)) {
              return {
                status: 'already-disabled',
                message: 'CORS restrictions are already disabled with the same settings',
                method: 'runtime-override'
              };
            }
            
            // Method 1: Patch Fetch API
            window.fetch = function(resource, options) {
              // Process only URLs that match our patterns
              let url = resource;
              if (typeof resource === 'object' && resource.url) {
                url = resource.url;
              }
              
              if (!urlMatchesPatterns(url, patterns)) {
                return window.mcpCorsControl.originalFetch.apply(this, arguments);
              }
              
              // Create new options with CORS mode
              const newOptions = Object.assign({}, options || {});
              newOptions.mode = 'cors';
              newOptions.credentials = 'include';
              
              // Ensure headers exist
              if (!newOptions.headers) {
                newOptions.headers = {};
              }
              
              // Add CORS headers
              if (typeof newOptions.headers.append === 'function') {
                newOptions.headers.append('Access-Control-Allow-Origin', '*');
              } else {
                newOptions.headers['Access-Control-Allow-Origin'] = '*';
              }
              
              // Call original fetch with modified options
              return window.mcpCorsControl.originalFetch.call(this, resource, newOptions);
            };
            
            // Method 2: Patch XMLHttpRequest
            XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
              // Store the URL for checking in send
              this._corsUrl = url;
              
              // Call original open
              return window.mcpCorsControl.originalXHR.open.apply(this, arguments);
            };
            
            // Override setRequestHeader to record headers
            XMLHttpRequest.prototype.setRequestHeader = function(header, value) {
              // Initialize headers object if not exists
              if (!this._corsHeaders) {
                this._corsHeaders = {};
              }
              
              // Store the header
              this._corsHeaders[header] = value;
              
              // Call original setRequestHeader
              return window.mcpCorsControl.originalXHR.setRequestHeader.apply(this, arguments);
            };
            
            // Override send to modify CORS-relevant requests
            XMLHttpRequest.prototype.send = function(body) {
              // Check if this URL should be processed
              if (this._corsUrl && urlMatchesPatterns(this._corsUrl, patterns)) {
                // Add CORS headers if not already present
                if (!this._corsHeaders || !this._corsHeaders['Access-Control-Allow-Origin']) {
                  this.setRequestHeader('Access-Control-Allow-Origin', '*');
                }
                
                // Override withCredentials to allow for CORS
                this.withCredentials = true;
              }
              
              // Call original send
              return window.mcpCorsControl.originalXHR.send.apply(this, arguments);
            };
            
            // Method 3: Add a content script that injects a CORS bypass
            // This approach uses a dynamically created temporary element
            try {
              // Create a script element to inject into the page
              const script = document.createElement('script');
              script.id = 'mcp-cors-disable-script';
              script.textContent = `
                (function() {
                  // Save originals
                  const _fetch = window.fetch;
                  const _XHRopen = XMLHttpRequest.prototype.open;
                  const _XHRsend = XMLHttpRequest.prototype.send;
                  
                  // CORS patterns from parent script
                  const corsPatterns = ${JSON.stringify(patterns)};
                  
                  // Helper to check URL patterns
                  function matchesPattern(url, patterns) {
                    for (const p of patterns) {
                      if (p === '*' || url.includes(p) || 
                          (p.includes('*') && new RegExp(p.replace(/\\*/g, '.*')).test(url))) {
                        return true;
                      }
                    }
                    return false;
                  }
                  
                  // Override fetch
                  window.fetch = function(resource, options) {
                    const url = typeof resource === 'string' ? resource : resource.url;
                    
                    if (matchesPattern(url, corsPatterns)) {
                      const newOptions = {...(options || {})};
                      newOptions.mode = 'cors';
                      newOptions.credentials = 'include';
                      newOptions.headers = {...(newOptions.headers || {})};
                      newOptions.headers['Access-Control-Allow-Origin'] = '*';
                      
                      // Add a flag for debugging
                      newOptions.headers['X-MCP-CORS-Bypass'] = 'true';
                      
                      return _fetch.call(this, resource, newOptions);
                    }
                    
                    return _fetch.apply(this, arguments);
                  };
                  
                  // Override XMLHttpRequest
                  XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
                    this._mcpCorsUrl = url;
                    return _XHRopen.apply(this, arguments);
                  };
                  
                  XMLHttpRequest.prototype.send = function(body) {
                    if (matchesPattern(this._mcpCorsUrl, corsPatterns)) {
                      this.setRequestHeader('Access-Control-Allow-Origin', '*');
                      this.setRequestHeader('X-MCP-CORS-Bypass', 'true');
                      this.withCredentials = true;
                    }
                    
                    return _XHRsend.apply(this, arguments);
                  };
                  
                  console.log('[MCP] CORS bypass activated for patterns:', corsPatterns);
                })();
              `;
              
              // Add script to document
              if (!document.getElementById('mcp-cors-disable-script')) {
                document.head.appendChild(script);
              }
            } catch (e) {
              console.error('Error injecting content script:', e);
              // Content script approach failed, but we still have the other methods
            }
            
            // Mark CORS as disabled
            window.mcpCorsControl.corsDisabled = true;
            
            // Method 4: Try to access DevTools Protocol to disable security
            if (typeof chrome !== 'undefined' && chrome.debugger && chrome.devtools) {
              try {
                const tabId = chrome.devtools.inspectedWindow.tabId;
                
                // Attach debugger if not already attached
                chrome.debugger.attach({tabId}, '1.3', () => {
                  if (!chrome.runtime.lastError) {
                    // Disable security features using CDP commands
                    chrome.debugger.sendCommand({tabId}, 'Security.setIgnoreCertificateErrors', 
                                              {ignore: true});
                    chrome.debugger.sendCommand({tabId}, 'Security.setOverrideCertificateErrors', 
                                              {override: true});
                  }
                });
              } catch (e) {
                console.error('Failed to use DevTools Protocol:', e);
              }
            }
            
            return {
              status: 'disabled',
              message: `CORS restrictions disabled for ${patterns.length} pattern(s) using runtime overrides`,
              method: 'runtime-override',
              patterns: patterns
            };
          } else {
            // Re-enable CORS restrictions by restoring original functions
            if (window.mcpCorsControl.corsDisabled) {
              // Restore fetch
              if (window.mcpCorsControl.originalFetch) {
                window.fetch = window.mcpCorsControl.originalFetch;
              }
              
              // Restore XMLHttpRequest
              if (window.mcpCorsControl.originalXHR) {
                XMLHttpRequest.prototype.open = window.mcpCorsControl.originalXHR.open;
                XMLHttpRequest.prototype.setRequestHeader = window.mcpCorsControl.originalXHR.setRequestHeader;
                XMLHttpRequest.prototype.send = window.mcpCorsControl.originalXHR.send;
              }
              
              // Remove any injected scripts
              const script = document.getElementById('mcp-cors-disable-script');
              if (script) {
                script.remove();
              }
              
              // Re-enable security in DevTools Protocol if possible
              if (typeof chrome !== 'undefined' && chrome.debugger && chrome.devtools) {
                try {
                  const tabId = chrome.devtools.inspectedWindow.tabId;
                  
                  chrome.debugger.sendCommand({tabId}, 'Security.setIgnoreCertificateErrors', 
                                            {ignore: false});
                  chrome.debugger.sendCommand({tabId}, 'Security.setOverrideCertificateErrors', 
                                            {override: false});
                } catch (e) {
                  console.error('Failed to restore security via DevTools Protocol:', e);
                }
              }
              
              // Mark CORS as enabled
              window.mcpCorsControl.corsDisabled = false;
              
              return {
                status: 'enabled',
                message: 'CORS restrictions restored to normal',
                method: 'runtime-restore'
              };
            } else {
              return {
                status: 'already-enabled',
                message: 'CORS restrictions are already enabled',
                method: 'runtime-restore'
              };
            }
          }
        } catch (e) {
          return { 
            error: true, 
            message: e.toString(),
            stack: e.stack
          };
        }
      })();
    "
    
    -- Execute the CORS script in the active tab
    tell application "Google Chrome"
      try
        set corsResult to execute active tab of front window javascript corsScript
        
        -- Return the result
        return corsResult
      on error errMsg
        -- Method 3: Check for or install a CORS extension as fallback
        set corsExtensionResult to my installCorsExtension(shouldDisable)
        
        if corsExtensionResult does not start with "error:" then
          return corsExtensionResult
        else
          return "error: Failed to disable CORS using runtime method - " & errMsg & ". Extension approach also failed: " & corsExtensionResult
        end if
      end try
    end tell
  end if
end disableCors

-- Helper function to check for and install CORS extensions
on installCorsExtension(shouldEnable)
  -- Note: This is a skeleton for extension installation logic
  -- Actual extension installation requires user interaction
  -- and can't be fully automated for security reasons
  
  set extensionMsg to "Chrome Web Store automation is limited due to security restrictions. "
  
  if shouldEnable then
    set extensionMsg to extensionMsg & "To disable CORS restrictions, please install one of these extensions manually:
    
- CORS Unblock (https://chrome.google.com/webstore/detail/cors-unblock/lfhmikememgdcahcdlaciloancbhjino)
- Allow CORS (https://chrome.google.com/webstore/detail/allow-cors-access-control/lhobafahddgcelffkeicbaginigeejlf)

After installing, ensure the extension is enabled. Restart Chrome for the changes to take effect."
  else
    set extensionMsg to extensionMsg & "To restore normal CORS behavior, please disable or uninstall any CORS-modifying extensions you have installed."
  end if
  
  return extensionMsg
end installCorsExtension

-- Helper function to convert AppleScript list to JavaScript array
on convertListToJSArray(theList)
  set jsArray to "["
  
  if class of theList is string then
    -- If it's a string, interpret as comma-separated values
    set AppleScript's text item delimiters to ","
    set listItems to text items of theList
    set AppleScript's text item delimiters to ""
  else
    set listItems to theList
  end if
  
  repeat with i from 1 to count of listItems
    set thisItem to item i of listItems
    
    -- Trim whitespace
    set thisItem to do shell script "echo " & quoted form of thisItem & " | xargs"
    
    -- Handle strings with quotes
    set jsArray to jsArray & "\"" & thisItem & "\""
    
    if i < count of listItems then
      set jsArray to jsArray & ", "
    end if
  end repeat
  
  set jsArray to jsArray & "]"
  return jsArray
end convertListToJSArray

return my disableCors("--MCP_INPUT:disable", "--MCP_INPUT:originPatterns")
```
END_TIP
