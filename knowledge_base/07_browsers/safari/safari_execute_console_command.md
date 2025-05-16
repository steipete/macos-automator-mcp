---
title: "Safari: Execute Console Command"
category: "05_web_browsers"
id: safari_execute_console_command
description: "Executes a JavaScript command in Safari's Web Inspector console and returns the result."
keywords: ["Safari", "console", "JavaScript", "Web Inspector", "developer tools", "debugging", "web development"]
language: applescript
isComplex: true
argumentsPrompt: "JavaScript console command as 'command' in inputData."
notes: |
  - Safari must be running with at least one open tab.
  - The Develop menu must be enabled in Safari preferences.
  - This script uses UI automation via System Events, so Accessibility permissions are required.
  - The script will open the Web Inspector, execute the command in the console, and capture the result.
  - The command should be valid JavaScript that can be executed in a browser console.
  - Complex commands with multiple lines are supported.
  - Results are captured from the console output (with some limitations).
---

This script executes a JavaScript command in Safari's Web Inspector console and returns the result.

```applescript
--MCP_INPUT:command

on executeConsoleCommand(jsCommand)
  if jsCommand is missing value or jsCommand is "" then
    return "error: JavaScript command not provided."
  end if
  
  if not application "Safari" is running then
    return "error: Safari is not running."
  end if
  
  tell application "Safari"
    if (count of windows) is 0 or (count of tabs of front window) is 0 then
      return "error: No tabs open in Safari."
    end if
    
    activate
    delay 0.5
    
    try
      -- Prepare a unique marker to identify our command's output
      set uniqueMarker to "CMD_RESULT_" & (random number from 10000 to 99999)
      set escapedCommand to my escapeJSString(jsCommand)
      
      -- Prepare the command with output capture wrapper
      set wrappedCommand to "try { "
      set wrappedCommand to wrappedCommand & "const " & uniqueMarker & " = (function() { return (" & escapedCommand & "); })(); "
      set wrappedCommand to wrappedCommand & "console.log('START_" & uniqueMarker & "'); "
      set wrappedCommand to wrappedCommand & "console.log(JSON.stringify(" & uniqueMarker & ", null, 2)); "
      set wrappedCommand to wrappedCommand & "console.log('END_" & uniqueMarker & "'); "
      set wrappedCommand to wrappedCommand & "} catch(e) { console.log('ERROR_" & uniqueMarker & ": ' + e.message); }"
      
      tell application "System Events"
        tell process "Safari"
          -- Open Web Inspector if not already open
          set inspectorOpen to false
          try
            if window "Web Inspector" exists then
              set inspectorOpen to true
            end if
          end try
          
          if not inspectorOpen then
            keystroke "i" using {command down, option down}
            delay 1
          end if
          
          -- Navigate to Console tab
          try
            -- Try to find and click the Console tab
            set consoleTabFound to false
            
            repeat with btn in (buttons of tab group 1 of group 1 of splitter group 1 of window "Web Inspector")
              if the name of btn is "Console" then
                click btn
                set consoleTabFound to true
                exit repeat
              end if
            end repeat
            
            if not consoleTabFound then
              -- If we couldn't find the Console tab, try alternative approaches
              -- First attempt: try clicking the tab by position
              click button 2 of tab group 1 of group 1 of splitter group 1 of window "Web Inspector"
            end if
            
            delay 0.5
          end try
          
          -- Clear the console before executing our command
          keystroke "k" using {command down}
          delay 0.3
          
          -- Enter and execute the command
          set the clipboard to wrappedCommand
          keystroke "v" using {command down}
          delay 0.1
          keystroke return
          delay 1
          
          -- Now we need to extract the result from the console
          -- We'll use a different approach based on UI scripting
          -- First, we need to find the console output area
          
          -- Determine if we got results by checking if our markers are present in the console
          -- Most reliable way is to copy all console text to clipboard and search
          set frontmost to true
          keystroke "a" using {command down}
          delay 0.1
          keystroke "c" using {command down}
          delay 0.1
          
          set consoleText to the clipboard
          
          -- Extract the result between our markers
          set startMarker to "START_" & uniqueMarker
          set endMarker to "END_" & uniqueMarker
          set errorMarker to "ERROR_" & uniqueMarker & ": "
          
          if consoleText contains errorMarker then
            -- Extract error message
            set AppleScript's text item delimiters to errorMarker
            set errorTextItems to text items of consoleText
            if (count of errorTextItems) > 1 then
              set errorTextFull to item 2 of errorTextItems
              set AppleScript's text item delimiters to return
              set errorTextLines to text items of errorTextFull
              set errorMessage to item 1 of errorTextLines
              return "error: JavaScript execution failed - " & errorMessage
            else
              return "error: JavaScript execution failed, but couldn't extract error message."
            end if
          else if consoleText contains startMarker and consoleText contains endMarker then
            -- Extract result between markers
            set AppleScript's text item delimiters to startMarker
            set resultTextItems to text items of consoleText
            if (count of resultTextItems) > 1 then
              set resultTextFull to item 2 of resultTextItems
              set AppleScript's text item delimiters to endMarker
              set resultTextParts to text items of resultTextFull
              if (count of resultTextParts) > 0 then
                set resultText to item 1 of resultTextParts
                -- Remove leading newline if present
                if character 1 of resultText is return then
                  set resultText to text 2 thru end of resultText
                end if
                return resultText
              end if
            end if
            
            return "Command executed, but couldn't parse the result."
          else
            return "Command executed, but couldn't find output markers. The command may have produced no output."
          end if
        end tell
      end tell
    on error errMsg
      return "error: Failed to execute console command - " & errMsg
    end try
  end tell
end executeConsoleCommand

-- Helper function to escape JavaScript string
on escapeJSString(jsString)
  set escapedString to ""
  repeat with c in characters of jsString
    if c is "\"" then
      set escapedString to escapedString & "\\\""
    else if c is "\\" then
      set escapedString to escapedString & "\\\\"
    else if c is return then
      set escapedString to escapedString & "\\n"
    else
      set escapedString to escapedString & c
    end if
  end repeat
  return escapedString
end escapeJSString

return my executeConsoleCommand("--MCP_INPUT:command")
```