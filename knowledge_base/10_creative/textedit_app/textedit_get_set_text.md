---
title: 'TextEdit: Get and Set Text of Front Document'
category: 10_creative/textedit_app
id: textedit_get_set_text
description: >-
  Retrieves the entire text content of the frontmost TextEdit document, or sets
  it.
keywords:
  - TextEdit
  - text content
  - document
  - read text
  - write text
language: applescript
notes: TextEdit must be running and have a document open (for getting text).
---

**Get Text:**
```applescript
tell application "TextEdit"
  if not running then return "error: TextEdit is not running."
  if (count of documents) is 0 then return "error: No documents open in TextEdit."
  activate
  try
    return text of front document
  on error errMsg
    return "error: Could not get text - " & errMsg
  end try
end tell
```

**Set Text (Overwrites existing content):**
```applescript
--MCP_INPUT:newTextContent

on setTextInFrontTextEditDoc(textContent)
  if textContent is missing value then set textContent to ""
  tell application "TextEdit"
    if not running then
      run
      delay 0.5
      make new document
    else if (count of documents) is 0 then
      make new document
    end if
    activate
    try
      set text of front document to textContent
      return "Text set in front TextEdit document."
    on error errMsg
      return "error: Could not set text - " & errMsg
    end try
  end tell
end setTextInFrontTextEditDoc

-- Example call for setting text if run by ID:
return my setTextInFrontTextEditDoc("--MCP_INPUT:newTextContent")
```
END_TIP
