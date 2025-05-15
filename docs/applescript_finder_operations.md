# Finder Operations in AppleScript

Finder is macOS's file management application, and AppleScript can interact with it to perform various file system operations. This document explains some of the most useful operations.

## Count Items on Desktop

```applescript
tell application "Finder"
  set desktopItems to count of items on desktop
  return "Finder has " & desktopItems & " items on the desktop"
end tell
```

## Get Selected Finder Items

```applescript
tell application "Finder"
  if selection is {} then
    return "No items selected in Finder"
  end if
  
  set selectedItems to selection
  set itemPaths to {}
  
  repeat with anItem in selectedItems
    set end of itemPaths to POSIX path of (anItem as alias)
  end repeat
  
  set AppleScript's text item delimiters to linefeed
  set pathsText to itemPaths as text
  set AppleScript's text item delimiters to ""
  
  return "Selected items:" & linefeed & pathsText
end tell
```

## Create New Folder

```applescript
tell application "Finder"
  set newFolderName to "My New Folder"
  
  if not (exists folder newFolderName of desktop) then
    make new folder at desktop with properties {name:newFolderName}
    return "Folder '" & newFolderName & "' created on Desktop"
  else
    return "Folder '" & newFolderName & "' already exists on Desktop"
  end if
end tell
```

## Move Files

```applescript
tell application "Finder"
  set sourceFile to (path to desktop as string) & "source.txt" as alias
  set targetFolder to (path to documents folder) as alias
  
  move sourceFile to targetFolder
  return "Moved file to Documents folder"
end tell
```

## Get File Information

```applescript
tell application "Finder"
  set targetFile to (path to desktop as string) & "example.txt" as alias
  
  set fileSize to size of targetFile
  set fileModDate to modification date of targetFile
  set fileCreator to creator type of targetFile
  set fileType to file type of targetFile
  
  return "File size: " & fileSize & " bytes" & linefeed & ¬
         "Modified: " & fileModDate & linefeed & ¬
         "Creator: " & fileCreator & linefeed & ¬
         "Type: " & fileType
end tell
```

## Notes

- Finder operations require the Automation permission for Finder to be granted to the application running the script
- Many operations can be performed using either Finder or direct file operations (`read file`, `write to file`, etc.)
- Finder operations are generally more user-friendly and handle aliases and packages well
- For better performance with many files, consider using shell commands via `do shell script`
- For simple operations on a few files, Finder commands are usually easier to understand
- Finder operations show visual feedback to the user (like file moves showing animation)
- Consider using `with showing packages` option if you need to work with package contents