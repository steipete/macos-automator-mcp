---
title: "Contacts: Create New Contact"
category: "07_productivity_apps"
id: contacts_create_new_contact
description: "Creates a new contact in the Contacts app with specified information."
keywords: ["Contacts", "add contact", "new person", "create contact", "address book"]
language: applescript
argumentsPrompt: "Enter name, email, and phone number for the new contact"
notes: "Creates a new contact with basic information. You can customize the script to include additional fields."
---

```applescript
on run {fullName, emailAddress, phoneNumber}
  tell application "Contacts"
    try
      -- Handle placeholder substitution
      if fullName is "" or fullName is missing value then
        set fullName to "--MCP_INPUT:fullName"
      end if
      
      if emailAddress is "" or emailAddress is missing value then
        set emailAddress to "--MCP_INPUT:emailAddress"
      end if
      
      if phoneNumber is "" or phoneNumber is missing value then
        set phoneNumber to "--MCP_INPUT:phoneNumber"
      end if
      
      -- Create a new person
      set newPerson to make new person with properties {first name:fullName, name:fullName}
      
      -- Add email if provided
      if emailAddress is not "" and emailAddress is not "--MCP_INPUT:emailAddress" then
        make new email at end of emails of newPerson with properties {label:"work", value:emailAddress}
      end if
      
      -- Add phone if provided
      if phoneNumber is not "" and phoneNumber is not "--MCP_INPUT:phoneNumber" then
        make new phone at end of phones of newPerson with properties {label:"mobile", value:phoneNumber}
      end if
      
      -- Save the contact
      save
      
      return "Successfully created new contact: " & fullName
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create contact - " & errMsg
    end try
  end tell
end run
```
END_TIP