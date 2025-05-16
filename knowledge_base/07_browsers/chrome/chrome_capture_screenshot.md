---
title: "Chrome: Capture Screenshot"
category: "05_web_browsers"
id: chrome_capture_screenshot
description: "Captures screenshots of webpages in Google Chrome with options for full page, visible area, or specific element, and saves to a specified location."
keywords: ["Chrome", "screenshot", "capture", "full page", "element", "save image", "web development"]
language: applescript
isComplex: true
argumentsPrompt: "Screenshot options in inputData. For example: { \"outputPath\": \"/Users/username/Downloads/screenshot.png\", \"captureMode\": \"fullPage\" }. The captureMode can be 'fullPage', 'viewport', or 'element'. If 'element' is chosen, provide a CSS selector with { \"selector\": \"#main-container\" }."
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Captures screenshots in PNG format.
  - Three capture modes: full page (entire scrollable content), viewport (visible area), or specific element.
  - When capturing specific elements, uses CSS selectors to identify them.
  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View > Developer menu.
  - Requires Full Disk Access permission to save files outside of user's Downloads folder.
---

This script captures screenshots from Chrome with options for the entire page, visible viewport, or specific elements.

```applescript
--MCP_INPUT:outputPath
--MCP_INPUT:captureMode
--MCP_INPUT:selector

on captureScreenshotInChrome(outputPath, captureMode, elementSelector)
  -- Set default values for missing parameters
  if outputPath is missing value or outputPath is "" then
    set userHome to POSIX path of (path to home folder)
    set outputPath to userHome & "Downloads/chrome_screenshot_" & my getTimestamp() & ".png"
  end if
  
  if captureMode is missing value or captureMode is "" then
    set captureMode to "viewport"
  else
    set captureMode to my toLowerCase(captureMode)
  end if
  
  -- Validate parameters
  if captureMode is not "fullpage" and captureMode is not "viewport" and captureMode is not "element" then
    return "error: Invalid captureMode. Use 'fullPage', 'viewport', or 'element'."
  end if
  
  if captureMode is "element" and (elementSelector is missing value or elementSelector is "") then
    return "error: Element selector is required when using 'element' capture mode."
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
    
    -- Activate Chrome to ensure it's in the foreground
    activate
    
    -- Generate a unique ID for this execution
    set executionId to "mcpScreenshot_" & (random number from 100000 to 999999) as string
    
    -- Create JavaScript to capture the screenshot
    set captureScript to "
      (function() {
        try {
          // Function to capture the screenshot
          async function captureScreenshot() {
            let screenshotData = null;
            let statusMessage = '';
            let errorMessage = null;
            
            try {
              const captureMode = '" & captureMode & "';
              " & (if captureMode is "element" then "const elementSelector = '" & my escapeJSString(elementSelector) & "';" else "") & "
              
              // Method 1: Try using the modern Capture API if available
              if (typeof CaptureController === 'function') {
                try {
                  const controller = new CaptureController();
                  let options = { controller };
                  
                  if (captureMode === 'fullpage') {
                    options.format = 'png';
                    options.captureBeyondViewport = true;
                  } else if (captureMode === 'element' && elementSelector) {
                    const element = document.querySelector(elementSelector);
                    if (!element) {
                      throw new Error('Element not found with selector: ' + elementSelector);
                    }
                    options.target = element;
                  }
                  
                  const blob = await new Promise((resolve, reject) => {
                    if (navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia) {
                      navigator.mediaDevices.getDisplayMedia({ preferCurrentTab: true })
                        .then(stream => {
                          const track = stream.getVideoTracks()[0];
                          const capture = new ImageCapture(track);
                          return capture.grabFrame();
                        })
                        .then(bitmap => {
                          const canvas = document.createElement('canvas');
                          canvas.width = bitmap.width;
                          canvas.height = bitmap.height;
                          const ctx = canvas.getContext('2d');
                          ctx.drawImage(bitmap, 0, 0);
                          canvas.toBlob(resolve, 'image/png');
                        })
                        .catch(reject);
                    } else {
                      reject(new Error('MediaDevices API not supported'));
                    }
                  });
                  
                  const reader = new FileReader();
                  await new Promise((resolve, reject) => {
                    reader.onload = resolve;
                    reader.onerror = reject;
                    reader.readAsDataURL(blob);
                  });
                  
                  screenshotData = reader.result.split(',')[1]; // Get base64 part
                  statusMessage = 'Screenshot captured using modern Capture API';
                  return { data: screenshotData, message: statusMessage };
                } catch (e) {
                  console.warn('Modern Capture API failed:', e);
                  // Continue to next method
                }
              }
              
              // Method 2: Try using DevTools Protocol if in DevTools context
              if (typeof chrome !== 'undefined' && chrome.debugger) {
                try {
                  let captureParams = {};
                  
                  if (captureMode === 'fullpage') {
                    captureParams = { format: 'png', captureBeyondViewport: true };
                  } else if (captureMode === 'element' && elementSelector) {
                    const element = document.querySelector(elementSelector);
                    if (!element) {
                      throw new Error('Element not found with selector: ' + elementSelector);
                    }
                    
                    const rect = element.getBoundingClientRect();
                    captureParams = { 
                      format: 'png',
                      clip: {
                        x: rect.left,
                        y: rect.top,
                        width: rect.width,
                        height: rect.height,
                        scale: window.devicePixelRatio
                      }
                    };
                  } else {
                    // Viewport capture
                    captureParams = { format: 'png' };
                  }
                  
                  const result = await new Promise((resolve) => {
                    chrome.debugger.sendCommand(
                      {tabId: chrome.devtools.inspectedWindow.tabId},
                      'Page.captureScreenshot',
                      captureParams,
                      resolve
                    );
                  });
                  
                  screenshotData = result.data;
                  statusMessage = 'Screenshot captured using DevTools Protocol';
                  return { data: screenshotData, message: statusMessage };
                } catch (e) {
                  console.warn('DevTools Protocol failed:', e);
                  // Continue to next method
                }
              }
              
              // Method 3: HTML2Canvas fallback (viewport or element only)
              if (captureMode !== 'fullpage') {
                // Dynamically load html2canvas if needed
                if (typeof html2canvas !== 'function') {
                  await new Promise((resolve, reject) => {
                    const script = document.createElement('script');
                    script.src = 'https://html2canvas.hertzen.com/dist/html2canvas.min.js';
                    script.onload = resolve;
                    script.onerror = reject;
                    document.head.appendChild(script);
                  });
                }
                
                let targetElement = document;
                if (captureMode === 'element' && elementSelector) {
                  targetElement = document.querySelector(elementSelector);
                  if (!targetElement) {
                    throw new Error('Element not found with selector: ' + elementSelector);
                  }
                } else {
                  targetElement = document.documentElement;
                }
                
                const canvas = await html2canvas(targetElement, {
                  scale: window.devicePixelRatio,
                  useCORS: true,
                  logging: false,
                  allowTaint: true,
                  foreignObjectRendering: true
                });
                
                screenshotData = canvas.toDataURL('image/png').split(',')[1];
                statusMessage = 'Screenshot captured using html2canvas';
                return { data: screenshotData, message: statusMessage };
              }
              
              // Method 4: Full page using canvas and scrolling (for fullpage only)
              if (captureMode === 'fullpage') {
                const fullHeight = Math.max(
                  document.body.scrollHeight, document.documentElement.scrollHeight,
                  document.body.offsetHeight, document.documentElement.offsetHeight,
                  document.body.clientHeight, document.documentElement.clientHeight
                );
                
                const fullWidth = Math.max(
                  document.body.scrollWidth, document.documentElement.scrollWidth,
                  document.body.offsetWidth, document.documentElement.offsetWidth,
                  document.body.clientWidth, document.documentElement.clientWidth
                );
                
                const viewportHeight = window.innerHeight;
                const viewportWidth = window.innerWidth;
                
                // Create canvas large enough for the entire page
                const canvas = document.createElement('canvas');
                canvas.width = fullWidth * window.devicePixelRatio;
                canvas.height = fullHeight * window.devicePixelRatio;
                const ctx = canvas.getContext('2d');
                ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
                
                // Save current scroll position
                const originalScrollPos = { x: window.scrollX, y: window.scrollY };
                
                // Function to capture visible portion
                const captureViewport = () => {
                  return new Promise(resolve => {
                    setTimeout(() => {
                      ctx.drawImage(
                        document.documentElement, 
                        window.scrollX, window.scrollY, 
                        viewportWidth, viewportHeight, 
                        window.scrollX, window.scrollY, 
                        viewportWidth, viewportHeight
                      );
                      resolve();
                    }, 100); // Small delay to allow rendering
                  });
                };
                
                // Iterate through the page and capture each viewport
                for (let y = 0; y < fullHeight; y += viewportHeight) {
                  for (let x = 0; x < fullWidth; x += viewportWidth) {
                    window.scrollTo(x, y);
                    await captureViewport();
                  }
                }
                
                // Restore original scroll position
                window.scrollTo(originalScrollPos.x, originalScrollPos.y);
                
                screenshotData = canvas.toDataURL('image/png').split(',')[1];
                statusMessage = 'Full page screenshot captured using canvas';
                return { data: screenshotData, message: statusMessage };
              }
              
              throw new Error('No screenshot capture method was successful');
            } catch (err) {
              errorMessage = err.message || 'Unknown error capturing screenshot';
              console.error('Screenshot capture failed:', err);
              return { error: true, message: errorMessage };
            }
          }
          
          // Execute the screenshot capture and store result
          captureScreenshot().then(result => {
            // Store result in sessionStorage with the unique ID
            window.sessionStorage.setItem('" & executionId & "', JSON.stringify(result));
            console.log('Screenshot capture complete, stored with ID: " & executionId & "');
          }).catch(err => {
            window.sessionStorage.setItem('" & executionId & "', JSON.stringify({
              error: true,
              message: err.message || 'Unknown error executing screenshot capture'
            }));
            console.error('Failed to capture screenshot:', err);
          });
          
          return { 
            status: 'pending', 
            message: 'Screenshot capture initiated. Retrieving result with ID: " & executionId & "',
            executionId: '" & executionId & "'
          };
        } catch (e) {
          return { error: true, message: e.toString() };
        }
      })();
    "
    
    -- Execute the first script to initiate screenshot capture
    set captureInitResult to execute active tab of front window javascript captureScript
    
    -- Prepare script to retrieve the screenshot data
    set retrieveScript to "
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
    
    -- Poll for the screenshot result with timeout
    set maxAttempts to 60 -- 30 seconds max wait time
    set attemptCounter to 0
    set screenshotData to ""
    
    repeat
      delay 0.5
      set attemptCounter to attemptCounter + 1
      set resultCheck to execute active tab of front window javascript retrieveScript
      
      -- If we got a result back with data, we're done
      if resultCheck is not missing value and resultCheck contains "data" then
        -- Extract the base64 data
        set screenshotData to extractFromJSON(resultCheck, "data")
        exit repeat
      end if
      
      -- If there was an error, report it
      if resultCheck is not missing value and resultCheck contains "error" then
        set errorMsg to extractFromJSON(resultCheck, "message")
        return "error: Screenshot capture failed - " & errorMsg
      end if
      
      -- Timeout check
      if attemptCounter ≥ maxAttempts then
        return "error: Timed out waiting for screenshot capture to complete."
      end if
    end repeat
    
    -- If we have screenshot data, save it to file
    if screenshotData is not "" then
      try
        set tempFilePath to my saveBase64ToPNG(screenshotData, outputPath)
        return "Screenshot saved to: " & outputPath
      on error errMsg
        return "error: Failed to save screenshot - " & errMsg
      end try
    else
      return "error: Failed to capture screenshot - no image data returned."
    end if
  end tell
end captureScreenshotInChrome

-- Helper function to extract values from JSON string
on extractFromJSON(jsonStr, key)
  set jsonText to jsonStr as text
  
  -- Simple pattern matching to extract the value
  set pattern to "\"" & key & "\"\\s*:\\s*\"([^\"]*)\"" -- For string values
  set regexCmd to "echo " & quoted form of jsonText & " | grep -o '" & pattern & "' | sed 's/.*: \"\\(.*\\)\"/\\1/'"
  
  try
    set valueStr to do shell script regexCmd
    return valueStr
  on error
    -- Try non-string pattern (for numbers, booleans, etc.)
    set pattern to "\"" & key & "\"\\s*:\\s*([^,\\}\\s][^,\\}]*)"
    set regexCmd to "echo " & quoted form of jsonText & " | grep -o '" & pattern & "' | sed 's/.*: \\(.*\\)/\\1/'"
    
    try
      set valueStr to do shell script regexCmd
      return valueStr
    on error
      return ""
    end try
  end try
end extractFromJSON

-- Helper function to save base64 data to a PNG file
on saveBase64ToPNG(base64Data, filePath)
  set tempFileCmd to "echo " & quoted form of base64Data & " | base64 -d > " & quoted form of filePath
  do shell script tempFileCmd
  return filePath
end saveBase64ToPNG

-- Helper function to get formatted timestamp
on getTimestamp()
  set currentDate to current date
  set y to year of currentDate as string
  set m to month of currentDate as integer
  if m < 10 then set m to "0" & m
  set d to day of currentDate as integer
  if d < 10 then set d to "0" & d
  set h to hours of currentDate as integer
  if h < 10 then set h to "0" & h
  set min to minutes of currentDate as integer
  if min < 10 then set min to "0" & min
  set s to seconds of currentDate as integer
  if s < 10 then set s to "0" & s
  
  return y & m & d & "_" & h & min & s
end getTimestamp

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

return my captureScreenshotInChrome("--MCP_INPUT:outputPath", "--MCP_INPUT:captureMode", "--MCP_INPUT:selector")
```
END_TIP