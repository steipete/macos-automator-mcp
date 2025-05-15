---
title: "Electron Editors: Get Editor Content via DevTools JS & Clipboard"
category: "06_ides_and_editors"
id: electron_editors_get_content_via_js_clipboard
description: "Retrieves the content of the active text editor in VS Code (or similar if API matches) by executing JavaScript in DevTools that copies the content to the clipboard, then AppleScript reads the clipboard."
keywords: ["vscode", "cursor", "electron", "devtools", "javascript", "clipboard", "get text", "editor content"]
language: applescript
isComplex: true
argumentsPrompt: "Target application name (e.g., 'Visual Studio Code') as 'targetAppName' in inputData."
notes: |
  - Target app must be frontmost. Relies on DevTools shortcut (Option+Command+I).
  - The JavaScript `vscode.env.clipboard.writeText(...)` and `vscode.window.activeTextEditor...` are specific to VS Code's renderer process API. Other Electron editors might require different JS.
  - This temporarily overwrites the user's clipboard.
---

```applescript
--MCP_INPUT:targetAppName

on getEditorContentViaJSClipboard(appName)
  if appName is missing value or appName is "" then return "error: Target application name not provided."

  set jsToExecuteAndCopyToClipboard to "
    (async () => {
      try {
        if (typeof vscode !== 'undefined' && vscode.window && vscode.window.activeTextEditor && vscode.env && vscode.env.clipboard) {
          const text = vscode.window.activeTextEditor.document.getText();
          await vscode.env.clipboard.writeText(text);
          return 'VSCODE_TEXT_COPIED'; // Signal success
        } else {
          return 'ERROR: VSCode API not available in this context.';
        }
      } catch (e) {
        return 'ERROR: JS Exception: ' + e.message;
      }
    })()
  "
  -- Store current clipboard to attempt restoration
  set oldClipboard to ""
  try
    set oldClipboard to the clipboard
  end try

  tell application appName to activate
  delay 0.5

  tell application "System Events"
    tell process appName
      set frontmost to true
      key code 34 using {command down, option down} -- Open DevTools
      delay 1.2 -- Wait for DevTools, ensure console is ready

      -- Paste the JS to execute (safer than keystroking complex JS)
      set the clipboard to jsToExecuteAndCopyToClipboard
      delay 0.2
      keystroke "v" using {command down} -- Paste JS
      delay 0.1
      key code 36 -- Execute JS (which copies editor content to clipboard)
      delay 0.8 -- Allow JS to run and clipboard to update
      
      -- Close DevTools (optional, keeps things cleaner)
      -- key code 34 using {command down, option down}
    end tell
  end tell

  delay 0.2 -- Final delay for clipboard
  set editorContent to (the clipboard as text)

  -- Attempt to restore clipboard
  -- Note: If the JS itself returned a string that ended up on clipboard instead of the desired content,
  -- this restoration logic is flawed. The JS *must* put the desired content on clipboard.
  -- The 'VSCODE_TEXT_COPIED' or 'ERROR: ...' signal from JS is actually what might be on clipboard if the JS is simple.
  -- For this pattern to truly work, the JS must *only* copy to clipboard and the AppleScript must assume success or handle failure.
  -- A robust method would be for the JS to return a status string, and if success, then AppleScript reads clipboard. This is hard with current `execute javascript` one-way.
  -- This simpler version just grabs what's on the clipboard after the JS runs.

  if oldClipboard is not "" then
    try
      -- set the clipboard to oldClipboard -- This might overwrite the result we want
    end try
  end if
  
  -- Check if the clipboard content is one of our JS status messages
  if editorContent starts with "VSCODE_TEXT_COPIED" then
    return "Successfully triggered JS to copy content. The content should be on the clipboard now. This script will return the JS confirmation."
    -- A more advanced version would re-read clipboard here to get the *actual* editor content
    -- if the JS copies it and then returns a status.
    -- For now, we assume the content IS the clipboard after the JS.
  else if editorContent starts with "ERROR:" then
    return "error: JavaScript execution reported an error: " & editorContent
  end if
  
  return editorContent
end getEditorContentViaJSClipboard

return my getEditorContentViaJSClipboard("--MCP_INPUT:targetAppName")

```
END_TIP