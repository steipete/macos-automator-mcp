---
title: 'Chrome: Intercept Network Requests'
category: 07_browsers
id: chrome_intercept_network_requests
description: >-
  Intercepts and modifies Chrome network requests and responses for testing,
  debugging, and mocking API responses without changing server code.
keywords:
  - Chrome
  - intercept
  - network
  - requests
  - responses
  - mock
  - API
  - debugging
  - testing
  - DevTools
language: applescript
isComplex: true
argumentsPrompt: >-
  Interception rules in inputData. For example: { "interceptRules": [{
  "urlPattern": "api.example.com/users", "responseBody": { "users": [{ "id": 1,
  "name": "Test User" }] }, "responseCode": 200, "contentType":
  "application/json" }] }. Can also use { "recordMode": true } to monitor
  requests without modifying them.
returnValueType: json
notes: >
  - Google Chrome must be running with at least one window and tab open.

  - Opens DevTools (if not already open) and configures request interception.

  - Can mock API responses by URL pattern with custom status codes, headers, and
  response bodies.

  - Supports monitoring mode to record network requests without modification.

  - Works with both REST and GraphQL APIs.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.

  - Interception only works while DevTools remains open.
---

This script intercepts and modifies Chrome network requests for testing, debugging, and mocking API responses.

```applescript
--MCP_INPUT:interceptRules
--MCP_INPUT:recordMode

on interceptNetworkRequests(interceptRules, recordMode)
  -- Set default values if not provided
  if recordMode is missing value or recordMode is "" then
    set recordMode to false
  end if
  
  -- Make sure Chrome is running
  tell application "Google Chrome"
    if not running then
      return "{\"error\": true, \"message\": \"Google Chrome is not running.\"}"
    end if
    
    if (count of windows) is 0 then
      return "{\"error\": true, \"message\": \"No Chrome windows open.\"}"
    end if
    
    if (count of tabs of front window) is 0 then
      return "{\"error\": true, \"message\": \"No tabs in front Chrome window.\"}"
    end if
    
    -- Activate Chrome to ensure it's in the foreground
    activate
  end tell
  
  -- Open DevTools with network panel
  tell application "System Events"
    tell process "Google Chrome"
      set frontmost to true
      delay 0.3
      
      -- Check if DevTools is already open
      set devToolsOpen to false
      repeat with w in windows
        if description of w contains "Developer Tools" then
          set devToolsOpen to true
          exit repeat
        end if
      end repeat
      
      -- Open DevTools if not already open
      if not devToolsOpen then
        key code 34 using {command down, option down} -- Option+Command+I
        delay 0.7
      end if
      
      -- Switch to Network panel
      key code 45 using {command down, option down} -- Option+Command+N
      delay 0.5
    end tell
  end tell
  
  -- Generate a unique ID for this interception session
  set sessionId to "mcpNetworkIntercept_" & (random number from 100000 to 999999) as string
  
  -- Check if we are in record-only mode
  set isRecordMode to recordMode
  
  -- Prepare the JavaScript code for network interception
  set interceptScript to "
    (function() {
      try {
        // Create a namespace for our interception code
        if (!window.mcpNetworkInterception) {
          window.mcpNetworkInterception = {
            interceptors: new Map(),
            records: [],
            activeSession: null,
            isMonitoring: false
          };
        }
        
        // Clear any existing session with the same ID
        if (window.mcpNetworkInterception.activeSession === '" & sessionId & "') {
          console.log('Stopping previous interception session with same ID');
          window.mcpNetworkInterception.interceptors.clear();
          window.mcpNetworkInterception.records = [];
          window.mcpNetworkInterception.activeSession = null;
          window.mcpNetworkInterception.isMonitoring = false;
        }
        
        // Set up the new session
        window.mcpNetworkInterception.activeSession = '" & sessionId & "';
        window.mcpNetworkInterception.isMonitoring = " & isRecordMode & ";
        
        // Function to implement request interception using different methods
        async function setupNetworkInterception() {
          let setupMethod = 'none';
          
          // Method 1: DevTools Protocol via chrome.debugger API
          // This is the most powerful but requires being in the right DevTools context
          if (typeof chrome !== 'undefined' && chrome.debugger && chrome.devtools) {
            try {
              const tabId = chrome.devtools.inspectedWindow.tabId;
              
              // First detach any existing debugger sessions
              await new Promise(resolve => {
                try {
                  chrome.debugger.detach({tabId}, resolve);
                } catch(e) {
                  resolve();
                }
              });
              
              // Attach debugger
              await new Promise((resolve, reject) => {
                chrome.debugger.attach({tabId}, '1.3', result => {
                  if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                  } else {
                    resolve();
                  }
                });
              });
              
              // Enable network interception
              await new Promise((resolve, reject) => {
                chrome.debugger.sendCommand({tabId}, 'Network.enable', {}, result => {
                  if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                  } else {
                    resolve();
                  }
                });
              });
              
              // Set up request/response interception
              await new Promise((resolve, reject) => {
                chrome.debugger.sendCommand({tabId}, 'Network.setRequestInterception', {
                  patterns: [{ urlPattern: '*' }]
                }, result => {
                  if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                  } else {
                    resolve();
                  }
                });
              });
              
              // Handle interception events
              chrome.debugger.onEvent.addListener((source, method, params) => {
                if (source.tabId !== tabId) return;
                
                if (method === 'Network.requestIntercepted') {
                  const interceptedRequest = params;
                  const requestId = interceptedRequest.interceptionId;
                  const url = interceptedRequest.request.url;
                  
                  // Record the request for monitoring
                  if (window.mcpNetworkInterception.isMonitoring) {
                    window.mcpNetworkInterception.records.push({
                      url: url,
                      method: interceptedRequest.request.method,
                      requestHeaders: interceptedRequest.request.headers,
                      requestBody: interceptedRequest.request.postData,
                      timestamp: Date.now()
                    });
                  }
                  
                  // Check if we have an interceptor for this URL
                  let shouldIntercept = false;
                  let mockResponse = null;
                  
                  window.mcpNetworkInterception.interceptors.forEach((interceptor) => {
                    if (url.match(interceptor.urlPattern)) {
                      shouldIntercept = true;
                      mockResponse = interceptor;
                    }
                  });
                  
                  if (shouldIntercept && mockResponse) {
                    // Create mock response
                    const responseHeaders = [];
                    if (mockResponse.contentType) {
                      responseHeaders.push({
                        name: 'Content-Type',
                        value: mockResponse.contentType
                      });
                    }
                    
                    // Add any custom headers
                    if (mockResponse.responseHeaders) {
                      Object.keys(mockResponse.responseHeaders).forEach(name => {
                        responseHeaders.push({
                          name: name,
                          value: mockResponse.responseHeaders[name]
                        });
                      });
                    }
                    
                    // Convert response body to string if it's an object
                    let responseBody = mockResponse.responseBody;
                    if (typeof responseBody === 'object') {
                      responseBody = JSON.stringify(responseBody);
                    }
                    
                    // Intercept with mock response
                    chrome.debugger.sendCommand({tabId}, 'Network.continueInterceptedRequest', {
                      interceptionId: requestId,
                      rawResponse: btoa(unescape(encodeURIComponent(
                        `HTTP/1.1 ${mockResponse.responseCode || 200} OK\\r\\n` +
                        responseHeaders.map(h => `${h.name}: ${h.value}`).join('\\r\\n') +
                        '\\r\\n\\r\\n' +
                        (responseBody || '')
                      )))
                    });
                  } else {
                    // Continue with original request
                    chrome.debugger.sendCommand({tabId}, 'Network.continueInterceptedRequest', {
                      interceptionId: requestId
                    });
                  }
                }
              });
              
              setupMethod = 'chrome.debugger';
            } catch (e) {
              console.error('Failed to set up interception via chrome.debugger:', e);
              // Fall through to next method
            }
          }
          
          // Method 2: Service Worker based interception
          // This requires creating a service worker if not in devtools context
          if (setupMethod === 'none' && typeof navigator !== 'undefined' && navigator.serviceWorker) {
            try {
              // Check if service worker is already registered
              const registrations = await navigator.serviceWorker.getRegistrations();
              let swRegistration = registrations.find(r => 
                r.active && r.active.scriptURL.includes('mcp-network-interceptor'));
              
              if (!swRegistration) {
                // Create a dynamic service worker
                const swBlob = new Blob([`
                  const CACHE_NAME = 'mcp-network-interceptor-cache';
                  let interceptRules = [];
                  let recordedRequests = [];
                  let isMonitoringOnly = false;
                  let sessionId = '';
                  
                  // Listen for messages from the page
                  self.addEventListener('message', event => {
                    if (event.data.action === 'setInterceptRules') {
                      interceptRules = event.data.rules || [];
                      recordedRequests = [];
                      isMonitoringOnly = event.data.isMonitoring || false;
                      sessionId = event.data.sessionId || '';
                      
                      // Respond to confirm rules received
                      event.source.postMessage({
                        action: 'rulesSet',
                        count: interceptRules.length,
                        sessionId: sessionId
                      });
                    } else if (event.data.action === 'getRecordedRequests') {
                      // Send back recorded requests when asked
                      event.source.postMessage({
                        action: 'recordedRequests',
                        requests: recordedRequests,
                        sessionId: event.data.sessionId
                      });
                    }
                  });
                  
                  // Intercept fetch requests
                  self.addEventListener('fetch', event => {
                    const url = event.request.url;
                    
                    // Record this request if monitoring is enabled
                    if (isMonitoringOnly) {
                      // Clone the request to read its content
                      event.request.clone().text().then(body => {
                        recordedRequests.push({
                          url: url,
                          method: event.request.method,
                          headers: Array.from(event.request.headers.entries()),
                          body: body,
                          timestamp: Date.now()
                        });
                      }).catch(err => {
                        console.error('Failed to record request:', err);
                      });
                      
                      // Continue with original request
                      return;
                    }
                    
                    // Check if this URL matches any intercept rules
                    const matchingRule = interceptRules.find(rule => {
                      if (typeof rule.urlPattern === 'string') {
                        return url.includes(rule.urlPattern);
                      } else if (rule.urlPattern instanceof RegExp) {
                        return rule.urlPattern.test(url);
                      }
                      return false;
                    });
                    
                    if (matchingRule) {
                      // Record the intercepted request
                      event.request.clone().text().then(body => {
                        recordedRequests.push({
                          url: url,
                          method: event.request.method,
                          headers: Array.from(event.request.headers.entries()),
                          body: body,
                          intercepted: true,
                          timestamp: Date.now()
                        });
                      }).catch(err => {
                        console.error('Failed to record intercepted request:', err);
                      });
                      
                      // Create mock response
                      let responseBody = matchingRule.responseBody;
                      if (typeof responseBody === 'object') {
                        responseBody = JSON.stringify(responseBody);
                      }
                      
                      const headers = new Headers();
                      headers.append('Content-Type', matchingRule.contentType || 'application/json');
                      
                      // Add any custom headers
                      if (matchingRule.responseHeaders) {
                        Object.keys(matchingRule.responseHeaders).forEach(name => {
                          headers.append(name, matchingRule.responseHeaders[name]);
                        });
                      }
                      
                      const response = new Response(responseBody, {
                        status: matchingRule.responseCode || 200,
                        statusText: 'OK',
                        headers: headers
                      });
                      
                      event.respondWith(response);
                    }
                  });
                  
                  // Service worker installation and activation
                  self.addEventListener('install', event => {
                    self.skipWaiting();
                  });
                  
                  self.addEventListener('activate', event => {
                    event.waitUntil(clients.claim());
                  });
                `], {type: 'application/javascript'});
                
                const swUrl = URL.createObjectURL(swBlob);
                
                // Register the service worker
                swRegistration = await navigator.serviceWorker.register(swUrl, {
                  scope: './'
                });
                
                // Wait for the service worker to be active
                if (swRegistration.installing) {
                  await new Promise(resolve => {
                    const worker = swRegistration.installing;
                    worker.addEventListener('statechange', () => {
                      if (worker.state === 'activated') {
                        resolve();
                      }
                    });
                  });
                }
                
                // Revoke the blob URL as it's no longer needed
                URL.revokeObjectURL(swUrl);
              }
              
              // Send the intercept rules to the service worker
              if (navigator.serviceWorker.controller) {
                navigator.serviceWorker.controller.postMessage({
                  action: 'setInterceptRules',
                  rules: " & (if interceptRules is missing value or interceptRules is "" then "[]" else interceptRules) & ",
                  isMonitoring: " & isRecordMode & ",
                  sessionId: '" & sessionId & "'
                });
                
                // Listen for messages from the service worker
                navigator.serviceWorker.addEventListener('message', event => {
                  if (event.data.action === 'rulesSet' && event.data.sessionId === '" & sessionId & "') {
                    console.log(`Service worker received ${event.data.count} intercept rules`);
                  } else if (event.data.action === 'recordedRequests' && event.data.sessionId === '" & sessionId & "') {
                    // Store recorded requests
                    window.mcpNetworkInterception.records = [
                      ...window.mcpNetworkInterception.records,
                      ...event.data.requests
                    ];
                  }
                });
                
                setupMethod = 'serviceWorker';
              }
            } catch (e) {
              console.error('Failed to set up interception via Service Worker:', e);
              // Fall through to next method
            }
          }
          
          // Method 3: Fetch/XHR monkey patching
          // This is less reliable but works in more contexts
          if (setupMethod === 'none') {
            try {
              // Store original fetch and XHR methods
              const originalFetch = window.fetch;
              const originalXHROpen = XMLHttpRequest.prototype.open;
              const originalXHRSend = XMLHttpRequest.prototype.send;
              
              // Intercept fetch API
              window.fetch = async function(resource, options) {
                let url = resource;
                if (typeof resource === 'object' && resource.url) {
                  url = resource.url;
                }
                
                // For monitoring mode, just record the request
                if (window.mcpNetworkInterception.isMonitoring) {
                  // Clone request to extract body if available
                  const request = resource instanceof Request ? resource : new Request(resource, options);
                  let requestBody = '';
                  
                  try {
                    const clonedRequest = request.clone();
                    if (['POST', 'PUT', 'PATCH'].includes(request.method)) {
                      requestBody = await clonedRequest.text();
                    }
                  } catch (e) {
                    console.error('Failed to extract request body:', e);
                  }
                  
                  window.mcpNetworkInterception.records.push({
                    url: url.toString(),
                    method: request.method,
                    requestHeaders: request.headers ? Array.from(request.headers.entries()) : [],
                    requestBody: requestBody,
                    timestamp: Date.now()
                  });
                  
                  // Proceed with original fetch
                  return originalFetch.apply(this, arguments);
                }
                
                // Check for matching intercept rule
                let matchingRule = null;
                window.mcpNetworkInterception.interceptors.forEach((interceptor) => {
                  if (url.toString().match(interceptor.urlPattern)) {
                    matchingRule = interceptor;
                  }
                });
                
                if (matchingRule) {
                  // Record the intercepted request
                  window.mcpNetworkInterception.records.push({
                    url: url.toString(),
                    method: options?.method || 'GET',
                    requestHeaders: options?.headers || {},
                    requestBody: options?.body || '',
                    intercepted: true,
                    timestamp: Date.now()
                  });
                  
                  // Create mock response body
                  let responseBody = matchingRule.responseBody;
                  if (typeof responseBody === 'object') {
                    responseBody = JSON.stringify(responseBody);
                  }
                  
                  // Create headers
                  const headers = new Headers();
                  headers.append('Content-Type', matchingRule.contentType || 'application/json');
                  
                  // Add any custom headers
                  if (matchingRule.responseHeaders) {
                    Object.keys(matchingRule.responseHeaders).forEach(name => {
                      headers.append(name, matchingRule.responseHeaders[name]);
                    });
                  }
                  
                  // Return mock response
                  return new Response(responseBody, {
                    status: matchingRule.responseCode || 200,
                    statusText: 'OK',
                    headers: headers
                  });
                }
                
                // If no matching rule, proceed with original fetch
                return originalFetch.apply(this, arguments);
              };
              
              // Intercept XMLHttpRequest
              XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
                this._mcpMethod = method;
                this._mcpUrl = url;
                this._mcpHeaders = {};
                
                // Check if this request should be intercepted
                this._mcpShouldIntercept = false;
                this._mcpMatchingRule = null;
                
                window.mcpNetworkInterception.interceptors.forEach((interceptor) => {
                  if (url.toString().match(interceptor.urlPattern)) {
                    this._mcpShouldIntercept = true;
                    this._mcpMatchingRule = interceptor;
                  }
                });
                
                // Call original open
                return originalXHROpen.apply(this, arguments);
              };
              
              // Store request headers
              const originalXHRSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
              XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
                if (this._mcpHeaders) {
                  this._mcpHeaders[name] = value;
                }
                return originalXHRSetRequestHeader.apply(this, arguments);
              };
              
              // Intercept send method
              XMLHttpRequest.prototype.send = function(body) {
                // For monitoring mode, just record the request
                if (window.mcpNetworkInterception.isMonitoring) {
                  window.mcpNetworkInterception.records.push({
                    url: this._mcpUrl,
                    method: this._mcpMethod,
                    requestHeaders: this._mcpHeaders || {},
                    requestBody: body || '',
                    timestamp: Date.now()
                  });
                  
                  // Proceed with original send
                  return originalXHRSend.apply(this, arguments);
                }
                
                // Check if this request should be intercepted
                if (this._mcpShouldIntercept && this._mcpMatchingRule) {
                  const rule = this._mcpMatchingRule;
                  
                  // Record the intercepted request
                  window.mcpNetworkInterception.records.push({
                    url: this._mcpUrl,
                    method: this._mcpMethod,
                    requestHeaders: this._mcpHeaders || {},
                    requestBody: body || '',
                    intercepted: true,
                    timestamp: Date.now()
                  });
                  
                  // Create mock response
                  let responseBody = rule.responseBody;
                  if (typeof responseBody === 'object') {
                    responseBody = JSON.stringify(responseBody);
                  }
                  
                  // Create a timer to simulate network delay
                  setTimeout(() => {
                    // Set response headers
                    Object.defineProperty(this, 'status', { value: rule.responseCode || 200 });
                    Object.defineProperty(this, 'statusText', { value: 'OK' });
                    Object.defineProperty(this, 'responseText', { value: responseBody });
                    Object.defineProperty(this, 'response', { value: responseBody });
                    
                    // Set default content type
                    this.setRequestHeader('Content-Type', rule.contentType || 'application/json');
                    
                    // Add any custom response headers
                    if (rule.responseHeaders) {
                      Object.keys(rule.responseHeaders).forEach(name => {
                        this.setRequestHeader(name, rule.responseHeaders[name]);
                      });
                    }
                    
                    // Trigger load events
                    const loadEvent = new Event('load');
                    this.dispatchEvent(loadEvent);
                    
                    if (this.onload) {
                      this.onload(loadEvent);
                    }
                    
                    const readyStateChangeEvent = new Event('readystatechange');
                    Object.defineProperty(this, 'readyState', { value: 4 });
                    this.dispatchEvent(readyStateChangeEvent);
                    
                    if (this.onreadystatechange) {
                      this.onreadystatechange(readyStateChangeEvent);
                    }
                  }, 10); // Small delay to simulate network
                  
                  // Don't call original send
                  return;
                }
                
                // If no interception, proceed with original send
                return originalXHRSend.apply(this, arguments);
              };
              
              setupMethod = 'monkeyPatch';
            } catch (e) {
              console.error('Failed to set up interception via monkey patching:', e);
            }
          }
          
          return { setupMethod };
        }
        
        // Register the intercept rules
        const interceptRules = " & (if interceptRules is missing value or interceptRules is "" then "[]" else interceptRules) & ";
        
        // Process and store the intercept rules
        if (Array.isArray(interceptRules)) {
          interceptRules.forEach((rule, index) => {
            if (!rule.urlPattern) {
              console.error(`Intercept rule at index ${index} missing urlPattern`);
              return;
            }
            
            // Convert string patterns to RegExp for more efficient matching
            let pattern = rule.urlPattern;
            if (typeof pattern === 'string') {
              // Escape special regex characters but keep * as wildcard
              pattern = pattern.replace(/[.+?^${}()|[\\]\\/]/g, '\\\\$&')
                              .replace(/\\\\\\*/g, '.*');
              pattern = new RegExp(pattern);
            }
            
            // Store the rule with processed pattern
            const processedRule = {
              ...rule,
              urlPattern: pattern
            };
            
            window.mcpNetworkInterception.interceptors.set(index, processedRule);
          });
        }
        
        // Start the interception with chosen method
        return setupNetworkInterception().then(result => {
          return {
            success: true,
            message: `Network interception set up using ${result.setupMethod}`,
            sessionId: '" & sessionId & "',
            interceptRuleCount: window.mcpNetworkInterception.interceptors.size,
            recordMode: " & isRecordMode & "
          };
        }).catch(error => {
          return {
            error: true,
            message: `Failed to set up network interception: ${error.message}`,
            sessionId: '" & sessionId & "'
          };
        });
      } catch (e) {
        return { 
          error: true, 
          message: e.toString(),
          stack: e.stack
        };
      }
    })();
  "
  
  -- Execute the script
  tell application "Google Chrome"
    try
      set initResult to execute active tab of front window javascript interceptScript
      
      -- Check for session ID to determine if we need to wait for results
      if initResult contains sessionId then
        -- Poll for the results with timeout
        set maxAttempts to 30
        set attemptCounter to 0
        
        -- Create a script to retrieve the current interception status
        set statusScript to "
          (function() {
            if (window.mcpNetworkInterception) {
              return {
                activeSession: window.mcpNetworkInterception.activeSession,
                isMonitoring: window.mcpNetworkInterception.isMonitoring,
                interceptorCount: window.mcpNetworkInterception.interceptors.size,
                recordCount: window.mcpNetworkInterception.records.length,
                records: window.mcpNetworkInterception.records
              };
            } else {
              return { error: true, message: 'Network interception not initialized' };
            }
          })();
        "
        
        repeat
          delay 0.5
          set attemptCounter to attemptCounter + 1
          set statusCheck to execute active tab of front window javascript statusScript
          
          -- If we successfully initialized, return the status
          if statusCheck contains "activeSession" and statusCheck does not contain "error" then
            if isRecordMode then
              -- In record mode, we want to return the current status
              return statusCheck
            else
              -- In intercept mode, just return confirmation
              return "{\"success\": true, \"message\": \"Network interception configured successfully\", \"sessionId\": \"" & sessionId & "\"}"
            end if
          end if
          
          -- Timeout check
          if attemptCounter ≥ maxAttempts then
            return "{\"error\": true, \"message\": \"Timed out waiting for network interception to initialize.\"}"
          end if
        end repeat
      else
        -- Return the immediate result if it doesn't contain session ID (likely an error)
        return initResult
      end if
    on error errMsg
      return "{\"error\": true, \"message\": \"" & my escapeJSString(errMsg) & "\"}"
    end try
  end tell
end interceptNetworkRequests

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

return my interceptNetworkRequests("--MCP_INPUT:interceptRules", "--MCP_INPUT:recordMode")
```
END_TIP
