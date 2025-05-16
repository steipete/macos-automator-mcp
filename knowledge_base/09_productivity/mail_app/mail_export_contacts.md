---
title: "Mail: Export Email Contacts"
category: "07_productivity_apps"
id: mail_export_contacts
description: "Extracts email addresses from selected messages and exports them to a file"
keywords: ["Mail", "email", "contacts", "extract", "export", "addresses"]
language: applescript
isComplex: true
argumentsPrompt: "Provide export file path as 'exportPath' in inputData (optional, defaults to Desktop)"
notes: |
  - Extracts email addresses from currently selected messages in Mail.app
  - Organizes addresses by domain for better analysis
  - Exports results to a text file with counts
  - Requires Automation permission for Mail.app
  - Requires Mail.app to be open with message(s) selected
---

```applescript
--MCP_INPUT:exportPath

on getDefaultExportPath(pathInput)
  if pathInput is missing value or pathInput is "" then
    -- Default to Desktop folder
    return POSIX path of (path to desktop folder) & "mail_contacts.txt"
  else
    -- Ensure path has proper extension
    if pathInput does not end with ".txt" then
      return pathInput & ".txt"
    else
      return pathInput
    end if
  end if
end getDefaultExportPath

on extractEmailAddress(fullAddress)
  try
    -- Extract email from formats like "Name <email@example.com>" or just "email@example.com"
    set AppleScript's text item delimiters to "<"
    set emailParts to text items of fullAddress
    
    if (count of emailParts) > 1 then
      -- Format has angle brackets
      set emailWithBracket to item 2 of emailParts
      set AppleScript's text item delimiters to ">"
      set emailAddress to item 1 of text items of emailWithBracket
    else
      -- Simple email format without brackets
      set emailAddress to fullAddress
    end if
    
    -- Clean up the address (remove any remaining whitespace)
    set AppleScript's text item delimiters to ""
    set emailAddress to emailAddress as string
    set emailAddress to do shell script "echo " & quoted form of emailAddress & " | tr -d '[:space:]'"
    
    return emailAddress
  on error
    return ""
  end try
end extractEmailAddress

on extractDomain(emailAddress)
  try
    set AppleScript's text item delimiters to "@"
    set emailParts to text items of emailAddress
    
    if (count of emailParts) > 1 then
      return item 2 of emailParts
    else
      return "unknown"
    end if
  on error
    return "unknown"
  end try
end extractDomain

on exportContacts(exportFilePath)
  set outputPath to my getDefaultExportPath(exportFilePath)
  
  tell application "Mail"
    try
      -- Get selected messages
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No messages selected. Please select messages in Mail.app before running this script."
      end if
      
      -- Create containers for the addresses
      set allAddresses to {}
      set fromAddresses to {}
      set toAddresses to {}
      set ccAddresses to {}
      set domainCounts to {}
      
      -- Process selected messages
      repeat with thisMessage in selectedMessages
        -- Extract From address
        set fromAddy to my extractEmailAddress(sender of thisMessage)
        if fromAddy is not "" and fromAddy is not in fromAddresses then
          copy fromAddy to end of fromAddresses
          copy fromAddy to end of allAddresses
        end if
        
        -- Extract To addresses (may be multiple)
        set toList to to recipient of thisMessage
        repeat with recipient in toList
          set toAddy to my extractEmailAddress(address of recipient)
          if toAddy is not "" and toAddy is not in toAddresses then
            copy toAddy to end of toAddresses
            copy toAddy to end of allAddresses
          end if
        end repeat
        
        -- Extract CC addresses if present
        set ccList to cc recipient of thisMessage
        repeat with recipient in ccList
          set ccAddy to my extractEmailAddress(address of recipient)
          if ccAddy is not "" and ccAddy is not in ccAddresses then
            copy ccAddy to end of ccAddresses
            copy ccAddy to end of allAddresses
          end if
        end repeat
      end repeat
      
      -- Count unique addresses
      set uniqueAddresses to {}
      repeat with address in allAddresses
        if address is not in uniqueAddresses then
          copy address to end of uniqueAddresses
          
          -- Count addresses by domain
          set domain to my extractDomain(address)
          set domainFound to false
          
          repeat with i from 1 to count of domainCounts
            set thisDomainInfo to item i of domainCounts
            if domain is equal to domain of thisDomainInfo then
              set count of thisDomainInfo to (count of thisDomainInfo) + 1
              set item i of domainCounts to thisDomainInfo
              set domainFound to true
              exit repeat
            end if
          end repeat
          
          if not domainFound then
            copy {domain:domain, count:1} to end of domainCounts
          end if
        end if
      end repeat
      
      -- Sort domains by count (descending)
      set sortedDomains to {}
      repeat while (count of domainCounts) > 0
        set maxCount to 0
        set maxIndex to 0
        
        repeat with i from 1 to count of domainCounts
          set thisDomainInfo to item i of domainCounts
          if (count of thisDomainInfo) > maxCount then
            set maxCount to count of thisDomainInfo
            set maxIndex to i
          end if
        end repeat
        
        if maxIndex > 0 then
          copy item maxIndex of domainCounts to end of sortedDomains
          set domainCounts to items 1 thru (maxIndex - 1) of domainCounts & items (maxIndex + 1) thru (count of domainCounts) of domainCounts
        end if
      end repeat
      
      -- Create the output content
      set outputContent to "Mail Contacts Export" & return & "====================" & return & return
      set outputContent to outputContent & "Total Addresses Found: " & (count of uniqueAddresses) & return
      set outputContent to outputContent & "From Addresses: " & (count of fromAddresses) & return
      set outputContent to outputContent & "To Addresses: " & (count of toAddresses) & return
      set outputContent to outputContent & "CC Addresses: " & (count of ccAddresses) & return & return
      
      -- Add domain statistics
      set outputContent to outputContent & "Email Domains (by frequency):" & return
      set outputContent to outputContent & "---------------------------" & return
      
      repeat with domainInfo in sortedDomains
        set outputContent to outputContent & domain of domainInfo & ": " & count of domainInfo & return
      end repeat
      
      set outputContent to outputContent & return & "All Email Addresses:" & return
      set outputContent to outputContent & "------------------" & return
      
      -- Sort addresses alphabetically
      set uniqueAddresses to my sortAddresses(uniqueAddresses)
      repeat with address in uniqueAddresses
        set outputContent to outputContent & address & return
      end repeat
      
      -- Write to file
      try
        set fileRef to open for access file outputPath with write permission
        set eof of fileRef to 0
        write outputContent to fileRef
        close access fileRef
        
        return "Exported " & (count of uniqueAddresses) & " unique email addresses to " & outputPath
      on error errMsg
        try
          close access file outputPath
        end try
        return "Error writing to file: " & errMsg
      end try
      
    on error errMsg
      return "Error exporting contacts: " & errMsg
    end try
  end tell
end exportContacts

on sortAddresses(addressList)
  -- Simple bubble sort implementation for addresses
  set listLength to count of addressList
  repeat with i from 1 to listLength - 1
    repeat with j from 1 to listLength - i
      if item j of addressList > item (j + 1) of addressList then
        set temp to item j of addressList
        set item j of addressList to item (j + 1) of addressList
        set item (j + 1) of addressList to temp
      end if
    end repeat
  end repeat
  return addressList
end sortAddresses

return my exportContacts("--MCP_INPUT:exportPath")
```

This script:
1. Extracts email addresses from currently selected messages in Mail.app
2. Handles addresses in various formats, including "Name <email@example.com>"
3. Groups addresses by sender, recipient, and CC categories
4. Analyzes email domains and sorts them by frequency
5. Exports all addresses to a text file with statistics
6. Formats output for easy reading and analysis
7. Useful for building contact lists or analyzing communication patterns