---
title: 'StandardAdditions: display dialog Command'
category: 02_as_core/scripting_additions_osax
id: osax_display_dialog
description: >-
  Displays a modal dialog box with a message, optional input field, buttons, and
  icon.
keywords:
  - StandardAdditions
  - display dialog
  - dialog
  - alert
  - prompt
  - user input
  - osax
language: applescript
notes: >
  - `display dialog` is a versatile command for user interaction.

  - Returns a record containing `button returned` and, if applicable, `text
  returned`.

  - If the user cancels (e.g., presses Escape or a designated Cancel button
  without `cancelButton` specified in `buttons`), an error (number -128) is
  raised. Use a `try` block for robust error handling.

  - Common parameters: `default answer "text"`, `hidden answer true`, `buttons
  {"Btn1", "Btn2", ...}`, `default button "BtnName"` or `default button number`,
  `cancel button "BtnName"` or `cancel button number`, `with title "Title"`,
  `with icon file/alias` or `with icon note/stop/caution`, `giving up after
  seconds`.
---

`display dialog` is a key command for interacting with the user.

```applescript
-- Simple dialog
-- display dialog "Hello, AppleScript User!"

-- Dialog with title and icon
-- display dialog "This is an important message." with title "System Alert" with icon stop

-- Dialog with input field
try
  set nameResult to display dialog "What is your name?" default answer "" with title "Name Entry"
  if button returned of nameResult is "OK" then
    set userName to text returned of nameResult
    if userName is "" then
      set userName to "Anonymous"
    end if
  else
    set userName to "User Cancelled"
  end if
on error number -128 -- User cancelled
  set userName to "User Cancelled (Error -128)"
end try

-- Dialog with custom buttons and timeout
set message to "Proceed with caution?"
set customButtons to {"Cancel", "No", "Yes"}
try
  set choiceResult to display dialog message with title "Confirmation" buttons customButtons default button "Yes" cancel button "Cancel" giving up after 10
  
  set userChoice to button returned of choiceResult
  if userChoice is "Yes" then
    set finalDecision to "Proceeding!"
  else if userChoice is "No" then
    set finalDecision to "Holding back."
  else -- Cancel or timeout (if not caught by giving up) 
    set finalDecision to "Cancelled or timed out."
  end if
  
on error errMsg number errNum
  if errNum = -1712 then -- "gave up" error from timeout
    set finalDecision to "Dialog timed out."
  else if errNum = -128 then -- User cancelled explicitly
    set finalDecision to "User cancelled dialog."
  else
    set finalDecision to "Error: " & errMsg
  end if
end try

return "User Name: " & userName & "\nFinal Decision: " & finalDecision
```
END_TIP 
