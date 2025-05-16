---
title: 'Mail: Move Messages to Folder'
category: 09_productivity
id: mail_move_messages
description: Moves selected or filtered messages to a specified target mailbox
keywords:
  - Mail
  - email
  - move
  - file
  - organize
  - folder
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide target mailbox name as 'targetMailbox' and account name as
  'accountName' in inputData
notes: |
  - Moves currently selected messages in Mail.app to the specified mailbox
  - Can specify both target mailbox name and account name
  - Will find the first matching mailbox if account isn't specified
  - Requires Automation permission for Mail.app
  - Requires Mail.app to be open with message(s) selected
---

```applescript
--MCP_INPUT:targetMailbox
--MCP_INPUT:accountName

on moveMessages(targetFolder, accountName)
  -- Validate input
  if targetFolder is missing value or targetFolder is "" then
    return "Error: Target mailbox name is required"
  end if
  
  tell application "Mail"
    try
      -- Get selected messages
      set selectedMessages to selection
      if (count of selectedMessages) is 0 then
        return "Error: No messages selected. Please select messages in Mail.app before running this script."
      end if
      
      -- Find the target mailbox
      set targetMailbox to missing value
      
      -- If account is specified, look only in that account
      if accountName is not missing value and accountName is not "" then
        try
          set accountObj to account accountName
          repeat with aMailbox in every mailbox of accountObj
            if name of aMailbox is targetFolder then
              set targetMailbox to aMailbox
              exit repeat
            end if
          end repeat
        on error
          return "Error: Could not find account '" & accountName & "'"
        end try
      else
        -- If no account specified, search all accounts
        set allAccounts to every account
        repeat with acct in allAccounts
          set acctMailboxes to every mailbox of acct
          repeat with aMailbox in acctMailboxes
            if name of aMailbox is targetFolder then
              set targetMailbox to aMailbox
              set accountName to name of acct
              exit repeat
            end if
          end repeat
          if targetMailbox is not missing value then exit repeat
        end repeat
      end if
      
      -- Error if target mailbox not found
      if targetMailbox is missing value then
        if accountName is not missing value and accountName is not "" then
          return "Error: Could not find mailbox '" & targetFolder & "' in account '" & accountName & "'"
        else
          return "Error: Could not find mailbox '" & targetFolder & "' in any account"
        end if
      end if
      
      -- Move the messages
      set messageCount to count of selectedMessages
      set moveCount to 0
      
      repeat with thisMessage in selectedMessages
        try
          set mailbox of thisMessage to targetMailbox
          set moveCount to moveCount + 1
        on error
          -- Continue with next message if this one fails
        end try
      end repeat
      
      -- Return result
      set resultText to "Moved " & moveCount & " of " & messageCount & " message"
      if messageCount ≠ 1 then set resultText to resultText & "s"
      set resultText to resultText & " to mailbox '" & targetFolder & "'"
      
      if accountName is not missing value and accountName is not "" then
        set resultText to resultText & " in account '" & accountName & "'"
      end if
      
      return resultText
    on error errMsg
      return "Error moving messages: " & errMsg
    end try
  end tell
end moveMessages

return my moveMessages("--MCP_INPUT:targetMailbox", "--MCP_INPUT:accountName")
```

This script:
1. Moves currently selected messages in Mail.app to a specified mailbox
2. Can target a mailbox in a specific account or search across all accounts
3. Reports how many messages were successfully moved
4. Provides helpful error messages if the account or mailbox isn't found
5. Continues processing even if some messages can't be moved
