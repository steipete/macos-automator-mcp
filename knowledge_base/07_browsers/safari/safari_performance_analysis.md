---
title: 'Safari: Performance Analysis'
category: 07_browsers
id: safari_performance_analysis
description: >-
  Analyzes and reports on the performance of webpages in Safari, including load
  times, rendering metrics, JavaScript execution, and resource usage.
keywords:
  - Safari
  - performance
  - web development
  - profiling
  - metrics
  - speed
  - optimization
  - load time
  - rendering
  - memory
language: applescript
isComplex: true
argumentsPrompt: >-
  Analysis type as 'analysisType' ('page', 'javascript', 'memory', 'resources',
  'all') and optional test URL as 'url' in inputData.
notes: >
  - Safari must be running with at least one open tab, or a URL must be
  provided.

  - "Allow JavaScript from Apple Events" must be enabled in Safari's Develop
  menu.

  - Available analysis types:
    - 'page': Basic page load metrics (DOMContentLoaded, load event)
    - 'javascript': JavaScript execution time and CPU usage
    - 'memory': Memory usage and potential memory leaks
    - 'resources': Resource loading analysis (images, scripts, CSS)
    - 'all': Comprehensive analysis of all aspects
  - The script uses Navigation Timing API, Performance API, and Resource Timing
  API when available.

  - Results are returned in JSON format for easy parsing and analysis.

  - For most accurate results, use the script on a freshly loaded page with
  minimal browser extensions.

  - Some metrics (like memory usage) require multiple samples for accurate
  trending.
---

This script analyzes the performance of webpages in Safari, providing detailed metrics for optimization.

```applescript
--MCP_INPUT:analysisType
--MCP_INPUT:url

on analyzePerformance(analysisType, testURL)
  -- Validate analysis type
  if analysisType is missing value or analysisType is "" then
    set analysisType to "all"
  else
    set analysisType to my toLowerCase(analysisType)
    if analysisType is not "page" and analysisType is not "javascript" and analysisType is not "memory" and analysisType is not "resources" and analysisType is not "all" then
      return "error: Invalid analysis type. Must be 'page', 'javascript', 'memory', 'resources', or 'all'."
    end if
  end if
  
  -- Check if we need to open a URL first
  set needToOpenURL to false
  if testURL is not missing value and testURL is not "" then
    set needToOpenURL to true
    
    -- Ensure URL has protocol
    if testURL does not start with "http://" and testURL does not start with "https://" then
      set testURL to "https://" & testURL
    end if
  end if
  
  -- Prepare performance analysis JavaScript
  set perfJS to "
    (function() {
      // Start timer for our own script's execution time
      const scriptStartTime = performance.now();
      
      // Analyze navigation and page load performance
      function analyzePagePerformance() {
        const result = {
          metrics: {
            timing: {},
            navigation: {}
          },
          domInfo: {}
        };
        
        // Check if Navigation Timing API is available
        if (window.performance && performance.timing) {
          const timing = performance.timing;
          
          // Calculate key metrics
          result.metrics.timing = {
            // DNS lookup time
            dnsLookup: timing.domainLookupEnd - timing.domainLookupStart,
            
            // Connection time
            tcpConnection: timing.connectEnd - timing.connectStart,
            
            // Server response time
            serverResponse: timing.responseEnd - timing.requestStart,
            
            // Document download time
            documentDownload: timing.responseEnd - timing.responseStart,
            
            // DOM processing time
            domProcessing: timing.domComplete - timing.domLoading,
            
            // DOM content loaded
            domContentLoaded: timing.domContentLoadedEventEnd - timing.navigationStart,
            
            // Window load event
            windowLoad: timing.loadEventEnd - timing.navigationStart,
            
            // Total page load time
            totalPageLoad: timing.loadEventEnd - timing.navigationStart,
            
            // Time to first byte
            timeToFirstByte: timing.responseStart - timing.navigationStart,
            
            // Time to interactive
            timeToInteractive: timing.domInteractive - timing.navigationStart
          };
          
          // Navigation type
          if (performance.navigation) {
            const navType = performance.navigation.type;
            if (navType === 0) {
              result.metrics.navigation.type = 'Navigation: Direct entry or link';
            } else if (navType === 1) {
              result.metrics.navigation.type = 'Navigation: Reload';
            } else if (navType === 2) {
              result.metrics.navigation.type = 'Navigation: Back/forward button';
            } else {
              result.metrics.navigation.type = 'Navigation: Other/unknown';
            }
            
            result.metrics.navigation.redirectCount = performance.navigation.redirectCount;
          }
        } else {
          result.metrics.error = 'Navigation Timing API not available';
        }
        
        // DOM statistics
        result.domInfo = {
          elementCount: document.getElementsByTagName('*').length,
          scriptCount: document.getElementsByTagName('script').length,
          styleSheetCount: document.styleSheets.length,
          domDepth: getDOMDepth(document.body),
          eventListenerCount: estimateEventListeners()
        };
        
        return result;
      }
      
      // Analyze JavaScript performance
      function analyzeJavaScriptPerformance() {
        const result = {
          scriptExecution: {},
          jsErrors: []
        };
        
        // Measure DOM event handlers' execution time (approximate)
        result.scriptExecution.eventHandlers = measureEventHandlers();
        
        // Snapshot of recent JavaScript errors
        try {
          // Try to access previous errors if any
          if (window._jsErrorLog) {
            result.jsErrors = window._jsErrorLog;
          }
          
          // Set up error logging for future errors
          if (!window._jsErrorLogSetup) {
            window._jsErrorLog = [];
            window.addEventListener('error', function(error) {
              window._jsErrorLog.push({
                message: error.message,
                source: error.filename,
                lineNumber: error.lineno,
                columnNumber: error.colno,
                timestamp: new Date().toISOString()
              });
            });
            window._jsErrorLogSetup = true;
          }
        } catch (e) {
          result.jsErrors.push({
            message: 'Error setting up JS error logging: ' + e.message
          });
        }
        
        return result;
      }
      
      // Analyze memory usage
      function analyzeMemoryUsage() {
        const result = {
          general: {},
          detailed: {}
        };
        
        // Basic memory info (might not be available in all browsers)
        if (window.performance && performance.memory) {
          result.general = {
            jsHeapSizeLimit: formatBytes(performance.memory.jsHeapSizeLimit),
            totalJSHeapSize: formatBytes(performance.memory.totalJSHeapSize),
            usedJSHeapSize: formatBytes(performance.memory.usedJSHeapSize),
            heapUtilization: (performance.memory.usedJSHeapSize / performance.memory.totalJSHeapSize * 100).toFixed(2) + '%'
          };
        } else {
          result.general.status = 'Memory performance API not available';
        }
        
        // DOM memory usage estimation
        const domSnapshot = {
          elementCount: document.getElementsByTagName('*').length,
          nodeCount: document.getElementsByTagName('*').length + document.createTreeWalker(document, NodeFilter.SHOW_COMMENT).filter(() => true).length,
          textNodeCount: document.createTreeWalker(document, NodeFilter.SHOW_TEXT).filter(() => true).length,
          attributeCount: countAttributes(),
          estimatedMemoryUsage: 'Unknown'
        };
        
        // Rough estimation of DOM memory usage (very approximate)
        // Typical element ~1-2KB, text node ~50-100 bytes, attribute ~40 bytes
        const estimatedBytes = 
          domSnapshot.elementCount * 1500 +
          domSnapshot.textNodeCount * 80 +
          domSnapshot.attributeCount * 40;
        
        domSnapshot.estimatedMemoryUsage = formatBytes(estimatedBytes) + ' (rough estimate)';
        result.detailed.dom = domSnapshot;
        
        return result;
      }
      
      // Analyze resource loading performance
      function analyzeResourcePerformance() {
        const result = {
          summary: {},
          resourcesByType: {},
          largestResources: [],
          slowestResources: []
        };
        
        // Check if Resource Timing API is available
        if (window.performance && performance.getEntriesByType) {
          const resources = performance.getEntriesByType('resource');
          
          // Summary statistics
          result.summary = {
            totalResources: resources.length,
            totalSize: 0,
            totalLoadTime: 0
          };
          
          // Group resources by type and calculate statistics
          const resourceTypes = {};
          const sizeByType = {};
          const timeByType = {};
          
          resources.forEach(resource => {
            // Get resource type
            let type = resource.initiatorType;
            if (!type || type === 'other') {
              // Try to determine type by extension
              const url = resource.name;
              if (url.match(/\\.(?:jpg|jpeg|png|gif|webp|svg|ico)(?:[?#]|$)/i)) {
                type = 'image';
              } else if (url.match(/\\.(?:css)(?:[?#]|$)/i)) {
                type = 'css';
              } else if (url.match(/\\.(?:js)(?:[?#]|$)/i)) {
                type = 'script';
              } else if (url.match(/\\.(?:woff2?|ttf|otf|eot)(?:[?#]|$)/i)) {
                type = 'font';
              } else {
                type = 'other';
              }
            }
            
            // Count by type
            resourceTypes[type] = (resourceTypes[type] || 0) + 1;
            
            // Processing time
            const loadTime = resource.responseEnd - resource.startTime;
            timeByType[type] = (timeByType[type] || 0) + loadTime;
            result.summary.totalLoadTime += loadTime;
            
            // Resource size (can be 0 if CORS prevents access)
            let resourceSize = 0;
            if (resource.transferSize) {
              resourceSize = resource.transferSize;
              sizeByType[type] = (sizeByType[type] || 0) + resourceSize;
              result.summary.totalSize += resourceSize;
            }
            
            // Add to top resources lists
            result.largestResources.push({
              url: resource.name,
              type: type,
              size: resourceSize,
              loadTime: loadTime
            });
            
            result.slowestResources.push({
              url: resource.name,
              type: type,
              loadTime: loadTime,
              size: resourceSize
            });
          });
          
          // Sort and limit largest resources
          result.largestResources.sort((a, b) => b.size - a.size);
          result.largestResources = result.largestResources.slice(0, 10);
          
          // Sort and limit slowest resources
          result.slowestResources.sort((a, b) => b.loadTime - a.loadTime);
          result.slowestResources = result.slowestResources.slice(0, 10);
          
          // Format summary with readable sizes
          result.summary.totalSize = formatBytes(result.summary.totalSize);
          result.summary.totalLoadTime = Math.round(result.summary.totalLoadTime) + 'ms';
          
          // Create resource breakdown by type
          Object.keys(resourceTypes).forEach(type => {
            result.resourcesByType[type] = {
              count: resourceTypes[type],
              totalSize: sizeByType[type] ? formatBytes(sizeByType[type]) : 'unknown',
              totalLoadTime: Math.round(timeByType[type]) + 'ms',
              averageLoadTime: Math.round(timeByType[type] / resourceTypes[type]) + 'ms'
            };
          });
        } else {
          result.error = 'Resource Timing API not available';
        }
        
        return result;
      }
      
      // Helper function to get DOM depth
      function getDOMDepth(node, depth = 0) {
        if (!node || !node.children) return depth;
        
        let maxChildDepth = depth;
        for (let i = 0; i < node.children.length; i++) {
          const childDepth = getDOMDepth(node.children[i], depth + 1);
          maxChildDepth = Math.max(maxChildDepth, childDepth);
          
          // Limit depth calculation to avoid excessive processing
          if (i > 100) break;
        }
        
        return maxChildDepth;
      }
      
      // Helper function to count attributes in the DOM
      function countAttributes() {
        let attributeCount = 0;
        const elements = document.getElementsByTagName('*');
        for (let i = 0; i < elements.length; i++) {
          attributeCount += elements[i].attributes.length;
        }
        return attributeCount;
      }
      
      // Helper function to estimate number of event listeners
      function estimateEventListeners() {
        const elements = document.getElementsByTagName('*');
        let estimatedListeners = 0;
        
        // Check for common event attribute patterns
        for (let i = 0; i < elements.length; i++) {
          const element = elements[i];
          const attributes = element.attributes;
          
          for (let j = 0; j < attributes.length; j++) {
            const attrName = attributes[j].name.toLowerCase();
            if (attrName.startsWith('on')) {
              estimatedListeners++;
            }
          }
          
          // Check if element has click handler using a heuristic approach
          const style = window.getComputedStyle(element);
          if (style.cursor === 'pointer') {
            estimatedListeners++;
          }
        }
        
        // Note: This is just an estimation as we can't reliably detect all event listeners
        return estimatedListeners;
      }
      
      // Helper function to measure event handler performance
      function measureEventHandlers() {
        const result = {
          message: 'Event handler analysis would require longer interaction with the page'
        };
        
        // This is a simplified version - a comprehensive analysis would require
        // monitoring the page during user interaction
        return result;
      }
      
      // Helper function to format bytes in a readable format
      function formatBytes(bytes, decimals = 2) {
        if (bytes === 0) return '0 Bytes';
        
        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
      }
      
      // Combine the results based on the requested analysis type
      const result = {
        url: window.location.href,
        pageTitle: document.title,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent
      };
      
      const analysisType = '" & analysisType & "';
      
      if (analysisType === 'page' || analysisType === 'all') {
        result.pagePerformance = analyzePagePerformance();
      }
      
      if (analysisType === 'javascript' || analysisType === 'all') {
        result.javascriptPerformance = analyzeJavaScriptPerformance();
      }
      
      if (analysisType === 'memory' || analysisType === 'all') {
        result.memoryUsage = analyzeMemoryUsage();
      }
      
      if (analysisType === 'resources' || analysisType === 'all') {
        result.resourcePerformance = analyzeResourcePerformance();
      }
      
      // Add our script's execution time
      result.analysisExecutionTime = (performance.now() - scriptStartTime).toFixed(2) + 'ms';
      
      return JSON.stringify(result, null, 2);
    })();
  "
  
  tell application "Safari"
    if not running then
      return "error: Safari is not running."
    end if
    
    -- If a URL was provided, open it first
    if needToOpenURL then
      try
        tell window 1
          set current tab to (make new tab with properties {URL:testURL})
          delay 3 -- Wait for page to load
        end tell
      on error errMsg
        return "error: Failed to open URL - " & errMsg
      end try
    end if
    
    try
      if (count of windows) is 0 or (count of tabs of front window) is 0 then
        return "error: No tabs open in Safari."
      end if
      
      set currentTab to current tab of front window
      
      -- Execute the JavaScript
      set jsResult to do JavaScript perfJS in currentTab
      
      return jsResult
    on error errMsg
      return "error: Failed to analyze page performance - " & errMsg & ". Make sure 'Allow JavaScript from Apple Events' is enabled in Safari's Develop menu."
    end try
  end tell
end analyzePerformance

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

return my analyzePerformance("--MCP_INPUT:analysisType", "--MCP_INPUT:url")
```
