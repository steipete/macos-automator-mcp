---
title: "iOS Simulator: Manage Biometric Enrollment"
category: "developer"
id: ios_simulator_biometric_enrollment
description: "Manages Touch ID and Face ID enrollment and settings in iOS Simulator."
keywords: ["iOS Simulator", "Xcode", "Touch ID", "Face ID", "biometrics", "enrollment", "fingerprint", "authentication", "developer", "iOS", "iPadOS"]
language: applescript
isComplex: true
argumentsPrompt: "Action as 'action' ('enroll', 'unenroll', 'match', 'nomatch', 'status'), biometric type as 'biometricType' ('touchid', 'faceid'), and optional device identifier as 'deviceIdentifier' (defaults to 'booted')."
notes: |
  - Manages biometric enrollment and authentication in the simulator
  - Can enroll and unenroll simulated fingerprints or face recognition
  - Simulates successful or failed authentication attempts
  - Useful for testing secure app functionality
  - Helps test authentication flows without manual interaction
  - Works with simulators that support Touch ID or Face ID
---

```applescript
--MCP_INPUT:action
--MCP_INPUT:biometricType
--MCP_INPUT:deviceIdentifier

on manageBiometricEnrollment(action, biometricType, deviceIdentifier)
  if action is missing value or action is "" then
    return "error: Action not provided. Available actions: 'enroll', 'unenroll', 'match', 'nomatch', 'status'."
  end if
  
  if biometricType is missing value or biometricType is "" then
    return "error: Biometric type not provided. Available types: 'touchid', 'faceid'."
  end if
  
  -- Normalize to lowercase
  set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  set biometricType to do shell script "echo " & quoted form of biometricType & " | tr '[:upper:]' '[:lower:]'"
  
  -- Handle variations in biometric type input
  if biometricType contains "touch" then
    set biometricType to "touchid"
  else if biometricType contains "face" then
    set biometricType to "faceid"
  end if
  
  -- Validate action
  if action is not in {"enroll", "unenroll", "match", "nomatch", "status"} then
    return "error: Invalid action. Available actions: 'enroll', 'unenroll', 'match', 'nomatch', 'status'."
  end if
  
  -- Validate biometric type
  if biometricType is not in {"touchid", "faceid"} then
    return "error: Invalid biometric type. Available types: 'touchid', 'faceid'."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  try
    -- Check if device exists
    if deviceIdentifier is not "booted" then
      set checkDeviceCmd to "xcrun simctl list devices | grep '" & deviceIdentifier & "'"
      try
        do shell script checkDeviceCmd
      on error
        return "error: Device '" & deviceIdentifier & "' not found. Use 'booted' for the currently booted device, or check available devices."
      end try
    end if
    
    -- Get the device type to determine if Touch ID or Face ID is supported
    set deviceTypeCmd to "xcrun simctl list devices | grep -A1 '" & deviceIdentifier & "' | grep -v '" & deviceIdentifier & "' | head -1 | sed -E 's/.*\\((.*)\\).*/\\1/'"
    set deviceType to do shell script deviceTypeCmd
    
    set supportedBiometricType to "unknown"
    if deviceType contains "iPhone X" or deviceType contains "iPhone 11" or deviceType contains "iPhone 12" or deviceType contains "iPhone 13" or deviceType contains "iPhone 14" or deviceType contains "iPhone 15" or deviceType contains "iPhone 16" or deviceType contains "iPad Pro" then
      set supportedBiometricType to "faceid"
    else if deviceType contains "iPhone 5s" or deviceType contains "iPhone 6" or deviceType contains "iPhone 7" or deviceType contains "iPhone 8" or deviceType contains "iPhone SE" or deviceType contains "iPad Air" or deviceType contains "iPad mini" then
      set supportedBiometricType to "touchid"
    end if
    
    if supportedBiometricType is "unknown" then
      -- If we couldn't determine, just try the requested biometric type
      set supportedBiometricType to biometricType
    end if
    
    -- Check if requested biometric type is supported by the device
    if supportedBiometricType is not biometricType then
      return "warning: The device '" & deviceIdentifier & "' likely supports " & supportedBiometricType & ", not " & biometricType & ". The command may not work as expected."
    end if
    
    -- Use direct simctl command for supported operations
    if action is in {"match", "nomatch"} then
      set cmdName to biometricType & " " & deviceIdentifier & " " & action
      set biometricCmd to "xcrun simctl " & cmdName
      
      try
        do shell script biometricCmd
        set actionText to "Simulated " & (if action is "match" then "successful" else "failed") & " " & (if biometricType is "touchid" then "Touch ID" else "Face ID") & " authentication"
        return actionText & " on " & deviceIdentifier & " simulator.

The authentication result has been sent to the simulator. If an app is waiting for biometric authentication, it will receive the " & (if action is "match" then "success" else "failure") & " result."
      on error errMsg
        return "Error simulating biometric authentication: " & errMsg
      end try
    end if
    
    -- For enrollment operations, we need to use alternative approaches
    if action is "status" then
      -- Check enrollment status
      if biometricType is "touchid" then
        set statusCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults read com.apple.BiometricKit enrolled"
      else
        set statusCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " defaults read com.apple.BiometricKit faceIDEnrolled"
      end if
      
      try
        set enrollmentStatus to do shell script statusCmd
        if enrollmentStatus contains "1" then
          return (if biometricType is "touchid" then "Touch ID" else "Face ID") & " is currently enrolled on " & deviceIdentifier & " simulator."
        else
          return (if biometricType is "touchid" then "Touch ID" else "Face ID") & " is NOT currently enrolled on " & deviceIdentifier & " simulator."
        end if
      on error
        return (if biometricType is "touchid" then "Touch ID" else "Face ID") & " enrollment status could not be determined. Likely not enrolled."
      end try
      
    else if action is "enroll" then
      -- Enroll biometric
      if biometricType is "touchid" then
        -- For Touch ID
        set enrollCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -s com.apple.BiometricKit_Sim.fingerTouch.enrolled 1"
      else
        -- For Face ID
        set enrollCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -s com.apple.BiometricKit_Sim.pearl.enrolled 1"
      end if
      
      try
        do shell script enrollCmd
        return "Successfully enrolled " & (if biometricType is "touchid" then "Touch ID" else "Face ID") & " on " & deviceIdentifier & " simulator.

The simulator now has a " & (if biometricType is "touchid" then "fingerprint" else "face") & " enrolled for authentication."
      on error errMsg
        return "Error enrolling biometric: " & errMsg
      end try
      
    else if action is "unenroll" then
      -- Unenroll biometric
      if biometricType is "touchid" then
        -- For Touch ID
        set unenrollCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -s com.apple.BiometricKit_Sim.fingerTouch.enrolled 0"
      else
        -- For Face ID
        set unenrollCmd to "xcrun simctl spawn " & quoted form of deviceIdentifier & " notifyutil -s com.apple.BiometricKit_Sim.pearl.enrolled 0"
      end if
      
      try
        do shell script unenrollCmd
        return "Successfully unenrolled " & (if biometricType is "touchid" then "Touch ID" else "Face ID") & " on " & deviceIdentifier & " simulator.

The simulator no longer has a " & (if biometricType is "touchid" then "fingerprint" else "face") & " enrolled for authentication."
      on error errMsg
        return "Error unenrolling biometric: " & errMsg
      end try
    end if
    
  on error errMsg number errNum
    return "error (" & errNum & ") managing biometric enrollment: " & errMsg
  end try
end manageBiometricEnrollment

return my manageBiometricEnrollment("--MCP_INPUT:action", "--MCP_INPUT:biometricType", "--MCP_INPUT:deviceIdentifier")
```