---
title: Mail Search and Organization
category: 09_productivity
id: mail_search_organization
description: Functions for searching and organizing emails in Apple Mail
keywords:
  - email
  - mail
  - search
  - filter
  - organize
  - move
  - archive
  - mark read
language: applescript
---

# Mail Search and Organization

This script provides functionality for searching and organizing emails in Apple Mail.

## Searching Emails

```applescript
-- Search emails with criteria
on searchEmails(searchCriteria)
  tell application "Mail"
    try
      set searchResults to {}
      
      -- Get the account to search in
      set accountToSearch to missing value
      if searchCriteria's account is not "" then
        set accountToSearch to account searchCriteria's account
      end if
      
      -- Get the mailbox to search in
      set mailboxToSearch to missing value
      if searchCriteria's folder is not "" and accountToSearch is not missing value then
        set mailboxToSearch to mailbox searchCriteria's folder of accountToSearch
      end if
      
      -- Build the search string
      set searchString to ""
      
      if searchCriteria's subject is not "" then
        set searchString to searchString & " subject:" & quoted form of searchCriteria's subject
      end if
      
      if searchCriteria's sender is not "" then
        set searchString to searchString & " from:" & quoted form of searchCriteria's sender
      end if
      
      if searchCriteria's recipient is not "" then
        set searchString to searchString & " to:" & quoted form of searchCriteria's recipient
      end if
      
      if searchCriteria's content is not "" then
        set searchString to searchString & " content:" & quoted form of searchCriteria's content
      end if
      
      -- Perform the search
      if mailboxToSearch is not missing value then
        -- Search in specific mailbox
        set foundMessages to search mailboxToSearch for searchString
      else if accountToSearch is not missing value then
        -- Search in all mailboxes of the account
        set foundMessages to search accountToSearch for searchString
      else
        -- Search in all accounts
        set foundMessages to search for searchString
      end if
      
      -- Filter by date if specified
      if searchCriteria's dateSince is not "" then
        try
          set dateThreshold to date searchCriteria's dateSince
          set filteredMessages to {}
          
          repeat with aMessage in foundMessages
            if date received of aMessage ≥ dateThreshold then
              set end of filteredMessages to aMessage
            end if
          end repeat
          
          set foundMessages to filteredMessages
        end try
      end if
      
      -- Limit results if specified
      if searchCriteria's maxResults is not "" and searchCriteria's maxResults is not 0 then
        set maxCount to searchCriteria's maxResults as integer
        if (count of foundMessages) > maxCount then
          set foundMessages to items 1 thru maxCount of foundMessages
        end if
      end if
      
      -- Extract information from found messages
      repeat with aMessage in foundMessages
        set messageSubject to subject of aMessage
        set messageSender to sender of aMessage
        set messageDate to date received of aMessage
        
        set messageInfo to {subject:messageSubject, sender:messageSender, date:messageDate}
        set end of searchResults to messageInfo
      end repeat
      
      logMessage("Search completed, found " & (count of searchResults) & " messages")
      return searchResults
    on error errMsg
      logMessage("Error during search: " & errMsg)
      return {}
    end try
  end tell
end searchEmails
```

## Moving Messages

```applescript
-- Move messages to a folder
on moveMessages(messageCriteria, destinationFolder, destinationAccount)
  tell application "Mail"
    try
      -- Find messages to move
      set messagesToMove to {}
      
      -- Prepare search criteria
      set searchCriteria to {subject:messageCriteria's subject, sender:messageCriteria's sender, recipient:messageCriteria's recipient, content:messageCriteria's content, account:messageCriteria's account, folder:messageCriteria's folder, dateSince:messageCriteria's dateSince, maxResults:""}
      
      -- Perform search
      set searchResults to my searchEmails(searchCriteria)
      
      -- Get the search results as actual message objects
      if searchResults is not {} then
        set searchString to ""
        
        if messageCriteria's subject is not "" then
          set searchString to searchString & " subject:" & quoted form of messageCriteria's subject
        end if
        
        if messageCriteria's sender is not "" then
          set searchString to searchString & " from:" & quoted form of messageCriteria's sender
        end if
        
        if messageCriteria's recipient is not "" then
          set searchString to searchString & " to:" & quoted form of messageCriteria's recipient
        end if
        
        if messageCriteria's content is not "" then
          set searchString to searchString & " content:" & quoted form of messageCriteria's content
        end if
        
        -- Get account and folder for search
        set accountToSearch to missing value
        set mailboxToSearch to missing value
        
        if messageCriteria's account is not "" then
          set accountToSearch to account messageCriteria's account
          
          if messageCriteria's folder is not "" then
            set mailboxToSearch to mailbox messageCriteria's folder of accountToSearch
          end if
        end if
        
        -- Execute search to get message objects
        if mailboxToSearch is not missing value then
          set messagesToMove to search mailboxToSearch for searchString
        else if accountToSearch is not missing value then
          set messagesToMove to search accountToSearch for searchString
        else
          set messagesToMove to search for searchString
        end if
        
        -- Filter by date if needed
        if messageCriteria's dateSince is not "" then
          try
            set dateThreshold to date messageCriteria's dateSince
            set filteredMessages to {}
            
            repeat with aMessage in messagesToMove
              if date received of aMessage ≥ dateThreshold then
                set end of filteredMessages to aMessage
              end if
            end repeat
            
            set messagesToMove to filteredMessages
          end try
        end if
      end if
      
      -- If we found messages to move
      if (count of messagesToMove) > 0 then
        -- Get destination mailbox
        set targetMailbox to missing value
        
        if destinationAccount is not "" then
          set targetAccount to account destinationAccount
          set targetMailbox to mailbox destinationFolder of targetAccount
        else
          -- Try to find the folder in any account
          set allAccounts to accounts
          repeat with anAccount in allAccounts
            try
              set targetMailbox to mailbox destinationFolder of anAccount
              exit repeat
            end try
          end repeat
        end if
        
        if targetMailbox is missing value then
          return "Error: Destination folder not found"
        end if
        
        -- Move the messages
        repeat with aMessage in messagesToMove
          move aMessage to targetMailbox
        end repeat
        
        logMessage("Moved " & (count of messagesToMove) & " messages to " & destinationFolder)
        return "Moved " & (count of messagesToMove) & " messages to " & destinationFolder
      else
        return "No messages found matching the criteria"
      end if
    on error errMsg
      logMessage("Error moving messages: " & errMsg)
      return "Error moving messages: " & errMsg
    end try
  end tell
end moveMessages
```

## Marking Messages as Read/Unread

```applescript
-- Mark messages as read/unread
on markMessages(messageCriteria, markAsRead)
  tell application "Mail"
    try
      -- Find messages to mark
      set messagesToMark to {}
      
      -- Prepare search criteria
      set searchCriteria to {subject:messageCriteria's subject, sender:messageCriteria's sender, recipient:messageCriteria's recipient, content:messageCriteria's content, account:messageCriteria's account, folder:messageCriteria's folder, dateSince:messageCriteria's dateSince, maxResults:""}
      
      -- Perform search to get actual message objects (similar to moveMessages function)
      set searchString to ""
      
      if messageCriteria's subject is not "" then
        set searchString to searchString & " subject:" & quoted form of messageCriteria's subject
      end if
      
      if messageCriteria's sender is not "" then
        set searchString to searchString & " from:" & quoted form of messageCriteria's sender
      end if
      
      if messageCriteria's recipient is not "" then
        set searchString to searchString & " to:" & quoted form of messageCriteria's recipient
      end if
      
      if messageCriteria's content is not "" then
        set searchString to searchString & " content:" & quoted form of messageCriteria's content
      end if
      
      -- Get account and folder for search
      set accountToSearch to missing value
      set mailboxToSearch to missing value
      
      if messageCriteria's account is not "" then
        set accountToSearch to account messageCriteria's account
        
        if messageCriteria's folder is not "" then
          set mailboxToSearch to mailbox messageCriteria's folder of accountToSearch
        end if
      end if
      
      -- Execute search to get message objects
      if mailboxToSearch is not missing value then
        set messagesToMark to search mailboxToSearch for searchString
      else if accountToSearch is not missing value then
        set messagesToMark to search accountToSearch for searchString
      else
        set messagesToMark to search for searchString
      end if
      
      -- Filter by date if needed
      if messageCriteria's dateSince is not "" then
        try
          set dateThreshold to date messageCriteria's dateSince
          set filteredMessages to {}
          
          repeat with aMessage in messagesToMark
            if date received of aMessage ≥ dateThreshold then
              set end of filteredMessages to aMessage
            end if
          end repeat
          
          set messagesToMark to filteredMessages
        end try
      end if
      
      -- If we found messages to mark
      if (count of messagesToMark) > 0 then
        -- Mark the messages
        repeat with aMessage in messagesToMark
          set read status of aMessage to markAsRead
        end repeat
        
        set actionText to "marked as " & (if markAsRead then "read" else "unread")
        logMessage((count of messagesToMark) & " messages " & actionText)
        return (count of messagesToMark) & " messages " & actionText
      else
        return "No messages found matching the criteria"
      end if
    on error errMsg
      logMessage("Error marking messages: " & errMsg)
      return "Error marking messages: " & errMsg
    end try
  end tell
end markMessages
```

## Archiving Messages

```applescript
-- Archive messages based on criteria
on archiveMessages(messageCriteria)
  -- Prepare the criteria for move operation
  set moveResult to moveMessages(messageCriteria, emailArchiveFolder, messageCriteria's account)
  return moveResult
end archiveMessages
```

## Interactive Search and Organization Dialog

```applescript
-- Show dialog for email search and organization
on showSearchOrganizeDialog()
  -- Criteria dialog
  set criteriaDialog to display dialog "Search/Organize Emails" & return & return & "Enter search criteria (leave blank for any):" & return & "Subject:" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of criteriaDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set subjectCriteria to text returned of criteriaDialog
  
  -- Sender dialog
  set senderDialog to display dialog "From: (sender)" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of senderDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set senderCriteria to text returned of senderDialog
  
  -- Recipient dialog
  set recipientDialog to display dialog "To: (recipient)" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of recipientDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set recipientCriteria to text returned of recipientDialog
  
  -- Content dialog
  set contentDialog to display dialog "Content contains:" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of contentDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set contentCriteria to text returned of contentDialog
  
  -- Date dialog
  set dateDialog to display dialog "Since date (e.g., 'yesterday', '2023-01-01'):" default answer "" buttons {"Cancel", "Next"} default button "Next"
  
  if button returned of dateDialog is "Cancel" then
    return "Search cancelled"
  end if
  
  set dateCriteria to text returned of dateDialog
  
  -- Get list of accounts
  set accountList to getMailAccounts()
  set accountOptions to {"All Accounts"} & accountList
  
  -- Account selection
  set selectedAccount to choose from list accountOptions with prompt "Select Account:" default items {"All Accounts"}
  
  if selectedAccount is false then
    return "Search cancelled"
  end if
  
  set accountCriteria to ""
  if item 1 of selectedAccount is not "All Accounts" then
    set accountCriteria to item 1 of selectedAccount
  end if
  
  -- Folder selection (if account was selected)
  set folderCriteria to ""
  if accountCriteria is not "" then
    set folderList to getMailFolders(accountCriteria)
    
    set folderNames to {"All Folders"}
    repeat with aFolder in folderList
      set folderName to aFolder's folder
      set end of folderNames to folderName
    end repeat
    
    set selectedFolder to choose from list folderNames with prompt "Select Folder:" default items {"All Folders"}
    
    if selectedFolder is false then
      return "Search cancelled"
    end if
    
    if item 1 of selectedFolder is not "All Folders" then
      set folderCriteria to item 1 of selectedFolder
    end if
  end if
  
  -- Action selection
  set actionOptions to {"Search Only", "Mark as Read", "Mark as Unread", "Move to Folder", "Archive"}
  set selectedAction to choose from list actionOptions with prompt "Select Action:" default items {"Search Only"}
  
  if selectedAction is false then
    return "Operation cancelled"
  end if
  
  set actionType to item 1 of selectedAction
  
  -- Prepare criteria
  set messageCriteria to {subject:subjectCriteria, sender:senderCriteria, recipient:recipientCriteria, content:contentCriteria, account:accountCriteria, folder:folderCriteria, dateSince:dateCriteria, maxResults:"100"}
  
  -- Perform the selected action
  if actionType is "Search Only" then
    -- Perform search
    set searchResults to searchEmails(messageCriteria)
    
    if searchResults is {} then
      return "No messages found matching the criteria"
    end if
    
    -- Format search results for display
    set resultText to "Search Results:" & return & return
    
    repeat with i from 1 to count of searchResults
      set messageInfo to item i of searchResults
      set messageSubject to messageInfo's subject
      set messageSender to messageInfo's sender
      set messageDate to messageInfo's date as string
      
      set resultText to resultText & i & ". " & messageSubject & return
      set resultText to resultText & "   From: " & messageSender & return
      set resultText to resultText & "   Date: " & messageDate & return & return
    end repeat
    
    -- Display results
    display dialog resultText buttons {"OK"} default button "OK"
    return "Found " & (count of searchResults) & " messages"
    
  else if actionType is "Mark as Read" then
    -- Mark messages as read
    return markMessages(messageCriteria, true)
    
  else if actionType is "Mark as Unread" then
    -- Mark messages as unread
    return markMessages(messageCriteria, false)
    
  else if actionType is "Move to Folder" then
    -- Get list of all mail folders across accounts
    set allFolders to getMailFolders("")
    
    set folderOptions to {}
    repeat with aFolder in allFolders
      set accountName to aFolder's account
      set folderName to aFolder's folder
      set folderDisplay to folderName & " (" & accountName & ")"
      set end of folderOptions to {display:folderDisplay, account:accountName, folder:folderName}
    end repeat
    
    -- Extract just the display names for the choose from list
    set folderDisplays to {}
    repeat with aFolder in folderOptions
      set end of folderDisplays to aFolder's display
    end repeat
    
    -- Select destination folder
    set selectedDestination to choose from list folderDisplays with prompt "Select Destination Folder:" default items item 1 of folderDisplays
    
    if selectedDestination is false then
      return "Move operation cancelled"
    end if
    
    -- Find the selected folder details
    set destinationAccount to ""
    set destinationFolder to ""
    
    repeat with i from 1 to count of folderOptions
      if (folderOptions's item i)'s display is item 1 of selectedDestination then
        set destinationAccount to (folderOptions's item i)'s account
        set destinationFolder to (folderOptions's item i)'s folder
        exit repeat
      end if
    end repeat
    
    -- Move the messages
    return moveMessages(messageCriteria, destinationFolder, destinationAccount)
    
  else if actionType is "Archive" then
    -- Archive the messages
    return archiveMessages(messageCriteria)
  end if
  
  return "Operation completed"
end showSearchOrganizeDialog
```

This script provides comprehensive functionality for searching and organizing emails in Apple Mail. It includes features for searching with multiple criteria, moving messages between folders, marking messages as read or unread, and archiving messages. The interactive dialog guides users through the search and organization process step by step.