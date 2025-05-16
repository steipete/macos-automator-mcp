---
title: 'Chrome: Open URL in New Tab (Specific Profile)'
category: 07_browsers
id: chrome_open_url_new_tab_profile
description: >-
  Opens a specified URL in Google Chrome, potentially in a specific user
  profile, creating a new tab if Chrome is already open.
keywords:
  - chrome
  - new tab
  - open url
  - profile
  - navigation
  - shell
language: applescript
isComplex: true
argumentsPrompt: >-
  URL as 'targetURL'. Optionally, profile directory name (e.g., 'Profile 1' or
  'Default') as 'profileDir' and boolean 'newWindow' in inputData.
notes: >
  - To find profile directory names, navigate to `chrome://version` in Chrome.

  - If `profileDir` is specified, it uses `do shell script` to launch Chrome
  with that profile.

  - If Chrome is already running with the desired profile, it will just open a
  new tab. If a different profile is active, it might open a new window with the
  specified profile.
---

```applescript
--MCP_INPUT:targetURL
--MCP_INPUT:profileDir
--MCP_INPUT:newWindow

on openInChrome(theURL, profileName, useNewWindow)
  if theURL is missing value or theURL is "" then return "error: URL not provided."
  
  if profileName is not missing value and profileName is not "" then
    try
      set chromeArgs to "--args"
      if useNewWindow is true then
         set chromeArgs to "-n " & chromeArgs -- -n for new instance/window
      end if
      do shell script "open -b com.google.Chrome " & chromeArgs & " --profile-directory=" & quoted form of profileName & " " & quoted form of theURL
      return "Attempted to open " & theURL & " in Chrome profile: " & profileName
    on error errMsg
      return "error: Could not open Chrome with profile '" & profileName & "': " & errMsg
    end try
  else
    tell application "Google Chrome"
      if not running then
        run
        delay 1
      end if
      activate
      if (count of windows) is 0 or useNewWindow is true then
        make new window with properties {URL:theURL}
      else
        tell front window
          make new tab at after (get active tab) with properties {URL:theURL}
        end tell
      end if
      return "Opened " & theURL & " in Chrome."
    on error errMsg
      return "error: Failed to open URL in Chrome - " & errMsg
    end try
  end if
end openInChrome

return my openInChrome("--MCP_INPUT:targetURL", "--MCP_INPUT:profileDir", --MCP_INPUT:newWindow)
```
END_TIP 
