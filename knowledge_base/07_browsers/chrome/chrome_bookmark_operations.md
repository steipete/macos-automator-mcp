---
title: "Chrome: Bookmark Operations"
category: "05_web_browsers"
id: chrome_bookmark_operations
description: "Performs operations with Chrome bookmarks including adding the current page to bookmarks or a specific folder."
keywords: ["Chrome", "bookmarks", "add bookmark", "bookmark folder", "browser"]
language: applescript
isComplex: true
argumentsPrompt: "Optional folder path as 'folderPath' in inputData. For example: { \"folderPath\": \"Google/Work\" } or {} to save to the Bookmarks Bar."
notes: |
  - Google Chrome must be running with at least one window and tab open.
  - When providing a folder path, use forward slash '/' as the separator.
  - The script can add the current tab to the Bookmarks Bar (default) or a specific folder.
  - If the specified folder doesn't exist, the bookmark will be added to the Bookmarks Bar.
  - For custom folder support, the script uses JavaScript to locate the folders and add the bookmark.
---

This script adds the current tab to Chrome bookmarks, optionally in a specified folder.

```applescript
--MCP_INPUT:folderPath

on bookmarkCurrentPage(folderPath)
  tell application "Google Chrome"
    if not running then
      return "error: Google Chrome is not running."
    end if
    
    if (count of windows) is 0 then
      return "error: No Chrome windows open."
    end if
    
    if (count of tabs of front window) is 0 then
      return "error: No tabs in front Chrome window."
    end if
    
    set currentTab to active tab of front window
    set pageURL to URL of currentTab
    set pageTitle to title of currentTab
    
    if folderPath is missing value or folderPath is "" then
      -- Add to Bookmarks Bar (default location)
      try
        tell application "System Events"
          tell process "Google Chrome"
            -- Make Chrome active to ensure keyboard shortcuts work
            set frontmost to true
            delay 0.5
            -- Use keyboard shortcut Command+D to add bookmark
            keystroke "d" using command down
            delay 0.5
            -- Press Return to confirm adding the bookmark with default settings
            keystroke return
            delay 0.5
          end tell
        end tell
        return "Successfully added \"" & pageTitle & "\" to Bookmarks Bar."
      on error errMsg
        return "error: Failed to add bookmark - " & errMsg
      end try
    else
      -- For adding to a specific folder, use JavaScript
      set jsCode to "
        function addBookmarkToFolder(url, title, folderPath) {
          // Split the path into folder names
          const folderNames = folderPath.split('/');
          
          // Get all bookmark folders
          function findFolder(bookmarkNodes, path) {
            for (let node of bookmarkNodes) {
              if (node.children) {
                if (node.title === path[0]) {
                  if (path.length === 1) {
                    return node; // Found the target folder
                  } else {
                    return findFolder(node.children, path.slice(1));
                  }
                }
                
                // Try to find the folder in this node's children
                const result = findFolder(node.children, path);
                if (result) return result;
              }
            }
            return null; // Folder not found
          }
          
          // Get bookmarks and add the new bookmark
          chrome.bookmarks.getTree(function(tree) {
            const targetFolder = findFolder(tree, folderNames);
            
            if (targetFolder) {
              chrome.bookmarks.create({
                'parentId': targetFolder.id,
                'title': title,
                'url': url
              }, function() {
                document.title = 'BOOKMARK_ADDED:' + targetFolder.title;
              });
            } else {
              // Folder not found, use default (Bookmarks Bar)
              chrome.bookmarks.create({
                'title': title,
                'url': url
              }, function() {
                document.title = 'BOOKMARK_ADDED:Bookmarks Bar';
              });
            }
          });
          
          return 'Processing bookmark...';
        }
        
        addBookmarkToFolder('" & pageURL & "', '" & my escapeJSString(pageTitle) & "', '" & my escapeJSString(folderPath) & "');
      "
      
      try
        -- Execute the JavaScript and check for results
        execute active tab of front window javascript jsCode
        
        -- Wait for the operation to complete (check for title change)
        set maxWait to 5 -- Maximum wait time in seconds
        set startTime to current date
        repeat
          delay 0.5
          set currentTitle to title of active tab of front window
          if currentTitle starts with "BOOKMARK_ADDED:" then
            set folderAdded to text 16 thru -1 of currentTitle
            
            -- Restore the original tab title with JavaScript
            execute active tab of front window javascript "document.title = '" & my escapeJSString(pageTitle) & "';"
            
            return "Successfully added \"" & pageTitle & "\" to \"" & folderAdded & "\" folder."
          end if
          
          -- Check timeout
          if ((current date) - startTime) > maxWait then
            exit repeat
          end if
        end repeat
        
        -- If we got here, operation may have succeeded but we couldn't confirm
        return "Bookmark operation completed, but couldn't confirm the target folder."
      on error errMsg
        return "error: Failed to add bookmark to folder - " & errMsg
      end try
    end if
  end tell
end bookmarkCurrentPage

-- Helper function to escape JavaScript strings
on escapeJSString(theString)
  set resultString to ""
  repeat with i from 1 to length of theString
    set currentChar to character i of theString
    if currentChar is "'" or currentChar is "\"" or currentChar is "\\" then
      set resultString to resultString & "\\" & currentChar
    else
      set resultString to resultString & currentChar
    end if
  end repeat
  return resultString
end escapeJSString

return my bookmarkCurrentPage("--MCP_INPUT:folderPath")
```
END_TIP