---
title: "Electron Editors (VS Code): Get Active Editor Content via DevTools JS"
category: "05_ides_and_editors" # Subdir: electron_editors
id: electron_vscode_get_editor_content_js
description: "Retrieves text from VS Code's active editor using JavaScript injection into DevTools, copying result to clipboard."
keywords: ["vscode", "electron", "devtools", "javascript", "get text", "editor content", "clipboard"]
language: applescript
isComplex: true
notes: |
  - VS Code must be frontmost. Relies on DevTools shortcut (Option+Command+I).
  - Uses VS Code specific JS API: `vscode.window.activeTextEditor.document.getText()` and `vscode.env.clipboard.writeText()`.
  - Temporarily overwrites clipboard. This script attempts to return the content directly.
---

This is a more refined version to get editor content directly.

```applescript
on getVSCodeEditorContent()
  set jsToExecute to "
    (async () => {
      try {
        if (typeof vscode !== 'undefined' && vscode.window && vscode.window.activeTextEditor && vscode.env && vscode.env.clipboard) {
          const text = vscode.window.activeTextEditor.document.getText();
          await vscode.env.clipboard.writeText('%%SCRIPT_RESULT_START%%' + text + '%%SCRIPT_RESULT_END%%');
          return 'VSCODE_TEXT_COPIED_WITH_MARKERS';
        } else {
          return 'ERROR: VSCode API not available.';
        }
      } catch (e) {
        return 'ERROR: JS Exception: ' + e.message;
      }
    })()
  "

  tell application "Visual Studio Code" to activate
  delay 0.5

  tell application "System Events"
    tell process "Visual Studio Code"
      set frontmost to true
      key code 34 using {command down, option down} -- Open DevTools
      delay 1.2

      set the clipboard to jsToExecute -- Put the JS itself on clipboard
      delay 0.2
      keystroke "v" using {command down} -- Paste JS code into console
      delay 0.1
      key code 36 -- Execute JS (which puts editor content with markers on clipboard)
      delay 1.0 -- Allow time for JS to run and clipboard to update fully

      -- key code 34 using {command down, option down} -- Optionally close DevTools
    end tell
  end tell
  
  delay 0.2
  set clipboardContent to (the clipboard as text)
  
  set text item delimiters to "%%SCRIPT_RESULT_START%%"
  set tempSplit to text items of clipboardContent
  if count of tempSplit > 1 then
    set text item delimiters to "%%SCRIPT_RESULT_END%%"
    set editorText to text item 1 of (text item 2 of tempSplit)
    set text item delimiters to "" -- Reset
    return editorText
  else
    set text item delimiters to "" -- Reset
    if clipboardContent starts with "ERROR:" then
        return "error: " & clipboardContent
    else
        return "error: Could not find expected markers in clipboard. JS might have failed or content was unusual. Clipboard: " & (text 1 thru 100 of clipboardContent)
    end if
  end if
end getVSCodeEditorContent

return my getVSCodeEditorContent()
```
END_TIP 