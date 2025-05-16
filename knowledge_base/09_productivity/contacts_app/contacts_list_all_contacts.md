---
title: 'Contacts: List All Contacts'
category: 09_productivity
id: contacts_list_all_contacts
description: Retrieves and lists all contacts from the Contacts app.
keywords:
  - Contacts
  - address book
  - list contacts
  - retrieve contacts
language: applescript
notes: >-
  Returns contact names, emails, and phone numbers. May take longer with large
  contact databases.
---

```applescript
tell application "Contacts"
  try
    set allPeople to every person
    
    if (count of allPeople) is 0 then
      return "No contacts found in your address book."
    end if
    
    set contactList to {}
    
    repeat with thisPerson in allPeople
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
    set outputString to "All Contacts (" & (count of allPeople) & "):\\n" & (contactList as string)
    set AppleScript's text item delimiters to ""
    
    return outputString
    
  on error errMsg number errNum
    return "Error (" & errNum & "): Failed to list contacts - " & errMsg
  end try
end tell
```
END_TIP
