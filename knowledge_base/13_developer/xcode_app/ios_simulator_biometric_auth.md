---
title: "iOS Simulator: Simulate Biometric Authentication"
category: "developer"
id: ios_simulator_biometric_auth
description: "Simulates Touch ID or Face ID authentication success or failure in the iOS Simulator."
keywords: ["iOS Simulator", "Xcode", "biometric", "Face ID", "Touch ID", "authentication", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Authentication result as 'authResult' ('success' or 'failure'), optional device identifier as 'deviceIdentifier' (defaults to 'booted'), and optional biometric type as 'biometricType' ('touchid' or 'faceid' - defaults to the device's native biometric type)."
notes: |
  - Simulates biometric authentication events in simulator
  - Can trigger success or failure states for testing
  - Works with both Touch ID and Face ID depending on device type
  - Useful for testing authentication flows without manual interaction
  - Serves same function as Hardware menu commands in Simulator
  - The simulator must be booted and an authentication prompt must be active
---

```applescript
--MCP_INPUT:authResult
--MCP_INPUT:deviceIdentifier
--MCP_INPUT:biometricType

on simulateBiometricAuth(authResult, deviceIdentifier, biometricType)
  if authResult is missing value or authResult is "" then
    set authResult to "success"
  else
    -- Normalize to lowercase
    set authResult to do shell script "echo " & quoted form of authResult & " | tr '[:upper:]' '[:lower:]'"
    
    if authResult is not in {"success", "failure", "fail"} then
      return "error: Invalid authentication result. Must be 'success' or 'failure'."
    end if
    
    -- Normalize "fail" to "failure"
    if authResult is "fail" then set authResult to "failure"
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Normalize biometric type if specified
  if biometricType is not missing value and biometricType is not "" then
    set biometricType to do shell script "echo " & quoted form of biometricType & " | tr '[:upper:]' '[:lower:]'"
    
    -- Check for various common formats and normalize
    if biometricType contains "face" then
      set biometricType to "faceid"
    else if biometricType contains "touch" then
      set biometricType to "touchid"
    end if
    
    if biometricType is not in {"faceid", "touchid"} then
      return "error: Invalid biometric type. Must be 'faceid' or 'touchid'."
    end if
  else
    -- If not specified, we'll detect or use a default later
    set biometricType to ""
  end if
  
  try
    -- Check if device exists and is booted
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- If biometric type wasn't specified, try to detect it based on device type
    if biometricType is "" then
      -- Get device info to determine if it's likely Face ID or Touch ID
      set deviceInfoCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      set deviceInfo to do shell script deviceInfoCmd
      
      -- Simple heuristic: newer devices are more likely to use Face ID
      -- iPhone X and later, iPad Pro 2018 and later typically use Face ID
      if deviceInfo contains "iPhone X" or deviceInfo contains "iPhone 11" or deviceInfo contains "iPhone 12" or deviceInfo contains "iPhone 13" or deviceInfo contains "iPhone 14" or deviceInfo contains "iPhone 15" or deviceInfo contains "iPad Pro" then
        set biometricType to "faceid"
      else
        set biometricType to "touchid"
      end if
    end if
    
    -- Simulate the biometric authentication
    set biometricCmd to "xcrun simctl " & biometricType & " " & quoted form of deviceIdentifier & " " & authResult
    
    try
      do shell script biometricCmd
      set authSimulated to true
    on error errMsg
      return "Error simulating " & biometricType & ": " & errMsg
    end try
    
    if authSimulated then
      set biometricName to ""
      if biometricType is "faceid" then
        set biometricName to "Face ID"
      else
        set biometricName to "Touch ID"
      end if
      
      set resultText to ""
      if authResult is "success" then
        set resultText to "successful"
      else
        set resultText to "failed"
      end if
      
      return "Successfully simulated " & resultText & " " & biometricName & " authentication on " & deviceIdentifier & " simulator.

Note: This will only have an effect if an authentication prompt is currently active in an app.
If no effect is seen, try the following:
1. Make sure the app is requesting biometric authentication
2. Check that the app has received biometric permission
3. For Face ID simulators, ensure the 'Enrolled' option is enabled in the Hardware menu"
    else
      return "Failed to simulate " & biometricType & " authentication for " & deviceIdentifier
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") simulating biometric authentication: " & errMsg
  end try
end simulateBiometricAuth

return my simulateBiometricAuth("--MCP_INPUT:authResult", "--MCP_INPUT:deviceIdentifier", "--MCP_INPUT:biometricType")
```