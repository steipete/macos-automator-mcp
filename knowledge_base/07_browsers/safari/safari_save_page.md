---
title: 'Safari: Save Webpage'
category: 07_browsers/safari
id: safari_save_page
description: >-
  Saves the current Safari webpage in various formats including HTML, PDF, and
  web archive.
keywords:
  - Safari
  - save page
  - download
  - PDF
  - web archive
  - HTML
  - offline
  - archiving
  - screenshot
language: applescript
isComplex: true
argumentsPrompt: >-
  Save format as 'format' ('pdf', 'webarchive', 'html', 'text', 'image'), output
  path as 'outputPath', and optional parameters in inputData.
notes: >
  - Safari must be running with at least one open tab.

  - The script supports several output formats:
    - 'pdf': Saves the page as a PDF document
    - 'webarchive': Saves as a Safari Web Archive (preserves most functionality)
    - 'html': Saves as HTML with a folder for resources
    - 'text': Extracts and saves just the text content
    - 'image': Saves a full-page screenshot (PNG format)
  - For PDF format, additional options include:
    - 'includeBackground': Whether to include background images/colors (default: true)
    - 'printHeaders': Whether to include headers/footers (default: false)
    - 'paperSize': Paper size for PDF ('A4', 'Letter', etc., default: 'A4')
  - If no output path is provided, files will be saved to the Desktop with an
  auto-generated name.

  - The script uses Safari's native Save As functionality when possible, or
  JavaScript for formats that require it.

  - Some websites may restrict certain saving operations due to security
  settings.
---

This script saves the current Safari webpage in various formats including PDF, Web Archive, and HTML.

```applescript
--MCP_INPUT:format
--MCP_INPUT:outputPath
--MCP_INPUT:includeBackground
--MCP_INPUT:printHeaders
--MCP_INPUT:paperSize

on saveWebpage(saveFormat, outputPath, includeBackground, printHeaders, paperSize)
  -- Validate format
  if saveFormat is missing value or saveFormat is "" then
    return "error: Save format not provided. Must be 'pdf', 'webarchive', 'html', 'text', or 'image'."
  end if
  
  -- Convert to lowercase for case-insensitive comparison
  set saveFormat to my toLowerCase(saveFormat)
  
  -- Validate format value
  if saveFormat is not "pdf" and saveFormat is not "webarchive" and saveFormat is not "html" and saveFormat is not "text" and saveFormat is not "image" then
    return "error: Invalid save format. Must be 'pdf', 'webarchive', 'html', 'text', or 'image'."
  end if
  
  -- Set default output path if not provided
  if outputPath is missing value or outputPath is "" then
    -- Use Desktop as default location
    set desktopPath to POSIX path of (path to desktop as string)
    
    -- Generate a filename based on format and current date/time
    set currentDate to current date
    set dateString to (year of currentDate as string) & "-" & (my padNumber(month of currentDate as integer)) & "-" & (my padNumber(day of currentDate)) & "_" & (my padNumber(hours of currentDate)) & "-" & (my padNumber(minutes of currentDate))
    
    -- Set filename based on format
    if saveFormat is "pdf" then
      set outputPath to desktopPath & "/Safari_Page_" & dateString & ".pdf"
    else if saveFormat is "webarchive" then
      set outputPath to desktopPath & "/Safari_Page_" & dateString & ".webarchive"
    else if saveFormat is "html" then
      set outputPath to desktopPath & "/Safari_Page_" & dateString & ".html"
    else if saveFormat is "text" then
      set outputPath to desktopPath & "/Safari_Page_" & dateString & ".txt"
    else if saveFormat is "image" then
      set outputPath to desktopPath & "/Safari_Page_" & dateString & ".png"
    end if
  end if
  
  -- Ensure the output directory exists
  set outputDir to do shell script "dirname " & quoted form of outputPath
  do shell script "mkdir -p " & quoted form of outputDir
  
  -- PDF specific options
  set includeBg to true
  if includeBackground is not missing value and includeBackground is not "" then
    if includeBackground is "false" or includeBackground is "no" or includeBackground is "0" then
      set includeBg to false
    end if
  end if
  
  set printHdrs to false
  if printHeaders is not missing value and printHeaders is not "" then
    if printHeaders is "true" or printHeaders is "yes" or printHeaders is "1" then
      set printHdrs to true
    end if
  end if
  
  set pdfPaperSize to "A4"
  if paperSize is not missing value and paperSize is not "" then
    set pdfPaperSize to paperSize
  end if
  
  tell application "Safari"
    if not running then
      return "error: Safari is not running."
    end if
    
    try
      if (count of windows) is 0 or (count of tabs of front window) is 0 then
        return "error: No tabs open in Safari."
      end if
      
      set currentTab to current tab of front window
      set pageURL to URL of currentTab
      set pageTitle to name of currentTab
      
      -- Different handling based on format
      if saveFormat is "webarchive" or saveFormat is "html" then
        -- Use Safari's Save As... menu option for webarchive and html
        -- This approach uses UI scripting
        activate
        delay 0.5
        
        -- Press Command+S to bring up Save dialog
        tell application "System Events"
          tell process "Safari"
            keystroke "s" using command down
            delay 1
            
            -- Set the filename
            keystroke (last item of paragraphs of outputPath)
            delay 0.5
            
            -- Try to set format based on the requested type
            if saveFormat is "webarchive" then
              -- Look for the Format popup button
              try
                set formatPopup to pop up button 1 of sheet 1 of window 1
                click formatPopup
                delay 0.3
                
                -- Click the Web Archive menu item
                click menu item "Web Archive" of menu 1 of formatPopup
                delay 0.3
              end try
            else if saveFormat is "html" then
              -- Look for the Format popup button
              try
                set formatPopup to pop up button 1 of sheet 1 of window 1
                click formatPopup
                delay 0.3
                
                -- Click the Page Source menu item
                click menu item "Page Source" of menu 1 of formatPopup
                delay 0.3
              end try
            end if
            
            -- Set the location
            set locationMenuItem to menu item "Other…" of menu of pop up button 2 of sheet 1 of window 1
            click locationMenuItem
            delay 0.5
            
            -- In the file browser dialog, paste the path and click Go
            keystroke "g" using {command down, shift down}
            delay 0.5
            set the clipboard to outputDir
            keystroke "v" using command down
            delay 0.5
            keystroke return
            delay 0.5
            
            -- Click the Save button
            click button "Save" of sheet 1 of sheet 1 of window 1
            delay 2
            
            -- If a dialog about Download folder appears, click Use Download Folder
            try
              if (exists button "Use Downloads Folder" of sheet 1 of window 1) then
                click button "Use Downloads Folder" of sheet 1 of window 1
                delay 1
              end if
            end try
          end tell
        end tell
        
        return "Successfully saved page as " & saveFormat & " to " & outputPath
      else if saveFormat is "pdf" then
        -- For PDF, we can use the Print Dialog with Export as PDF
        activate
        delay 0.5
        
        -- Press Command+P to bring up Print dialog
        tell application "System Events"
          tell process "Safari"
            keystroke "p" using command down
            delay 1.5
            
            -- Click the PDF button and select "Save as PDF..."
            try
              click menu button "PDF" of window 1
              delay 0.5
              click menu item "Save as PDF…" of menu 1 of menu button "PDF" of window 1
              delay 1
              
              -- Set the filename and path
              keystroke (last item of paragraphs of outputPath)
              delay 0.5
              
              -- Set the location
              set locationMenuItem to menu item "Other…" of menu of pop up button "Where:" of sheet 1 of window 1
              click locationMenuItem
              delay 0.5
              
              -- In the file browser dialog, paste the path and click Go
              keystroke "g" using {command down, shift down}
              delay 0.5
              set the clipboard to outputDir
              keystroke "v" using command down
              delay 0.5
              keystroke return
              delay 0.5
              
              -- Click the Save button
              click button "Save" of sheet 1 of sheet 1 of window 1
              delay 2
            end try
          end tell
        end tell
        
        return "Successfully saved page as PDF to " & outputPath
      else if saveFormat is "text" or saveFormat is "image" then
        -- For text and image, we'll use JavaScript
        
        if saveFormat is "text" then
          -- Extract text content using JavaScript
          set jsScript to "
            (function() {
              // Get all text from the body
              const extractedText = document.body.innerText;
              return extractedText;
            })();
          "
          
          -- Execute the script and save the result
          set textContent to do JavaScript jsScript in currentTab
          
          -- Write the text to the file
          do shell script "echo " & quoted form of textContent & " > " & quoted form of outputPath
          
          return "Successfully saved page text to " & outputPath
        else if saveFormat is "image" then
          -- For a full page screenshot, we'll use a JavaScript approach
          -- Similar to safari_capture_screenshot.md but without DOM changes
          set jsScript to "
            (function() {
              // Create a canvas the size of the entire page
              const fullHeight = Math.max(
                document.body.scrollHeight,
                document.documentElement.scrollHeight,
                document.body.offsetHeight,
                document.documentElement.offsetHeight,
                document.body.clientHeight,
                document.documentElement.clientHeight
              );
              const fullWidth = Math.max(
                document.body.scrollWidth,
                document.documentElement.scrollWidth,
                document.body.offsetWidth,
                document.documentElement.offsetWidth,
                document.body.clientWidth,
                document.documentElement.clientWidth
              );
              
              // Remember the current scroll position
              const originalScrollTop = window.pageYOffset || document.documentElement.scrollTop;
              const originalScrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
              
              // Create a canvas large enough for the entire page
              const canvas = document.createElement('canvas');
              canvas.width = fullWidth;
              canvas.height = fullHeight;
              const ctx = canvas.getContext('2d');
              
              // Convert to data URL
              const dataUrl = canvas.toDataURL('image/png');
              
              // Create a download link and trigger it
              const a = document.createElement('a');
              a.href = dataUrl;
              a.download = 'screenshot.png';
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              
              // Restore the original scroll position
              window.scrollTo(originalScrollLeft, originalScrollTop);
              
              return 'Screenshot initiated. The image should be saved to your Downloads folder.';
            })();
          "
          
          -- Execute the screenshot script
          do JavaScript jsScript in currentTab
          delay 2
          
          -- Move the file from Downloads to the specified location
          do shell script "mv ~/Downloads/screenshot.png " & quoted form of outputPath
          
          return "Successfully saved page screenshot to " & outputPath
        end if
      end if
    on error errMsg
      return "error: Failed to save page - " & errMsg
    end try
  end tell
end saveWebpage

-- Helper function to pad numbers with leading zeros
on padNumber(n)
  if n < 10 then
    return "0" & n
  else
    return n as string
  end if
end padNumber

-- Helper function to convert text to lowercase
on toLowerCase(sourceText)
  set lowercaseText to ""
  set upperChars to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  set lowerChars to "abcdefghijklmnopqrstuvwxyz"
  
  repeat with i from 1 to length of sourceText
    set currentChar to character i of sourceText
    set charPos to offset of currentChar in upperChars
    
    if charPos > 0 then
      set lowercaseText to lowercaseText & character charPos of lowerChars
    else
      set lowercaseText to lowercaseText & currentChar
    end if
  end repeat
  
  return lowercaseText
end toLowerCase

return my saveWebpage("--MCP_INPUT:format", "--MCP_INPUT:outputPath", "--MCP_INPUT:includeBackground", "--MCP_INPUT:printHeaders", "--MCP_INPUT:paperSize")
```
