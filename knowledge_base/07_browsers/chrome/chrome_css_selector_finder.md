---
title: "Chrome: CSS Selector Finder"
category: "05_web_browsers"
id: chrome_css_selector_finder
description: "Finds optimal CSS selectors for web elements using various strategies including shortest unique path, ID-based, and robust attribute selectors."
keywords: ["Chrome", "CSS", "selector", "finder", "XPath", "web scraping", "automation", "web development", "element selection"]
language: applescript
isComplex: true
argumentsPrompt: "Options in inputData. For example: { \"interactiveMode\": true } to enter point-and-click element selection mode, or { \"searchText\": \"Login\" } to find elements containing specific text. Use { \"generateOptions\": [\"shortest\", \"id-based\", \"robust\"] } to control selector generation strategies."
returnValueType: json
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Can operate in interactive mode for visual element selection or search for elements programmatically.
  - Generates multiple selector types (CSS, XPath) with varying levels of specificity and robustness.
  - Very useful for building automation scripts that need reliable element selectors.
  - Supports multiple selection strategies including text-based, attribute-based, and relative positioning.
  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View > Developer menu.
  - Requires Accessibility permissions for UI scripting via System Events.
---

This script finds optimal CSS selectors for web elements using various strategies to support web automation.

```applescript
--MCP_INPUT:interactiveMode
--MCP_INPUT:searchText
--MCP_INPUT:generateOptions

on findCssSelectors(interactiveMode, searchText, generateOptions)
  -- Set default values
  if interactiveMode is missing value or interactiveMode is "" then
    set interactiveMode to false
  end if
  
  if generateOptions is missing value or generateOptions is "" then
    set generateOptions to {"shortest", "id-based", "robust", "xpath"}
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
  
  -- Generate a unique ID for this session
  set sessionId to "mcpCssSelector_" & (random number from 100000 to 999999) as string
  
  if interactiveMode then
    -- Show instructions to the user via dialog
    tell application "System Events"
      display dialog "CSS Selector Finder: Interactive Mode" & return & return & "1. Click on any element in Chrome to select it" & return & "2. The script will generate optimal selectors" & return & return & "Press OK to start interactive element selection" buttons {"Cancel", "OK"} default button "OK"
      
      if button returned of result is "Cancel" then
        return "User canceled interactive selector finder."
      end if
    end tell
  end if
  
  -- Prepare the JavaScript for CSS selector finding
  set selectorScript to "
    (function() {
      try {
        // Create a namespace for our selector finder
        if (!window.mcpSelectorFinder) {
          window.mcpSelectorFinder = {
            activeSession: null,
            selectedElement: null,
            selectors: [],
            status: 'idle',
            highlightBox: null
          };
        }
        
        // Clear any existing session with the same ID
        if (window.mcpSelectorFinder.activeSession === '" & sessionId & "') {
          console.log('Stopping previous selector session with same ID');
          window.mcpSelectorFinder.activeSession = null;
          window.mcpSelectorFinder.selectedElement = null;
          window.mcpSelectorFinder.selectors = [];
          window.mcpSelectorFinder.status = 'idle';
          
          // Remove any previous highlight box
          if (window.mcpSelectorFinder.highlightBox) {
            document.body.removeChild(window.mcpSelectorFinder.highlightBox);
            window.mcpSelectorFinder.highlightBox = null;
          }
          
          // Remove any event listeners from previous sessions
          document.removeEventListener('click', window.mcpSelectorFinder._clickHandler);
          document.removeEventListener('mouseover', window.mcpSelectorFinder._mouseoverHandler);
          document.removeEventListener('mouseout', window.mcpSelectorFinder._mouseoutHandler);
        }
        
        // Set up the new session
        window.mcpSelectorFinder.activeSession = '" & sessionId & "';
        window.mcpSelectorFinder.status = 'initializing';
        window.mcpSelectorFinder.generateOptions = " & my convertListToJSArray(generateOptions) & ";
        
        /* ----- Selector Generation Utilities ----- */
        
        // Get optimal ID-based selector if available
        function getIdBasedSelector(element) {
          // If element has ID, that's the optimal selector
          if (element.id) {
            return { 
              selector: '#' + CSS.escape(element.id), 
              type: 'id-based',
              specificity: 'high',
              description: 'Direct ID selector'
            };
          }
          
          // Look for parent with ID, then relative path
          let current = element;
          let path = [];
          while (current && current !== document.body) {
            let parent = current.parentElement;
            if (!parent) break;
            
            if (parent.id) {
              // Found parent with ID, now create relative path
              const tag = element.tagName.toLowerCase();
              const index = Array.from(parent.children).filter(c => c.tagName === element.tagName).indexOf(element);
              
              if (index === 0 && Array.from(parent.children).filter(c => c.tagName === element.tagName).length === 1) {
                // Only one element of this type, no need for :nth-child
                path.unshift(tag);
              } else {
                // Need to use nth-child
                path.unshift(`${tag}:nth-child(${index + 1})`);
              }
              
              return {
                selector: `#${CSS.escape(parent.id)} > ${path.join(' > ')}`,
                type: 'id-based-parent',
                specificity: 'medium',
                description: 'Parent ID-based with child relation'
              };
            }
            
            // No ID found, add to path and move up
            const tag = current.tagName.toLowerCase();
            const index = Array.from(parent.children).filter(c => c.tagName === current.tagName).indexOf(current);
            
            if (index === 0 && Array.from(parent.children).filter(c => c.tagName === current.tagName).length === 1) {
              path.unshift(tag);
            } else {
              path.unshift(`${tag}:nth-child(${index + 1})`);
            }
            
            current = parent;
          }
          
          // No good ID-based selectors found
          return null;
        }
        
        // Get shortest unique path selector
        function getShortestUniqueSelector(element) {
          // Try different combination strategies from most specific to least
          const strategies = [
            // Tag + ID (if available)
            function() {
              if (element.id) {
                return `${element.tagName.toLowerCase()}#${CSS.escape(element.id)}`;
              }
              return null;
            },
            
            // Tag + Class (if available and unique)
            function() {
              if (element.classList.length) {
                const cls = Array.from(element.classList)
                  .map(c => `.${CSS.escape(c)}`)
                  .join('');
                const selector = `${element.tagName.toLowerCase()}${cls}`;
                
                // Check if unique
                if (document.querySelectorAll(selector).length === 1) {
                  return selector;
                }
              }
              return null;
            },
            
            // Tag + Attribute (common attributes only)
            function() {
              const attributes = ['name', 'data-test', 'data-testid', 'data-cy', 'data-qa', 'data-target'];
              
              for (const attr of attributes) {
                if (element.hasAttribute(attr)) {
                  const selector = `${element.tagName.toLowerCase()}[${attr}='${element.getAttribute(attr)}']`;
                  
                  // Check if unique
                  if (document.querySelectorAll(selector).length === 1) {
                    return selector;
                  }
                }
              }
              return null;
            },
            
            // Try with content-based selectors (for text elements)
            function() {
              const text = element.textContent.trim();
              if (text && text.length < 50) {
                // For elements that typically contain text
                if (['P', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'SPAN', 'A', 'BUTTON', 'LABEL'].includes(element.tagName)) {
                  const escapedText = text.replace(/['\"]/g, '\\\\$&');
                  
                  // Try with exact text content match
                  const selector = `${element.tagName.toLowerCase()}:contains('${escapedText}')`;
                  
                  // This :contains selector is not standard CSS but works in jQuery
                  // We're just generating it, we'll check for uniqueness differently
                  const similarElements = Array.from(document.querySelectorAll(element.tagName))
                    .filter(el => el.textContent.trim() === text);
                  
                  if (similarElements.length === 1) {
                    return selector;
                  }
                }
              }
              return null;
            }
          ];
          
          // Try each strategy until we find a unique selector
          for (const strategy of strategies) {
            const selector = strategy();
            if (selector) {
              return {
                selector: selector,
                type: 'shortest-unique',
                specificity: 'medium',
                description: 'Shortest unique element selector'
              };
            }
          }
          
          // If no unique simple selector, try a short path
          let current = element;
          let path = [];
          const pathLimit = 3; // Limit path depth for brevity
          
          while (current && current !== document.body && path.length < pathLimit) {
            const tag = current.tagName.toLowerCase();
            
            // Add any class that seems to be a non-utility class
            // (avoids classes likely to change like positioning utilities)
            const significantClasses = Array.from(current.classList)
              .filter(c => !c.match(/^(is-|has-|position-|d-|p-|m-|col-|row-|text-|bg-|border-|flex-|grid-|w-|h-)/))
              .map(c => `.${CSS.escape(c)}`)
              .join('');
            
            path.unshift(tag + significantClasses);
            
            // Check if the current path is unique
            const currentPath = path.join(' > ');
            if (document.querySelectorAll(currentPath).length === 1) {
              return {
                selector: currentPath,
                type: 'shortest-path',
                specificity: 'medium',
                description: 'Short path with moderate specificity'
              };
            }
            
            current = current.parentElement;
          }
          
          // No good short selector found, we'll fall back to other methods
          return null;
        }
        
        // Get robust selector with multiple attributes (less likely to break)
        function getRobustSelector(element) {
          // Start with tag name
          let selectorParts = [element.tagName.toLowerCase()];
          
          // Add ID if available
          if (element.id) {
            selectorParts.push(`#${CSS.escape(element.id)}`);
          }
          
          // Add classes that seem semantic (not utility classes) - limit to first 2
          const semanticClasses = Array.from(element.classList)
            .filter(c => !c.match(/^(is-|has-|position-|d-|p-|m-|col-|row-|text-|bg-|border-|flex-|grid-|w-|h-)/))
            .slice(0, 2);
          
          for (const cls of semanticClasses) {
            selectorParts.push(`.${CSS.escape(cls)}`);
          }
          
          // Add stable attributes
          const stableAttributes = ['name', 'type', 'role', 'aria-label', 'data-test', 'data-testid', 'data-target'];
          
          for (const attr of stableAttributes) {
            if (element.hasAttribute(attr)) {
              selectorParts.push(`[${attr}='${element.getAttribute(attr)}']`);
            }
          }
          
          // If we have a good robust selector at this point, use it
          const directSelector = selectorParts.join('');
          
          // Otherwise, create a hierarchical selector with parent context
          if (document.querySelectorAll(directSelector).length === 1) {
            return {
              selector: directSelector,
              type: 'robust-direct',
              specificity: 'high',
              description: 'Robust multi-attribute selector'
            };
          }
          
          // If direct selector isn't unique, add parent context
          let current = element;
          let path = [directSelector];
          const pathLimit = 2; // Limit to 2 levels up
          
          while (current.parentElement && current.parentElement !== document.body && path.length <= pathLimit) {
            current = current.parentElement;
            
            let parentSelector = current.tagName.toLowerCase();
            
            // Add parent ID if available
            if (current.id) {
              parentSelector += `#${CSS.escape(current.id)}`;
            } 
            // Otherwise add some classes
            else if (current.classList.length) {
              const semanticParentClasses = Array.from(current.classList)
                .filter(c => !c.match(/^(is-|has-|position-|d-|p-|m-|col-|row-|text-|bg-|border-|flex-|grid-|w-|h-)/))
                .slice(0, 1); // Limit to 1 parent class
              
              for (const cls of semanticParentClasses) {
                parentSelector += `.${CSS.escape(cls)}`;
              }
            }
            
            path.unshift(parentSelector);
            
            // Check if current path is unique
            const currentPath = path.join(' > ');
            if (document.querySelectorAll(currentPath).length === 1) {
              return {
                selector: currentPath,
                type: 'robust-path',
                specificity: 'high',
                description: 'Robust path-based selector with multiple attributes'
              };
            }
          }
          
          // Return the most specific one we have, even if not unique
          return {
            selector: path.join(' > '),
            type: 'robust-fallback',
            specificity: 'medium',
            description: 'Robust selector (may match multiple elements)',
            uniqueMatch: false
          };
        }
        
        // Get XPath selector for the element
        function getXPathSelector(element) {
          // Function to get XPath of element
          function getElementXPath(element) {
            if (!element) return '';
            
            // If element has ID, use it for a simple XPath
            if (element.id) {
              return `//*[@id='${element.id}']`;
            }
            
            // Otherwise, get full path to element
            let xpath = '';
            let current = element;
            
            while (current && current.nodeType === Node.ELEMENT_NODE) {
              let index = 0;
              let sibling = current;
              
              // Count previous siblings with same tag name
              while (sibling) {
                if (sibling.nodeType === Node.ELEMENT_NODE && sibling.tagName === current.tagName) {
                  index++;
                }
                sibling = sibling.previousSibling;
              }
              
              // Build the XPath segment
              let tagName = current.tagName.toLowerCase();
              let indexSuffix = index > 1 ? `[${index}]` : '';
              
              // Add any relevant attributes for better identification
              let attrs = '';
              if (current.hasAttribute('name')) {
                attrs = `[@name='${current.getAttribute('name')}']`;
              } else if (current.hasAttribute('data-testid')) {
                attrs = `[@data-testid='${current.getAttribute('data-testid')}']`;
              } else if (current.hasAttribute('role')) {
                attrs = `[@role='${current.getAttribute('role')}']`;
              }
              
              // If we have good attributes, use them instead of positional index
              let pathSegment = attrs ? `/${tagName}${attrs}` : `/${tagName}${indexSuffix}`;
              xpath = pathSegment + xpath;
              
              current = current.parentNode;
              
              // Break if we reach the body to avoid going all the way to document
              if (current === document.body) {
                xpath = '/html/body' + xpath;
                break;
              }
            }
            
            return xpath;
          }
          
          // Get XPath and check uniqueness
          const xpath = getElementXPath(element);
          let uniqueMatch = true;
          
          try {
            const result = document.evaluate(xpath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
            uniqueMatch = result.snapshotLength === 1;
          } catch (e) {
            console.error('Error evaluating XPath:', e);
            uniqueMatch = false;
          }
          
          return {
            selector: xpath,
            type: 'xpath',
            specificity: 'high',
            description: 'XPath selector for the element',
            uniqueMatch: uniqueMatch
          };
        }
        
        // Find all elements containing a specific text
        function findElementsByText(searchText) {
          if (!searchText) return [];
          
          // Get all visible text nodes
          const textNodes = [];
          const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
              acceptNode: function(node) {
                // Skip script and style elements
                if (['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(node.parentElement.tagName)) {
                  return NodeFilter.FILTER_REJECT;
                }
                
                // Check if text content matches and the element is visible
                if (node.textContent.trim() && 
                    node.textContent.toLowerCase().includes(searchText.toLowerCase())) {
                  const computedStyle = window.getComputedStyle(node.parentElement);
                  if (computedStyle.display !== 'none' && 
                      computedStyle.visibility !== 'hidden' && 
                      computedStyle.opacity !== '0') {
                    return NodeFilter.FILTER_ACCEPT;
                  }
                }
                
                return NodeFilter.FILTER_REJECT;
              }
            }
          );
          
          while (walker.nextNode()) {
            textNodes.push(walker.currentNode);
          }
          
          // Map to parent elements
          return textNodes.map(node => {
            const element = node.parentElement;
            const exactMatch = node.textContent.trim().toLowerCase() === searchText.toLowerCase();
            
            return {
              element: element,
              text: node.textContent.trim(),
              exactMatch: exactMatch,
              visible: true,
              attributes: {
                tagName: element.tagName.toLowerCase(),
                id: element.id || null,
                className: element.className || null
              }
            };
          });
        }
        
        // Generate all selectors for an element
        function generateSelectorsForElement(element) {
          const selectors = [];
          const options = window.mcpSelectorFinder.generateOptions;
          
          // Add different selector strategies based on options
          if (options.includes('id-based')) {
            const idSelector = getIdBasedSelector(element);
            if (idSelector) selectors.push(idSelector);
          }
          
          if (options.includes('shortest')) {
            const shortestSelector = getShortestUniqueSelector(element);
            if (shortestSelector) selectors.push(shortestSelector);
          }
          
          if (options.includes('robust')) {
            const robustSelector = getRobustSelector(element);
            if (robustSelector) selectors.push(robustSelector);
          }
          
          if (options.includes('xpath')) {
            const xpathSelector = getXPathSelector(element);
            if (xpathSelector) selectors.push(xpathSelector);
          }
          
          // Add basic tag selector as fallback
          let basicSelector = element.tagName.toLowerCase();
          
          // Add nth-child if there are siblings of the same type
          const siblings = Array.from(element.parentNode.children).filter(c => c.tagName === element.tagName);
          if (siblings.length > 1) {
            const index = siblings.indexOf(element) + 1;
            basicSelector += `:nth-child(${index})`;
          }
          
          selectors.push({
            selector: basicSelector,
            type: 'basic',
            specificity: 'low',
            description: 'Basic element type selector' + (siblings.length > 1 ? ' with position' : '')
          });
          
          return selectors;
        }
        
        /* ----- Interactive Mode Utilities ----- */
        
        // Create highlight box for element hover
        function createHighlightBox() {
          const box = document.createElement('div');
          box.style.position = 'absolute';
          box.style.border = '2px solid #00a8ff';
          box.style.backgroundColor = 'rgba(0, 168, 255, 0.1)';
          box.style.pointerEvents = 'none';
          box.style.zIndex = '999999';
          box.style.borderRadius = '2px';
          box.style.boxShadow = '0 0 0 2000px rgba(0, 0, 0, 0.05)';
          box.style.transition = 'all 0.2s';
          box.style.display = 'none';
          document.body.appendChild(box);
          return box;
        }
        
        // Update highlight box position for an element
        function updateHighlightBox(element) {
          if (!window.mcpSelectorFinder.highlightBox) {
            window.mcpSelectorFinder.highlightBox = createHighlightBox();
          }
          
          const box = window.mcpSelectorFinder.highlightBox;
          const rect = element.getBoundingClientRect();
          
          box.style.left = rect.left + window.pageXOffset + 'px';
          box.style.top = rect.top + window.pageYOffset + 'px';
          box.style.width = rect.width + 'px';
          box.style.height = rect.height + 'px';
          box.style.display = 'block';
        }
        
        // Set up click handler for interactive mode
        function setupInteractiveMode() {
          // Create element hover highlight
          const box = createHighlightBox();
          window.mcpSelectorFinder.highlightBox = box;
          
          // Hover handler
          window.mcpSelectorFinder._mouseoverHandler = function(e) {
            e.stopPropagation();
            updateHighlightBox(e.target);
          };
          
          // Mouse out handler
          window.mcpSelectorFinder._mouseoutHandler = function(e) {
            e.stopPropagation();
            if (window.mcpSelectorFinder.highlightBox) {
              window.mcpSelectorFinder.highlightBox.style.display = 'none';
            }
          };
          
          // Click handler
          window.mcpSelectorFinder._clickHandler = function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            // Store selected element
            window.mcpSelectorFinder.selectedElement = e.target;
            
            // Generate selectors
            window.mcpSelectorFinder.selectors = 
              generateSelectorsForElement(window.mcpSelectorFinder.selectedElement);
            
            // Clean up listeners since selection is done
            document.removeEventListener('click', window.mcpSelectorFinder._clickHandler);
            document.removeEventListener('mouseover', window.mcpSelectorFinder._mouseoverHandler);
            document.removeEventListener('mouseout', window.mcpSelectorFinder._mouseoutHandler);
            
            // Set status to completed
            window.mcpSelectorFinder.status = 'completed';
            
            // Keep highlight on the selected element
            updateHighlightBox(window.mcpSelectorFinder.selectedElement);
            
            return false;
          };
          
          // Add event listeners
          document.addEventListener('click', window.mcpSelectorFinder._clickHandler, true);
          document.addEventListener('mouseover', window.mcpSelectorFinder._mouseoverHandler, true);
          document.addEventListener('mouseout', window.mcpSelectorFinder._mouseoutHandler, true);
          
          // Set status to active
          window.mcpSelectorFinder.status = 'interactive';
          
          return {
            success: true,
            message: 'Interactive selector finder started - click on an element to select it',
            interactiveMode: true,
            sessionId: window.mcpSelectorFinder.activeSession
          };
        }
        
        /* ----- Text Search Mode ----- */
        
        function performTextSearch(searchText) {
          if (!searchText) {
            return {
              error: true,
              message: 'No search text provided'
            };
          }
          
          const elements = findElementsByText(searchText);
          
          if (elements.length === 0) {
            return {
              success: true,
              message: 'No elements found with text containing: ' + searchText,
              count: 0,
              elements: []
            };
          }
          
          // Generate selectors for the first few matches
          const maxResults = 5; // Limit to prevent excessive processing
          const results = elements.slice(0, maxResults).map(item => {
            const selectors = generateSelectorsForElement(item.element);
            
            return {
              text: item.text,
              exactMatch: item.exactMatch,
              elementInfo: {
                tagName: item.attributes.tagName,
                id: item.attributes.id,
                className: item.attributes.className
              },
              selectors: selectors
            };
          });
          
          return {
            success: true,
            message: `Found ${elements.length} element(s) with text containing: ${searchText}`,
            count: elements.length,
            results: results,
            truncated: elements.length > maxResults
          };
        }
        
        /* ----- Main Execution ----- */
        
        // Check parameters and select execution mode
        if (" & interactiveMode & ") {
          return setupInteractiveMode();
        } else if ('" & searchText & "') {
          return performTextSearch('" & searchText & "');
        } else {
          return {
            error: true,
            message: 'No mode specified. Use interactiveMode=true or provide searchText.'
          };
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
  
  -- Execute the script
  tell application "Google Chrome"
    try
      set initialResult to execute active tab of front window javascript selectorScript
      
      -- Check for interactive mode
      if initialResult contains "interactiveMode" then
        -- Create a script to check when element selection is complete
        set statusScript to "
          (function() {
            if (window.mcpSelectorFinder) {
              return {
                status: window.mcpSelectorFinder.status,
                selectedElement: window.mcpSelectorFinder.selectedElement ? true : false,
                selectors: window.mcpSelectorFinder.selectors
              };
            } else {
              return { error: true, message: 'Selector finder not initialized' };
            }
          })();
        "
        
        -- Tell user we're in interactive mode
        set messageText to "Click on any element in the Chrome window to select it for CSS selector generation."
        
        -- Poll for status changes with timeout
        set maxAttempts to 300 -- 2.5 minutes max wait time
        set attemptCounter to 0
        
        repeat
          delay 0.5
          set attemptCounter to attemptCounter + 1
          set statusCheck to execute active tab of front window javascript statusScript
          
          -- If selection is complete, get the selectors
          if statusCheck contains "\"status\":\"completed\"" then
            return statusCheck
          end if
          
          -- Timeout check
          if attemptCounter ≥ maxAttempts then
            -- Send Escape key to cancel interactive mode
            tell application "System Events"
              key code 53 -- Escape key
            end tell
            
            return "{\"error\": true, \"message\": \"Timed out waiting for element selection.\"}"
          end if
        end repeat
      else
        -- Return the direct result for text search or error
        return initialResult
      end if
    on error errMsg
      return "{\"error\": true, \"message\": \"" & my escapeJSString(errMsg) & "\"}"
    end try
  end tell
end findCssSelectors

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

return my findCssSelectors("--MCP_INPUT:interactiveMode", "--MCP_INPUT:searchText", "--MCP_INPUT:generateOptions")
```
END_TIP