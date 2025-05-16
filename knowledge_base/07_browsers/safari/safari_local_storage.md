---
title: "Safari: Local Storage Management"
category: "05_web_browsers"
id: safari_local_storage
description: "Manages browser storage in Safari, including localStorage, sessionStorage, cookies, and IndexedDB operations."
keywords: ["Safari", "localStorage", "sessionStorage", "cookies", "web storage", "web development", "IndexedDB", "browser storage"]
language: applescript
isComplex: true
argumentsPrompt: "Storage operation as 'operation' ('get', 'set', 'remove', 'clear'), storage type as 'storageType' ('local', 'session', 'cookie', 'indexedDB'), key name as 'key', and value as 'value' in inputData."
notes: |
  - Safari must be running with at least one open tab.
  - "Allow JavaScript from Apple Events" must be enabled in Safari's Develop menu.
  - The script supports four types of web storage:
    - localStorage: Persistent storage without expiration
    - sessionStorage: Storage that lasts until the tab is closed
    - cookies: Traditional browser cookies
    - indexedDB: More advanced object storage (limited operations supported)
  - Available operations:
    - 'get': Retrieves a value by key (or all values if no key specified)
    - 'set': Stores a key-value pair
    - 'remove': Deletes a specific key
    - 'clear': Removes all data from the specified storage type
  - For cookies, additional parameters are supported:
    - 'domain': Domain for the cookie (defaults to current domain)
    - 'path': Path for the cookie (defaults to '/')
    - 'expires': Expiration date in days (defaults to session)
    - 'secure': Whether the cookie should only be sent over HTTPS
  - IndexedDB operations are limited to basic read/write with a default object store.
---

This script manages browser storage mechanisms in Safari, including localStorage, sessionStorage, cookies, and IndexedDB.

```applescript
--MCP_INPUT:operation
--MCP_INPUT:storageType
--MCP_INPUT:key
--MCP_INPUT:value
--MCP_INPUT:domain
--MCP_INPUT:path
--MCP_INPUT:expires
--MCP_INPUT:secure

on manageBrowserStorage(operation, storageType, storageKey, storageValue, domain, path, expires, secure)
  -- Validate operation
  if operation is missing value or operation is "" then
    return "error: Operation not provided. Must be 'get', 'set', 'remove', or 'clear'."
  end if
  
  -- Validate storage type
  if storageType is missing value or storageType is "" then
    return "error: Storage type not provided. Must be 'local', 'session', 'cookie', or 'indexedDB'."
  end if
  
  -- Convert to lowercase for case-insensitive comparison
  set operation to my toLowerCase(operation)
  set storageType to my toLowerCase(storageType)
  
  -- Validate operation and storage type values
  if operation is not "get" and operation is not "set" and operation is not "remove" and operation is not "clear" then
    return "error: Invalid operation. Must be 'get', 'set', 'remove', or 'clear'."
  end if
  
  if storageType is not "local" and storageType is not "session" and storageType is not "cookie" and storageType is not "indexeddb" then
    return "error: Invalid storage type. Must be 'local', 'session', 'cookie', or 'indexedDB'."
  end if
  
  -- Validate operation-specific required parameters
  if operation is "set" and (storageKey is missing value or storageKey is "") then
    return "error: Key parameter is required for 'set' operation."
  end if
  
  if operation is "remove" and (storageKey is missing value or storageKey is "") then
    return "error: Key parameter is required for 'remove' operation."
  end if
  
  -- Prepare cookie parameters as JavaScript object properties
  set cookieParams to ""
  if storageType is "cookie" then
    if domain is not missing value and domain is not "" then
      set cookieParams to cookieParams & "domain: '" & domain & "', "
    end if
    
    if path is not missing value and path is not "" then
      set cookieParams to cookieParams & "path: '" & path & "', "
    else
      set cookieParams to cookieParams & "path: '/', "
    end if
    
    if expires is not missing value and expires is not "" then
      set cookieParams to cookieParams & "expires: " & expires & ", "
    end if
    
    if secure is not missing value and secure is not "" then
      if secure is "true" or secure is "yes" or secure is "1" then
        set cookieParams to cookieParams & "secure: true, "
      end if
    end if
  end if
  
  -- Construct JavaScript for browser storage operations
  set storageJS to "
    (function() {
      // Helper function to safely serialize objects/arrays to JSON
      function safeStringify(value) {
        try {
          if (typeof value === 'undefined') return 'undefined';
          if (value === null) return 'null';
          if (typeof value === 'function') return value.toString();
          return JSON.stringify(value);
        } catch (error) {
          return String(value);
        }
      }
      
      // Helper function to parse string values that might be JSON
      function safeParse(value) {
        if (typeof value !== 'string') return value;
        try {
          return JSON.parse(value);
        } catch (e) {
          return value;
        }
      }
      
      // Storage type and operations
      const storageType = '" & storageType & "';
      const operation = '" & operation & "';
      const key = " & my jsStringOrNull(storageKey) & ";
      let value = " & my jsValueOrNull(storageValue) & ";
      
      // Results object
      const result = {
        operation: operation,
        storageType: storageType,
        success: false
      };
      
      try {
        // Handle operations based on storage type
        switch (storageType) {
          case 'local':
            // localStorage operations
            if (operation === 'get') {
              if (key) {
                result.key = key;
                result.value = safeParse(localStorage.getItem(key));
                if (result.value === null) {
                  result.message = `Key '${key}' not found in localStorage`;
                } else {
                  result.message = `Retrieved value for key '${key}' from localStorage`;
                  result.success = true;
                }
              } else {
                // Get all localStorage items
                const allItems = {};
                for (let i = 0; i < localStorage.length; i++) {
                  const itemKey = localStorage.key(i);
                  allItems[itemKey] = safeParse(localStorage.getItem(itemKey));
                }
                result.items = allItems;
                result.count = localStorage.length;
                result.message = `Retrieved all ${localStorage.length} items from localStorage`;
                result.success = true;
              }
            } else if (operation === 'set') {
              // For objects and arrays, stringify before storing
              if (typeof value === 'object' && value !== null) {
                value = JSON.stringify(value);
              }
              localStorage.setItem(key, value);
              result.key = key;
              result.value = value;
              result.message = `Successfully set localStorage key '${key}'`;
              result.success = true;
            } else if (operation === 'remove') {
              localStorage.removeItem(key);
              result.key = key;
              result.message = `Removed key '${key}' from localStorage`;
              result.success = true;
            } else if (operation === 'clear') {
              const itemCount = localStorage.length;
              localStorage.clear();
              result.message = `Cleared ${itemCount} items from localStorage`;
              result.success = true;
            }
            break;
            
          case 'session':
            // sessionStorage operations - same pattern as localStorage
            if (operation === 'get') {
              if (key) {
                result.key = key;
                result.value = safeParse(sessionStorage.getItem(key));
                if (result.value === null) {
                  result.message = `Key '${key}' not found in sessionStorage`;
                } else {
                  result.message = `Retrieved value for key '${key}' from sessionStorage`;
                  result.success = true;
                }
              } else {
                // Get all sessionStorage items
                const allItems = {};
                for (let i = 0; i < sessionStorage.length; i++) {
                  const itemKey = sessionStorage.key(i);
                  allItems[itemKey] = safeParse(sessionStorage.getItem(itemKey));
                }
                result.items = allItems;
                result.count = sessionStorage.length;
                result.message = `Retrieved all ${sessionStorage.length} items from sessionStorage`;
                result.success = true;
              }
            } else if (operation === 'set') {
              // For objects and arrays, stringify before storing
              if (typeof value === 'object' && value !== null) {
                value = JSON.stringify(value);
              }
              sessionStorage.setItem(key, value);
              result.key = key;
              result.value = value;
              result.message = `Successfully set sessionStorage key '${key}'`;
              result.success = true;
            } else if (operation === 'remove') {
              sessionStorage.removeItem(key);
              result.key = key;
              result.message = `Removed key '${key}' from sessionStorage`;
              result.success = true;
            } else if (operation === 'clear') {
              const itemCount = sessionStorage.length;
              sessionStorage.clear();
              result.message = `Cleared ${itemCount} items from sessionStorage`;
              result.success = true;
            }
            break;
            
          case 'cookie':
            // Cookie operations
            if (operation === 'get') {
              // Parse the document.cookie string
              const cookies = document.cookie.split(';').reduce((acc, cookie) => {
                const [name, value] = cookie.trim().split('=').map(part => decodeURIComponent(part));
                if (name) acc[name] = safeParse(value);
                return acc;
              }, {});
              
              if (key) {
                result.key = key;
                result.value = cookies[key];
                if (result.value === undefined) {
                  result.message = `Cookie '${key}' not found`;
                } else {
                  result.message = `Retrieved cookie '${key}'`;
                  result.success = true;
                }
              } else {
                result.cookies = cookies;
                result.count = Object.keys(cookies).length;
                result.message = `Retrieved all ${Object.keys(cookies).length} cookies`;
                result.success = true;
              }
            } else if (operation === 'set') {
              // Create cookie with provided parameters
              let cookieString = `${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
              
              // Add cookie parameters
              const cookieParams = {" & cookieParams & "};
              
              if (cookieParams.domain) {
                cookieString += `; domain=${cookieParams.domain}`;
              }
              
              if (cookieParams.path) {
                cookieString += `; path=${cookieParams.path}`;
              }
              
              if (cookieParams.expires) {
                const expirationDate = new Date();
                expirationDate.setDate(expirationDate.getDate() + cookieParams.expires);
                cookieString += `; expires=${expirationDate.toUTCString()}`;
              }
              
              if (cookieParams.secure) {
                cookieString += '; secure';
              }
              
              // Set the cookie
              document.cookie = cookieString;
              
              result.key = key;
              result.value = value;
              result.message = `Set cookie '${key}'`;
              result.success = true;
            } else if (operation === 'remove') {
              // To remove a cookie, set its expiration date to the past
              document.cookie = `${encodeURIComponent(key)}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`;
              
              result.key = key;
              result.message = `Removed cookie '${key}'`;
              result.success = true;
            } else if (operation === 'clear') {
              // Clear all cookies by setting their expiration dates to the past
              const cookies = document.cookie.split(';');
              for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i];
                const eqPos = cookie.indexOf('=');
                const name = eqPos > -1 ? cookie.substring(0, eqPos).trim() : cookie.trim();
                document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`;
              }
              
              result.message = `Attempted to clear all accessible cookies`;
              result.success = true;
            }
            break;
            
          case 'indexeddb':
            // Basic IndexedDB operations
            // Note: IndexedDB is asynchronous, so we need to handle promises
            
            // For simplicity, we'll use a fixed database and object store name
            const dbName = 'SafariAutomationDB';
            const storeName = 'DataStore';
            
            // Create a promise that will be resolved with the result
            return new Promise((resolve, reject) => {
              let request;
              
              // Common function to handle DB open errors
              const handleError = (event) => {
                resolve(JSON.stringify({
                  operation: operation,
                  storageType: 'indexedDB',
                  success: false,
                  message: `IndexedDB error: ${event.target.error}`
                }));
              };
              
              if (operation === 'clear') {
                // Deleting the entire database is the simplest way to clear all data
                request = indexedDB.deleteDatabase(dbName);
                request.onsuccess = () => {
                  resolve(JSON.stringify({
                    operation: 'clear',
                    storageType: 'indexedDB',
                    success: true,
                    message: `Successfully cleared IndexedDB database '${dbName}'`
                  }));
                };
                request.onerror = handleError;
                return;
              }
              
              // Open (or create) the database
              request = indexedDB.open(dbName, 1);
              
              request.onupgradeneeded = (event) => {
                const db = event.target.result;
                // Create an object store if it doesn't exist
                if (!db.objectStoreNames.contains(storeName)) {
                  db.createObjectStore(storeName);
                }
              };
              
              request.onerror = handleError;
              
              request.onsuccess = (event) => {
                const db = event.target.result;
                
                // Handle different operations
                if (operation === 'get') {
                  // Get a specific value or all values
                  const transaction = db.transaction([storeName], 'readonly');
                  const objectStore = transaction.objectStore(storeName);
                  
                  if (key) {
                    // Get specific key
                    const getRequest = objectStore.get(key);
                    
                    getRequest.onsuccess = () => {
                      resolve(JSON.stringify({
                        operation: 'get',
                        storageType: 'indexedDB',
                        key: key,
                        value: getRequest.result,
                        success: getRequest.result !== undefined,
                        message: getRequest.result !== undefined ? 
                          `Retrieved value for key '${key}' from IndexedDB` : 
                          `Key '${key}' not found in IndexedDB`
                      }));
                    };
                    
                    getRequest.onerror = handleError;
                  } else {
                    // Get all values
                    const allData = {};
                    const cursorRequest = objectStore.openCursor();
                    
                    cursorRequest.onsuccess = (event) => {
                      const cursor = event.target.result;
                      if (cursor) {
                        allData[cursor.key] = cursor.value;
                        cursor.continue();
                      } else {
                        resolve(JSON.stringify({
                          operation: 'get',
                          storageType: 'indexedDB',
                          items: allData,
                          count: Object.keys(allData).length,
                          success: true,
                          message: `Retrieved all items from IndexedDB`
                        }));
                      }
                    };
                    
                    cursorRequest.onerror = handleError;
                  }
                } else if (operation === 'set') {
                  // Set a value
                  const transaction = db.transaction([storeName], 'readwrite');
                  const objectStore = transaction.objectStore(storeName);
                  
                  const putRequest = objectStore.put(value, key);
                  
                  putRequest.onsuccess = () => {
                    resolve(JSON.stringify({
                      operation: 'set',
                      storageType: 'indexedDB',
                      key: key,
                      success: true,
                      message: `Successfully set IndexedDB key '${key}'`
                    }));
                  };
                  
                  putRequest.onerror = handleError;
                } else if (operation === 'remove') {
                  // Remove a value
                  const transaction = db.transaction([storeName], 'readwrite');
                  const objectStore = transaction.objectStore(storeName);
                  
                  const deleteRequest = objectStore.delete(key);
                  
                  deleteRequest.onsuccess = () => {
                    resolve(JSON.stringify({
                      operation: 'remove',
                      storageType: 'indexedDB',
                      key: key,
                      success: true,
                      message: `Removed key '${key}' from IndexedDB`
                    }));
                  };
                  
                  deleteRequest.onerror = handleError;
                }
              };
            });
        }
        
        // Return result as JSON string for non-IndexedDB operations
        return JSON.stringify(result);
      } catch (error) {
        return JSON.stringify({
          operation: operation,
          storageType: storageType,
          success: false,
          error: error.message
        });
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
      
      -- Execute the JavaScript
      set jsResult to do JavaScript storageJS in currentTab
      
      return jsResult
    on error errMsg
      return "error: Failed to manage browser storage - " & errMsg & ". Make sure 'Allow JavaScript from Apple Events' is enabled in Safari's Develop menu."
    end try
  end tell
end manageBrowserStorage

-- Helper function to format a JavaScript string or null
on jsStringOrNull(value)
  if value is missing value or value is "" then
    return "null"
  else
    return "'" & my escapeJSString(value) & "'"
  end if
end jsStringOrNull

-- Helper function to format a JavaScript value or null
on jsValueOrNull(value)
  if value is missing value or value is "" then
    return "null"
  else
    -- Check if it looks like JSON (object or array)
    if (value starts with "{" and value ends with "}") or (value starts with "[" and value ends with "]") then
      -- It's probably JSON, so don't quote it
      return value
    else
      -- It's probably a string, so quote it
      return "'" & my escapeJSString(value) & "'"
    end if
  end if
end jsValueOrNull

-- Helper function to escape JavaScript strings
on escapeJSString(jsString)
  -- Replace backslashes first
  set escapedString to my replaceText(jsString, "\\", "\\\\")
  -- Replace newlines
  set escapedString to my replaceText(escapedString, return, "\\n")
  -- Replace quotes
  set escapedString to my replaceText(escapedString, "'", "\\'")
  
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

return my manageBrowserStorage("--MCP_INPUT:operation", "--MCP_INPUT:storageType", "--MCP_INPUT:key", "--MCP_INPUT:value", "--MCP_INPUT:domain", "--MCP_INPUT:path", "--MCP_INPUT:expires", "--MCP_INPUT:secure")
```