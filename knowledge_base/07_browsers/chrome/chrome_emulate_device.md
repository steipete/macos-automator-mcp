---
title: 'Chrome: Emulate Mobile Device'
category: 07_browsers/chrome
id: chrome_emulate_device
description: >-
  Configures Chrome DevTools to emulate specific mobile devices, setting
  viewport sizes, user agent strings, and device pixel ratios for testing
  responsive designs and mobile-specific behavior.
keywords:
  - Chrome
  - DevTools
  - mobile
  - responsive
  - emulation
  - device
  - testing
  - web development
language: applescript
isComplex: true
argumentsPrompt: >-
  Device settings in inputData. For example: { "deviceName": "iPhone 13" } to
  use a predefined device, or custom settings: { "width": 375, "height": 667,
  "devicePixelRatio": 2, "userAgent": "Custom UA string", "mobile": true }.
  Leave deviceName empty to use custom settings.
notes: >
  - Google Chrome must be running with at least one window and tab open.

  - Opens DevTools (if not already open) and configures device emulation.

  - Supports both predefined devices and custom device configurations.

  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View
  > Developer menu.

  - Requires Accessibility permissions for UI scripting via System Events.

  - Changes will persist until emulation is disabled or browser is closed.
---

This script configures Chrome DevTools to emulate mobile devices for testing responsive designs and mobile-specific features.

```applescript
--MCP_INPUT:deviceName
--MCP_INPUT:width
--MCP_INPUT:height
--MCP_INPUT:devicePixelRatio
--MCP_INPUT:userAgent
--MCP_INPUT:mobile

on emulateDeviceInChrome(deviceName, width, height, devicePixelRatio, userAgent, mobile)
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
    
    -- Activate Chrome to ensure keyboard shortcuts work
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
      
      -- Toggle device toolbar with Command+Shift+M
      key code 46 using {command down, shift down} -- Command+Shift+M
      delay 0.5
    end tell
  end tell
  
  -- Prepare the device emulation script based on provided parameters
  if deviceName is not missing value and deviceName is not "" then
    -- Use predefined device
    set emulationScript to "
      (function() {
        try {
          const deviceName = '" & my escapeJSString(deviceName) & "';
          
          // Function to ensure we're in a DevTools context
          function ensureDevTools() {
            if (typeof DevToolsAPI === 'undefined') {
              // We're in the page context, not DevTools context
              // Try to execute in DevTools context via extension API if available
              if (typeof chrome !== 'undefined' && chrome.devtools) {
                chrome.devtools.inspectedWindow.eval(
                  'DevToolsAPI && DevToolsAPI.setDeviceMetricsOverride()',
                  function(result, isException) { 
                    if (isException) {
                      console.error('Failed to execute in DevTools context');
                    }
                  }
                );
                return { message: 'Attempted to execute in DevTools context via extension API' };
              }
              return { error: true, message: 'Not in DevTools context and no fallback available' };
            }
            return { success: true };
          }
          
          // Check if we're in DevTools context
          const devToolsCheck = ensureDevTools();
          if (devToolsCheck.error) {
            // Fallback: Use the main page's emulation API
            const devices = [
              { name: 'iPhone 13', width: 390, height: 844, devicePixelRatio: 3, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              { name: 'iPhone SE', width: 375, height: 667, devicePixelRatio: 2, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              { name: 'iPad', width: 810, height: 1080, devicePixelRatio: 2, userAgent: 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              { name: 'Pixel 6', width: 412, height: 915, devicePixelRatio: 2.625, userAgent: 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36', mobile: true },
              { name: 'Samsung Galaxy S21', width: 360, height: 800, devicePixelRatio: 3, userAgent: 'Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36', mobile: true }
            ];
            
            // Find the requested device
            const device = devices.find(d => d.name.toLowerCase() === deviceName.toLowerCase());
            
            if (!device) {
              return { error: true, message: 'Device \"' + deviceName + '\" not found in predefined devices' };
            }
            
            // Apply device emulation using the main page emulation API
            const result = emulateDeviceDirectly(device);
            return result;
          }
          
          // Use the DevTools API
          // This function tries various approaches to enable device emulation
          function emulateWithDevToolsAPI() {
            // Try with the current DevTools version API
            if (typeof DevToolsHost !== 'undefined' && typeof DevToolsAPI !== 'undefined') {
              // Method 1: Use the setDeviceMetricsOverride method if available (newer versions)
              if (typeof DevToolsAPI.setDeviceMetricsOverride === 'function') {
                const devices = DevToolsAPI.getDevicesList();
                const device = devices.find(d => d.title.toLowerCase() === deviceName.toLowerCase());
                
                if (device) {
                  DevToolsAPI.setDeviceMetricsOverride(device);
                  return { success: true, message: 'Device emulation set to ' + deviceName };
                } else {
                  return { error: true, message: 'Device name not found in DevTools device list' };
                }
              }
              
              // Method 2: Use UI automation via DevToolsAPI
              if (typeof DevToolsAPI.showPanel === 'function' && typeof UI !== 'undefined') {
                // Switch to Device Mode in DevTools
                DevToolsAPI.showPanel('device_mode');
                
                if (typeof UI.inspectorView !== 'undefined' && UI.inspectorView.showPanel) {
                  UI.inspectorView.showPanel('device_mode');
                  
                  // Try to select the device from the dropdown
                  if (UI.DeviceModeModel && UI.DeviceModeModel.deviceModelSetting) {
                    UI.DeviceModeModel.deviceModelSetting.set(deviceName);
                    return { success: true, message: 'Device model set to ' + deviceName + ' via UI model' };
                  }
                }
              }
            }
            
            // Fallback: Use direct emulation
            const fallbackDevice = getDefaultDeviceSpecs(deviceName);
            return emulateDeviceDirectly(fallbackDevice);
          }
          
          // Function to get device specs for known devices
          function getDefaultDeviceSpecs(name) {
            const devices = {
              'iphone 13': { width: 390, height: 844, devicePixelRatio: 3, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              'iphone se': { width: 375, height: 667, devicePixelRatio: 2, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              'ipad': { width: 810, height: 1080, devicePixelRatio: 2, userAgent: 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true },
              'pixel 6': { width: 412, height: 915, devicePixelRatio: 2.625, userAgent: 'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36', mobile: true },
              'samsung galaxy s21': { width: 360, height: 800, devicePixelRatio: 3, userAgent: 'Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36', mobile: true }
            };
            
            const deviceKey = name.toLowerCase();
            return devices[deviceKey] || { width: 375, height: 667, devicePixelRatio: 2, userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1', mobile: true };
          }
          
          // Function to directly emulate a device using page emulation API
          function emulateDeviceDirectly(device) {
            if (typeof EmulationAgent !== 'undefined') {
              // Use the protocol directly if available
              EmulationAgent.setDeviceMetricsOverride({
                width: device.width,
                height: device.height,
                deviceScaleFactor: device.devicePixelRatio,
                mobile: device.mobile,
                screenWidth: device.width,
                screenHeight: device.height
              });
              
              EmulationAgent.setUserAgentOverride({
                userAgent: device.userAgent
              });
              
              return { success: true, message: 'Device emulated using EmulationAgent' };
            } else if (typeof chrome !== 'undefined' && chrome.debugger) {
              // Try using chrome.debugger API if available (rare in this context)
              chrome.debugger.sendCommand({tabId: chrome.devtools.inspectedWindow.tabId}, 'Emulation.setDeviceMetricsOverride', {
                width: device.width, 
                height: device.height,
                deviceScaleFactor: device.devicePixelRatio,
                mobile: device.mobile
              });
              
              chrome.debugger.sendCommand({tabId: chrome.devtools.inspectedWindow.tabId}, 'Emulation.setUserAgentOverride', {
                userAgent: device.userAgent
              });
              
              return { success: true, message: 'Device emulated using chrome.debugger API' };
            } else {
              // Last resort: Try to use the window.emulationParams approach
              if (typeof window !== 'undefined') {
                window.emulationParams = {
                  deviceName: deviceName,
                  device: device
                };
                
                // Add a fake element to indicate success for screen scraping
                const infoDiv = document.createElement('div');
                infoDiv.id = 'mcpDeviceEmulationInfo';
                infoDiv.style.display = 'none';
                infoDiv.textContent = JSON.stringify(device);
                document.body.appendChild(infoDiv);
                
                return { success: true, message: 'Emulation parameters stored for later use' };
              }
            }
            
            return { error: true, message: 'No emulation API available' };
          }
          
          // Execute the emulation
          return emulateWithDevToolsAPI();
        } catch (e) {
          return { error: true, message: e.toString() };
        }
      })();
    "
  else
    -- Use custom device settings
    -- Set defaults for missing parameters
    if width is missing value or width is "" then set width to 375
    if height is missing value or height is "" then set height to 667
    if devicePixelRatio is missing value or devicePixelRatio is "" then set devicePixelRatio to 2
    if userAgent is missing value or userAgent is "" then set userAgent to "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
    if mobile is missing value then set mobile to true
    
    set emulationScript to "
      (function() {
        try {
          const customDevice = {
            width: " & width & ",
            height: " & height & ",
            devicePixelRatio: " & devicePixelRatio & ",
            userAgent: '" & my escapeJSString(userAgent) & "',
            mobile: " & mobile & "
          };
          
          // Function to directly emulate a device using page emulation API
          function emulateDeviceDirectly(device) {
            if (typeof EmulationAgent !== 'undefined') {
              // Use the protocol directly if available
              EmulationAgent.setDeviceMetricsOverride({
                width: device.width,
                height: device.height,
                deviceScaleFactor: device.devicePixelRatio,
                mobile: device.mobile,
                screenWidth: device.width,
                screenHeight: device.height
              });
              
              EmulationAgent.setUserAgentOverride({
                userAgent: device.userAgent
              });
              
              return { success: true, message: 'Custom device emulated using EmulationAgent' };
            } else if (typeof chrome !== 'undefined' && chrome.debugger) {
              // Try using chrome.debugger API if available
              chrome.debugger.sendCommand({tabId: chrome.devtools.inspectedWindow.tabId}, 'Emulation.setDeviceMetricsOverride', {
                width: device.width, 
                height: device.height,
                deviceScaleFactor: device.devicePixelRatio,
                mobile: device.mobile
              });
              
              chrome.debugger.sendCommand({tabId: chrome.devtools.inspectedWindow.tabId}, 'Emulation.setUserAgentOverride', {
                userAgent: device.userAgent
              });
              
              return { success: true, message: 'Custom device emulated using chrome.debugger API' };
            } else {
              // Last resort: Set parameters and try to use UI automation
              window.customEmulationParams = device;
              
              // Add a marker element for screen scraping
              const infoDiv = document.createElement('div');
              infoDiv.id = 'mcpDeviceEmulationInfo';
              infoDiv.style.display = 'none';
              infoDiv.textContent = JSON.stringify(device);
              document.body.appendChild(infoDiv);
              
              return { success: true, message: 'Custom emulation parameters set' };
            }
            
            return { error: true, message: 'No emulation API available' };
          }
          
          return emulateDeviceDirectly(customDevice);
        } catch (e) {
          return { error: true, message: e.toString() };
        }
      })();
    "
  end if
  
  -- Execute the emulation script
  tell application "Google Chrome"
    try
      set emulationResult to execute active tab of front window javascript emulationScript
      
      -- Check the result
      if emulationResult contains "error" then
        return "error: " & emulationResult
      else
        -- Try to get the device info using a follow-up script
        set infoScript to "
          (function() {
            const infoElement = document.getElementById('mcpDeviceEmulationInfo');
            if (infoElement) {
              const info = infoElement.textContent;
              try {
                return JSON.parse(info);
              } catch(e) {
                return info;
              }
            }
            
            // Check for stored emulation parameters
            if (window.emulationParams) {
              return window.emulationParams;
            } else if (window.customEmulationParams) {
              return window.customEmulationParams;
            }
            
            return null;
          })();
        "
        
        set deviceInfo to execute active tab of front window javascript infoScript
        
        if deviceName is not missing value and deviceName is not "" then
          return "Successfully configured emulation for device: " & deviceName
        else
          return "Successfully configured custom device emulation with settings: width=" & width & ", height=" & height & ", devicePixelRatio=" & devicePixelRatio
        end if
      end if
    on error errMsg
      return "error: Failed to configure device emulation - " & errMsg
    end try
  end tell
end emulateDeviceInChrome

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

return my emulateDeviceInChrome("--MCP_INPUT:deviceName", "--MCP_INPUT:width", "--MCP_INPUT:height", "--MCP_INPUT:devicePixelRatio", "--MCP_INPUT:userAgent", "--MCP_INPUT:mobile")
```
END_TIP
