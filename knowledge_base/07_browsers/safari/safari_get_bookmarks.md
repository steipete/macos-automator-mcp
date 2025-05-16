---
title: 'Safari: Get Bookmarks'
category: 07_browsers
id: safari_get_bookmarks
description: Retrieves bookmarks from Safari and returns them in a structured format.
keywords:
  - Safari
  - bookmarks
  - favorites
  - reading list
  - browser
  - web
language: applescript
isComplex: true
argumentsPrompt: >-
  Optional bookmark folder name as 'folderName' in inputData. If not provided,
  retrieves all bookmarks.
notes: >
  - Safari must be installed (but doesn't need to be running).

  - This script uses SQLite to access Safari's bookmarks database.

  - The script returns bookmark data in JSON format.

  - Bookmarks are organized by folder, maintaining Safari's folder structure.

  - If a folder name is provided, only bookmarks from that folder will be
  returned.

  - The Reading List is treated as a special bookmark folder.

  - Accessing bookmark data may require permissions based on your macOS privacy
  settings.
---

This script retrieves bookmarks from Safari and returns them in a structured JSON format.

```applescript
--MCP_INPUT:folderName

on getSafariBookmarks(folderName)
  set bookmarksDbPath to (POSIX path of (path to home folder)) & "Library/Safari/Bookmarks.plist"
  
  -- Check if the database exists
  set dbExists to do shell script "[ -f " & quoted form of bookmarksDbPath & " ] && echo 'yes' || echo 'no'"
  
  if dbExists is "no" then
    return "error: Safari bookmarks database not found. Make sure Safari has been run at least once."
  end if
  
  -- Use plutil to convert plist to JSON and then parse it
  set jsonData to do shell script "plutil -convert json -o - " & quoted form of bookmarksDbPath
  
  -- Use shell script with Python to extract bookmarks from JSON
  set pythonScript to "
import sys
import json
import os

# Parse JSON
data = json.loads(sys.stdin.read())

# Function to process bookmark items recursively
def process_bookmark_items(items, folder_filter=None, current_folder=''):
    result = []
    
    for item in items:
        if item.get('WebBookmarkType') == 'WebBookmarkTypeList':
            # This is a folder
            folder_name = item.get('Title', 'Untitled Folder')
            folder_path = current_folder + '/' + folder_name if current_folder else folder_name
            
            # Process children of this folder
            children = item.get('Children', [])
            child_results = process_bookmark_items(children, folder_filter, folder_path)
            
            # Add folder entry with its children
            if child_results and (folder_filter is None or folder_filter.lower() in folder_path.lower()):
                result.append({
                    'type': 'folder',
                    'title': folder_name,
                    'path': folder_path,
                    'items': child_results
                })
        elif item.get('WebBookmarkType') == 'WebBookmarkTypeLeaf':
            # This is a bookmark
            url = item.get('URLString', '')
            title = item.get('URIDictionary', {}).get('title', 'Untitled')
            
            if url and (folder_filter is None or folder_filter.lower() in current_folder.lower()):
                result.append({
                    'type': 'bookmark',
                    'title': title,
                    'url': url,
                    'path': current_folder
                })
    
    return result

# Main processing
try:
    # Handle Reading List specially
    reading_list_items = []
    for child in data.get('Children', []):
        if child.get('Title') == 'com.apple.ReadingList':
            reading_list = child.get('Children', [])
            for item in reading_list:
                url = item.get('URLString', '')
                title = item.get('URIDictionary', {}).get('title', 'Untitled')
                if url:
                    reading_list_items.append({
                        'type': 'bookmark',
                        'title': title,
                        'url': url,
                        'path': 'Reading List'
                    })
    
    # Process bookmark bar and other bookmarks
    bookmark_items = []
    for child in data.get('Children', []):
        if child.get('Title') in ['BookmarksBar', 'BookmarksMenu']:
            folder_name = 'Favorites Bar' if child.get('Title') == 'BookmarksBar' else 'Bookmarks Menu'
            items = process_bookmark_items(child.get('Children', []), '" & folderName & "', folder_name)
            if items:
                bookmark_items.append({
                    'type': 'folder',
                    'title': folder_name,
                    'path': folder_name,
                    'items': items
                })
    
    # Combine everything
    result = {
        'bookmarks': bookmark_items
    }
    
    # Add reading list if it exists and either no folder filter or it matches Reading List
    if reading_list_items and (not '" & folderName & "' or 'reading list'.lower() in '" & folderName & "'.lower()):
        result['reading_list'] = {
            'type': 'folder',
            'title': 'Reading List',
            'path': 'Reading List',
            'items': reading_list_items
        }
    
    # Convert to JSON and print
    print(json.dumps(result, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e)}))
"
  
  -- Execute Python script
  set result to do shell script "python3 -c " & quoted form of pythonScript & " <<< " & quoted form of jsonData
  
  -- Handle potential errors from the Python script
  if result contains "\"error\":" then
    set errorDict to my parseJSON(result)
    return "error: Failed to extract bookmarks - " & (errorDict's error)
  end if
  
  return result
end getSafariBookmarks

-- Simple helper function to check if a string is in JSON format
on parseJSON(jsonString)
  -- This is a very simple JSON parser for error handling only
  set errorText to text ((offset of "\"error\":\"" in jsonString) + 9) thru -3 of jsonString
  return {error:errorText}
end parseJSON

return my getSafariBookmarks("--MCP_INPUT:folderName")
```
