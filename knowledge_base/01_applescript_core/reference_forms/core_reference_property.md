---
title: "Core: Property Reference Form"
category: "01_applescript_core" # Subdir: reference_forms
id: core_reference_property
description: "Accessing the properties of objects (e.g., name of file, URL of document)."
keywords: ["reference form", "property", "attribute", "object property", "name of", "class of"]
language: applescript
notes: |
  - Properties are characteristics or attributes of an object.
  - The syntax is `property_name of object_reference` or `object_reference's property_name`.
  - Available properties depend on the object's class and the application defining it (check its dictionary).
---

The Property reference form allows you to get or set the attributes of an object.

```applescript
-- Record property
set myRecord to {fruit:"apple", color:"red", quantity:10}
set fruitName to fruit of myRecord      -- "apple"
set fruitColor to myRecord's color     -- "red"

-- Date properties
set today to current date
set theYear to year of today
set theMonth to month of today -- This is a constant, e.g., December
set theDay to day of today

-- File properties (using Finder)
set fileInfo to "(Finder example not run by default / TextEdit.app example)"
(*
tell application "Finder"
  try
    set appPath to (path to application "TextEdit")
    set appFile to file (POSIX path of appPath) -- More direct way to get Finder item for app
    
    set appName to name of appFile
    set appKind to kind of appFile
    set appSize to size of appFile
    set fileInfo to "App: " & appName & ", Kind: " & appKind & ", Size: " & appSize
  on error errMsg
    set fileInfo to "Finder error: " & errMsg
  end try
end tell
*)

-- Application object properties (example with Safari, if running and has a document)
set safariDocURL to "(Safari example not run or no document)"
(*
if application "Safari" is running then
  tell application "Safari"
    try
      if (count of documents) > 0 then
        set frontSafariDoc to document 1
        set safariDocURL to URL of frontSafariDoc
      else
        set safariDocURL to "Safari has no documents open."
      end if
    on error errMsg
      set safariDocURL to "Safari error: " & errMsg
    end try
  end tell
else
  set safariDocURL to "Safari is not running."
end if
*)

return "Record fruit: " & fruitName & ¬
  "\nRecord color: " & fruitColor & ¬
  "\nYear: " & theYear & ¬
  "\nMonth: " & (theMonth as string) & ¬ -- Coerce month constant to string for display
  "\nFile Info: " & fileInfo & ¬
  "\nSafari Doc URL: " & safariDocURL
```
END_TIP 