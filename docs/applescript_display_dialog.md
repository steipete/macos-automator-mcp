# Dialog Operations in AppleScript

AppleScript's `display dialog` is a powerful command for presenting user interfaces. This document explains how to create dialogs for user interaction.

## Simple Dialog with Input

```applescript
-- Dialog with input field
set nameResult to display dialog "What is your name?" default answer "" with title "Name Entry"
set userName to text returned of nameResult

return "Hello, " & userName
```

## Dialog with Custom Buttons

```applescript
-- Dialog with custom buttons and timeout
set message to "Proceed with caution?"
set customButtons to {"Cancel", "No", "Yes"}
set choiceResult to display dialog message with title "Confirmation" buttons customButtons default button "Yes" cancel button "Cancel" giving up after 10
  
-- Process the user's response
set userChoice to button returned of choiceResult
if userChoice is "Yes" then
  return "User chose to proceed"
else if userChoice is "No" then
  return "User chose not to proceed"
else
  return "User cancelled"
end if
```

## Dialog with Password Input

```applescript
-- Dialog with hidden text entry (for passwords)
set passwordResult to display dialog "Enter your password:" default answer "" with title "Password Entry" with hidden answer
set userPassword to text returned of passwordResult

-- Never display passwords in real scripts!
return "Password received (length: " & (length of userPassword) & " characters)"
```

## Error Handling for Dialogs

```applescript
try
  set userResult to display dialog "Make a choice:" buttons {"Cancel", "OK"} default button "OK" cancel button "Cancel"
  return "User clicked: " & (button returned of userResult)
on error number -128
  -- Error -128 means the user cancelled
  return "User cancelled the dialog"
on error errMsg
  -- Other errors
  return "An error occurred: " & errMsg
end try
```

## Notes

- Dialogs block script execution until the user responds or the timeout is reached
- The `giving up after N` parameter sets a timeout in seconds
- When a dialog times out, it triggers error number -1712
- When the user cancels, error number -128 is thrown
- Dialog results are returned as records with properties like `button returned` and `text returned`
- Use hidden answer for sensitive input like passwords
- Dialogs are synchronous - the script pauses until the user responds