---
title: 'Mail: Check for Missing Replies'
category: 09_productivity
id: mail_check_for_replies
description: >-
  Identifies sent messages that have not received replies after a specified
  timeframe
keywords:
  - Mail
  - email
  - reply
  - follow up
  - pending
  - unanswered
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide days threshold as 'daysThreshold' in inputData (optional, defaults to
  3 days)
notes: >
  - Identifies sent emails that have not received replies after a specified
  number of days

  - Helps with follow-up tasks for important messages

  - Searches across all mail accounts

  - Requires Automation permission for Mail.app
---

```applescript
--MCP_INPUT:daysThreshold

on setDefaultThreshold(thresholdInput)
  if thresholdInput is missing value or thresholdInput is "" then
    return 3
  else
    try
      return thresholdInput as number
    on error
      return 3
    end try
  end if
end setDefaultThreshold

on checkForMissingReplies(daysInput)
  set threshold to my setDefaultThreshold(daysInput)
  
  tell application "Mail"
    try
      set currentDate to current date
      set thresholdSeconds to threshold * 24 * 60 * 60 -- Convert days to seconds
      set cutoffDate to currentDate - thresholdSeconds
      
      -- Result will store messages needing follow-up
      set pendingReplies to {}
      
      -- Check all accounts
      set allAccounts to every account
      repeat with acct in allAccounts
        set acctName to name of acct
        
        -- First check sent messages
        try
          set sentFolder to mailbox "Sent" of acct
          if sentFolder is missing value then
            set sentFolder to mailbox "Sent Messages" of acct
          end if
          
          if sentFolder is not missing value then
            set sentMessages to messages of sentFolder
            
            -- Check each sent message that's older than threshold but not too old
            -- Only check messages sent in the last 30 days to keep performance reasonable
            set longAgoDate to currentDate - (30 * 24 * 60 * 60) -- 30 days ago
            
            repeat with sentMsg in sentMessages
              try
                set sentDate to date sent of sentMsg
                
                -- Only check messages sent between cutoff and 30 days ago
                if sentDate < cutoffDate and sentDate > longAgoDate then
                  set msgSubject to subject of sentMsg
                  
                  -- Skip auto-replies, calendar invites, etc.
                  if msgSubject starts with "Re:" or msgSubject starts with "Automatic Reply:" or msgSubject starts with "Out of Office:" or msgSubject contains "Meeting" or msgSubject contains "Calendar" or msgSubject contains "Invite" then
                    continue
                  end if
                  
                  -- Get recipients
                  set msgRecipients to to recipient of sentMsg
                  if (count of msgRecipients) = 0 then
                    continue
                  end if
                  
                  -- For each recipient, check if we've received a reply
                  repeat with recipient in msgRecipients
                    set recipientAddress to address of recipient
                    set gotReply to false
                    
                    -- Check inbox and other mailboxes for replies
                    -- First try inbox as it's most likely location
                    try
                      set inboxFolder to mailbox "INBOX" of acct
                      set inboxMessages to messages of inboxFolder
                      
                      repeat with inboxMsg in inboxMessages
                        -- Check if message is from the recipient and has a matching subject or is a reply
                        set msgFrom to sender of inboxMsg
                        set msgSubj to subject of inboxMsg
                        
                        -- Consider it a reply if:
                        -- 1. From address contains the recipient's address, and
                        -- 2. Subject contains original subject or starts with Re:
                        if msgFrom contains recipientAddress and (msgSubj contains msgSubject or msgSubj starts with "Re:") then
                          set replyDate to date received of inboxMsg
                          
                          -- Only count if reply came after sent date
                          if replyDate > sentDate then
                            set gotReply to true
                            exit repeat
                          end if
                        end if
                      end repeat
                    end try
                    
                    -- If no reply found in inbox, could add additional folder checks here
                    -- (Archive, specific project folders, etc.)
                    
                    -- If no reply found, add to our list
                    if not gotReply then
                      -- Calculate days since sent
                      set daysSinceSent to (currentDate - sentDate) / days
                      set daysSinceSent to round daysSinceSent
                      
                      -- Add to pending replies list
                      copy {subject:msgSubject, recipient:recipientAddress, date:sentDate, days:daysSinceSent, account:acctName} to end of pendingReplies
                    end if
                  end repeat
                end if
              on error
                -- Skip problematic messages
                continue
              end try
            end repeat
          end if
        on error
          -- Skip account if no Sent folder found
          continue
        end try
      end repeat
      
      -- Format results
      if (count of pendingReplies) = 0 then
        return "No emails pending replies after " & threshold & " days were found."
      else
        -- Sort by days (most overdue first)
        set sortedPending to my sortByDays(pendingReplies)
        
        set resultText to "Emails Awaiting Replies (" & threshold & "+ days):" & return & "====================================" & return & return
        
        repeat with pendingItem in sortedPending
          set itemSubject to subject of pendingItem
          set itemRecipient to recipient of pendingItem
          set itemDays to days of pendingItem
          set itemAccount to account of pendingItem
          set itemDate to my formatDate(date of pendingItem)
          
          set resultText to resultText & "Subject: " & itemSubject & return
          set resultText to resultText & "To: " & itemRecipient & return
          set resultText to resultText & "Sent: " & itemDate & " (" & itemDays & " days ago)" & return
          set resultText to resultText & "Account: " & itemAccount & return & return
        end repeat
        
        set resultText to resultText & "Found " & (count of sortedPending) & " emails without replies after " & threshold & " days."
        return resultText
      end if
    on error errMsg
      return "Error checking for missing replies: " & errMsg
    end try
  end tell
end checkForMissingReplies

on sortByDays(pendingList)
  -- Sort by days (descending)
  set sortedList to {}
  set tempList to pendingList
  
  repeat while (count of tempList) > 0
    set maxDays to 0
    set maxIndex to 0
    
    repeat with i from 1 to count of tempList
      set thisPending to item i of tempList
      if days of thisPending > maxDays then
        set maxDays to days of thisPending
        set maxIndex to i
      end if
    end repeat
    
    if maxIndex > 0 then
      copy item maxIndex of tempList to end of sortedList
      set tempList to items 1 thru (maxIndex - 1) of tempList & items (maxIndex + 1) thru (count of tempList) of tempList
    end if
  end repeat
  
  return sortedList
end sortByDays

on formatDate(dateObj)
  set {year:y, month:m, day:d} to dateObj
  set monthNames to {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
  set monthName to item m of monthNames
  
  return monthName & " " & d & ", " & y
end formatDate

return my checkForMissingReplies("--MCP_INPUT:daysThreshold")
```

This script:
1. Scans your sent mail folders to find messages sent more than X days ago (default: 3)
2. Checks if any replies have been received from the original recipients
3. Compiles a list of messages that are still awaiting replies
4. Sorts results by age (most overdue first)
5. Filters out auto-replies, calendar invites, and other non-standard messages
6. Provides detailed information about each pending message
7. Helps track important correspondence that needs follow-up
8. Great for maintaining communication flow and preventing dropped threads
