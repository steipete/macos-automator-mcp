---
title: "Mail: List Accounts and Mailboxes"
category: "07_productivity_apps"
id: mail_list_accounts_mailboxes
description: "Lists all Mail.app accounts and their mailboxes with message counts"
keywords: ["Mail", "email", "accounts", "mailboxes", "folders", "list"]
language: applescript
isComplex: false
notes: |
  - Lists all configured Mail.app accounts
  - Shows mailboxes in each account with message and unread counts
  - Also lists local 'On My Mac' mailboxes if present
  - Requires Automation permission for Mail.app
---

```applescript
on formatNumber(num)
  -- Add thousands separators to large numbers
  set theString to num as string
  set strlen to length of theString
  
  if strlen ≤ 3 then
    return theString
  else
    set formatted to ""
    set counter to 0
    
    repeat with i from strlen to 1 by -1
      set counter to counter + 1
      set formatted to (character i of theString) & formatted
      if counter mod 3 = 0 and i > 1 then
        set formatted to "," & formatted
      end if
    end repeat
    
    return formatted
  end if
end formatNumber

on listMailboxesAndAccounts()
  tell application "Mail"
    try
      set resultText to "Mail Accounts and Mailboxes:" & return & return
      set allAccounts to every account
      
      -- First handle standard accounts
      repeat with acct in allAccounts
        set accountName to name of acct
        if accountName is not "On My Mac" then
          set resultText to resultText & "Account: " & accountName & return
          set resultText to resultText & "───────────────────────" & return
          
          set accountMailboxes to every mailbox of acct
          repeat with aMailbox in accountMailboxes
            set boxName to name of aMailbox
            set msgCount to count of messages of aMailbox
            set unreadCount to unread count of aMailbox
            
            -- Format counts with thousands separators
            set formattedMsgCount to my formatNumber(msgCount)
            set formattedUnreadCount to my formatNumber(unreadCount)
            
            -- Compute padding for alignment (up to 20 chars)
            set boxNameLength to length of boxName
            set paddingLength to 20 - boxNameLength
            if paddingLength < 1 then set paddingLength to 1
            set padding to ""
            repeat paddingLength times
              set padding to padding & " "
            end repeat
            
            -- Generate mailbox line with stats
            set mailboxLine to "• " & boxName & padding
            set mailboxLine to mailboxLine & formattedMsgCount & " message"
            if msgCount ≠ 1 then set mailboxLine to mailboxLine & "s"
            
            if unreadCount > 0 then
              set mailboxLine to mailboxLine & " (" & formattedUnreadCount & " unread)"
            end if
            
            set resultText to resultText & mailboxLine & return
          end repeat
          
          set resultText to resultText & return
        end if
      end repeat
      
      -- Then handle local "On My Mac" mailboxes if they exist
      set localMailboxes to every mailbox
      if (count of localMailboxes) > 0 then
        set resultText to resultText & "Local Mailboxes (On My Mac):" & return
        set resultText to resultText & "───────────────────────" & return
        
        repeat with aMailbox in localMailboxes
          set boxName to name of aMailbox
          set msgCount to count of messages of aMailbox
          set unreadCount to unread count of aMailbox
          
          -- Format the same way as account mailboxes
          set formattedMsgCount to my formatNumber(msgCount)
          set formattedUnreadCount to my formatNumber(unreadCount)
          
          set boxNameLength to length of boxName
          set paddingLength to 20 - boxNameLength
          if paddingLength < 1 then set paddingLength to 1
          set padding to ""
          repeat paddingLength times
            set padding to padding & " "
          end repeat
          
          set mailboxLine to "• " & boxName & padding
          set mailboxLine to mailboxLine & formattedMsgCount & " message"
          if msgCount ≠ 1 then set mailboxLine to mailboxLine & "s"
          
          if unreadCount > 0 then
            set mailboxLine to mailboxLine & " (" & formattedUnreadCount & " unread)"
          end if
          
          set resultText to resultText & mailboxLine & return
        end repeat
      end if
      
      return resultText
    on error errMsg
      return "Error listing accounts and mailboxes: " & errMsg
    end try
  end tell
end listMailboxesAndAccounts

return my listMailboxesAndAccounts()
```

This script:
1. Lists all configured accounts in Mail.app
2. For each account, displays all mailboxes with message counts
3. Shows both total messages and unread message counts for each mailbox
4. Formats large numbers with thousands separators for better readability
5. Provides nicely formatted, aligned output for easy scanning
6. Includes local "On My Mac" mailboxes if present