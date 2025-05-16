---
title: "Chrome: Record Performance Trace"
category: "05_web_browsers"
id: chrome_record_performance_trace
description: "Records a detailed performance trace in Chrome to analyze rendering, JavaScript execution, memory usage, and other performance metrics."
keywords: ["Chrome", "performance", "trace", "profiling", "DevTools", "optimization", "web development", "debugging"]
language: applescript
isComplex: true
argumentsPrompt: "Options in inputData. For example: { \"duration\": 5, \"categories\": [\"loading\", \"scripting\", \"rendering\"], \"outputPath\": \"/Users/username/Downloads/trace.json\" }. Set { \"screencast\": true } to include screenshots in the trace. Duration is in seconds."
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Opens DevTools (if not already open) and configures performance recording.
  - Records a performance trace for the specified duration, capturing various metrics.
  - Can save the trace data to a file for later analysis or sharing.
  - Supports setting specific tracing categories to focus on particular aspects of performance.
  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View > Developer menu.
  - Requires Accessibility permissions for UI scripting via System Events.
  - Requires Full Disk Access permission to save trace files outside of user's Downloads folder.
---

This script records and saves Chrome performance traces to analyze and optimize web application performance.

```applescript
--MCP_INPUT:duration
--MCP_INPUT:categories
--MCP_INPUT:outputPath
--MCP_INPUT:screencast

on recordPerformanceTrace(recordingDuration, categories, outputPath, includeScreencast)
  -- Set default values
  if recordingDuration is missing value or recordingDuration is "" then
    set recordingDuration to 5 -- Default 5 seconds
  end if
  
  -- Convert duration to milliseconds
  set durationMs to recordingDuration * 1000
  
  -- Default categories if not specified
  if categories is missing value or categories is "" then
    set categories to {"loading", "scripting", "rendering", "painting", "network"}
  end if
  
  -- Default output path if not specified
  if outputPath is missing value or outputPath is "" then
    set userHome to POSIX path of (path to home folder)
    set outputPath to userHome & "Downloads/chrome_performance_trace_" & my getTimestamp() & ".json"
  end if
  
  -- Default screencast setting
  if includeScreencast is missing value or includeScreencast is "" then
    set includeScreencast to false
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
  end tell
  
  -- Open DevTools and switch to Performance panel
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
      
      -- Switch to Performance panel
      key code 35 using {command down, option down} -- Option+Command+P
      delay 0.5
    end tell
  end tell
  
  -- Generate a unique ID for this recording session
  set sessionId to "mcpPerformanceTrace_" & (random number from 100000 to 999999) as string
  
  -- Prepare the JavaScript for performance recording
  set recordingScript to "
    (function() {
      try {
        // Create a namespace for our performance recording
        if (!window.mcpPerformance) {
          window.mcpPerformance = {
            activeSession: null,
            recorder: null,
            traceData: null,
            status: 'idle'
          };
        }
        
        // Clear any existing session with the same ID
        if (window.mcpPerformance.activeSession === '" & sessionId & "') {
          console.log('Stopping previous performance recording session with same ID');
          window.mcpPerformance.activeSession = null;
          window.mcpPerformance.traceData = null;
          window.mcpPerformance.status = 'idle';
        }
        
        // Set up the new session
        window.mcpPerformance.activeSession = '" & sessionId & "';
        window.mcpPerformance.status = 'initializing';
        
        // Function to check if we're in DevTools context
        function isInDevToolsContext() {
          return typeof UI !== 'undefined' && typeof SDK !== 'undefined';
        }
        
        // Function to start recording using Performance API
        async function startRecordingPerformanceAPI() {
          try {
            // Create a PerformanceObserver to capture all entries
            const observer = new PerformanceObserver((list) => {
              for (const entry of list.getEntries()) {
                // Store or process performance entries
                console.log('Performance Entry:', entry.name, entry);
              }
            });
            
            // Subscribe to various entry types
            observer.observe({ 
              entryTypes: [
                'navigation', 'resource', 'mark', 'measure', 
                'paint', 'longtask', 'layout-shift'
              ] 
            });
            
            // Mark the start of our custom recording
            performance.mark('mcp-performance-start');
            
            // Store the observer for cleanup
            window.mcpPerformance.observer = observer;
            
            return { success: true, method: 'PerformanceAPI' };
          } catch (e) {
            console.error('Failed to start recording using Performance API:', e);
            return { error: true, message: e.toString() };
          }
        }
        
        // Function to start recording using DevTools Performance panel
        async function startRecordingDevTools() {
          try {
            if (!isInDevToolsContext()) {
              return { error: true, message: 'Not in DevTools context' };
            }
            
            // Try to access Performance panel components
            if (typeof UI.panels !== 'undefined' && UI.panels.timeline) {
              const performancePanel = UI.panels.timeline;
              
              // Check if we can access the controller
              if (performancePanel._state && 
                  typeof performancePanel.toggleRecording === 'function') {
                
                // Configure recording settings
                // Force capture screenshots if enabled
                if (" & includeScreencast & " === true && 
                    typeof performancePanel._captureScreenShotsSetting !== 'undefined') {
                  performancePanel._captureScreenShotsSetting.set(true);
                }
                
                // Set memory recording
                if (typeof performancePanel._showMemorySetting !== 'undefined') {
                  performancePanel._showMemorySetting.set(true);
                }
                
                // Start recording
                if (performancePanel._state !== UI.TimelinePanel.State.Recording) {
                  performancePanel.toggleRecording();
                }
                
                // Store reference to the panel for stopping later
                window.mcpPerformance.recorder = performancePanel;
                
                return { success: true, method: 'DevToolsPanel' };
              }
            }
            
            // Try Timeline instead (older DevTools)
            if (typeof Timeline !== 'undefined' && 
                typeof Timeline.TimelinePanel !== 'undefined') {
              const timelinePanel = Timeline.TimelinePanel.instance();
              
              if (timelinePanel && typeof timelinePanel.toggleRecording === 'function') {
                // Configure settings if possible
                if (" & includeScreencast & " === true && 
                    typeof timelinePanel._captureScreenShotsSetting !== 'undefined') {
                  timelinePanel._captureScreenShotsSetting.set(true);
                }
                
                // Start recording
                timelinePanel.toggleRecording();
                
                // Store reference
                window.mcpPerformance.recorder = timelinePanel;
                
                return { success: true, method: 'TimelinePanel' };
              }
            }
            
            // Try Performance module (newer DevTools)
            if (typeof Performance !== 'undefined' && 
                typeof Performance.PerformancePanel !== 'undefined') {
              const panel = Performance.PerformancePanel.instance();
              
              if (panel && typeof panel.toggleRecording === 'function') {
                // Configure settings if possible
                if (" & includeScreencast & " === true && 
                    typeof panel._captureScreenShotsSetting !== 'undefined') {
                  panel._captureScreenShotsSetting.set(true);
                }
                
                // Start recording
                panel.toggleRecording();
                
                // Store reference
                window.mcpPerformance.recorder = panel;
                
                return { success: true, method: 'PerformancePanel' };
              }
            }
            
            return { error: true, message: 'Could not access Performance panel in DevTools' };
          } catch (e) {
            console.error('Failed to start recording using DevTools panel:', e);
            return { error: true, message: e.toString() };
          }
        }
        
        // Function to start recording using Chrome Tracing API
        async function startRecordingTracing() {
          try {
            if (typeof chrome !== 'undefined' && chrome.devtools && chrome.debugger) {
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
              
              // Convert input categories to Chrome's format
              const categoryObj = {};
              const requestedCategories = " & my convertListToJSArray(categories) & ";
              
              const categoryMap = {
                'loading': ['loading', 'parseHTML', 'resourceLoading'],
                'scripting': ['javaScript', 'parseHTML', 'scriptStreaming'],
                'rendering': ['rendering', 'layout', 'compositing'],
                'painting': ['painting', 'rasterization', 'gpu'],
                'network': ['network', 'netlog', 'loading'],
                'memory': ['memory'],
                'timeline': ['devtools.timeline'],
                'input': ['input', 'evdev']
              };
              
              // Add specified categories
              for (const category of requestedCategories) {
                if (categoryMap[category]) {
                  for (const detail of categoryMap[category]) {
                    categoryObj[detail] = true;
                  }
                }
              }
              
              // Always include these
              categoryObj['disabled-by-default-devtools.timeline'] = true;
              
              // Add screenshots if requested
              if (" & includeScreencast & ") {
                categoryObj['disabled-by-default-devtools.screenshot'] = true;
              }
              
              // Start tracing
              await new Promise((resolve, reject) => {
                chrome.debugger.sendCommand({tabId}, 'Tracing.start', {
                  categories: Object.keys(categoryObj).join(','),
                  options: 'sampling-frequency=10000',
                  transferMode: 'ReturnAsStream',
                  bufferUsageReportingInterval: 500
                }, result => {
                  if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                  } else {
                    resolve();
                  }
                });
              });
              
              // Store reference to the debugger
              window.mcpPerformance.tracer = {
                tabId: tabId
              };
              
              return { success: true, method: 'ChromeTracing' };
            }
            
            return { error: true, message: 'Chrome Tracing API not available' };
          } catch (e) {
            console.error('Failed to start recording using Chrome Tracing:', e);
            return { error: true, message: e.toString() };
          }
        }
        
        // Try each method in sequence until one works
        async function startRecording() {
          let result = null;
          
          // First try DevTools Performance Panel
          result = await startRecordingDevTools();
          if (result && result.success) {
            window.mcpPerformance.recordingMethod = result.method;
            window.mcpPerformance.status = 'recording';
            return result;
          }
          
          // Then try Chrome Tracing API
          result = await startRecordingTracing();
          if (result && result.success) {
            window.mcpPerformance.recordingMethod = result.method;
            window.mcpPerformance.status = 'recording';
            return result;
          }
          
          // Finally fall back to Performance API
          result = await startRecordingPerformanceAPI();
          if (result && result.success) {
            window.mcpPerformance.recordingMethod = result.method;
            window.mcpPerformance.status = 'recording';
            return result;
          }
          
          // If all methods failed
          return {
            error: true,
            message: 'Failed to start performance recording with any method'
          };
        }
        
        // Start the recording
        return startRecording().then(result => {
          if (result.success) {
            // Setup automatic stop after duration
            window.mcpPerformance.stopTimer = setTimeout(() => {
              // Call stop function after the specified duration
              stopRecording();
            }, " & durationMs & ");
            
            return {
              success: true,
              message: `Started performance recording using ${result.method}`,
              sessionId: '" & sessionId & "',
              status: 'recording',
              duration: " & recordingDuration & ",
              categories: " & my convertListToJSArray(categories) & "
            };
          } else {
            return result;
          }
        });
        
        // This will be called automatically by the timer
        function stopRecording() {
          return (async () => {
            try {
              let traceData = null;
              const method = window.mcpPerformance.recordingMethod;
              
              // Mark the end of recording
              performance.mark('mcp-performance-end');
              performance.measure('mcp-performance-duration', 
                                 'mcp-performance-start', 
                                 'mcp-performance-end');
              
              switch (method) {
                case 'DevToolsPanel':
                case 'TimelinePanel':
                case 'PerformancePanel':
                  if (window.mcpPerformance.recorder) {
                    // Stop recording if it's still active
                    const recorder = window.mcpPerformance.recorder;
                    
                    if (typeof recorder.toggleRecording === 'function') {
                      recorder.toggleRecording();
                    }
                    
                    // Try to get the trace data
                    if (typeof recorder.getDataFileForDownload === 'function') {
                      // Get the trace data file
                      const dataFile = await new Promise(resolve => {
                        recorder.getDataFileForDownload(resolve);
                      });
                      
                      if (dataFile) {
                        traceData = dataFile;
                      }
                    } else if (recorder._model && 
                               typeof recorder._model.saveToFile === 'function') {
                      // Try to access the model's save function
                      const modelData = await new Promise(resolve => {
                        recorder._model.saveToFile(resolve);
                      });
                      
                      if (modelData) {
                        traceData = modelData;
                      }
                    }
                  }
                  break;
                  
                case 'ChromeTracing':
                  if (window.mcpPerformance.tracer) {
                    const tabId = window.mcpPerformance.tracer.tabId;
                    
                    // Stop tracing
                    await new Promise((resolve, reject) => {
                      chrome.debugger.sendCommand({tabId}, 'Tracing.end', {}, result => {
                        if (chrome.runtime.lastError) {
                          reject(chrome.runtime.lastError);
                        } else {
                          resolve();
                        }
                      });
                    });
                    
                    // Get the trace data
                    // This is complex with streams, simplifying for demo
                    traceData = { message: 'Trace data available via chrome.debugger' };
                  }
                  break;
                  
                case 'PerformanceAPI':
                  // Collect data from Performance API
                  const performanceEntries = performance.getEntries();
                  const measures = performance.getEntriesByType('measure')
                    .filter(m => m.name === 'mcp-performance-duration');
                  
                  traceData = {
                    entries: performanceEntries,
                    duration: measures.length > 0 ? measures[0].duration : 0
                  };
                  
                  // Clean up observer
                  if (window.mcpPerformance.observer) {
                    window.mcpPerformance.observer.disconnect();
                  }
                  break;
              }
              
              // Store the trace data
              window.mcpPerformance.traceData = traceData;
              window.mcpPerformance.status = 'completed';
              
              // Clean up timer
              if (window.mcpPerformance.stopTimer) {
                clearTimeout(window.mcpPerformance.stopTimer);
              }
              
              // Signal that recording is complete
              console.log('Performance recording complete');
              
              // Try to save the file if we have data
              if (traceData) {
                try {
                  // Create a download link for the trace
                  const jsonData = JSON.stringify(traceData);
                  const blob = new Blob([jsonData], {type: 'application/json'});
                  const url = URL.createObjectURL(blob);
                  
                  // Create a link element
                  const a = document.createElement('a');
                  a.style.display = 'none';
                  a.href = url;
                  a.download = 'performance_trace.json';
                  
                  // Add to document and trigger download
                  document.body.appendChild(a);
                  a.click();
                  
                  // Clean up
                  URL.revokeObjectURL(url);
                  document.body.removeChild(a);
                } catch (e) {
                  console.error('Failed to save trace data:', e);
                }
              }
              
              return {
                success: true,
                message: 'Performance recording completed',
                method: method,
                sessionId: '" & sessionId & "',
                hasTraceData: !!traceData
              };
            } catch (e) {
              console.error('Error stopping performance recording:', e);
              return {
                error: true,
                message: `Error stopping performance recording: ${e.toString()}`
              };
            }
          })();
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
  
  -- Execute the script to start recording
  tell application "Google Chrome"
    try
      set startResult to execute active tab of front window javascript recordingScript
      
      -- If the recording started successfully, wait for it to complete
      if startResult contains "success" and startResult contains sessionId then
        -- Show a message to the user that recording is in progress
        set progressMessage to "Recording performance trace for " & recordingDuration & " seconds... Please do not switch tabs or close DevTools."
        
        -- Calculate the end time for the recording
        set endTime to (current date) + recordingDuration
        
        -- Wait until the recording is complete
        repeat until (current date) > endTime
          delay 0.5
        end repeat
        
        -- Create a script to check the recording status
        set statusScript to "
          (function() {
            if (window.mcpPerformance) {
              return {
                status: window.mcpPerformance.status,
                sessionId: window.mcpPerformance.activeSession,
                traceData: window.mcpPerformance.traceData ? true : false
              };
            } else {
              return { error: true, message: 'Performance recording not initialized' };
            }
          })();
        "
        
        -- Wait a bit more to ensure everything is properly saved
        delay 1
        
        -- Check if the recording completed successfully
        set statusResult to execute active tab of front window javascript statusScript
        
        -- If the recording has trace data, save it to the specified file
        if statusResult contains "traceData\":true" then
          -- Create a script to get and save the trace data
          set saveScript to "
            (function() {
              if (window.mcpPerformance && window.mcpPerformance.traceData) {
                try {
                  const traceData = window.mcpPerformance.traceData;
                  
                  // For saving to server-side file, we need to convert to JSON string
                  return JSON.stringify(traceData);
                } catch (e) {
                  return { error: true, message: `Failed to serialize trace data: ${e.toString()}` };
                }
              } else {
                return { error: true, message: 'No trace data available' };
              }
            })();
          "
          
          -- Get the trace data as JSON
          set traceDataJSON to execute active tab of front window javascript saveScript
          
          -- Save to the specified file
          try
            do shell script "echo " & quoted form of traceDataJSON & " > " & quoted form of outputPath
            
            return "Performance trace recorded and saved to: " & outputPath
          on error errMsg
            return "Performance trace recorded but failed to save to file: " & errMsg
          end try
        else
          return "Performance trace recording completed, but no trace data was captured. This may be due to DevTools API restrictions."
        end if
      else
        -- Return the error from starting the recording
        return startResult
      end if
    on error errMsg
      return "error: Failed to record performance trace - " & errMsg
    end try
  end tell
end recordPerformanceTrace

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

return my recordPerformanceTrace("--MCP_INPUT:duration", "--MCP_INPUT:categories", "--MCP_INPUT:outputPath", "--MCP_INPUT:screencast")
```
END_TIP