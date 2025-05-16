---
title: 'Contacts: Export Contact as vCard'
category: 09_productivity/contacts_app
id: contacts_export_vcard
description: Exports a contact as a vCard file (.vcf) to a specified location.
keywords:
  - Contacts
  - export contact
  - vCard
  - vcf
  - save contact
language: applescript
argumentsPrompt: Enter the contact name to export and the destination file path
notes: >-
  Searches for a contact by name and exports it as a vCard file. The destination
  path should be a full POSIX path ending with .vcf
---

```applescript
on run {contactName, destinationPath}
  tell application "Contacts"
    try
      -- Handle placeholder substitution
      if contactName is "" or contactName is missing value then
        set contactName to "--MCP_INPUT:contactName"
      end if
      
      if destinationPath is "" or destinationPath is missing value then
        set destinationPath to "--MCP_INPUT:destinationPath"
      end if
      
      -- Verify destination path format
      if destinationPath does not start with "/" then
        return "Error: Destination path must be a valid absolute POSIX path starting with /"
      end if
      
      if destinationPath does not end with ".vcf" then
        set destinationPath to destinationPath & ".vcf"
      end if
      
      -- Find the contact
      set matchingPeople to (every person whose name contains contactName)
      
      if (count of matchingPeople) is 0 then
        return "No contacts found matching: " & contactName
      end if
      
      -- Select the first matching contact
      set selectedPerson to item 1 of matchingPeople
      set selectedName to name of selectedPerson
      
      -- Export the contact using UI scripting
      activate
      
      -- Select the contact
      set selectedID to id of selectedPerson
      select selectedPerson
      
      tell application "System Events"
        tell process "Contacts"
          -- Open File menu
          click menu item "Export..." of menu "File" of menu bar 1
          delay 0.5
          
          -- Wait for the save dialog to appear
          repeat until exists sheet 1 of window 1
            delay 0.1
          end repeat
          
          tell sheet 1 of window 1
            -- Set the export format to vCard
            if exists pop up button 1 then
              click pop up button 1
              click menu item "vCard Format" of menu 1 of pop up button 1
            end if
            
            -- Set the destination path
            keystroke "g" using {command down, shift down} -- Go to folder dialog
            delay 0.5
            
            -- Enter the folder path (parent directory of destination)
            set folderPath to do shell script "dirname " & quoted form of destinationPath
            keystroke folderPath
            keystroke return
            delay 0.5
            
            -- Enter the filename
            set fileName to do shell script "basename " & quoted form of destinationPath
            set value of text field 1 of sheet 1 to fileName
            
            -- Click Save/Export button
            click button "Save" of sheet 1
          end tell
        end tell
      end tell
      
      return "Successfully exported contact \"" & selectedName & "\" to " & destinationPath
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to export contact - " & errMsg
    end try
  end tell
end run
```
END_TIP
