---
title: 'StandardAdditions: choose color Command'
category: 02_as_core
id: osax_choose_color
description: >-
  Displays the standard macOS color picker dialog and returns the selected color
  as an RGB list.
keywords:
  - StandardAdditions
  - choose color
  - color picker
  - RGB color
  - dialog
  - osax
language: applescript
notes: >
  - The `choose color` command presents the standard macOS color picker.

  - Returns a list of three integers representing the Red, Green, and Blue
  components of the selected color, each from 0 to 65535.

  - If the user cancels, an error (number -128) is raised.

  - Can optionally take a `default color` parameter with an RGB list.
---

This command allows the user to select a color using the macOS color picker.

```applescript
try
  -- Choose color with a default (e.g., a light blue)
  set chosenColorRGB to choose color default color {30000, 45000, 60000} -- R, G, B values (0-65535)
  
  set redValue to item 1 of chosenColorRGB
  set greenValue to item 2 of chosenColorRGB
  set blueValue to item 3 of chosenColorRGB
  
  set resultMessage to "Chosen color (RGB 0-65535): {" & redValue & ", " & greenValue & ", " & blueValue & "}"
  
  -- Convert to RGB 0-255 for common usage (approximate)
  set red255 to round (redValue / 65535 * 255) without rounding
  set green255 to round (greenValue / 65535 * 255) without rounding
  set blue255 to round (blueValue / 65535 * 255) without rounding
  
  set resultMessage to resultMessage & "\nApprox. RGB (0-255): {" & red255 & ", " & green255 & ", " & blue255 & "}"
  
on error errMsg number errNum
  if errNum is -128 then
    set resultMessage to "User cancelled color selection."
  else
    set resultMessage to "Error (" & errNum & "): " & errMsg
  end if
end try

return resultMessage
```
END_TIP 
