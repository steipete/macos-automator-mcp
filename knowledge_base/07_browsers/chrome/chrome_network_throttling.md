---
title: "Chrome: Network Throttling"
category: "05_web_browsers"
id: chrome_network_throttling
description: "Configures Chrome DevTools network throttling to simulate various connection speeds for testing website performance under different network conditions."
keywords: ["Chrome", "DevTools", "network", "throttling", "bandwidth", "latency", "testing", "performance", "web development"]
language: applescript
isComplex: true
argumentsPrompt: "Network profile in inputData. For example: { \"profile\": \"Slow 3G\" } for a predefined profile, or custom settings: { \"downloadKbps\": 500, \"uploadKbps\": 256, \"latencyMs\": 300 }. Set { \"profile\": \"Online\" } to disable throttling."
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - Opens DevTools (if not already open) and switches to the Network panel.
  - Supports both predefined profiles and custom throttling configurations.
  - Predefined profiles include: "Offline", "Slow 3G", "Fast 3G", "Online".
  - Requires "Allow JavaScript from Apple Events" to be enabled in Chrome's View > Developer menu.
  - Requires Accessibility permissions for UI scripting via System Events.
  - Changes will persist until disabled or browser is closed.
---

This script configures Chrome DevTools' network throttling to simulate various connection speeds for testing website performance.

```applescript
--MCP_INPUT:profile
--MCP_INPUT:downloadKbps
--MCP_INPUT:uploadKbps
--MCP_INPUT:latencyMs

on configureNetworkThrottling(profileName, downloadKbps, uploadKbps, latencyMs)
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
  
  -- Open DevTools and switch to Network panel
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
      
      -- Switch to Network panel
      key code 45 using {command down, option down} -- Option+Command+N
      delay 0.5
    end tell
  end tell
  
  -- Determine if using predefined profile or custom settings
  set useCustomProfile to false
  if profileName is missing value or profileName is "" then
    -- If profile not specified but custom values are, use custom profile
    if (downloadKbps is not missing value and downloadKbps is not "") or (uploadKbps is not missing value and uploadKbps is not "") or (latencyMs is not missing value and latencyMs is not "") then
      set useCustomProfile to true
      -- Set defaults for missing parameters
      if downloadKbps is missing value or downloadKbps is "" then set downloadKbps to 500
      if uploadKbps is missing value or uploadKbps is "" then set uploadKbps to 256
      if latencyMs is missing value or latencyMs is "" then set latencyMs to 300
    else
      -- Default to "Fast 3G" if nothing specified
      set profileName to "Fast 3G"
    end if
  end if
  
  -- Prepare the JavaScript for network throttling configuration
  set throttlingScript to "
    (function() {
      try {
        // Function to ensure we're in a DevTools context
        function ensureDevToolsContext() {
          if (typeof NetworkConditions === 'undefined' && typeof SDK === 'undefined') {
            // We're not in the DevTools context
            // Check if we can find DevTools elements in the DOM
            if (document.querySelector('.network-throttling-selector')) {
              return { 
                uiAvailable: true, 
                programmaticAPI: false 
              };
            }
            return { 
              error: true, 
              message: 'Not in DevTools context and UI elements not found' 
            };
          }
          return { 
            uiAvailable: false, 
            programmaticAPI: true 
          };
        }
        
        const devToolsCheck = ensureDevToolsContext();
        
        " & (if useCustomProfile then "
        // Custom throttling profile
        const customProfile = {
          downloadThroughput: " & downloadKbps & " * 1024 / 8, // Convert Kbps to Bytes/s
          uploadThroughput: " & uploadKbps & " * 1024 / 8,
          latency: " & latencyMs & "
        };
        const profileDescription = 'Custom (" & downloadKbps & " Kbps down, " & latencyMs & "ms latency)';
        " else "
        // Predefined throttling profile
        const profileName = '" & my escapeJSString(profileName) & "';
        let predefinedProfile;
        let profileDescription;
        
        // Define the network conditions for predefined profiles
        switch (profileName.toLowerCase()) {
          case 'offline':
            predefinedProfile = { offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0 };
            profileDescription = 'Offline';
            break;
          case 'slow 3g':
            predefinedProfile = { offline: false, latency: 400, downloadThroughput: 400 * 1024 / 8, uploadThroughput: 400 * 1024 / 8 };
            profileDescription = 'Slow 3G (400 Kbps, 400ms RTT)';
            break;
          case 'fast 3g':
            predefinedProfile = { offline: false, latency: 200, downloadThroughput: 1.5 * 1024 * 1024 / 8, uploadThroughput: 750 * 1024 / 8 };
            profileDescription = 'Fast 3G (1.5 Mbps, 200ms RTT)';
            break;
          case 'online':
          case 'no throttling':
          case 'disabled':
            predefinedProfile = { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 };
            profileDescription = 'Online (No throttling)';
            break;
          default:
            return { error: true, message: 'Unknown predefined profile: ' + profileName };
        }
        ") & "
        
        // First attempt: Use DevTools API if available
        if (devToolsCheck.programmaticAPI) {
          if (typeof SDK !== 'undefined' && SDK.NetworkManager && SDK.NetworkManager.throttlingManager) {
            // Modern DevTools API approach
            const manager = SDK.NetworkManager.throttlingManager();
            
            " & (if useCustomProfile then "
            // Apply custom profile
            manager.setCustomConditions(customProfile.latency, customProfile.downloadThroughput, customProfile.uploadThroughput);
            return { success: true, message: 'Applied custom throttling: ' + profileDescription };
            " else "
            // Apply predefined profile
            if (predefinedProfile.offline) {
              manager.setNetworkConditions(SDK.NetworkManager.OfflineConditions);
            } else if (predefinedProfile.downloadThroughput === -1) {
              manager.setNetworkConditions(SDK.NetworkManager.NoThrottlingConditions);
            } else {
              manager.setNetworkConditions(new SDK.NetworkManager.Conditions(
                predefinedProfile.latency,
                predefinedProfile.downloadThroughput,
                predefinedProfile.uploadThroughput,
                false
              ));
            }
            return { success: true, message: 'Applied network profile: ' + profileDescription };
            ") & "
          } else if (typeof NetworkConditions !== 'undefined') {
            // Older DevTools API approach
            const conditions = " & (if useCustomProfile then "
              new NetworkConditions(customProfile.latency, 
                                  customProfile.downloadThroughput, 
                                  customProfile.uploadThroughput);
            " else "
              new NetworkConditions(predefinedProfile.latency, 
                                  predefinedProfile.downloadThroughput, 
                                  predefinedProfile.uploadThroughput, 
                                  predefinedProfile.offline);
            ") & "
            
            NetworkConditions.setNetworkConditions(conditions);
            return { success: true, message: 'Applied network conditions using legacy API: ' + profileDescription };
          } else if (typeof Mobile !== 'undefined' && typeof Mobile.NetworkManager !== 'undefined') {
            // Alternative DevTools API path
            " & (if useCustomProfile then "
            Mobile.NetworkManager.setNetworkConditions(customProfile.latency, 
                                                   customProfile.downloadThroughput, 
                                                   customProfile.uploadThroughput);
            " else "
            Mobile.NetworkManager.setNetworkConditions(predefinedProfile.latency, 
                                                   predefinedProfile.downloadThroughput, 
                                                   predefinedProfile.uploadThroughput, 
                                                   predefinedProfile.offline);
            ") & "
            return { success: true, message: 'Applied network conditions using Mobile API: ' + profileDescription };
          }
        }
        
        // Second attempt: UI automation via JavaScript
        if (devToolsCheck.uiAvailable) {
          // Find and click the network throttling dropdown
          const throttlingSelector = document.querySelector('.network-throttling-selector');
          if (throttlingSelector) {
            throttlingSelector.click();
            
            // Wait for dropdown menu to appear
            setTimeout(() => {
              // Look for the option matching our profile
              const menuItems = document.querySelectorAll('.toolbar-item');
              let found = false;
              
              for (const item of menuItems) {
                " & (if useCustomProfile then "
                // For custom profile, look for "Custom..." option
                if (item.textContent.includes('Custom')) {
                  item.click();
                  found = true;
                  
                  // Wait for custom dialog
                  setTimeout(() => {
                    // Try to find input fields for custom values
                    const downloadInput = document.querySelector('[aria-label=\"Download\"]');
                    const uploadInput = document.querySelector('[aria-label=\"Upload\"]');
                    const latencyInput = document.querySelector('[aria-label=\"Latency\"]');
                    
                    if (downloadInput && uploadInput && latencyInput) {
                      downloadInput.value = " & downloadKbps & ";
                      uploadInput.value = " & uploadKbps & ";
                      latencyInput.value = " & latencyMs & ";
                      
                      // Find and click the Apply button
                      const buttons = document.querySelectorAll('button');
                      for (const button of buttons) {
                        if (button.textContent.includes('Apply')) {
                          button.click();
                          console.log('Applied custom throttling settings via UI');
                          break;
                        }
                      }
                    }
                  }, 500);
                  break;
                }
                " else "
                // For predefined profile, find matching name
                if (item.textContent.toLowerCase().includes(profileName.toLowerCase())) {
                  item.click();
                  found = true;
                  console.log('Applied network profile via UI: ' + profileDescription);
                  break;
                }
                ") & "
              }
              
              if (!found) {
                console.error('Profile option not found in UI');
              }
            }, 200);
            
            return { success: true, message: 'Attempted to set throttling via UI' };
          }
        }
        
        // Third attempt: Inject a script tag with a workaround
        const scriptTag = document.createElement('script');
        scriptTag.textContent = `
          // Store throttling settings for retrieval
          window.__mcpNetworkThrottling = {
            " & (if useCustomProfile then "
            type: 'custom',
            downloadKbps: " & downloadKbps & ",
            uploadKbps: " & uploadKbps & ",
            latencyMs: " & latencyMs & "
            " else "
            type: 'predefined',
            profile: '" & my escapeJSString(profileName) & "'
            ") & "
          };
          console.log('Network throttling settings stored in window.__mcpNetworkThrottling');
        `;
        document.head.appendChild(scriptTag);
        
        return { 
          partial: true, 
          message: 'DevTools APIs not available. Instructions: manually select \"" & 
          (if useCustomProfile then "Custom... > " & downloadKbps & "Kbps download, " & uploadKbps & "Kbps upload, " & latencyMs & "ms latency" else profileName) & 
          "\" from the network throttling dropdown in DevTools Network panel.'
        };
      } catch (e) {
        return { error: true, message: e.toString() };
      }
    })();
  "
  
  -- Execute the throttling script
  tell application "Google Chrome"
    try
      set throttlingResult to execute active tab of front window javascript throttlingScript
      
      -- Check the result
      if throttlingResult contains "error" then
        return "error: " & throttlingResult
      else if throttlingResult contains "partial" then
        return "partial: " & throttlingResult
      else
        if useCustomProfile then
          return "Successfully configured custom network throttling: " & downloadKbps & " Kbps download, " & uploadKbps & " Kbps upload, " & latencyMs & "ms latency"
        else
          return "Successfully applied network throttling profile: " & profileName
        end if
      end if
    on error errMsg
      return "error: Failed to configure network throttling - " & errMsg
    end try
  end tell
end configureNetworkThrottling

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

return my configureNetworkThrottling("--MCP_INPUT:profile", "--MCP_INPUT:downloadKbps", "--MCP_INPUT:uploadKbps", "--MCP_INPUT:latencyMs")
```
END_TIP