---
title: 'iOS Simulator: Manage Pasteboard'
category: 13_developer/xcode_app
id: ios_simulator_pasteboard
description: Manages clipboard content between Mac and iOS Simulator device.
keywords:
  - iOS Simulator
  - Xcode
  - pasteboard
  - clipboard
  - copy
  - paste
  - text
  - developer
  - iOS
  - iPadOS
language: applescript
isComplex: true
argumentsPrompt: >-
  Action as 'action' ('copy-to-simulator', 'copy-from-simulator', 'get', or
  'set'), optional content as 'content' (for 'set' action), and optional device
  identifier as 'deviceIdentifier' (defaults to 'booted').
notes: |
  - Transfers text between Mac and simulator clipboard
  - Copies content in both directions
  - Useful for automating clipboard-based testing
  - Can set specific content for simulator clipboard
  - Works with currently running simulators only
  - Handles text content (plain text, no images or rich content)
---

```applescript
--MCP_INPUT:action
--MCP_INPUT:content
--MCP_INPUT:deviceIdentifier

on manageSimulatorPasteboard(action, content, deviceIdentifier)
  if action is missing value or action is "" then
    return "error: Action not provided. Available actions: 'copy-to-simulator', 'copy-from-simulator', 'get', 'set'."
  end if
  
  -- Normalize action to lowercase and handle aliases
  set action to do shell script "echo " & quoted form of action & " | tr '[:upper:]' '[:lower:]'"
  if action is "copy-to-sim" or action is "copytosim" or action is "to-sim" or action is "tosim" then
    set action to "copy-to-simulator"
  else if action is "copy-from-sim" or action is "copyfromsim" or action is "from-sim" or action is "fromsim" then
    set action to "copy-from-simulator"
  end if
  
  -- Validate action
  if action is not in {"copy-to-simulator", "copy-from-simulator", "get", "set"} then
    return "error: Invalid action. Available actions: 'copy-to-simulator', 'copy-from-simulator', 'get', 'set'."
  end if
  
  -- Default to booted device if not specified
  if deviceIdentifier is missing value or deviceIdentifier is "" then
    set deviceIdentifier to "booted"
  end if
  
  -- Check if we need content
  if action is "set" and (content is missing value or content is "") then
    return "error: Content not provided for 'set' action. Specify the text to set on the simulator pasteboard."
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
    
    -- Perform the requested action
    if action is "copy-to-simulator" then
      -- Get Mac clipboard content and copy to simulator
      try
        set macClipboardContent to the clipboard
        if macClipboardContent is "" then
          return "error: Mac clipboard is empty. Nothing to copy to simulator."
        end if
        
        -- Write Mac clipboard to a temp file
        set tempFile to do shell script "mktemp /tmp/clipboard_XXXXX.txt"
        do shell script "echo " & quoted form of macClipboardContent & " > " & quoted form of tempFile
        
        -- Copy to simulator
        set pbpasteCmd to "xcrun simctl pbpaste " & quoted form of deviceIdentifier & " < " & quoted form of tempFile
        do shell script pbpasteCmd
        
        -- Clean up temp file
        do shell script "rm " & quoted form of tempFile
        
        return "Successfully copied Mac clipboard content to " & deviceIdentifier & " simulator.

Content: " & (if length of macClipboardContent > 200 then text 1 thru 197 of macClipboardContent & "..." else macClipboardContent) & "

The content is now available in the simulator's pasteboard for pasting into apps."
      on error errMsg
        return "Error copying to simulator pasteboard: " & errMsg
      end try
      
    else if action is "copy-from-simulator" or action is "get" then
      -- Get simulator clipboard content
      try
        set tempFile to do shell script "mktemp /tmp/simulator_clipboard_XXXXX.txt"
        set pbcopyCmd to "xcrun simctl pbcopy " & quoted form of deviceIdentifier & " > " & quoted form of tempFile
        do shell script pbcopyCmd
        
        -- Read clipboard content
        set simClipboardContent to do shell script "cat " & quoted form of tempFile
        
        -- Clean up temp file
        do shell script "rm " & quoted form of tempFile
        
        -- Copy to Mac clipboard if requested
        if action is "copy-from-simulator" then
          set the clipboard to simClipboardContent
        end if
        
        set actionText to ""
        if action is "copy-from-simulator" then
          set actionText to "Copied simulator clipboard content to Mac clipboard.

"
        end if
        
        return actionText & "Simulator pasteboard content from " & deviceIdentifier & ":

" & (if simClipboardContent is "" then "[Empty]" else simClipboardContent)
      on error errMsg
        return "Error getting simulator pasteboard: " & errMsg
      end try
      
    else if action is "set" then
      -- Set content to simulator clipboard
      try
        -- Write content to a temp file
        set tempFile to do shell script "mktemp /tmp/clipboard_XXXXX.txt"
        do shell script "echo " & quoted form of content & " > " & quoted form of tempFile
        
        -- Copy to simulator
        set pbpasteCmd to "xcrun simctl pbpaste " & quoted form of deviceIdentifier & " < " & quoted form of tempFile
        do shell script pbpasteCmd
        
        -- Clean up temp file
        do shell script "rm " & quoted form of tempFile
        
        return "Successfully set clipboard content on " & deviceIdentifier & " simulator.

Content: " & (if length of content > 200 then text 1 thru 197 of content & "..." else content) & "

The content is now available in the simulator's pasteboard for pasting into apps."
      on error errMsg
        return "Error setting simulator pasteboard: " & errMsg
      end try
    end if
  on error errMsg number errNum
    return "error (" & errNum & ") managing simulator pasteboard: " & errMsg
  end try
end manageSimulatorPasteboard

return my manageSimulatorPasteboard("--MCP_INPUT:action", "--MCP_INPUT:content", "--MCP_INPUT:deviceIdentifier")
```
