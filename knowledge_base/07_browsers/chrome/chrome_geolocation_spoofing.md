---
title: "Chrome: Geolocation Spoofing"
category: "05_web_browsers"
id: chrome_geolocation_spoofing
description: "Spoofs geolocation data in Chrome to simulate specific geographic locations for testing location-based web features and applications."
keywords: ["Chrome", "geolocation", "spoofing", "location", "GPS", "testing", "web development", "DevTools"]
language: applescript
isComplex: true
argumentsPrompt: "Location data in inputData. For example: { \"latitude\": 37.7749, \"longitude\": -122.4194, \"accuracy\": 10 } for San Francisco coordinates. Can also use predefined locations with { \"preset\": \"san_francisco\" }. Set { \"useRealLocation\": true } to stop spoofing."
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Opens DevTools (if not already open) and configures geolocation spoofing.
  - Allows using predefined locations or custom coordinates.
  - Website must request location permissions for spoofing to work.
  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View > Developer menu.
  - Requires Accessibility permissions for UI scripting via System Events.
  - Useful for testing location-based features without changing physical location.
---

This script configures Chrome to spoof geolocation data, allowing testing of location-based web features.

```applescript
--MCP_INPUT:latitude
--MCP_INPUT:longitude
--MCP_INPUT:accuracy
--MCP_INPUT:preset
--MCP_INPUT:useRealLocation

on spoofGeolocation(latitude, longitude, accuracy, preset, useRealLocation)
  -- Set default values
  if accuracy is missing value or accuracy is "" then
    set accuracy to 10 -- Default accuracy in meters
  end if
  
  -- Predefined locations
  set presetLocations to {¬
    {"london", 51.5074, -0.1278, "London, UK"}, ¬
    {"new_york", 40.7128, -74.0060, "New York, USA"}, ¬
    {"san_francisco", 37.7749, -122.4194, "San Francisco, USA"}, ¬
    {"tokyo", 35.6762, 139.6503, "Tokyo, Japan"}, ¬
    {"sydney", -33.8688, 151.2093, "Sydney, Australia"}, ¬
    {"paris", 48.8566, 2.3522, "Paris, France"}, ¬
    {"beijing", 39.9042, 116.4074, "Beijing, China"}, ¬
    {"rio", -22.9068, -43.1729, "Rio de Janeiro, Brazil"}, ¬
    {"cape_town", -33.9249, 18.4241, "Cape Town, South Africa"}, ¬
    {"moscow", 55.7558, 37.6173, "Moscow, Russia"} ¬
  }
  
  -- If we have a preset, use those coordinates
  if preset is not missing value and preset is not "" then
    set presetFound to false
    
    repeat with presetInfo in presetLocations
      if item 1 of presetInfo is preset then
        set latitude to item 2 of presetInfo
        set longitude to item 3 of presetInfo
        set locationName to item 4 of presetInfo
        set presetFound to true
        exit repeat
      end if
    end repeat
    
    if not presetFound then
      return "error: Invalid preset location. Available options: london, new_york, san_francisco, tokyo, sydney, paris, beijing, rio, cape_town, moscow."
    end if
  else
    -- If no preset and no coordinates, default to San Francisco
    if (latitude is missing value or latitude is "") and useRealLocation is not true then
      set latitude to 37.7749
      set longitude to -122.4194
      set locationName to "San Francisco, USA"
    end if
  end if
  
  -- Check for real location mode
  if useRealLocation is true then
    set locationMode to "useRealLocation"
  else
    set locationMode to "customLocation"
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
  
  -- Open DevTools
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
    end tell
  end tell
  
  -- Generate a unique ID for this geolocation session
  set sessionId to "mcpGeoLocation_" & (random number from 100000 to 999999) as string
  
  -- Prepare the JavaScript for geolocation spoofing
  set geoScript to "
    (function() {
      try {
        // Create a namespace for our geolocation spoofing
        if (!window.mcpGeolocation) {
          window.mcpGeolocation = {
            originalGeolocation: null,
            activeSession: null,
            mode: 'default',
            mockPosition: null
          };
        }
        
        // Clear any existing session with the same ID
        if (window.mcpGeolocation.activeSession === '" & sessionId & "') {
          console.log('Stopping previous geolocation session with same ID');
          // If we're restoring real location, don't reset everything yet
          if ('" & locationMode & "' !== 'useRealLocation') {
            window.mcpGeolocation.activeSession = null;
            window.mcpGeolocation.mockPosition = null;
          }
        }
        
        // Set up the new session
        window.mcpGeolocation.activeSession = '" & sessionId & "';
        
        // Configure the location mode
        if ('" & locationMode & "' === 'useRealLocation') {
          window.mcpGeolocation.mode = 'real';
          window.mcpGeolocation.mockPosition = null;
          
          // Restore original geolocation if it was saved
          if (window.mcpGeolocation.originalGeolocation) {
            try {
              navigator.geolocation = window.mcpGeolocation.originalGeolocation;
              window.mcpGeolocation.originalGeolocation = null;
            } catch (e) {
              console.error('Failed to restore original geolocation:', e);
            }
          }
        } else {
          window.mcpGeolocation.mode = 'mock';
          window.mcpGeolocation.mockPosition = {
            coords: {
              latitude: " & latitude & ",
              longitude: " & longitude & ",
              accuracy: " & accuracy & ",
              altitude: null,
              altitudeAccuracy: null,
              heading: null,
              speed: null
            },
            timestamp: Date.now()
          };
        }
        
        // Configuration methods for geolocation spoofing
        
        // Method 1: DevTools Emulation API (most reliable if available)
        async function setupDevToolsEmulation() {
          if (typeof EmulationAgent !== 'undefined') {
            try {
              if (window.mcpGeolocation.mode === 'mock') {
                // Set the mock geolocation
                await EmulationAgent.setGeolocationOverride({
                  latitude: " & latitude & ",
                  longitude: " & longitude & ",
                  accuracy: " & accuracy & "
                });
                return { success: true, method: 'EmulationAgent' };
              } else {
                // Clear the override
                await EmulationAgent.clearGeolocationOverride();
                return { success: true, method: 'EmulationAgent.clear' };
              }
            } catch (e) {
              console.error('Failed to use EmulationAgent:', e);
            }
          }
          
          return null; // Indicate method not available
        }
        
        // Method 2: chrome.debugger API
        async function setupChromeDebugger() {
          if (typeof chrome !== 'undefined' && chrome.debugger && chrome.devtools) {
            try {
              const tabId = chrome.devtools.inspectedWindow.tabId;
              
              // First attach the debugger
              await new Promise((resolve, reject) => {
                chrome.debugger.attach({tabId}, '1.3', result => {
                  if (chrome.runtime.lastError) {
                    reject(chrome.runtime.lastError);
                  } else {
                    resolve();
                  }
                });
              });
              
              // Set or clear geolocation override
              if (window.mcpGeolocation.mode === 'mock') {
                await new Promise((resolve, reject) => {
                  chrome.debugger.sendCommand({tabId}, 'Emulation.setGeolocationOverride', {
                    latitude: " & latitude & ",
                    longitude: " & longitude & ",
                    accuracy: " & accuracy & "
                  }, result => {
                    if (chrome.runtime.lastError) {
                      reject(chrome.runtime.lastError);
                    } else {
                      resolve();
                    }
                  });
                });
              } else {
                await new Promise((resolve, reject) => {
                  chrome.debugger.sendCommand({tabId}, 'Emulation.clearGeolocationOverride', {}, result => {
                    if (chrome.runtime.lastError) {
                      reject(chrome.runtime.lastError);
                    } else {
                      resolve();
                    }
                  });
                });
              }
              
              return { success: true, method: 'chrome.debugger' };
            } catch (e) {
              console.error('Failed to use chrome.debugger:', e);
            }
          }
          
          return null; // Indicate method not available
        }
        
        // Method 3: Navigator.geolocation override (fallback)
        function setupNavigatorOverride() {
          try {
            // Save original geolocation object if not already saved
            if (!window.mcpGeolocation.originalGeolocation) {
              window.mcpGeolocation.originalGeolocation = navigator.geolocation;
            }
            
            // If returning to real location, restore original
            if (window.mcpGeolocation.mode === 'real') {
              if (window.mcpGeolocation.originalGeolocation) {
                navigator.geolocation = window.mcpGeolocation.originalGeolocation;
                window.mcpGeolocation.originalGeolocation = null;
              }
              return { success: true, method: 'navigatorRestore' };
            }
            
            // Create mock geolocation object
            const mockGeolocation = {
              getCurrentPosition: function(success, error, options) {
                setTimeout(function() {
                  success(window.mcpGeolocation.mockPosition);
                }, 200); // Small delay to simulate network
              },
              
              watchPosition: function(success, error, options) {
                // Immediately return the position
                setTimeout(function() {
                  success(window.mcpGeolocation.mockPosition);
                }, 200);
                
                // Create a timer to simulate position updates
                const watchId = setInterval(function() {
                  // Add small random variations to make it realistic
                  const variation = (Math.random() - 0.5) * 0.0001; // ~10m variation
                  const mockPosition = {
                    coords: {
                      latitude: window.mcpGeolocation.mockPosition.coords.latitude + variation,
                      longitude: window.mcpGeolocation.mockPosition.coords.longitude + variation,
                      accuracy: window.mcpGeolocation.mockPosition.coords.accuracy,
                      altitude: null,
                      altitudeAccuracy: null,
                      heading: null,
                      speed: null
                    },
                    timestamp: Date.now()
                  };
                  
                  success(mockPosition);
                }, 5000); // Update every 5 seconds
                
                return watchId;
              },
              
              clearWatch: function(watchId) {
                clearInterval(watchId);
              }
            };
            
            // Replace navigator.geolocation with our mock
            navigator.geolocation = mockGeolocation;
            
            return { success: true, method: 'navigatorOverride' };
          } catch (e) {
            console.error('Failed to override navigator.geolocation:', e);
            return { error: true, message: e.toString(), method: 'navigatorOverride' };
          }
        }
        
        // Try each method in sequence until one works
        return (async () => {
          let result = null;
          
          // Try DevTools Emulation first
          result = await setupDevToolsEmulation();
          if (result && result.success) {
            return {
              success: true,
              method: result.method,
              sessionId: '" & sessionId & "',
              mode: window.mcpGeolocation.mode,
              " & (if locationMode is "useRealLocation" then "message: 'Successfully restored real geolocation'" else "message: 'Successfully spoofed geolocation to " & latitude & ", " & longitude & " (accuracy: " & accuracy & "m)'") & "
            };
          }
          
          // Try chrome.debugger next
          result = await setupChromeDebugger();
          if (result && result.success) {
            return {
              success: true,
              method: result.method,
              sessionId: '" & sessionId & "',
              mode: window.mcpGeolocation.mode,
              " & (if locationMode is "useRealLocation" then "message: 'Successfully restored real geolocation'" else "message: 'Successfully spoofed geolocation to " & latitude & ", " & longitude & " (accuracy: " & accuracy & "m)'") & "
            };
          }
          
          // Fall back to navigator override
          result = setupNavigatorOverride();
          if (result && result.success) {
            return {
              success: true,
              method: result.method,
              sessionId: '" & sessionId & "',
              mode: window.mcpGeolocation.mode,
              " & (if locationMode is "useRealLocation" then "message: 'Successfully restored real geolocation'" else "message: 'Successfully spoofed geolocation to " & latitude & ", " & longitude & " (accuracy: " & accuracy & "m)'") & ",
              note: 'Using the navigator override method. This works only for new geolocation requests and requires a page refresh for best results.'
            };
          }
          
          // If all methods failed
          return {
            error: true,
            message: 'Failed to set up geolocation spoofing',
            sessionId: '" & sessionId & "',
          };
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
      set geoResult to execute active tab of front window javascript geoScript
      
      -- Check if request succeeded
      if geoResult contains "error" then
        -- We need to try a different approach - first open the Sensors panel in DevTools to set location
        tell application "System Events"
          tell process "Google Chrome"
            -- Try to open the DevTools menu
            click menu item "More Tools" of menu 1 of menu bar item "View" of menu bar 1
            delay 0.2
            
            -- Look for Sensors or Developer Tools options
            try
              click menu item "Sensors" of menu 1 of menu item "More Tools" of menu 1 of menu bar item "View" of menu bar 1
              delay 0.5
              
              -- Now look for location dropdown in the Sensors panel
              -- Note: This is a heuristic as the exact UI elements can vary
              repeat with w in windows
                try
                  set allGroups to groups of w
                  
                  repeat with g in allGroups
                    if description of g contains "Location" or description of g contains "Geolocation" then
                      set locationGroup to g
                      
                      -- Try to find the dropdown
                      set allPopups to pop up buttons of locationGroup
                      if (count of allPopups) > 0 then
                        -- Click the location dropdown
                        click (item 1 of allPopups)
                        delay 0.3
                        
                        -- Select appropriate option
                        if locationMode is "useRealLocation" then
                          click menu item "No override" of menu 1 of item 1 of allPopups
                        else
                          -- If custom location option exists
                          click menu item "Custom location..." of menu 1 of item 1 of allPopups
                          delay 0.3
                          
                          -- Try to find latitude/longitude fields
                          set allTextFields to text fields of locationGroup
                          if (count of allTextFields) ≥ 3 then
                            -- Enter the coordinates
                            set value of item 1 of allTextFields to latitude as string
                            set value of item 2 of allTextFields to longitude as string
                            set value of item 3 of allTextFields to accuracy as string
                          end if
                        end if
                        
                        exit repeat
                      end if
                    end if
                  end repeat
                  
                  exit repeat
                on error
                  -- Continue to next window
                end try
              end repeat
            on error
              -- Sensors option not found, let's try manually opening the sensors panel
              -- Go to Network conditions 
              key code 110 using {command down, shift down} -- Command+Shift+N for network
              delay 0.5
              
              -- Try to access the additional panels using keyboard
              key code 48 using {command down} -- Command+Tab key to navigate panels
              delay 0.3
              key code 48 using {command down} -- Command+Tab key to navigate panels
              delay 0.3
            end try
          end tell
        end tell
        
        -- After UI manipulation, try running our JavaScript again
        delay 1
        set secondAttemptResult to execute active tab of front window javascript geoScript
        
        -- Return the result, which might still be an error but at least we tried UI method
        return secondAttemptResult
      else
        -- Return the successful result
        return geoResult
      end if
    on error errMsg
      return "error: Failed to spoof geolocation - " & errMsg
    end try
  end tell
end spoofGeolocation

return my spoofGeolocation("--MCP_INPUT:latitude", "--MCP_INPUT:longitude", "--MCP_INPUT:accuracy", "--MCP_INPUT:preset", "--MCP_INPUT:useRealLocation")
```
END_TIP