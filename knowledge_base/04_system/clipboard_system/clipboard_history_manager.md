---
title: Clipboard History Manager
category: 04_system
id: clipboard_history_manager
description: >-
  Manages a history of clipboard contents, allowing storage and retrieval of
  multiple clipboard items
keywords:
  - clipboard
  - history
  - copy
  - paste
  - clipboard manager
  - System Events
  - temporary storage
language: applescript
notes: >-
  Preserves clipboard history between script runs by saving to a file. Supports
  text, images, and file paths with configurable history size.
---

```applescript
-- Clipboard History Manager
-- Stores clipboard history in a file for persistence between script runs

property clipboardHistoryFile : (path to home folder as text) & "Library:Application Support:ClipboardHistory.plist"
property maxHistoryItems : 20 -- Maximum number of clipboard items to store
property clipboardHistory : {}
property lastClipboardContent : missing value

-- Initialize the clipboard history manager
on initialize()
  -- Create directory if needed
  set clipboardFolder to (path to home folder as text) & "Library:Application Support:"
  tell application "Finder"
    if not (exists folder clipboardFolder) then
      make new folder at (path to library folder from user domain) with properties {name:"Application Support"}
    end if
  end tell
  
  -- Load existing history if available
  loadHistory()
  
  -- Set up initial last clipboard content
  set lastClipboardContent to getCurrentClipboardContent()
  
  -- Return initialization status
  return "Clipboard History Manager initialized with " & (count of clipboardHistory) & " items"
end initialize

-- Get the current clipboard content
on getCurrentClipboardContent()
  set clipContent to missing value
  
  tell application "System Events"
    try
      -- Attempt to get clipboard as text first
      set clipContent to the clipboard as text
      return {type:"text", data:clipContent}
    on error
      try
        -- Try as picture
        set clipContent to the clipboard as picture
        return {type:"image", data:clipContent}
      on error
        try
          -- Try as alias list (files)
          set clipContent to the clipboard as «class furl»
          return {type:"files", data:clipContent}
        on error
          -- Unable to determine content type
          return {type:"unknown", data:missing value}
        end try
      end try
    end try
  end tell
end getCurrentClipboardContent

-- Check if clipboard content has changed
on hasClipboardChanged()
  set currentContent to getCurrentClipboardContent()
  
  -- If last content was missing, consider it changed
  if lastClipboardContent is missing value then
    set lastClipboardContent to currentContent
    return true
  end if
  
  -- If types are different, it changed
  if lastClipboardContent's type is not currentContent's type then
    set lastClipboardContent to currentContent
    return true
  end if
  
  -- If types are the same, compare data
  if lastClipboardContent's type is "text" then
    if lastClipboardContent's data is not currentContent's data then
      set lastClipboardContent to currentContent
      return true
    end if
  else if lastClipboardContent's type is "files" then
    -- For files, compare the number of items and paths
    if (count of (lastClipboardContent's data)) is not (count of (currentContent's data)) then
      set lastClipboardContent to currentContent
      return true
    end if
    
    -- Check each file path
    repeat with i from 1 to count of (lastClipboardContent's data)
      if item i of (lastClipboardContent's data) is not item i of (currentContent's data) then
        set lastClipboardContent to currentContent
        return true
      end if
    end repeat
  else
    -- For other types, assume changed (images, etc.)
    set lastClipboardContent to currentContent
    return true
  end if
  
  -- No change detected
  return false
end hasClipboardChanged

-- Add current clipboard content to history
on addToHistory()
  if hasClipboardChanged() then
    -- Get current content
    set currentContent to lastClipboardContent
    
    -- Don't add empty or unknown content
    if currentContent's type is "unknown" or currentContent's data is missing value then
      return "Skipped adding unknown content to history"
    end if
    
    -- Add timestamp
    set currentContent's timestamp to (current date) as string
    
    -- Add to history (at the beginning)
    set clipboardHistory to {currentContent} & clipboardHistory
    
    -- Trim history if needed
    if (count of clipboardHistory) > maxHistoryItems then
      set clipboardHistory to items 1 thru maxHistoryItems of clipboardHistory
    end if
    
    -- Save updated history
    saveHistory()
    
    return "Added " & currentContent's type & " to clipboard history"
  else
    return "No change in clipboard detected"
  end if
end addToHistory

-- Save history to file
on saveHistory()
  try
    set historyPath to POSIX path of clipboardHistoryFile
    
    -- Create a simplified history to save
    -- (some types like images may need special handling)
    set saveableHistory to {}
    
    repeat with historyItem in clipboardHistory
      set itemType to historyItem's type
      set itemToSave to {type:itemType, timestamp:historyItem's timestamp}
      
      if itemType is "text" then
        set itemToSave's data to historyItem's data
      else if itemType is "files" then
        -- Convert aliases to paths
        set filePaths to {}
        repeat with filePath in historyItem's data
          set end of filePaths to POSIX path of filePath
        end repeat
        set itemToSave's data to filePaths
      else if itemType is "image" then
        -- For images, just store a placeholder
        -- Real images would need special handling to serialize
        set itemToSave's data to "[IMAGE DATA]"
      end if
      
      set end of saveableHistory to itemToSave
    end repeat
    
    -- Convert to property list and save
    set plistData to do shell script "plutil -convert xml1 -o - <<< " & quoted form of (saveableHistory as string)
    do shell script "echo " & quoted form of plistData & " > " & quoted form of historyPath
    
    return "Clipboard history saved with " & (count of saveableHistory) & " items"
  on error errMsg
    return "Error saving clipboard history: " & errMsg
  end try
end saveHistory

-- Load history from file
on loadHistory()
  try
    set historyPath to POSIX path of clipboardHistoryFile
    
    -- Check if file exists
    set fileExists to do shell script "test -f " & quoted form of historyPath & " && echo 'yes' || echo 'no'"
    
    if fileExists is "yes" then
      -- Read and parse the plist data
      set plistData to do shell script "cat " & quoted form of historyPath
      
      -- Process the data - in a real implementation you would properly parse the plist
      -- This is a simplified version that assumes a certain format
      set AppleScript's text item delimiters to ", "
      set historyItems to text items of plistData
      
      -- Reset clipboardHistory
      set clipboardHistory to {}
      
      -- Parse each history item (simplified)
      repeat with historyItem in historyItems
        set itemProperties to parseHistoryItem(historyItem)
        set end of clipboardHistory to itemProperties
      end repeat
      
      return "Loaded " & (count of clipboardHistory) & " items from clipboard history"
    else
      set clipboardHistory to {}
      return "No clipboard history file found. Created new history."
    end if
  on error errMsg
    set clipboardHistory to {}
    return "Error loading clipboard history: " & errMsg
  end try
end loadHistory

-- Helper function to parse a history item string (simplified)
on parseHistoryItem(itemString)
  -- In a real implementation, you would properly parse the plist data
  -- This is a simplified example that assumes a specific format
  
  -- Extract type
  set typeStart to offset of "type:" in itemString
  set typeEnd to offset of ", " in itemString after typeStart
  set itemType to text (typeStart + 5) thru (typeEnd - 1) of itemString
  
  -- Extract timestamp (simplified)
  set timestampStart to offset of "timestamp:" in itemString
  set timestampEnd to offset of ", " in itemString after timestampStart
  set itemTimestamp to text (timestampStart + 10) thru (timestampEnd - 1) of itemString
  
  -- Extract data (simplified)
  set dataStart to offset of "data:" in itemString
  set itemData to text (dataStart + 5) thru -1 of itemString
  
  -- Remove trailing "}" if present
  if last character of itemData is "}" then
    set itemData to text 1 thru -2 of itemData
  end if
  
  return {type:itemType, timestamp:itemTimestamp, data:itemData}
end parseHistoryItem

-- Restore clipboard content from history at specified index
on restoreFromHistory(index)
  if index > (count of clipboardHistory) then
    return "Invalid history index: " & index
  end if
  
  set historyItem to item index of clipboardHistory
  set itemType to historyItem's type
  set itemData to historyItem's data
  
  tell application "System Events"
    if itemType is "text" then
      -- Restore text
      set the clipboard to itemData
      return "Restored text from history: " & (text 1 thru 50 of itemData) & "..."
      
    else if itemType is "files" then
      -- Restore file paths
      set the clipboard to itemData
      return "Restored " & (count of itemData) & " file paths from history"
      
    else if itemType is "image" then
      -- Restore image (if possible)
      try
        set the clipboard to itemData
        return "Restored image from history"
      on error
        return "Unable to restore image from history"
      end try
      
    else
      return "Unknown content type in history: " & itemType
    end if
  end tell
end restoreFromHistory

-- Clear the clipboard history
on clearHistory()
  set clipboardHistory to {}
  saveHistory()
  return "Clipboard history cleared"
end clearHistory

-- Show clipboard history in a dialog
on showHistory()
  if clipboardHistory is {} then
    display dialog "Clipboard history is empty" buttons {"OK"} default button "OK"
    return "No clipboard history items"
  end if
  
  -- Create list of items for display
  set historyLabels to {}
  repeat with i from 1 to count of clipboardHistory
    set historyItem to item i of clipboardHistory
    set itemType to historyItem's type
    set itemTime to historyItem's timestamp
    
    -- Create a preview based on content type
    if itemType is "text" then
      set itemData to historyItem's data
      set previewText to if length of itemData > 30 then text 1 thru 30 of itemData & "..." else itemData
      set end of historyLabels to i & ". [" & itemType & "] " & previewText & " (" & itemTime & ")"
      
    else if itemType is "files" then
      set previewText to (count of historyItem's data) & " files"
      set end of historyLabels to i & ". [" & itemType & "] " & previewText & " (" & itemTime & ")"
      
    else if itemType is "image" then
      set end of historyLabels to i & ". [" & itemType & "] Image (" & itemTime & ")"
      
    else
      set end of historyLabels to i & ". [" & itemType & "] Unknown content (" & itemTime & ")"
    end if
  end repeat
  
  -- Display the history
  set selectedItem to choose from list historyLabels with prompt "Select an item to restore:" default items item 1 of historyLabels
  
  if selectedItem is false then
    return "No item selected"
  else
    -- Extract the index from the selected item
    set selectedLine to item 1 of selectedItem
    set itemIndex to extract_number(selectedLine)
    
    -- Restore the selected item
    return restoreFromHistory(itemIndex)
  end if
end showHistory

-- Extract the first number from a string
on extract_number(theText)
  set theNumber to ""
  repeat with i from 1 to count of characters of theText
    set thisChar to character i of theText
    if thisChar is in "0123456789" then
      set theNumber to theNumber & thisChar
    else if theNumber is not "" then
      exit repeat
    end if
  end repeat
  
  if theNumber is "" then
    return 0
  else
    return theNumber as number
  end if
end extract_number

-- Start monitoring clipboard changes
on startMonitoring()
  -- In a real implementation, you'd set up a timer or other mechanism
  -- to regularly check the clipboard
  
  -- Initialize the manager
  initialize()
  
  -- Check for clipboard changes periodically
  repeat
    addToHistory()
    delay 2 -- Check every 2 seconds
  end repeat
end startMonitoring

-- Monitor clipboard for a limited time (useful for running as a script)
on monitorForDuration(minutes)
  set endTime to (current date) + (minutes * minutes)
  
  -- Initialize the manager
  initialize()
  
  -- Set up a dialog to allow user to stop monitoring
  display notification "Started clipboard monitoring for " & minutes & " minutes" with title "Clipboard History Manager"
  
  -- Check for clipboard changes periodically until time expires
  repeat until (current date) > endTime
    addToHistory()
    delay 2 -- Check every 2 seconds
  end repeat
  
  display notification "Clipboard monitoring ended" with title "Clipboard History Manager"
  return "Monitored clipboard for " & minutes & " minutes and captured " & (count of clipboardHistory) & " items"
end monitorForDuration

-- Main menu for clipboard history operations
on showClipboardMenu()
  set menuOptions to {"Show Clipboard History", "Start Monitoring (10 minutes)", "Clear History", "Cancel"}
  
  set selectedOption to choose from list menuOptions with prompt "Clipboard History Manager:" default items {"Show Clipboard History"}
  
  if selectedOption is false then
    return "Operation cancelled"
  else
    set operation to item 1 of selectedOption
    
    if operation is "Show Clipboard History" then
      return showHistory()
      
    else if operation is "Start Monitoring (10 minutes)" then
      return monitorForDuration(10)
      
    else if operation is "Clear History" then
      set confirmClear to display dialog "Are you sure you want to clear the clipboard history?" buttons {"Cancel", "Clear"} default button "Cancel"
      
      if button returned of confirmClear is "Clear" then
        return clearHistory()
      else
        return "Clear operation cancelled"
      end if
      
    else
      return "Operation cancelled"
    end if
  end if
end showClipboardMenu

-- Run the clipboard history manager menu
showClipboardMenu()
```

This script implements a comprehensive clipboard history manager that can:

1. **Monitor Clipboard Changes**:
   - Continuously checks for changes to the clipboard content
   - Detects different content types (text, images, files)
   - Stores clipboard items with timestamps

2. **Persistent Storage**:
   - Saves clipboard history to a plist file for persistence between sessions
   - Automatically loads history when the script is initialized
   - Maintains a configurable maximum number of history items (default: 20)

3. **Content Management**:
   - Allows browsing through clipboard history with previews
   - Restores historical clipboard items when selected
   - Provides options to clear the history

4. **User Interface**:
   - Interactive menu for accessing clipboard history
   - Options to start/stop clipboard monitoring
   - Notifications for monitoring status

The script supports multiple clipboard content types:
- **Text**: Stores and retrieves text content with previews
- **Files**: Preserves file references/paths that were copied
- **Images**: Handles image data on the clipboard (with simplified serialization)

For practical use, this script could be:
1. Added to your login items to automatically monitor clipboard changes
2. Bound to a keyboard shortcut for quick access to clipboard history
3. Modified to run as a background process with a menu bar icon

Note: The history file serialization is simplified for demonstration purposes. A production implementation might use a more robust storage format or database for larger history sizes and better handling of complex data types like images.
