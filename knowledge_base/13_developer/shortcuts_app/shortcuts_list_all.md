---
title: 'Shortcuts: List All Shortcuts'
category: 13_developer
id: shortcuts_list_all
description: >-
  Lists all available shortcuts in the macOS Shortcuts app, with folder
  organization.
keywords:
  - Shortcuts
  - list shortcuts
  - shortcut folders
  - automation
  - workflow list
language: applescript
notes: >-
  Retrieves and displays all shortcuts, showing their folder organization and
  availability. Useful for discovering what shortcuts are available to run.
---

```applescript
tell application "Shortcuts"
  try
    activate
    
    -- Give Shortcuts app time to launch and load
    delay 1
    
    -- Prepare to collect data
    set folderList to {}
    set shortcutList to {}
    
    tell application "System Events"
      tell process "Shortcuts"
        -- First, get folders shown in the sidebar
        if exists outline 1 of scroll area 1 of splitter group 1 of window 1 then
          set sidebarOutline to outline 1 of scroll area 1 of splitter group 1 of window 1
          
          -- Get all rows in the sidebar (folders and special categories)
          set folderRows to rows of sidebarOutline
          
          repeat with i from 1 to count of folderRows
            set currentRow to item i of folderRows
            
            -- Get the folder/category name
            if exists UI element 1 of currentRow then
              set folderName to value of UI element 1 of currentRow
              set end of folderList to folderName
              
              -- Click on the folder to view its shortcuts
              click currentRow
              delay 0.5
              
              -- Get shortcuts in this folder
              if exists table 1 of scroll area 1 of splitter group 1 of window 1 then
                set shortcutsTable to table 1 of scroll area 1 of splitter group 1 of window 1
                
                if exists rows of shortcutsTable then
                  set shortcutRows to rows of shortcutsTable
                  
                  set folderShortcuts to {}
                  
                  repeat with j from 1 to count of shortcutRows
                    set currentShortcutRow to item j of shortcutRows
                    
                    if exists text field 1 of currentShortcutRow then
                      set shortcutName to value of text field 1 of currentShortcutRow
                      set end of folderShortcuts to shortcutName
                    end if
                  end repeat
                  
                  -- Add shortcuts to the list with their folder
                  if folderName is not "" and (count of folderShortcuts) > 0 then
                    set end of shortcutList to {folder:folderName, shortcuts:folderShortcuts}
                  end if
                end if
              end if
            end if
          end repeat
        end if
      end tell
    end tell
    
    -- Generate the report
    if (count of shortcutList) is 0 then
      return "No shortcuts found or unable to access shortcuts list."
    else
      set resultText to "Available Shortcuts:" & return & return
      set totalShortcutCount to 0
      
      repeat with folderInfo in shortcutList
        set folderName to folder of folderInfo
        set folderShortcuts to shortcuts of folderInfo
        set shortcutCount to count of folderShortcuts
        set totalShortcutCount to totalShortcutCount + shortcutCount
        
        set resultText to resultText & "Folder: " & folderName & " (" & shortcutCount & " shortcuts)" & return
        
        repeat with i from 1 to count of folderShortcuts
          set shortcutName to item i of folderShortcuts
          set resultText to resultText & "  - " & shortcutName & return
        end repeat
        
        set resultText to resultText & return
      end repeat
      
      set resultText to resultText & "Total shortcuts: " & totalShortcutCount
      
      return resultText
    end if
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list shortcuts - " & errMsg
  end try
end tell
```
END_TIP
