---
title: 'Firefox: Capture Screenshot'
category: 07_browsers
id: firefox_capture_screenshot
description: Captures a screenshot of a webpage using Firefox's built-in screenshot tool.
keywords:
  - Firefox
  - screenshot
  - capture
  - web development
  - testing
  - documentation
  - full page
language: applescript
notes: |
  - Firefox must be running.
  - Uses Firefox's Developer Tools Screenshot functionality.
  - Requires accessibility permissions for UI scripting.
  - Can capture visible area, full page, or a specific element.
  - Screenshots are saved to Desktop by default.
---

This script captures screenshots in Firefox using the Developer Tools Screenshot functionality. It can capture the visible area of a webpage, a full-page screenshot, or a specific element.

```applescript
on run {input, parameters}
  -- Get parameters with defaults
  set screenshotType to "--MCP_INPUT:type" -- "visible", "fullpage", or "element"
  set saveLocation to "--MCP_INPUT:saveLocation" -- Destination folder
  set fileName to "--MCP_INPUT:fileName" -- Custom filename
  
  -- Use defaults if not specified
  if screenshotType is "" or screenshotType is "--MCP_INPUT:type" then
    set screenshotType to "visible"
  end if
  
  if saveLocation is "" or saveLocation is "--MCP_INPUT:saveLocation" then
    set saveLocation to (path to desktop folder as string)
  end if
  
  if fileName is "" or fileName is "--MCP_INPUT:fileName" then
    -- Generate a timestamp-based filename
    set currentDate to current date
    set fileName to "Firefox_Screenshot_" & (year of currentDate as string) & "-" & (month of currentDate as integer as string) & "-" & (day of currentDate as string) & "_" & (time string of currentDate)
    -- Replace colons with underscores for valid filename
    set fileName to do shell script "echo " & quoted form of fileName & " | sed 's/:/./g'"
    set fileName to fileName & ".png"
  else
    -- Ensure filename has .png extension
    if fileName does not end with ".png" then
      set fileName to fileName & ".png"
    end if
  end if
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- Open Developer Tools if not already open
  tell application "System Events"
    tell process "Firefox"
      key code 111 -- F12 to open Developer Tools
      delay 1 -- Allow DevTools to open
    end tell
  end tell
  
  -- Take screenshot using the menu commands in Developer Tools
  tell application "System Events"
    tell process "Firefox"
      -- First, click the "..." menu in DevTools if it exists
      -- This is where Screenshot is usually found
      
      -- Try to find the kebab menu (three dots) in DevTools
      try
        -- This will depend on Firefox version and UI layout
        -- Find and click the button with the "..." label or similar
        
        -- Open DevTools menu (may vary by Firefox version)
        keystroke "." using {command down, shift down} -- Common shortcut for DevTools options
        delay 0.5
        
        -- Look for "Take a screenshot" option and click it
        set foundScreenshot to false
        
        -- Try to find and click the screenshot option
        -- Loop through menu items to find it
        repeat with menuItem in menu items of menu 1 of front window
          if name of menuItem contains "screenshot" then
            click menuItem
            set foundScreenshot to true
            delay 0.5
            exit repeat
          end if
        end repeat
        
        -- If above method fails, try alternative approach with keyboard
        if not foundScreenshot then
          -- Close the menu with Escape
          key code 53 -- Escape key
          delay 0.3
          
          -- Try using Shift+F2 to open the Developer Toolbar
          key code 120 using {shift down} -- Shift+F2
          delay 0.5
          
          -- Type "screenshot" command
          if screenshotType is "visible" then
            keystroke "screenshot --clipboard"
          else if screenshotType is "fullpage" then
            keystroke "screenshot --fullpage --clipboard"
          else if screenshotType is "element" then
            keystroke "screenshot --selector \"--MCP_INPUT:selector\" --clipboard"
          end if
          
          keystroke return
          delay 1.5 -- Allow time for the screenshot to be taken
        end if
      on error
        -- If the above approaches fail, try the keyboard shortcut
        -- Press Ctrl+Shift+S which is the Firefox shortcut to take a screenshot in some versions
        keystroke "s" using {control down, shift down}
        delay 0.5
        
        -- Send additional keystrokes based on screenshot type
        if screenshotType is "fullpage" then
          -- Navigate to full page option (might need adjustments)
          keystroke tab
          keystroke tab
          keystroke space
        else if screenshotType is "element" then
          -- Navigate to element selection option (might need adjustments)
          keystroke tab
          keystroke tab
          keystroke tab
          keystroke space
        end if
        
        -- Confirm/save the screenshot
        delay 0.5
        keystroke return
        delay 1 -- Wait for save dialog
      end try
      
      -- Handle the save dialog
      delay 1.5 -- Wait for save dialog to appear
      
      -- Type the file path
      set fullSavePath to saveLocation & fileName
      keystroke "g" using {command down, shift down} -- Open Go to Folder
      delay 0.3
      keystroke saveLocation
      keystroke return
      delay 0.5
      
      -- Type the filename
      keystroke "a" using {command down} -- Select all
      keystroke fileName
      delay 0.3
      
      -- Click Save button
      keystroke return
      delay 1 -- Allow save to complete
    end tell
  end tell
  
  return "Screenshot captured: " & fileName & " saved to " & saveLocation
end run
```

### Alternative Implementation Using Console Commands

This version uses Firefox's Developer Tools Console to take a screenshot through JavaScript commands:

```applescript
on run {input, parameters}
  -- Get parameters
  set screenshotType to "--MCP_INPUT:type" -- "visible", "fullpage", or "element"
  set cssSelector to "--MCP_INPUT:selector" -- For element screenshots
  
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  -- First open the console
  tell application "System Events"
    tell process "Firefox"
      -- Open console with Command+Option+K
      keystroke "k" using {command down, option down}
      delay 0.7 -- Allow console to open
      
      -- Clear any existing console content
      keystroke "l" using {command down}
      delay 0.3
      
      -- Prepare JavaScript based on screenshot type
      set jsCommand to ""
      
      if screenshotType is "fullpage" then
        -- Full page screenshot JavaScript
        set jsCommand to "async function fullPageScreenshot() {
  const allDevicePixelRatios = window.devicePixelRatio;
  window.devicePixelRatio = 1;
  
  const fullHeight = Math.max(
    document.body.scrollHeight, document.documentElement.scrollHeight,
    document.body.offsetHeight, document.documentElement.offsetHeight,
    document.body.clientHeight, document.documentElement.clientHeight
  );
  
  const fullWidth = Math.max(
    document.body.scrollWidth, document.documentElement.scrollWidth,
    document.body.offsetWidth, document.documentElement.offsetWidth,
    document.body.clientWidth, document.documentElement.clientWidth
  );
  
  const canvas = document.createElement('canvas');
  canvas.width = fullWidth;
  canvas.height = fullHeight;
  const ctx = canvas.getContext('2d');
  
  const originalScrollPos = window.scrollY;
  
  for (let y = 0; y < fullHeight; y += window.innerHeight) {
    window.scrollTo(0, y);
    await new Promise(r => setTimeout(r, 200)); // Wait for render
    
    ctx.drawImage(
      await new Promise(resolve => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.src = 'data:image/png;base64,' + btoa(window.document);
      }),
      0, y, window.innerWidth, window.innerHeight,
      0, y, window.innerWidth, window.innerHeight
    );
  }
  
  window.scrollTo(0, originalScrollPos);
  window.devicePixelRatio = allDevicePixelRatios;
  
  return canvas.toDataURL('image/png');
}
fullPageScreenshot().then(dataUrl => {
  console.log('Screenshot data URL:', dataUrl.substring(0, 50) + '...');
  const a = document.createElement('a');
  a.href = dataUrl;
  a.download = 'fullpage_screenshot.png';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
});"
      else if screenshotType is "element" and cssSelector is not "" then
        -- Element screenshot JavaScript
        set jsCommand to "(() => {
  const element = document.querySelector('" & cssSelector & "');
  if (!element) {
    console.error('Element not found with selector: " & cssSelector & "');
    return;
  }
  
  html2canvas(element).then(canvas => {
    const dataUrl = canvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.href = dataUrl;
    a.download = 'element_screenshot.png';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  });
})();"
      else
        -- Visible area screenshot (default)
        set jsCommand to "(() => {
  const canvas = document.createElement('canvas');
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  const ctx = canvas.getContext('2d');
  
  ctx.drawWindow(window, window.scrollX, window.scrollY, 
                 window.innerWidth, window.innerHeight, 'rgb(255,255,255)');
  
  const dataUrl = canvas.toDataURL('image/png');
  const a = document.createElement('a');
  a.href = dataUrl;
  a.download = 'visible_screenshot.png';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
})();"
      end if
      
      -- Execute the JavaScript in console
      keystroke jsCommand
      keystroke return
      delay 3 -- Allow screenshot to be processed
    end tell
  end tell
  
  return "Screenshot captured and saved"
end run
```

### Simplified Version using Firefox's Built-in Screenshot Tool

This version uses Firefox's built-in screenshot tool directly with fewer options but simpler execution:

```applescript
on run
  tell application "Firefox"
    activate
    delay 0.5 -- Allow Firefox to activate
  end tell
  
  tell application "System Events"
    tell process "Firefox"
      -- Use Shift+Command+S to open screenshot tool (Firefox 88+)
      keystroke "s" using {shift down, command down}
      delay 1 -- Allow screenshot tool to appear
      
      -- Press Return to take screenshot with default settings
      keystroke return
      delay 1.5 -- Allow time for the save dialog
      
      -- Press Return again to save with default filename location
      keystroke return
      delay 1 -- Allow save to complete
    end tell
  end tell
  
  return "Screenshot captured and saved to Downloads folder"
end run
```

Note: The JavaScript approach for full-page screenshots may not work perfectly in all cases, as it depends on the page structure and browser implementation. The built-in Firefox screenshot tool (accessible via keyboard shortcuts or the Developer Tools) is usually more reliable.
END_TIP
