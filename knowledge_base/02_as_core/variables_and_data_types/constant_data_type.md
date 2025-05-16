---
title: 'AppleScript Constants: The ''constant'' Data Type'
category: 02_as_core
id: core_datatype_constant
description: >-
  Explains AppleScript's 'constant' data type, which represents named constant
  values used by applications.
keywords:
  - constant
  - data type
  - enumeration
  - application constants
  - symbolic values
  - type coercion
language: applescript
notes: >
  - Constants are enumerated values defined by applications or AppleScript

  - They represent symbolic values that have meaning within an application's
  context

  - Constants are often returned by application properties and can be used as
  parameters

  - While constants have a symbolic representation, they can be coerced to
  strings
---

In AppleScript, the `constant` data type represents symbolic values with specific meanings in a particular context. Applications define constants to represent specific states, modes, or options.

```applescript
-- Example of application constants
tell application "Finder"
  -- File sorting constants
  set nameSort to name column -- Returns constant value: 'name'
  set sizeSort to size column -- Returns constant value: 'size'
  set dateSort to modification date column -- Returns constant value: 'modd'
  
  -- View mode constants
  set listViewMode to list view -- Returns constant value: 'clvw'
  set iconViewMode to icon view -- Returns constant value: 'icnv'
  set columnViewMode to column view -- Returns constant value: 'clvw'
  
  -- Using constants as parameters
  -- Set the front Finder window to list view
  if (count of Finder windows) > 0 then
    set current view of front Finder window to list view
  end if
end tell

-- AppleScript's built-in constants
set mondayConstant to Monday -- Returns constant: Monday (day of week)
set textStyleConstant to bold -- Returns constant: bold (text style)

-- Converting constants to strings
set mondayString to mondayConstant as string -- Becomes "Monday"
set textStyleString to textStyleConstant as string -- Becomes "bold"

-- Constants typically have a class name that categorizes them
set mondayClass to class of mondayConstant -- Returns 'weekday'
set textStyleClass to class of textStyleConstant -- Returns 'style'

return "Finder sorting constants: " & nameSort & ", " & sizeSort & ", " & dateSort & return & ¬
  "Finder view mode constants: " & listViewMode & ", " & iconViewMode & ", " & columnViewMode & return & ¬
  "AppleScript constants: " & mondayConstant & " (class: " & mondayClass & "), " & ¬
  textStyleConstant & " (class: " & textStyleClass & ")" & return & ¬
  "As strings: " & mondayString & ", " & textStyleString
```

Key points about constants:

1. Constants are symbolic representations of values with specific meanings
2. They have a textual representation that describes their purpose
3. Applications define constants in their AppleScript dictionaries
4. Constants can be used as parameters in commands
5. They can be compared directly to other constants
6. Most constants can be coerced to strings, which gives their name
7. Constants have a "class" property that indicates their category

Constants are useful because they provide a more meaningful and readable way to represent specific values compared to using numbers or cryptic codes.
END_TIP
