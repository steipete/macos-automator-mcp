---
title: 'Calculator: Perform Basic Calculation'
category: 13_developer/calculator_app
id: calculator_perform_calculation
description: Performs a basic calculation using the macOS Calculator app.
keywords:
  - Calculator
  - math
  - arithmetic
  - calculation
  - compute
language: applescript
argumentsPrompt: 'Enter the calculation to perform (e.g., ''15 * 7'')'
notes: >-
  Performs basic arithmetic operations using the Calculator app's UI. Limited to
  simple calculations that can be entered via keystrokes.
---

```applescript
on run {calculationInput}
  tell application "Calculator"
    try
      if calculationInput is "" or calculationInput is missing value then
        set calculationInput to "--MCP_INPUT:calculationInput"
      end if
      
      activate
      
      -- Give Calculator time to launch
      delay 1
      
      tell application "System Events"
        tell process "Calculator"
          -- Clear any previous calculation
          keystroke "c"
          
          -- Process each character in the calculation string
          set calculationChars to characters of calculationInput
          
          repeat with i from 1 to count of calculationChars
            set currentChar to item i of calculationChars
            
            -- Map operators and handle spaces
            if currentChar is "+" then
              keystroke "+"
            else if currentChar is "-" then
              keystroke "-"
            else if currentChar is "*" then
              keystroke "*"
            else if currentChar is "×" then
              keystroke "*"
            else if currentChar is "÷" then
              keystroke "/"
            else if currentChar is "/" then
              keystroke "/"
            else if currentChar is "=" then
              keystroke "="
            else if currentChar is " " then
              -- Skip spaces
            else
              -- For digits and other characters, just type them directly
              keystroke currentChar
            end if
          end repeat
          
          -- Press equals to get the result
          keystroke "="
          
          -- Get the result from the display
          set resultText to value of static text 1 of window 1
          
          return "Calculation: " & calculationInput & "\\nResult: " & resultText
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to perform calculation - " & errMsg
    end try
  end tell
end run
```
END_TIP
