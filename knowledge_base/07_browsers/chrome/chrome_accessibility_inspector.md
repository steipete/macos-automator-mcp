---
title: 'Chrome: Accessibility Inspector'
category: 07_browsers
id: chrome_accessibility_inspector
description: >-
  Runs Chrome's Accessibility Inspector on a webpage or specific element,
  generating a comprehensive accessibility audit report or accessibility tree.
keywords:
  - Chrome
  - accessibility
  - a11y
  - audit
  - inspector
  - WCAG
  - screen reader
  - testing
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Options in inputData. For example: { "selector": "#main-content" } to audit a
  specific element, { "generateReport": true } for a full audit report, or {
  "showTree": true } to view the accessibility tree. Can also specify {
  "standards": ["wcag2a", "wcag2aa"] } to test against specific accessibility
  standards.
returnValueType: json
notes: >
  - Google Chrome must be running with at least one window and tab open.

  - Opens DevTools (if not already open) and activates the Accessibility panel.

  - Can run on the entire page or a specific element using CSS selectors.

  - Supports generating detailed accessibility audit reports with issues and
  suggestions.

  - Can visualize the accessibility tree used by screen readers and assistive
  technologies.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.
---

This script runs Chrome's Accessibility Inspector to audit webpages for accessibility issues and view the accessibility tree.

```applescript
--MCP_INPUT:selector
--MCP_INPUT:generateReport
--MCP_INPUT:showTree
--MCP_INPUT:standards

on runAccessibilityInspector(elementSelector, generateReport, showTree, standards)
  -- Set default values
  if showTree is missing value or showTree is "" then
    set showTree to false
  end if
  
  if generateReport is missing value or generateReport is "" then
    set generateReport to true
  end if
  
  if standards is missing value or standards is "" then
    -- Default to WCAG 2.0 levels A and AA
    set standards to {"wcag2a", "wcag2aa"}
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
  
  -- Open DevTools if not already open and switch to Elements tab first
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
      
      -- First ensure we're on the Elements panel
      key code 8 using {command down, option down} -- Option+Command+C for Elements panel
      delay 0.5
    end tell
  end tell
  
  -- Prepare the JavaScript for accessibility inspection
  set accessibilityScript to "
    (function() {
      try {
        /* Setup and utility functions */
        async function setupAccessibilityTools() {
          // Check if we need to select a specific element
          const selector = '" & my escapeJSString(elementSelector) & "';
          let targetElement = document;
          let nodeId = null;
          
          if (selector && selector !== '') {
            targetElement = document.querySelector(selector);
            if (!targetElement) {
              throw new Error('Element not found with selector: ' + selector);
            }
            
            // If we're in the DevTools context, try to highlight the element
            if (typeof SDK !== 'undefined' && SDK.DOMModel) {
              // Get all DOM models
              const domModels = SDK.targetManager.models(SDK.DOMModel);
              
              if (domModels.length > 0) {
                // Try to find the node in DevTools
                for (const domModel of domModels) {
                  try {
                    // Get the node ID for the element
                    const objectId = await new Promise(resolve => {
                      // Create a script to find the element and get its objectId
                      const script = `(function() { 
                        return document.querySelector('${selector}'); 
                      })()`;
                      
                      domModel.target().runtimeAgent().invoke_evaluate({
                        expression: script,
                        returnByValue: false
                      }, (error, result) => {
                        if (!error && result.result && result.result.objectId) {
                          resolve(result.result.objectId);
                        } else {
                          resolve(null);
                        }
                      });
                    });
                    
                    if (objectId) {
                      // Convert object ID to Node ID
                      nodeId = await new Promise(resolve => {
                        domModel.requestNode(objectId, (node) => {
                          resolve(node ? node.id : null);
                        });
                      });
                      
                      if (nodeId) {
                        // Highlight the node in the Elements panel
                        Common.Revealer.reveal(new SDK.DOMNode(domModel, nodeId));
                        break;
                      }
                    }
                  } catch (e) {
                    console.warn('Error finding element in DevTools:', e);
                  }
                }
              }
            }
          }
          
          return {
            targetElement,
            nodeId,
            hasAccessibilityPanel: typeof Components !== 'undefined' && typeof Components.AccessibilityTreeView !== 'undefined'
          };
        }
        
        /* Main accessibility functions */
        async function showAccessibilityTree() {
          try {
            const setup = await setupAccessibilityTools();
            
            // Try different methods to open the accessibility tree
            
            // Method 1: Use DevTools API if available
            if (typeof SDK !== 'undefined' && typeof UI !== 'undefined') {
              // Try to switch to the Accessibility panel in DevTools
              if (UI.panels && UI.panels.accessibility) {
                UI.panels.accessibility.showInPanel(setup.nodeId);
                return { 
                  success: true, 
                  message: 'Accessibility tree shown using DevTools API' 
                };
              }
              
              // Try to open the Accessibility pane in the Elements panel
              if (UI.panels && UI.panels.elements && UI.panels.elements.sidebarPaneView) {
                const sidebarView = UI.panels.elements.sidebarPaneView;
                const panes = sidebarView._tabbedPane;
                
                if (panes && panes._tabs) {
                  for (const tab of panes._tabs) {
                    if (tab.title.toLowerCase().includes('accessibility')) {
                      panes.selectTab(tab.id);
                      return { 
                        success: true, 
                        message: 'Accessibility panel shown in Elements sidebar' 
                      };
                    }
                  }
                }
              }
            }
            
            // Method 2: Try keyboard shortcuts
            // This is handled outside in the AppleScript UI automation
            
            // Method 3: Use accessibility API to extract the tree directly
            // This works in the page context, not DevTools context
            const axTree = [];
            
            function buildAccessibilityTree(element, depth = 0) {
              if (!element) return null;
              
              let axNode = {
                role: element.getAttribute('role') || getImplicitRole(element),
                name: getAccessibleName(element),
                tagName: element.tagName.toLowerCase(),
                depth: depth
              };
              
              // Add important properties
              if (element.hasAttribute('aria-label')) {
                axNode.ariaLabel = element.getAttribute('aria-label');
              }
              
              if (element.hasAttribute('aria-hidden')) {
                axNode.ariaHidden = element.getAttribute('aria-hidden');
              }
              
              if (element.hasAttribute('tabindex')) {
                axNode.tabIndex = element.getAttribute('tabindex');
              }
              
              // Add children
              const children = [];
              for (let i = 0; i < element.children.length; i++) {
                const childTree = buildAccessibilityTree(element.children[i], depth + 1);
                if (childTree) {
                  children.push(childTree);
                }
              }
              
              if (children.length > 0) {
                axNode.children = children;
              }
              
              return axNode;
            }
            
            function getImplicitRole(element) {
              // Very simplified implicit role detection
              const tag = element.tagName.toLowerCase();
              const roles = {
                'a': element.hasAttribute('href') ? 'link' : '',
                'button': 'button',
                'h1': 'heading',
                'h2': 'heading',
                'h3': 'heading',
                'h4': 'heading',
                'h5': 'heading',
                'h6': 'heading',
                'img': 'img',
                'input': getInputRole(element),
                'ul': 'list',
                'ol': 'list',
                'li': 'listitem',
                'table': 'table',
                'tr': 'row',
                'td': 'cell',
                'th': 'columnheader',
                'form': 'form',
                'nav': 'navigation',
                'main': 'main',
                'header': 'banner',
                'footer': 'contentinfo',
                'aside': 'complementary'
              };
              
              return roles[tag] || '';
            }
            
            function getInputRole(input) {
              const type = (input.getAttribute('type') || '').toLowerCase();
              const roles = {
                'checkbox': 'checkbox',
                'radio': 'radio',
                'submit': 'button',
                'button': 'button',
                'search': 'searchbox',
                'text': 'textbox'
              };
              
              return roles[type] || 'textbox';
            }
            
            function getAccessibleName(element) {
              // Simplified accessible name calculation
              if (element.hasAttribute('aria-label')) {
                return element.getAttribute('aria-label');
              }
              
              if (element.hasAttribute('aria-labelledby')) {
                const id = element.getAttribute('aria-labelledby');
                const labelElement = document.getElementById(id);
                if (labelElement) {
                  return labelElement.textContent.trim();
                }
              }
              
              // Check for label association (for form elements)
              if (element.id) {
                const label = document.querySelector(`label[for=\"${element.id}\"]`);
                if (label) {
                  return label.textContent.trim();
                }
              }
              
              // Check common attributes
              if (element.hasAttribute('alt')) {
                return element.getAttribute('alt');
              }
              
              if (element.hasAttribute('title')) {
                return element.getAttribute('title');
              }
              
              // For buttons, links, etc. use text content
              if (['button', 'a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(element.tagName.toLowerCase())) {
                return element.textContent.trim();
              }
              
              return '';
            }
            
            // Build the tree from the target element
            const tree = buildAccessibilityTree(setup.targetElement);
            
            return {
              success: true,
              message: 'Generated accessibility tree',
              tree: tree
            };
          } catch (e) {
            return {
              error: true,
              message: `Error showing accessibility tree: ${e.message}`,
              stack: e.stack
            };
          }
        }
        
        async function runAccessibilityAudit() {
          try {
            const setup = await setupAccessibilityTools();
            
            // Check if Lighthouse or Axe are available in DevTools
            let auditMethod = 'fallback';
            
            // Try to use Lighthouse API if available
            if (typeof Lighthouse !== 'undefined') {
              auditMethod = 'lighthouse';
            } 
            // Try to load Axe core if not in DevTools
            else if (typeof axe === 'undefined') {
              await new Promise((resolve, reject) => {
                const script = document.createElement('script');
                script.src = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.5.1/axe.min.js';
                script.onload = resolve;
                script.onerror = reject;
                document.head.appendChild(script);
              });
              
              if (typeof axe !== 'undefined') {
                auditMethod = 'axe';
              }
            } else {
              auditMethod = 'axe';
            }
            
            // Based on available tools, run the audit
            if (auditMethod === 'lighthouse' && typeof Lighthouse.startLighthouse === 'function') {
              // Use Lighthouse within DevTools
              const flags = {
                categoryIDs: ['accessibility'],
                emulatedFormFactor: 'desktop'
              };
              
              const results = await new Promise((resolve) => {
                Lighthouse.startLighthouse('', flags, resolve);
              });
              
              // Extract the accessibility results
              const accessibilityResults = results.reportCategories.find(
                category => category.id === 'accessibility'
              );
              
              return {
                success: true,
                message: 'Accessibility audit completed using Lighthouse',
                auditMethod: 'lighthouse',
                score: accessibilityResults.score,
                results: accessibilityResults.audits
              };
            } 
            else if (auditMethod === 'axe' && typeof axe !== 'undefined') {
              // Configure Axe based on standards
              const standards = " & (if standards is missing value or standards is "" then "['wcag2a', 'wcag2aa']" else my listToJSArray(standards)) & ";
              
              const axeOptions = {
                runOnly: {
                  type: 'tag',
                  values: standards
                },
                reporter: 'v2'
              };
              
              // Run Axe on the target element or whole document
              const context = setup.targetElement === document ? 
                document : 
                { include: [setup.targetElement] };
              
              const results = await axe.run(context, axeOptions);
              
              // Format results
              const formattedResults = {
                violations: results.violations.map(issue => ({
                  id: issue.id,
                  impact: issue.impact,
                  description: issue.description,
                  help: issue.help,
                  helpUrl: issue.helpUrl,
                  nodes: issue.nodes.map(node => ({
                    html: node.html,
                    impact: node.impact,
                    target: node.target,
                    failureSummary: node.failureSummary
                  }))
                })),
                passes: results.passes.map(pass => ({
                  id: pass.id,
                  description: pass.description,
                  nodes: pass.nodes.length
                })),
                incomplete: results.incomplete.map(incomplete => ({
                  id: incomplete.id,
                  impact: incomplete.impact,
                  description: incomplete.description,
                  nodes: incomplete.nodes.length
                }))
              };
              
              // Calculate a simple score based on issues
              const totalChecks = results.passes.length + results.violations.length + results.incomplete.length;
              const score = Math.round((results.passes.length / totalChecks) * 100) / 100;
              
              return {
                success: true,
                message: 'Accessibility audit completed using axe-core',
                auditMethod: 'axe',
                score: score,
                results: formattedResults
              };
            } 
            else {
              // Fallback: Basic accessibility checks
              const issues = [];
              
              // Function to check basic accessibility rules
              function checkAccessibility(element) {
                // Images without alt text
                if (element.tagName === 'IMG' && (!element.hasAttribute('alt') || element.getAttribute('alt') === '')) {
                  issues.push({
                    rule: 'img-alt',
                    impact: 'critical',
                    element: element.outerHTML.substring(0, 100),
                    message: 'Image has no alt text'
                  });
                }
                
                // Inputs without labels
                if (element.tagName === 'INPUT' && element.type !== 'button' && element.type !== 'submit' && element.type !== 'hidden') {
                  let hasLabel = false;
                  
                  // Check for associated label
                  if (element.id) {
                    hasLabel = !!document.querySelector(`label[for=\"${element.id}\"]`);
                  }
                  
                  // Check for aria-label
                  if (!hasLabel && (!element.hasAttribute('aria-label') || element.getAttribute('aria-label') === '')) {
                    issues.push({
                      rule: 'input-label',
                      impact: 'critical',
                      element: element.outerHTML.substring(0, 100),
                      message: 'Form input has no associated label'
                    });
                  }
                }
                
                // Links with no text
                if (element.tagName === 'A' && element.textContent.trim() === '' && 
                    !element.hasAttribute('aria-label') && !element.querySelector('img[alt]')) {
                  issues.push({
                    rule: 'link-text',
                    impact: 'critical',
                    element: element.outerHTML.substring(0, 100),
                    message: 'Link has no text content'
                  });
                }
                
                // Color contrast (simplified, just checks computed style)
                const style = window.getComputedStyle(element);
                if (element.textContent.trim() !== '' && 
                    style.color === style.backgroundColor) {
                  issues.push({
                    rule: 'color-contrast',
                    impact: 'serious',
                    element: element.outerHTML.substring(0, 100),
                    message: 'Text may have insufficient contrast with background'
                  });
                }
                
                // Check heading order
                if (['H1', 'H2', 'H3', 'H4', 'H5', 'H6'].includes(element.tagName)) {
                  const headingLevel = parseInt(element.tagName.substring(1));
                  const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
                  const index = headings.indexOf(element);
                  
                  if (index > 0) {
                    const prevHeading = headings[index - 1];
                    const prevLevel = parseInt(prevHeading.tagName.substring(1));
                    
                    if (headingLevel > prevLevel + 1) {
                      issues.push({
                        rule: 'heading-order',
                        impact: 'moderate',
                        element: element.outerHTML.substring(0, 100),
                        message: `Heading levels should only increase by one (found h${prevLevel} followed by h${headingLevel})`
                      });
                    }
                  }
                }
                
                // Recursively check children
                for (let i = 0; i < element.children.length; i++) {
                  checkAccessibility(element.children[i]);
                }
              }
              
              // Run the checks
              checkAccessibility(setup.targetElement);
              
              // Calculate a simple score
              const score = Math.max(0, 1 - (issues.length / 10));
              
              return {
                success: true,
                message: 'Basic accessibility audit completed',
                auditMethod: 'basic',
                score: score,
                results: {
                  violations: issues,
                  passes: [],
                  incomplete: []
                }
              };
            }
          } catch (e) {
            return {
              error: true,
              message: `Error running accessibility audit: ${e.message}`,
              stack: e.stack
            };
          }
        }
        
        /* Main execution */
        const showTreeOption = " & showTree & ";
        const generateReportOption = " & generateReport & ";
        
        // Run the appropriate functions based on options
        return (async () => {
          let results = { status: 'completed' };
          
          if (showTreeOption) {
            results.treeResult = await showAccessibilityTree();
          }
          
          if (generateReportOption) {
            results.auditResult = await runAccessibilityAudit();
          }
          
          return results;
        })();
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
      set initResult to execute active tab of front window javascript accessibilityScript
      
      -- Check if we got a Promise (async execution)
      if initResult contains "Promise" then
        -- Wait for the promise to resolve with a follow-up script
        delay 1
        
        -- Poll for the result
        set resultScript to "
          (function() {
            // This just returns the latest result
            const displayTree = function(node, indent = 0) {
              if (!node) return '';
              
              const spacing = ' '.repeat(indent * 2);
              let output = spacing + node.role + (node.name ? ': ' + node.name : '') + '\\n';
              
              if (node.children && node.children.length > 0) {
                node.children.forEach(child => {
                  output += displayTree(child, indent + 1);
                });
              }
              
              return output;
            };
            
            // Format the results for display
            if (window.accessibilityResults) {
              const results = window.accessibilityResults;
              
              // Add a text representation of the tree if available
              if (results.treeResult && results.treeResult.tree) {
                results.treeText = displayTree(results.treeResult.tree);
              }
              
              return results;
            }
            
            return { status: 'waiting' };
          })();
        "
        
        -- Poll for the results with timeout
        set maxAttempts to 30
        set attemptCounter to 0
        
        repeat
          delay 0.5
          set attemptCounter to attemptCounter + 1
          set resultCheck to execute active tab of front window javascript resultScript
          
          -- If we got a result with 'status' other than 'waiting', we're done
          if resultCheck is not missing value and resultCheck does not contain "waiting" then
            return resultCheck
          end if
          
          -- Timeout check
          if attemptCounter ≥ maxAttempts then
            return "{\"error\": true, \"message\": \"Timed out waiting for accessibility inspection to complete.\"}"
          end if
        end repeat
      else
        -- Return the immediate result if not a Promise
        return initResult
      end if
    on error errMsg
      return "{\"error\": true, \"message\": \"" & my escapeJSString(errMsg) & "\"}"
    end try
  end tell
end runAccessibilityInspector

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

-- Helper function to convert AppleScript list to JavaScript array
on listToJSArray(theList)
  set jsArray to "["
  repeat with i from 1 to count of theList
    set thisItem to item i of theList
    
    -- Handle strings with quotes
    if class of thisItem is string then
      set jsArray to jsArray & "\"" & my escapeJSString(thisItem) & "\""
    else
      set jsArray to jsArray & thisItem
    end if
    
    if i < count of theList then
      set jsArray to jsArray & ", "
    end if
  end repeat
  set jsArray to jsArray & "]"
  return jsArray
end listToJSArray

return my runAccessibilityInspector("--MCP_INPUT:selector", "--MCP_INPUT:generateReport", "--MCP_INPUT:showTree", "--MCP_INPUT:standards")
```
END_TIP
