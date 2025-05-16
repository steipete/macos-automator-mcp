---
title: 'Chrome: Advanced Browser Automation'
category: 07_browsers
id: chrome_browser_automation
description: >-
  Performs advanced multi-step browser automation in Chrome similar to
  Playwright or Puppeteer, executing sequences of navigation, clicking, typing,
  waiting, and extracting data.
keywords:
  - Chrome
  - automation
  - Playwright
  - Puppeteer
  - testing
  - scraping
  - clicking
  - typing
  - navigation
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  JSON automation steps array as 'steps' in inputData. For example: { "steps":
  [{"action":"navigate","url":"https://example.com"},
  {"action":"click","selector":"#login-button"},
  {"action":"type","selector":"#username","text":"testuser"},
  {"action":"wait","ms":1000}, {"action":"extract","selector":"h1.title"}] }.
  See notes for all supported actions.
returnValueType: json
notes: >
  - Google Chrome must be running.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Executes a sequence of automation steps in order, with results returned as
  JSON.

  - Supported actions include:
    - `navigate`: Go to a URL
    - `click`: Click on an element matching a selector
    - `type`: Type text into an input matching a selector
    - `wait`: Wait for a specified time in milliseconds
    - `waitForSelector`: Wait for an element to appear
    - `waitForNavigation`: Wait for navigation to complete
    - `extract`: Extract text or attributes from elements
    - `screenshot`: Capture a screenshot
    - `hover`: Hover over an element
    - `scroll`: Scroll to an element or position
    - `select`: Select an option in a dropdown
    - `evaluate`: Execute custom JavaScript
  - Returns detailed results for each step with success/failure status.

  - Stops execution and returns an error if any required step fails.

  - Steps can be marked as optional with `"required": false` to continue despite
  failures.
---

This script executes advanced multi-step browser automation in Chrome, similar to Playwright or Puppeteer.

```applescript
--MCP_INPUT:steps

on automateChrome(stepsArray)
  if stepsArray is missing value or stepsArray is "" then
    return "{\"error\": true, \"message\": \"No automation steps provided.\"}"
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
    
    -- Generate a unique ID for this execution
    set executionId to "mcpAutomation_" & (random number from 100000 to 999999) as string
    
    -- Create JavaScript to prepare the automation environment
    set setupScript to "
      (function() {
        try {
          // Create automation namespace if it doesn't exist
          if (!window.mcpAutomation) {
            window.mcpAutomation = {
              results: [],
              executionId: '" & executionId & "',
              startTime: Date.now(),
              status: 'initializing',
              currentStep: -1,
              error: null,
              
              // Helper function to find elements
              findElement: function(selector, timeout = 5000) {
                return new Promise((resolve, reject) => {
                  const startTime = Date.now();
                  
                  const checkElement = () => {
                    const element = document.querySelector(selector);
                    if (element) {
                      resolve(element);
                      return;
                    }
                    
                    if (Date.now() - startTime > timeout) {
                      reject(new Error(`Element not found: ${selector} (timeout: ${timeout}ms)`));
                      return;
                    }
                    
                    setTimeout(checkElement, 100);
                  };
                  
                  checkElement();
                });
              },
              
              // Wait for navigation to complete
              waitForNavigation: function(timeout = 30000) {
                return new Promise((resolve, reject) => {
                  const startTime = Date.now();
                  
                  // Store the current URL to detect changes
                  const startUrl = window.location.href;
                  let navigationStarted = false;
                  
                  const checkNavigation = () => {
                    // First, detect if navigation has started
                    if (!navigationStarted && window.location.href !== startUrl) {
                      navigationStarted = true;
                    }
                    
                    // If navigation started, check if page is fully loaded
                    if (navigationStarted && document.readyState === 'complete') {
                      resolve();
                      return;
                    }
                    
                    // Check for timeout
                    if (Date.now() - startTime > timeout) {
                      reject(new Error(`Navigation timeout (${timeout}ms)`));
                      return;
                    }
                    
                    setTimeout(checkNavigation, 100);
                  };
                  
                  // Also resolve immediately if the page is already 'complete'
                  if (document.readyState === 'complete') {
                    const pageLoadListener = () => {
                      window.removeEventListener('load', pageLoadListener);
                      resolve();
                    };
                    window.addEventListener('load', pageLoadListener);
                  } else {
                    checkNavigation();
                  }
                });
              },
              
              // Safely scroll element into view with offset
              scrollIntoViewWithOffset: function(element, offset = 0) {
                if (!element) return;
                
                const elementRect = element.getBoundingClientRect();
                const absoluteElementTop = elementRect.top + window.pageYOffset;
                const scrollPosition = absoluteElementTop - offset;
                
                window.scrollTo({
                  top: scrollPosition,
                  behavior: 'smooth'
                });
                
                return new Promise(resolve => setTimeout(resolve, 300));
              },
              
              // Function to perform a real-like click with proper events
              simulateClick: function(element) {
                if (!element) return false;
                
                // First scroll it into view
                this.scrollIntoViewWithOffset(element, 100).then(() => {
                  // Create and dispatch mouse events for a more realistic interaction
                  const clickEvents = [
                    new MouseEvent('mouseover', {bubbles: true}),
                    new MouseEvent('mousedown', {bubbles: true}),
                    new MouseEvent('mouseup', {bubbles: true}),
                    new MouseEvent('click', {bubbles: true})
                  ];
                  
                  clickEvents.forEach(event => element.dispatchEvent(event));
                });
                
                return true;
              },
              
              // Simulate typing like a human
              simulateTyping: function(element, text) {
                if (!element) return false;
                
                // Focus the element
                element.focus();
                
                // Clear existing value if this is an input or textarea
                if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                  element.value = '';
                }
                
                // Dispatch events for each character with slight random delays
                return new Promise(resolve => {
                  let i = 0;
                  
                  function typeNextChar() {
                    if (i < text.length) {
                      const char = text.charAt(i);
                      
                      // Create and dispatch keyboard events
                      const keyDown = new KeyboardEvent('keydown', {
                        key: char,
                        code: 'Key' + char.toUpperCase(),
                        bubbles: true
                      });
                      
                      const keyPress = new KeyboardEvent('keypress', {
                        key: char,
                        code: 'Key' + char.toUpperCase(),
                        bubbles: true
                      });
                      
                      const keyUp = new KeyboardEvent('keyup', {
                        key: char,
                        code: 'Key' + char.toUpperCase(),
                        bubbles: true
                      });
                      
                      element.dispatchEvent(keyDown);
                      element.dispatchEvent(keyPress);
                      
                      // For inputs, manually update the value
                      if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                        element.value += char;
                        // Dispatch input event to trigger listeners
                        const inputEvent = new Event('input', { bubbles: true });
                        element.dispatchEvent(inputEvent);
                      } else {
                        // For other elements, insert text node
                        const textEvent = new InputEvent('textInput', {
                          data: char,
                          bubbles: true
                        });
                        element.dispatchEvent(textEvent);
                      }
                      
                      element.dispatchEvent(keyUp);
                      
                      i++;
                      
                      // Add a random delay between keypresses (30-70ms) for realistic typing
                      setTimeout(typeNextChar, Math.floor(Math.random() * 40) + 30);
                    } else {
                      // Dispatch change event after typing is complete
                      const changeEvent = new Event('change', { bubbles: true });
                      element.dispatchEvent(changeEvent);
                      
                      resolve(true);
                    }
                  }
                  
                  typeNextChar();
                });
              }
            };
            
            console.log('MCP Automation environment initialized with ID:', window.mcpAutomation.executionId);
          }
          
          return {
            status: 'initialized',
            executionId: window.mcpAutomation.executionId
          };
        } catch (e) {
          return { error: true, message: e.toString() };
        }
      })();
    "
    
    -- Execute the setup script
    set setupResult to execute active tab of front window javascript setupScript
    
    -- Prepare all steps to be executed
    set executeScript to "
      (function() {
        try {
          // Parse steps from the provided JSON
          const steps = " & stepsArray & ";
          
          if (!Array.isArray(steps) || steps.length === 0) {
            return { 
              error: true, 
              message: 'Invalid steps array. Must be a non-empty array of action objects.' 
            };
          }
          
          // Update automation status
          window.mcpAutomation.status = 'running';
          window.mcpAutomation.totalSteps = steps.length;
          
          // Function to execute a single step
          async function executeStep(step, index) {
            window.mcpAutomation.currentStep = index;
            
            // Default step object structure with required field
            const defaultStep = { required: true };
            const currentStep = { ...defaultStep, ...step, index };
            
            const startTime = Date.now();
            let result = {
              step: index,
              action: step.action,
              status: 'unknown',
              duration: 0,
              error: null
            };
            
            try {
              // Execute based on the action type
              switch (step.action) {
                case 'navigate':
                  if (!step.url) throw new Error('URL is required for navigate action');
                  window.location.href = step.url;
                  await window.mcpAutomation.waitForNavigation();
                  result.url = step.url;
                  break;
                  
                case 'click':
                  if (!step.selector) throw new Error('Selector is required for click action');
                  const clickElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                  await window.mcpAutomation.simulateClick(clickElement);
                  result.selector = step.selector;
                  break;
                  
                case 'type':
                  if (!step.selector) throw new Error('Selector is required for type action');
                  if (step.text === undefined) throw new Error('Text is required for type action');
                  const typeElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                  await window.mcpAutomation.simulateTyping(typeElement, step.text);
                  result.selector = step.selector;
                  // Don't include the text in the result for security
                  result.textLength = step.text.length;
                  break;
                  
                case 'wait':
                  const ms = step.ms || 1000;
                  await new Promise(resolve => setTimeout(resolve, ms));
                  result.ms = ms;
                  break;
                  
                case 'waitForSelector':
                  if (!step.selector) throw new Error('Selector is required for waitForSelector action');
                  const waitElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 30000);
                  result.selector = step.selector;
                  break;
                  
                case 'waitForNavigation':
                  await window.mcpAutomation.waitForNavigation(step.timeout || 30000);
                  result.url = window.location.href;
                  break;
                  
                case 'extract':
                  if (!step.selector) throw new Error('Selector is required for extract action');
                  let elements;
                  if (step.all) {
                    elements = Array.from(document.querySelectorAll(step.selector));
                    if (elements.length === 0) throw new Error(`No elements found: ${step.selector}`);
                  } else {
                    const element = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                    elements = [element];
                  }
                  
                  // Extract requested data
                  const extractData = elements.map(el => {
                    const data = {};
                    if (!step.attributes || step.attributes.includes('text')) {
                      data.text = el.textContent.trim();
                    }
                    if (step.attributes && step.attributes.length > 0) {
                      step.attributes.forEach(attr => {
                        if (attr !== 'text') {
                          data[attr] = el.getAttribute(attr) || '';
                        }
                      });
                    }
                    return data;
                  });
                  
                  result.selector = step.selector;
                  result.data = step.all ? extractData : extractData[0];
                  break;
                  
                case 'screenshot':
                  // Capture screenshot (viewport only in this implementation)
                  const canvas = document.createElement('canvas');
                  const context = canvas.getContext('2d');
                  const width = window.innerWidth;
                  const height = window.innerHeight;
                  
                  canvas.width = width;
                  canvas.height = height;
                  
                  // Draw the current viewport
                  context.drawImage(document, 0, 0, width, height);
                  
                  // Convert to data URL
                  const screenshotDataUrl = canvas.toDataURL('image/png');
                  result.dataUrl = screenshotDataUrl;
                  break;
                  
                case 'hover':
                  if (!step.selector) throw new Error('Selector is required for hover action');
                  const hoverElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                  
                  // Create and dispatch mouse events
                  const mouseoverEvent = new MouseEvent('mouseover', {bubbles: true});
                  const mouseenterEvent = new MouseEvent('mouseenter', {bubbles: true});
                  
                  hoverElement.dispatchEvent(mouseoverEvent);
                  hoverElement.dispatchEvent(mouseenterEvent);
                  
                  result.selector = step.selector;
                  break;
                  
                case 'scroll':
                  if (step.selector) {
                    const scrollElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                    await window.mcpAutomation.scrollIntoViewWithOffset(scrollElement, step.offset || 0);
                    result.selector = step.selector;
                  } else if (step.x !== undefined || step.y !== undefined) {
                    window.scrollTo({
                      top: step.y || 0,
                      left: step.x || 0,
                      behavior: 'smooth'
                    });
                    result.position = { x: step.x || 0, y: step.y || 0 };
                  } else {
                    throw new Error('Either selector or x/y position required for scroll action');
                  }
                  
                  // Wait for scroll to complete
                  await new Promise(resolve => setTimeout(resolve, 300));
                  break;
                  
                case 'select':
                  if (!step.selector) throw new Error('Selector is required for select action');
                  if (!step.value && !step.index && !step.text) throw new Error('One of value, index, or text is required for select action');
                  
                  const selectElement = await window.mcpAutomation.findElement(step.selector, step.timeout || 5000);
                  
                  if (selectElement.tagName !== 'SELECT') {
                    throw new Error(`Element is not a select: ${step.selector}`);
                  }
                  
                  let optionFound = false;
                  
                  if (step.value !== undefined) {
                    selectElement.value = step.value;
                    optionFound = Array.from(selectElement.options).some(option => option.value === step.value);
                  } else if (step.index !== undefined) {
                    if (step.index >= 0 && step.index < selectElement.options.length) {
                      selectElement.selectedIndex = step.index;
                      optionFound = true;
                    }
                  } else if (step.text) {
                    const options = Array.from(selectElement.options);
                    const option = options.find(opt => opt.text === step.text);
                    if (option) {
                      option.selected = true;
                      optionFound = true;
                    }
                  }
                  
                  if (!optionFound) {
                    throw new Error(`Option not found in select: ${step.value || step.index || step.text}`);
                  }
                  
                  // Dispatch change event
                  const changeEvent = new Event('change', { bubbles: true });
                  selectElement.dispatchEvent(changeEvent);
                  
                  result.selector = step.selector;
                  break;
                  
                case 'evaluate':
                  if (!step.code) throw new Error('Code is required for evaluate action');
                  
                  // Execute the custom JavaScript
                  const evalFunction = new Function(step.code);
                  const evalResult = evalFunction();
                  
                  result.result = evalResult;
                  break;
                  
                default:
                  throw new Error(`Unknown action: ${step.action}`);
              }
              
              // Mark as successful
              result.status = 'success';
            } catch (e) {
              // Handle error based on whether step is required
              result.status = 'error';
              result.error = e.message;
              
              // Rethrow if required
              if (currentStep.required !== false) {
                throw e;
              }
            } finally {
              // Calculate duration
              result.duration = Date.now() - startTime;
              
              // Store result
              window.mcpAutomation.results[index] = result;
            }
            
            return result;
          }
          
          // Execute all steps sequentially
          async function executeAllSteps() {
            try {
              for (let i = 0; i < steps.length; i++) {
                await executeStep(steps[i], i);
              }
              
              window.mcpAutomation.status = 'completed';
              window.mcpAutomation.endTime = Date.now();
              window.mcpAutomation.duration = window.mcpAutomation.endTime - window.mcpAutomation.startTime;
              
              return {
                status: 'completed',
                executionId: window.mcpAutomation.executionId,
                duration: window.mcpAutomation.duration,
                stepResults: window.mcpAutomation.results
              };
            } catch (e) {
              window.mcpAutomation.status = 'error';
              window.mcpAutomation.error = e.message;
              window.mcpAutomation.endTime = Date.now();
              window.mcpAutomation.duration = window.mcpAutomation.endTime - window.mcpAutomation.startTime;
              
              return {
                status: 'error',
                executionId: window.mcpAutomation.executionId,
                error: e.message,
                failedStep: window.mcpAutomation.currentStep,
                duration: window.mcpAutomation.duration,
                stepResults: window.mcpAutomation.results
              };
            }
          }
          
          // Start execution and store the promise
          window.mcpAutomation.executionPromise = executeAllSteps();
          
          // Return immediately with execution started status
          return {
            status: 'executing',
            message: 'Automation steps execution started',
            executionId: window.mcpAutomation.executionId
          };
        } catch (e) {
          return { 
            error: true, 
            message: e.toString() 
          };
        }
      })();
    "
    
    -- Execute the steps script
    set executionInitResult to execute active tab of front window javascript executeScript
    
    -- Prepare script to retrieve the execution results
    set retrieveScript to "
      (function() {
        // Check if automation is initialized
        if (!window.mcpAutomation) {
          return { error: true, message: 'Automation environment not initialized' };
        }
        
        // Check for completed status
        if (window.mcpAutomation.status === 'completed' || window.mcpAutomation.status === 'error') {
          // Return final results
          return {
            status: window.mcpAutomation.status,
            executionId: window.mcpAutomation.executionId,
            error: window.mcpAutomation.error,
            failedStep: window.mcpAutomation.status === 'error' ? window.mcpAutomation.currentStep : null,
            duration: window.mcpAutomation.duration,
            startTime: window.mcpAutomation.startTime,
            endTime: window.mcpAutomation.endTime,
            stepResults: window.mcpAutomation.results
          };
        } else {
          // Execution still in progress
          return {
            status: 'in_progress',
            executionId: window.mcpAutomation.executionId,
            currentStep: window.mcpAutomation.currentStep,
            totalSteps: window.mcpAutomation.totalSteps,
            message: 'Automation still running'
          };
        }
      })();
    "
    
    -- Poll for the execution results with timeout
    set maxAttempts to 300 -- 150 seconds max wait time (adjust as needed)
    set attemptCounter to 0
    
    repeat
      delay 0.5
      set attemptCounter to attemptCounter + 1
      set resultCheck to execute active tab of front window javascript retrieveScript
      
      -- If we got a completed or error status, we're done
      if resultCheck is not missing value and (resultCheck contains "\"status\":\"completed\"" or resultCheck contains "\"status\":\"error\"") then
        return resultCheck
      end if
      
      -- Timeout check
      if attemptCounter ≥ maxAttempts then
        set timeoutScript to "
          (function() {
            if (window.mcpAutomation) {
              window.mcpAutomation.status = 'timeout';
              return {
                status: 'timeout',
                executionId: window.mcpAutomation.executionId,
                message: 'Automation timed out after waiting " & maxAttempts / 2 & " seconds',
                currentStep: window.mcpAutomation.currentStep,
                stepResults: window.mcpAutomation.results
              };
            } else {
              return { error: true, message: 'Automation environment not initialized or lost' };
            }
          })();
        "
        
        set timeoutResult to execute active tab of front window javascript timeoutScript
        return timeoutResult
      end if
    end repeat
  end tell
end automateChrome

return my automateChrome("--MCP_INPUT:steps")
```
END_TIP
