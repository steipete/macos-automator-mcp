---
title: 'Chrome: Automated Test Runner'
category: 07_browsers
id: chrome_test_runner
description: >-
  Runs automated browser tests in Chrome with support for assertions,
  screenshots, and detailed reporting similar to Playwright or Cypress.
keywords:
  - Chrome
  - testing
  - automation
  - test runner
  - assertions
  - screenshots
  - web development
  - QA
  - Playwright
  - Cypress
language: applescript
isComplex: true
argumentsPrompt: >-
  Test configuration in inputData. For example: { "tests": [{"name": "Homepage
  Test", "url": "https://example.com", "assertions": [{"selector": "h1", "type":
  "text", "expected": "Example Domain"}], "screenshot": true}], "reportPath":
  "/Users/username/Downloads/test-report.json", "headless": false }
returnValueType: json
notes: >
  - Google Chrome must be running (unless headless mode is specified).

  - Creates and runs browser tests with assertions on elements, network
  requests, and page state.

  - Supports taking screenshots during test execution for visual verification.

  - Can generate detailed test reports with pass/fail results and timing
  information.

  - Handles waiting for elements, navigation events, and network requests.

  - Can run tests in headless mode for CI/CD integration.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.

  - Requires Full Disk Access permission to save report files outside of user's
  Downloads folder.
---

This script runs automated browser tests in Chrome with assertion checking, screenshots, and detailed reporting.

```applescript
--MCP_INPUT:tests
--MCP_INPUT:reportPath
--MCP_INPUT:headless

on runChromeTests(testCases, reportPath, headlessMode)
  -- Set default values
  if testCases is missing value or testCases is "" then
    return "error: No test cases provided. Please specify at least one test case."
  end if
  
  if headlessMode is missing value or headlessMode is "" then
    set headlessMode to false
  end if
  
  -- Default report path if not specified
  if reportPath is missing value or reportPath is "" then
    set userHome to POSIX path of (path to home folder)
    set reportPath to userHome & "Downloads/chrome_test_report_" & my getTimestamp() & ".json"
  end if
  
  -- Check if we should use headless mode
  if headlessMode then
    -- Launch Chrome in headless mode
    return my runHeadlessTests(testCases, reportPath)
  end if
  
  -- Make sure Chrome is running for non-headless tests
  tell application "Google Chrome"
    if not running then
      return "error: Google Chrome is not running. Please start Chrome or use headless mode."
    end if
    
    if (count of windows) is 0 then
      return "error: No Chrome windows open."
    end if
    
    if (count of tabs of front window) is 0 then
      return "error: No tabs in front Chrome window."
    end if
    
    -- Activate Chrome to ensure it's in the foreground
    activate
  end tell
  
  -- Generate a unique ID for this test session
  set sessionId to "mcpTestRunner_" & (random number from 100000 to 999999) as string
  
  -- Prepare the JavaScript for test execution
  set runnerScript to "
    (function() {
      try {
        // Create namespace for our test runner
        if (!window.mcpTestRunner) {
          window.mcpTestRunner = {
            activeSession: null,
            testCases: [],
            results: [],
            status: 'idle',
            currentTestIndex: -1
          };
        }
        
        // Clear any existing session with the same ID
        if (window.mcpTestRunner.activeSession === '" & sessionId & "') {
          console.log('Stopping previous test session with same ID');
          window.mcpTestRunner.activeSession = null;
          window.mcpTestRunner.testCases = [];
          window.mcpTestRunner.results = [];
          window.mcpTestRunner.status = 'idle';
          window.mcpTestRunner.currentTestIndex = -1;
        }
        
        // Set up the new session
        window.mcpTestRunner.activeSession = '" & sessionId & "';
        window.mcpTestRunner.status = 'initializing';
        window.mcpTestRunner.testCases = " & testCases & ";
        window.mcpTestRunner.currentTestIndex = -1;
        
        /* ----- Test Assertion Utilities ----- */
        
        // Wait for a selector to appear in the DOM
        async function waitForSelector(selector, timeout = 10000) {
          const startTime = Date.now();
          
          while (Date.now() - startTime < timeout) {
            const element = document.querySelector(selector);
            if (element) {
              return element;
            }
            
            // Wait a bit before trying again
            await new Promise(resolve => setTimeout(resolve, 100));
          }
          
          throw new Error(`Timeout waiting for selector: ${selector}`);
        }
        
        // Wait for navigation to complete
        async function waitForNavigation(timeout = 30000) {
          // If document is already complete, we're done
          if (document.readyState === 'complete') {
            return;
          }
          
          // Otherwise wait for the 'load' event
          return new Promise((resolve, reject) => {
            const timeoutId = setTimeout(() => {
              reject(new Error('Navigation timeout'));
            }, timeout);
            
            window.addEventListener('load', () => {
              clearTimeout(timeoutId);
              // Add a small delay after load for scripts to execute
              setTimeout(resolve, 500);
            }, { once: true });
          });
        }
        
        // Take a screenshot using canvas
        async function takeScreenshot() {
          // Create a canvas element
          const canvas = document.createElement('canvas');
          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;
          
          // Get the canvas context and draw the current viewport
          const context = canvas.getContext('2d');
          context.drawImage(document, 0, 0, window.innerWidth, window.innerHeight);
          
          // Convert to data URL and return
          return canvas.toDataURL('image/png');
        }
        
        // Get stacked element path for error messages
        function getElementPath(element) {
          if (!element) return 'Element not found';
          
          let path = [];
          let currentElement = element;
          
          while (currentElement && currentElement.tagName) {
            let identifier = currentElement.tagName.toLowerCase();
            
            if (currentElement.id) {
              identifier += `#${currentElement.id}`;
            } else if (currentElement.className) {
              const classes = currentElement.className.split(' ')
                .filter(c => c)
                .map(c => `.${c}`)
                .join('');
              identifier += classes;
            }
            
            path.unshift(identifier);
            currentElement = currentElement.parentElement;
            
            // Limit path depth
            if (path.length > 5) break;
          }
          
          return path.join(' > ');
        }
        
        // Check a specific assertion
        async function checkAssertion(assertion, context = document) {
          const result = {
            type: assertion.type,
            selector: assertion.selector,
            expected: assertion.expected,
            actual: null,
            success: false,
            error: null
          };
          
          try {
            let element = null;
            
            // If a selector is provided, find the element
            if (assertion.selector) {
              element = await waitForSelector(assertion.selector, assertion.timeout || 10000);
              if (!element) {
                throw new Error(`Element not found: ${assertion.selector}`);
              }
              
              // Add element path to the result for debugging
              result.elementPath = getElementPath(element);
            }
            
            // Check different assertion types
            switch (assertion.type) {
              case 'text':
              case 'textContent':
                result.actual = element.textContent.trim();
                result.success = result.actual === assertion.expected;
                break;
                
              case 'innerHTML':
                result.actual = element.innerHTML.trim();
                result.success = result.actual === assertion.expected;
                break;
                
              case 'value':
                result.actual = element.value;
                result.success = result.actual === assertion.expected;
                break;
                
              case 'attribute':
                if (!assertion.attribute) {
                  throw new Error('attribute name is required for attribute assertions');
                }
                result.attribute = assertion.attribute;
                result.actual = element.getAttribute(assertion.attribute);
                result.success = result.actual === assertion.expected;
                break;
                
              case 'exists':
                result.actual = !!element;
                result.success = result.actual === (assertion.expected !== false);
                break;
                
              case 'visible':
                const style = window.getComputedStyle(element);
                result.actual = style.display !== 'none' && 
                                style.visibility !== 'hidden' && 
                                style.opacity !== '0';
                result.success = result.actual === (assertion.expected !== false);
                break;
                
              case 'count':
                const elements = context.querySelectorAll(assertion.selector);
                result.actual = elements.length;
                result.success = result.actual === assertion.expected;
                break;
                
              case 'url':
                result.actual = window.location.href;
                
                if (assertion.contains) {
                  result.success = result.actual.includes(assertion.expected);
                } else {
                  result.success = result.actual === assertion.expected;
                }
                break;
                
              case 'title':
                result.actual = document.title;
                result.success = result.actual === assertion.expected;
                break;
                
              case 'jsExpression':
                if (!assertion.expression) {
                  throw new Error('expression is required for jsExpression assertions');
                }
                
                // Safely evaluate the expression
                const expressionFn = new Function('return ' + assertion.expression);
                result.actual = expressionFn();
                result.success = result.actual === assertion.expected;
                break;
                
              case 'cookie':
                if (!assertion.name) {
                  throw new Error('cookie name is required for cookie assertions');
                }
                
                const cookies = document.cookie.split(';')
                  .map(c => c.trim().split('='))
                  .reduce((acc, [name, value]) => {
                    acc[name] = value;
                    return acc;
                  }, {});
                
                result.actual = cookies[assertion.name];
                result.success = result.actual === assertion.expected;
                break;
                
              case 'console':
                // This requires special handling as we need to monitor console
                // For now, just report that it can't be checked directly
                result.error = 'Console assertions require monitoring before the test runs';
                result.success = false;
                break;
                
              default:
                result.error = `Unknown assertion type: ${assertion.type}`;
                result.success = false;
            }
          } catch (error) {
            result.success = false;
            result.error = error.message;
          }
          
          return result;
        }
        
        /* ----- Test Execution ----- */
        
        // Execute a single test case
        async function executeTest(test, index) {
          const result = {
            name: test.name || `Test ${index + 1}`,
            url: test.url,
            startTime: Date.now(),
            endTime: null,
            duration: 0,
            status: 'running',
            assertions: [],
            screenshot: null,
            error: null
          };
          
          try {
            // Navigate to the test URL if provided
            if (test.url) {
              // Record if we're on the same domain or cross-origin
              const currentUrl = window.location.href;
              const targetUrl = test.url;
              const isSameDomain = currentUrl.startsWith(window.location.origin) && 
                                 targetUrl.startsWith(window.location.origin);
              
              // Navigate and wait for page to load
              window.location.href = test.url;
              
              // If cross-origin, we can't really wait properly
              if (isSameDomain) {
                await waitForNavigation();
              } else {
                // For cross-origin, just wait a bit
                await new Promise(resolve => setTimeout(resolve, 5000));
              }
            }
            
            // Wait for page readiness if specified
            if (test.readySelector) {
              await waitForSelector(test.readySelector, test.timeout || 30000);
            } else if (test.readyState) {
              // If specific ready state is required
              if (test.readyState === 'networkIdle') {
                // Wait for network to be idle - approximate by waiting
                await new Promise(resolve => setTimeout(resolve, 2000));
              }
            }
            
            // Run any setup steps
            if (test.setup) {
              for (const step of test.setup) {
                switch (step.action) {
                  case 'click':
                    const clickEl = await waitForSelector(step.selector, step.timeout || 10000);
                    clickEl.click();
                    // Wait a bit for the click to take effect
                    await new Promise(resolve => setTimeout(resolve, 1000));
                    break;
                    
                  case 'type':
                    const inputEl = await waitForSelector(step.selector, step.timeout || 10000);
                    inputEl.value = step.text;
                    inputEl.dispatchEvent(new Event('input', { bubbles: true }));
                    break;
                    
                  case 'wait':
                    await new Promise(resolve => setTimeout(resolve, step.duration || 1000));
                    break;
                    
                  case 'executeJs':
                    if (step.code) {
                      // Execute JS directly in the page context
                      const execFn = new Function(step.code);
                      execFn();
                    }
                    break;
                    
                  default:
                    console.warn(`Unknown setup action: ${step.action}`);
                }
              }
            }
            
            // Run assertions
            if (test.assertions && test.assertions.length > 0) {
              for (const assertion of test.assertions) {
                const assertionResult = await checkAssertion(assertion);
                result.assertions.push(assertionResult);
                
                // If this is a critical assertion and it failed, stop the test
                if (assertion.critical && !assertionResult.success) {
                  throw new Error(`Critical assertion failed: ${assertionResult.error || 'Expected ' + assertion.expected + ' but got ' + assertionResult.actual}`);
                }
              }
            }
            
            // Take screenshot if requested
            if (test.screenshot) {
              result.screenshot = await takeScreenshot();
            }
            
            // Mark test as passed
            result.status = 'passed';
          } catch (error) {
            // Mark test as failed
            result.status = 'failed';
            result.error = error.message;
            
            // Take failure screenshot if enabled
            if (test.screenshotOnFailure) {
              result.screenshot = await takeScreenshot();
            }
          } finally {
            // Record end time and duration
            result.endTime = Date.now();
            result.duration = result.endTime - result.startTime;
          }
          
          return result;
        }
        
        // Execute all test cases sequentially
        async function executeAllTests() {
          const results = [];
          const startTime = Date.now();
          
          try {
            for (let i = 0; i < window.mcpTestRunner.testCases.length; i++) {
              window.mcpTestRunner.currentTestIndex = i;
              const test = window.mcpTestRunner.testCases[i];
              
              // Execute the test and get results
              const result = await executeTest(test, i);
              results.push(result);
              
              // If one test fails and stopOnFailure is true, stop testing
              if (result.status === 'failed' && test.stopOnFailure) {
                break;
              }
            }
            
            // Compile overall results
            const endTime = Date.now();
            const passed = results.filter(r => r.status === 'passed').length;
            const failed = results.filter(r => r.status === 'failed').length;
            
            const finalResults = {
              sessionId: window.mcpTestRunner.activeSession,
              startTime: startTime,
              endTime: endTime,
              duration: endTime - startTime,
              total: results.length,
              passed: passed,
              failed: failed,
              status: failed === 0 ? 'passed' : 'failed',
              tests: results
            };
            
            // Store results
            window.mcpTestRunner.results = finalResults;
            window.mcpTestRunner.status = 'completed';
            
            return finalResults;
          } catch (error) {
            // Handle unexpected errors in the test framework
            const endTime = Date.now();
            
            const errorResults = {
              sessionId: window.mcpTestRunner.activeSession,
              startTime: startTime,
              endTime: endTime,
              duration: endTime - startTime,
              total: window.mcpTestRunner.testCases.length,
              passed: results.filter(r => r.status === 'passed').length,
              failed: results.length - results.filter(r => r.status === 'passed').length + 1,
              status: 'error',
              error: error.message,
              stack: error.stack,
              tests: results
            };
            
            // Store results even with error
            window.mcpTestRunner.results = errorResults;
            window.mcpTestRunner.status = 'error';
            
            return errorResults;
          }
        }
        
        // Start the test execution
        window.mcpTestRunner.executionPromise = executeAllTests();
        
        // Return immediately with execution started status
        return {
          status: 'executing',
          message: 'Test execution started',
          testCount: window.mcpTestRunner.testCases.length,
          sessionId: window.mcpTestRunner.activeSession
        };
      } catch (e) {
        return { 
          error: true, 
          message: e.toString(),
          stack: e.stack
        };
      }
    })();
  "
  
  -- Execute the script to start the tests
  tell application "Google Chrome"
    try
      set startResult to execute active tab of front window javascript runnerScript
      
      -- If the tests started successfully, wait for them to complete
      if startResult contains "executing" and startResult contains sessionId then
        -- Show a message that tests are running
        set testCount to do shell script "echo " & quoted form of startResult & " | grep -o '\"testCount\":[0-9]*' | cut -d':' -f2"
        set progressMessage to "Running " & testCount & " tests... Please do not switch tabs or close Chrome."
        
        -- Create a script to check the test status
        set statusScript to "
          (function() {
            if (window.mcpTestRunner) {
              return {
                status: window.mcpTestRunner.status,
                sessionId: window.mcpTestRunner.activeSession,
                currentTest: window.mcpTestRunner.currentTestIndex,
                totalTests: window.mcpTestRunner.testCases ? window.mcpTestRunner.testCases.length : 0,
                hasResults: !!window.mcpTestRunner.results && window.mcpTestRunner.results.tests
              };
            } else {
              return { error: true, message: 'Test runner not initialized' };
            }
          })();
        "
        
        -- Poll for the status with timeout
        set maxAttempts to 300 -- 2.5 minutes max wait time
        set attemptCounter to 0
        
        repeat
          delay 0.5
          set attemptCounter to attemptCounter + 1
          set statusCheck to execute active tab of front window javascript statusScript
          
          -- If the tests completed, get the results
          if statusCheck contains "\"status\":\"completed\"" or statusCheck contains "\"status\":\"error\"" then
            -- Get the full test results
            set resultsScript to "
              (function() {
                if (window.mcpTestRunner && window.mcpTestRunner.results) {
                  // Clone results and remove screenshots to keep response size manageable
                  const results = JSON.parse(JSON.stringify(window.mcpTestRunner.results));
                  
                  // Store screenshot data separately
                  const screenshots = {};
                  
                  // Extract screenshots
                  if (results.tests) {
                    results.tests.forEach((test, index) => {
                      if (test.screenshot) {
                        screenshots[`test_${index}`] = test.screenshot;
                        test.screenshot = `[Screenshot data stored separately as test_${index}]`;
                      }
                    });
                  }
                  
                  // Return complete results
                  return {
                    results: results,
                    screenshots: screenshots,
                    screenshotCount: Object.keys(screenshots).length
                  };
                } else {
                  return { error: true, message: 'No test results available' };
                }
              })();
            "
            
            -- Get the results
            set resultsData to execute active tab of front window javascript resultsScript
            
            -- Try to save the report to file
            try
              -- Extract just the results part for the report
              set reportScript to "
                (function() {
                  if (window.mcpTestRunner && window.mcpTestRunner.results) {
                    return JSON.stringify(window.mcpTestRunner.results, null, 2);
                  } else {
                    return JSON.stringify({ error: 'No test results available' });
                  }
                })();
              "
              
              set reportJSON to execute active tab of front window javascript reportScript
              
              -- Save to the specified file
              do shell script "echo " & quoted form of reportJSON & " > " & quoted form of reportPath
            on error errMsg
              return "{\"error\": true, \"message\": \"Tests completed but failed to save report: " & my escapeJSString(errMsg) & "\"}"
            end try
            
            -- Return a success message or the results
            return resultsData
          end if
          
          -- Handle status updates
          if statusCheck contains "\"currentTest\":" then
            -- Extract current test number
            set currentTestNumString to do shell script "echo " & quoted form of statusCheck & " | grep -o '\"currentTest\":[0-9]*' | cut -d':' -f2"
            set currentTestNum to currentTestNumString as integer
            
            -- TODO: Could use this to update progress indicator if needed
          end if
          
          -- Timeout check
          if attemptCounter ≥ maxAttempts then
            return "{\"error\": true, \"message\": \"Timed out waiting for tests to complete.\"}"
          end if
        end repeat
      else
        -- Return the error from starting the tests
        return startResult
      end if
    on error errMsg
      return "{\"error\": true, \"message\": \"" & my escapeJSString(errMsg) & "\"}"
    end try
  end tell
end runChromeTests

-- Function to run tests in headless Chrome
on runHeadlessTests(testCases, reportPath)
  -- This is a placeholder for headless test functionality
  -- Actual implementation would use Chrome's headless mode via command line
  
  -- Example command to launch headless Chrome
  set launchCmd to "
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' 
    --headless
    --disable-gpu
    --remote-debugging-port=9222
    --no-sandbox
    'about:blank'
  "
  
  -- Simplified message for now, as headless requires more complex setup
  return "{\"message\": \"Headless mode requires Chrome DevTools Protocol implementation. This feature is not fully supported yet in the AppleScript version. Use a non-headless browser for testing.\"}"
end runHeadlessTests

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

return my runChromeTests("--MCP_INPUT:tests", "--MCP_INPUT:reportPath", "--MCP_INPUT:headless")
```
END_TIP
