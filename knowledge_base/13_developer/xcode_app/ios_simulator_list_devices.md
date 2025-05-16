---
title: 'iOS Simulator: List Available Devices'
category: 13_developer/xcode_app
id: ios_simulator_list_devices
description: 'Lists all available iOS, iPadOS, watchOS, and tvOS simulator devices.'
keywords:
  - iOS Simulator
  - Xcode
  - device
  - list
  - UDID
  - runtime
  - developer
  - iOS
  - iPadOS
  - watchOS
  - tvOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional filter string to search for specific device types (e.g., 'iPhone',
  'iPad', 'Watch') as 'deviceFilter' in inputData. Optional boolean to show only
  booted devices as 'onlyBootedDevices' (default is false).
notes: |
  - Uses xcrun simctl to list available simulator devices
  - Shows device name, runtime version, state, and UDID
  - Can filter for specific device types
  - Option to show only currently booted simulators
  - Useful for getting simulator UDIDs for use in other scripts
  - Results are formatted as a readable list
---

```applescript
--MCP_INPUT:deviceFilter
--MCP_INPUT:onlyBootedDevices

on listIOSSimulatorDevices(deviceFilter, onlyBootedDevices)
  -- Default for only booted devices if not specified
  if onlyBootedDevices is missing value or onlyBootedDevices is "" then
    set onlyBootedDevices to false
  else if onlyBootedDevices is "true" then
    set onlyBootedDevices to true
  end if
  
  -- Get the list of devices from xcrun simctl
  try
    set deviceListRaw to do shell script "xcrun simctl list devices --json"
    
    -- Parse the JSON manually by extracting device info sections
    set deviceListFormatted to ""
    set deviceLinesCount to 0
    
    -- First make a readable text list format
    set deviceListCommand to "xcrun simctl list devices"
    if onlyBootedDevices then
      set deviceListCommand to deviceListCommand & " | grep '(Booted)'"
    end if
    if deviceFilter is not missing value and deviceFilter is not "" then
      set deviceListCommand to deviceListCommand & " | grep -i '" & deviceFilter & "'"
    end if
    
    set deviceListText to do shell script deviceListCommand
    
    -- Process the output line by line to make it more readable
    set AppleScript's text item delimiters to return
    set deviceLines to text items of deviceListText
    set AppleScript's text item delimiters to ""
    
    set currentRuntime to ""
    set deviceCount to 0
    
    repeat with deviceLine in deviceLines
      set trimmedLine to trim(deviceLine)
      if trimmedLine starts with "--" then
        -- This is a runtime version header line
        if currentRuntime is not "" and deviceCount > 0 then
          set deviceListFormatted to deviceListFormatted & return & return
        end if
        set currentRuntime to text 3 thru -3 of trimmedLine
        set deviceListFormatted to deviceListFormatted & "Runtime: " & currentRuntime & return & "-------------------" & return
        set deviceCount to 0
      else if trimmedLine is not "" then
        -- This is a device line
        set deviceCount to deviceCount + 1
        set deviceLinesCount to deviceLinesCount + 1
        
        -- Extract device name, state and UDID
        set deviceName to ""
        set deviceState to ""
        set deviceUDID to ""
        
        -- Try to parse the line
        try
          -- Typical line format: "iPhone 14 (AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE) (Booted)"
          set nameEndPos to offset of " (" in trimmedLine
          if nameEndPos > 0 then
            set deviceName to text 1 thru (nameEndPos - 1) of trimmedLine
            
            -- Extract UDID - look for text between first set of parentheses
            set uidStartPos to nameEndPos + 2
            set uidEndPos to offset of ")" in (text uidStartPos thru -1 of trimmedLine)
            if uidEndPos > 0 then
              set deviceUDID to text uidStartPos thru (uidStartPos + uidEndPos - 2) of trimmedLine
              
              -- Check if there is a state in parentheses
              set stateStartPos to uidStartPos + uidEndPos + 1
              if stateStartPos < length of trimmedLine then
                set restOfLine to text stateStartPos thru -1 of trimmedLine
                if restOfLine contains "(" then
                  set stateStartPos to offset of "(" in restOfLine
                  set stateEndPos to offset of ")" in (text stateStartPos thru -1 of restOfLine)
                  if stateEndPos > 0 then
                    set deviceState to text (stateStartPos + 1) thru (stateStartPos + stateEndPos - 2) of restOfLine
                  end if
                end if
              end if
            end if
          end if
        end try
        
        -- Add formatted device info to the list
        set deviceListFormatted to deviceListFormatted & "  " & deviceCount & ". " & deviceName
        if deviceState is not "" then
          set deviceListFormatted to deviceListFormatted & " (" & deviceState & ")"
        end if
        set deviceListFormatted to deviceListFormatted & return & "     UDID: " & deviceUDID & return
      end if
    end repeat
    
    -- Add summary count
    set deviceListFormatted to deviceListFormatted & return & "-------------------------------" & return & "Total Devices: " & deviceLinesCount
    
    -- If no devices found, provide a message
    if deviceLinesCount = 0 then
      if deviceFilter is not missing value and deviceFilter is not "" then
        set deviceListFormatted to "No simulator devices found matching filter: '" & deviceFilter & "'"
      else if onlyBootedDevices then
        set deviceListFormatted to "No booted simulator devices found."
      else
        set deviceListFormatted to "No simulator devices found. You may need to install simulator runtimes in Xcode."
      end if
    end if
    
    return deviceListFormatted
  on error errMsg number errNum
    return "error (" & errNum & ") listing iOS simulator devices: " & errMsg
  end try
end listIOSSimulatorDevices

-- Helper function to trim whitespace
on trim(inputString)
  set whitespace to {" ", tab, return, linefeed}
  set outputString to inputString
  
  repeat while outputString starts with any item of whitespace
    set outputString to text 2 thru -1 of outputString
  end repeat
  
  repeat while outputString ends with any item of whitespace
    set outputString to text 1 thru -2 of outputString
  end repeat
  
  return outputString
end trim

return my listIOSSimulatorDevices("--MCP_INPUT:deviceFilter", "--MCP_INPUT:onlyBootedDevices")
```
