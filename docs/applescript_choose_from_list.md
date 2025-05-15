# List Selection Operations in AppleScript

AppleScript's `choose from list` command allows users to select items from a presented list. This document explains how to use this feature.

## Simple List Selection

```applescript
set myList to {"Apple", "Banana", "Cherry", "Date", "Elderberry"}

-- Single selection
set singleChoice to choose from list myList with prompt "Select your favorite fruit:" with title "Fruit Picker" default items {"Banana"}

if singleChoice is false then
  return "User cancelled selection"
else
  return "User selected: " & (item 1 of singleChoice)
end if
```

## Multiple Selection

```applescript
set myList to {"Apple", "Banana", "Cherry", "Date", "Elderberry"}

-- Multiple selections allowed
set multipleChoices to choose from list myList with prompt "Select multiple fruits:" with title "Multi-Fruit Picker" default items {"Apple", "Date"} multiple selections allowed true

if multipleChoices is false then
  return "User cancelled selection"
else if multipleChoices is {} then
  return "User selected nothing (but clicked OK)"
else
  -- Convert list to comma-separated string
  set AppleScript's text item delimiters to ", "
  set choicesString to multipleChoices as string
  set AppleScript's text item delimiters to ""
  return "User selected: " & choicesString
end if
```

## Empty Selection Option

```applescript
-- Allow empty selection
set myList to {"Option 1", "Option 2", "Option 3"}
set choices to choose from list myList with prompt "Select options (or none):" with title "Options" empty selection allowed true

if choices is false then
  return "User cancelled"
else if choices is {} then
  return "User explicitly selected nothing (clicked OK with no selection)"
else
  return "User selected: " & (choices as string)
end if
```

## Complete Example with Error Handling

```applescript
set myList to {"Alpha", "Beta", "Gamma", "Delta"}

try
  set singleChoice to choose from list myList with prompt "Select an item:" with title "Selection" OK button name "Choose" cancel button name "Skip"
  
  if singleChoice is false then
    return "User cancelled selection"
  else
    return "User selected: " & (item 1 of singleChoice)
  end if
on error errMsg number errNum
  if errNum is -128 then
    return "User cancelled selection using Escape key"
  else
    return "Error occurred: " & errMsg
  end if
end try
```

## Notes

- Returns `false` if user cancels (clicks Cancel or presses Escape)
- Returns an empty list `{}` if `empty selection allowed` is true and user clicks OK without selecting
- Returns a list (even for single selections) of the selected items
- For single selection (the default), the selected item is always the first (only) item in the returned list
- Use the `default items` parameter to pre-select items in the list
- The dialog is modal, blocking script execution until the user responds