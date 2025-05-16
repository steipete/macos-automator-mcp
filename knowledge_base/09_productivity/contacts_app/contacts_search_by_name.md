---
title: 'Contacts: Search by Name'
category: 09_productivity
id: contacts_search_by_name
description: Searches for contacts in the Contacts app by name.
keywords:
  - Contacts
  - search contacts
  - find contact
  - name search
language: applescript
argumentsPrompt: Enter the name to search for
notes: >-
  Performs a partial match search on contact names. Returns matching contacts
  with their details.
---

```applescript
on run {searchName}
  tell application "Contacts"
    try
      if searchName is "" or searchName is missing value then
        set searchName to "--MCP_INPUT:searchName"
      end if
      
      set matchingPeople to (every person whose name contains searchName)
      
      if (count of matchingPeople) is 0 then
        return "No contacts found matching: " & searchName
      end if
      
      set contactList to {}
      
      repeat with thisPerson in matchingPeople
        set personName to name of thisPerson
        
        -- Get email addresses if available
        set emailAddresses to {}
        repeat with thisEmail in (every email of thisPerson)
          set emailValue to value of thisEmail
          set emailLabel to label of thisEmail
          set end of emailAddresses to emailLabel & ": " & emailValue
        end repeat
        
        -- Get phone numbers if available
        set phoneNumbers to {}
        repeat with thisPhone in (every phone of thisPerson)
          set phoneValue to value of thisPhone
          set phoneLabel to label of thisPhone
          set end of phoneNumbers to phoneLabel & ": " & phoneValue
        end repeat
        
        -- Format the contact info
        set contactInfo to "Contact: " & personName & "\\n"
        
        if (count of emailAddresses) > 0 then
          set AppleScript's text item delimiters to ", "
          set contactInfo to contactInfo & "  Emails: " & (emailAddresses as string) & "\\n"
          set AppleScript's text item delimiters to ""
        end if
        
        if (count of phoneNumbers) > 0 then
          set AppleScript's text item delimiters to ", "
          set contactInfo to contactInfo & "  Phones: " & (phoneNumbers as string) & "\\n"
          set AppleScript's text item delimiters to ""
        end if
        
        set end of contactList to contactInfo
      end repeat
      
      set AppleScript's text item delimiters to "\\n"
      set outputString to "Matching Contacts (" & (count of matchingPeople) & "):\\n" & (contactList as string)
      set AppleScript's text item delimiters to ""
      
      return outputString
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to search contacts - " & errMsg
    end try
  end tell
end run
```
END_TIP
