---
title: 'Mail: Generate Inbox Summary'
category: 09_productivity/mail_app
id: mail_summarize_inbox
description: >-
  Creates a summary report of your inbox including message counts, top senders,
  and recent conversations
keywords:
  - Mail
  - email
  - inbox
  - analytics
  - statistics
  - summary
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide account name as 'accountName' in inputData (optional, searches across
  all accounts if not specified)
notes: |
  - Analyzes your Mail.app inbox and generates statistical insights
  - Shows message counts, unread messages, top senders, and recent activity
  - Can focus on a specific account or analyze all accounts
  - Requires Automation permission for Mail.app
---

```applescript
--MCP_INPUT:accountName

on summarizeInbox(accountInput)
  tell application "Mail"
    try
      set summaryText to "Mail Inbox Summary" & return & "=================" & return & return
      set totalMessages to 0
      set totalUnread to 0
      set senderCounts to {}
      set subjectCounts to {}
      set dateRanges to {today:0, week:0, month:0, older:0}
      set currentDate to current date
      
      -- Determine account(s) to analyze
      if accountInput is missing value or accountInput is "" then
        -- Analyze all accounts
        set summaryText to summaryText & "Analyzing all mail accounts" & return
        set accountsToCheck to every account
      else
        -- Analyze specific account
        try
          set specificAccount to account accountInput
          set accountsToCheck to {specificAccount}
          set summaryText to summaryText & "Analyzing account: " & accountInput & return
        on error
          return "Error: Account '" & accountInput & "' not found"
        end try
      end if
      
      -- Process each account
      repeat with acct in accountsToCheck
        set acctName to name of acct
        
        -- Skip accounts that don't have an inbox (like On My Mac)
        try
          set inboxMailbox to mailbox "INBOX" of acct
        on error
          -- Skip this account
          continue
        end try
        
        -- Get messages
        set inboxMessages to messages of inboxMailbox
        set messageCount to count of inboxMessages
        set totalMessages to totalMessages + messageCount
        
        -- Count unread
        set unreadCount to unread count of inboxMailbox
        set totalUnread to totalUnread + unreadCount
        
        -- Add account stats to summary
        set summaryText to summaryText & "  • " & acctName & ": " & messageCount & " messages (" & unreadCount & " unread)" & return
        
        -- Skip detailed analysis if no messages
        if messageCount is 0 then
          continue
        end if
        
        -- Analyze only the most recent messages (up to 100) to avoid performance issues
        set messagesToAnalyze to {}
        set maxToAnalyze to 100
        
        if messageCount > maxToAnalyze then
          -- Sort by date and take most recent
          set sortedMessages to my sortMessagesByDate(inboxMessages)
          set messagesToAnalyze to items 1 thru maxToAnalyze of sortedMessages
        else
          set messagesToAnalyze to inboxMessages
        end if
        
        -- Analyze these messages
        repeat with msg in messagesToAnalyze
          -- Count by sender
          set senderName to sender of msg
          set senderFound to false
          
          repeat with i from 1 to count of senderCounts
            set thisSenderInfo to item i of senderCounts
            if senderName is equal to sender of thisSenderInfo then
              set count of thisSenderInfo to (count of thisSenderInfo) + 1
              set item i of senderCounts to thisSenderInfo
              set senderFound to true
              exit repeat
            end if
          end repeat
          
          if not senderFound then
            copy {sender:senderName, count:1} to end of senderCounts
          end if
          
          -- Count by subject thread (simple grouping)
          set msgSubject to subject of msg
          -- Strip Re:, Fwd:, etc.
          set cleanSubject to my cleanSubjectLine(msgSubject)
          set subjectFound to false
          
          repeat with i from 1 to count of subjectCounts
            set thisSubjectInfo to item i of subjectCounts
            if cleanSubject is equal to subject of thisSubjectInfo then
              set count of thisSubjectInfo to (count of thisSubjectInfo) + 1
              set item i of subjectCounts to thisSubjectInfo
              set subjectFound to true
              exit repeat
            end if
          end repeat
          
          if not subjectFound and cleanSubject is not "" then
            copy {subject:cleanSubject, count:1} to end of subjectCounts
          end if
          
          -- Count by date range
          set msgDate to date received of msg
          set daysBetween to (currentDate - msgDate) / days
          
          if daysBetween < 1 then
            set today of dateRanges to (today of dateRanges) + 1
          else if daysBetween < 7 then
            set week of dateRanges to (week of dateRanges) + 1
          else if daysBetween < 30 then
            set month of dateRanges to (month of dateRanges) + 1
          else
            set older of dateRanges to (older of dateRanges) + 1
          end if
        end repeat
      end repeat
      
      -- Add total counts to summary
      set summaryText to summaryText & return & "Total Messages: " & totalMessages & return
      set summaryText to summaryText & "Total Unread: " & totalUnread & return & return
      
      -- Add date range analysis
      set summaryText to summaryText & "Messages by Date:" & return
      set summaryText to summaryText & "  • Today: " & today of dateRanges & return
      set summaryText to summaryText & "  • This Week: " & week of dateRanges & return
      set summaryText to summaryText & "  • This Month: " & month of dateRanges & return
      set summaryText to summaryText & "  • Older: " & older of dateRanges & return & return
      
      -- Add top senders (up to 5)
      set topSenders to my getTopItems(senderCounts, 5)
      set summaryText to summaryText & "Top Senders:" & return
      repeat with senderInfo in topSenders
        set summaryText to summaryText & "  • " & sender of senderInfo & " (" & count of senderInfo & ")" & return
      end repeat
      set summaryText to summaryText & return
      
      -- Add top conversation threads (up to 5)
      set topThreads to my getTopItems(subjectCounts, 5)
      set summaryText to summaryText & "Active Conversations:" & return
      repeat with threadInfo in topThreads
        set summaryText to summaryText & "  • " & subject of threadInfo & " (" & count of threadInfo & ")" & return
      end repeat
      
      return summaryText
    on error errMsg
      return "Error generating inbox summary: " & errMsg
    end try
  end tell
end summarizeInbox

on sortMessagesByDate(messageList)
  -- Get dates with indices
  set dateList to {}
  repeat with i from 1 to count of messageList
    set thisMessage to item i of messageList
    set thisDate to date received of thisMessage
    copy {index:i, dateValue:thisDate} to end of dateList
  end repeat
  
  -- Sort by date (newest first)
  set sortedDates to {}
  repeat while (count of dateList) > 0
    set latestDate to missing value
    set latestIndex to 0
    
    repeat with i from 1 to count of dateList
      set thisDateInfo to item i of dateList
      if latestDate is missing value or dateValue of thisDateInfo > latestDate then
        set latestDate to dateValue of thisDateInfo
        set latestIndex to i
      end if
    end repeat
    
    if latestIndex > 0 then
      set latestItem to item latestIndex of dateList
      set messageIndex to index of latestItem
      copy item messageIndex of messageList to end of sortedDates
      set dateList to items 1 thru (latestIndex - 1) of dateList & items (latestIndex + 1) thru (count of dateList) of dateList
    end if
  end repeat
  
  return sortedDates
end sortMessagesByDate

on getTopItems(itemList, maxItems)
  -- Sort items by count (descending)
  set sortedItems to {}
  set tempList to itemList
  
  repeat maxItems times
    if (count of tempList) is 0 then
      exit repeat
    end if
    
    set maxCount to 0
    set maxIndex to 0
    
    repeat with i from 1 to count of tempList
      set thisItem to item i of tempList
      if count of thisItem > maxCount then
        set maxCount to count of thisItem
        set maxIndex to i
      end if
    end repeat
    
    if maxIndex > 0 then
      copy item maxIndex of tempList to end of sortedItems
      set tempList to items 1 thru (maxIndex - 1) of tempList & items (maxIndex + 1) thru (count of tempList) of tempList
    end if
  end repeat
  
  return sortedItems
end getTopItems

on cleanSubjectLine(subjectText)
  set cleanSubject to subjectText
  
  -- Remove common prefixes
  set prefixes to {"Re:", "Fwd:", "RE:", "FW:", "Re: ", "Fwd: ", "RE: ", "FW: "}
  
  repeat
    set foundPrefix to false
    repeat with prefix in prefixes
      if cleanSubject starts with prefix then
        set prefixLength to length of prefix
        set cleanSubject to text (prefixLength + 1) thru (length of cleanSubject) of cleanSubject
        set foundPrefix to true
        exit repeat
      end if
    end repeat
    
    if not foundPrefix then
      exit repeat
    end if
  end repeat
  
  -- Remove leading/trailing whitespace
  set AppleScript's text item delimiters to ""
  repeat while cleanSubject begins with " "
    set cleanSubject to text 2 thru (length of cleanSubject) of cleanSubject
  end repeat
  
  repeat while cleanSubject ends with " "
    set cleanSubject to text 1 thru ((length of cleanSubject) - 1) of cleanSubject
  end repeat
  
  return cleanSubject
end cleanSubjectLine

return my summarizeInbox("--MCP_INPUT:accountName")
```

This script:
1. Analyzes your Mail.app inbox to generate statistical insights
2. Works with a specific account or across all mail accounts
3. Reports total message counts and unread messages
4. Shows message distribution by time period (today, this week, this month, older)
5. Identifies the most frequent senders and active conversation threads
6. Optimizes performance by analyzing only the most recent messages
7. Formats output as a readable text report
8. Helps identify communication patterns and important conversations
