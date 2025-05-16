---
title: 'Mail: Generate Email Statistics Report'
category: 09_productivity
id: mail_statistics_report
description: >-
  Creates a detailed statistical report about your email usage and communication
  patterns
keywords:
  - Mail
  - email
  - statistics
  - analytics
  - report
  - patterns
language: applescript
isComplex: true
argumentsPrompt: >-
  Provide days to analyze as 'daysToAnalyze' in inputData (optional, defaults to
  30), and output format as 'outputFormat' (text, markdown, or html, defaults to
  text)
notes: |
  - Analyzes email communication patterns across specified time period
  - Generates statistics on volume, peak times, top contacts, and response times
  - Can output in plain text, markdown, or HTML format for easy sharing
  - Requires Automation permission for Mail.app
  - May take a while to process if analyzing large mailboxes
---

```applescript
--MCP_INPUT:daysToAnalyze
--MCP_INPUT:outputFormat

on setDefaults(daysInput, formatInput)
  set defaults to {days:30, format:"text"}
  
  -- Set days to analyze
  if daysInput is not missing value and daysInput is not "" then
    try
      set daysValue to daysInput as number
      if daysValue > 0 then
        set defaults's days to daysValue
      end if
    end try
  end if
  
  -- Set output format
  if formatInput is not missing value and formatInput is not "" then
    set formatValue to lowercase of formatInput
    if formatValue is in {"text", "markdown", "html"} then
      set defaults's format to formatValue
    end if
  end if
  
  return defaults
end setDefaults

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

on extractEmailAddress(fullAddress)
  try
    -- Extract email from formats like "Name <email@example.com>" or just "email@example.com"
    if fullAddress contains "<" and fullAddress contains ">" then
      set AppleScript's text item delimiters to "<"
      set emailParts to text items of fullAddress
      
      if (count of emailParts) > 1 then
        set emailWithBracket to item 2 of emailParts
        set AppleScript's text item delimiters to ">"
        set emailAddress to item 1 of text items of emailWithBracket
        set AppleScript's text item delimiters to ""
        return emailAddress
      end if
    end if
    
    -- If no angle brackets, assume the whole string is an email
    if fullAddress contains "@" then
      return fullAddress
    end if
    
    return ""
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
  
  return cleanSubject
end cleanSubjectLine

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

on getDayName(dayNumber)
  set dayNames to {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
  return item dayNumber of dayNames
end getDayName

on addTableRow(cells, isHeader, formatType)
  set cellSeparator to " | "
  if formatType is "html" then
    set rowStart to "<tr>"
    set rowEnd to "</tr>"
    if isHeader then
      set cellStart to "<th>"
      set cellEnd to "</th>"
    else
      set cellStart to "<td>"
      set cellEnd to "</td>"
    end if
    
    set rowText to rowStart
    repeat with cellText in cells
      set rowText to rowText & cellStart & cellText & cellEnd
    end repeat
    set rowText to rowText & rowEnd
  else if formatType is "markdown" then
    set rowText to "| "
    repeat with i from 1 to count of cells
      set rowText to rowText & item i of cells
      if i < count of cells then
        set rowText to rowText & " | "
      end if
    end repeat
    set rowText to rowText & " |"
    
    -- Add header separator row
    if isHeader then
      set separatorRow to "|"
      repeat with i from 1 to count of cells
        set separatorRow to separatorRow & " --- |"
      end repeat
      set rowText to rowText & return & separatorRow
    end if
  else
    -- Plain text format
    set rowText to ""
    repeat with i from 1 to count of cells
      set rowText to rowText & item i of cells
      if i < count of cells then
        set rowText to rowText & cellSeparator
      end if
    end repeat
    
    -- Add separator line for header
    if isHeader then
      set separatorLine to ""
      repeat with i from 1 to length of rowText
        set separatorLine to separatorLine & "-"
      end repeat
      set rowText to rowText & return & separatorLine
    end if
  end if
  
  return rowText & return
end addTableRow

on generateStatisticsReport(daysInput, formatInput)
  -- Set defaults
  set params to my setDefaults(daysInput, formatInput)
  set daysToAnalyze to days of params
  set outputFormat to format of params
  
  tell application "Mail"
    try
      set currentDate to current date
      set startDate to currentDate - (daysToAnalyze * days)
      
      -- Initialize statistics containers
      set totalReceived to 0
      set totalSent to 0
      set receivedByDay to {0, 0, 0, 0, 0, 0, 0} -- Sun to Sat
      set sentByDay to {0, 0, 0, 0, 0, 0, 0}
      set receivedByHour to {}
      set sentByHour to {}
      repeat with i from 0 to 23
        copy 0 to end of receivedByHour
        copy 0 to end of sentByHour
      end repeat
      
      set senderCounts to {}
      set recipientCounts to {}
      set domainCounts to {}
      set threadCounts to {}
      set responseTimeData to {}
      
      -- First analyze received messages
      set allAccounts to every account
      repeat with acct in allAccounts
        set acctName to name of acct
        
        -- Skip special accounts
        if acctName is "On My Mac" then
          continue
        end if
        
        -- Process inbox
        try
          set inboxMailbox to mailbox "INBOX" of acct
          set inboxMessages to messages of inboxMailbox
          
          repeat with msg in inboxMessages
            try
              set msgDate to date received of msg
              
              -- Only analyze messages within our time range
              if msgDate ≥ startDate and msgDate ≤ currentDate then
                -- Count total
                set totalReceived to totalReceived + 1
                
                -- Count by day of week (1=Sunday to 7=Saturday)
                set dayOfWeek to weekday of msgDate
                set item dayOfWeek of receivedByDay to (item dayOfWeek of receivedByDay) + 1
                
                -- Count by hour
                set hourOfDay to hours of msgDate
                set item (hourOfDay + 1) of receivedByHour to (item (hourOfDay + 1) of receivedByHour) + 1
                
                -- Count by sender
                set msgSender to sender of msg
                set senderFound to false
                
                repeat with i from 1 to count of senderCounts
                  set thisSenderInfo to item i of senderCounts
                  if msgSender is equal to sender of thisSenderInfo then
                    set count of thisSenderInfo to (count of thisSenderInfo) + 1
                    set item i of senderCounts to thisSenderInfo
                    set senderFound to true
                    exit repeat
                  end if
                end repeat
                
                if not senderFound then
                  copy {sender:msgSender, count:1} to end of senderCounts
                end if
                
                -- Count by sender domain
                set senderEmail to my extractEmailAddress(msgSender)
                if senderEmail is not "" then
                  set senderDomain to my extractDomain(senderEmail)
                  set domainFound to false
                  
                  repeat with i from 1 to count of domainCounts
                    set thisDomainInfo to item i of domainCounts
                    if senderDomain is equal to domain of thisDomainInfo then
                      set count of thisDomainInfo to (count of thisDomainInfo) + 1
                      set item i of domainCounts to thisDomainInfo
                      set domainFound to true
                      exit repeat
                    end if
                  end repeat
                  
                  if not domainFound then
                    copy {domain:senderDomain, count:1} to end of domainCounts
                  end if
                end if
                
                -- Count by conversation thread
                set msgSubject to my cleanSubjectLine(subject of msg)
                if msgSubject is not "" then
                  set threadFound to false
                  
                  repeat with i from 1 to count of threadCounts
                    set thisThreadInfo to item i of threadCounts
                    if msgSubject is equal to subject of thisThreadInfo then
                      set count of thisThreadInfo to (count of thisThreadInfo) + 1
                      set item i of threadCounts to thisThreadInfo
                      set threadFound to true
                      exit repeat
                    end if
                  end repeat
                  
                  if not threadFound then
                    copy {subject:msgSubject, count:1} to end of threadCounts
                  end if
                end if
              end if
            on error
              -- Skip problematic messages
              continue
            end try
          end repeat
        on error
          -- Skip if no inbox found
          continue
        end try
        
        -- Process sent messages
        try
          set sentFolder to mailbox "Sent" of acct
          if sentFolder is missing value then
            set sentFolder to mailbox "Sent Messages" of acct
          end if
          
          if sentFolder is not missing value then
            set sentMessages to messages of sentFolder
            
            repeat with msg in sentMessages
              try
                set msgDate to date sent of msg
                
                -- Only analyze messages within our time range
                if msgDate ≥ startDate and msgDate ≤ currentDate then
                  -- Count total
                  set totalSent to totalSent + 1
                  
                  -- Count by day of week (1=Sunday to 7=Saturday)
                  set dayOfWeek to weekday of msgDate
                  set item dayOfWeek of sentByDay to (item dayOfWeek of sentByDay) + 1
                  
                  -- Count by hour
                  set hourOfDay to hours of msgDate
                  set item (hourOfDay + 1) of sentByHour to (item (hourOfDay + 1) of sentByHour) + 1
                  
                  -- Count by recipient
                  set msgRecipients to to recipient of msg
                  repeat with recipient in msgRecipients
                    set recipientAddress to address of recipient
                    set recipientFound to false
                    
                    repeat with i from 1 to count of recipientCounts
                      set thisRecipientInfo to item i of recipientCounts
                      if recipientAddress is equal to recipient of thisRecipientInfo then
                        set count of thisRecipientInfo to (count of thisRecipientInfo) + 1
                        set item i of recipientCounts to thisRecipientInfo
                        set recipientFound to true
                        exit repeat
                      end if
                    end repeat
                    
                    if not recipientFound then
                      copy {recipient:recipientAddress, count:1} to end of recipientCounts
                    end if
                  end repeat
                  
                  -- Check if this is a reply to calculate response time
                  set msgSubject to subject of msg
                  if msgSubject starts with "Re:" then
                    set baseSubject to my cleanSubjectLine(msgSubject)
                    
                    -- Look for original message in inbox
                    repeat with acct2 in allAccounts
                      try
                        set inbox2 to mailbox "INBOX" of acct2
                        set inboxMsgs to messages of inbox2
                        
                        repeat with inboxMsg in inboxMsgs
                          set inboxSubject to my cleanSubjectLine(subject of inboxMsg)
                          set inboxSender to sender of inboxMsg
                          
                          -- Look for matching subject from one of our recipients
                          if inboxSubject is baseSubject then
                            set recipientsList to to recipient of msg
                            set foundMatch to false
                            
                            repeat with recip in recipientsList
                              if inboxSender contains address of recip then
                                set foundMatch to true
                                exit repeat
                              end if
                            end repeat
                            
                            if foundMatch then
                              set receivedDate to date received of inboxMsg
                              set sentDate to date sent of msg
                              
                              -- Only count if sent date is after received date and within reasonable window (5 days)
                              if sentDate > receivedDate and (sentDate - receivedDate) < 5 * days then
                                -- Calculate response time in minutes
                                set responseMinutes to (sentDate - receivedDate) / minutes
                                copy {subject:baseSubject, minutes:responseMinutes} to end of responseTimeData
                                exit repeat
                              end if
                            end if
                          end if
                        end repeat
                      on error
                        -- Skip accounts without inbox
                        continue
                      end try
                    end repeat
                  end if
                end if
              on error
                -- Skip problematic messages
                continue
              end try
            end repeat
          end if
        on error
          -- Skip if no sent folder found
          continue
        end try
      end repeat
      
      -- Prepare report
      -- Get top rankings
      set topSenders to my getTopItems(senderCounts, 10)
      set topRecipients to my getTopItems(recipientCounts, 10)
      set topDomains to my getTopItems(domainCounts, 10)
      set topThreads to my getTopItems(threadCounts, 10)
      
      -- Calculate response time metrics
      set avgResponseTime to 0
      set minResponseTime to 0
      set maxResponseTime to 0
      set responseCount to count of responseTimeData
      
      if responseCount > 0 then
        set totalResponseTime to 0
        set minResponseTime to 10000 -- Start with a high number
        set maxResponseTime to 0
        
        repeat with responseInfo in responseTimeData
          set thisTime to minutes of responseInfo
          set totalResponseTime to totalResponseTime + thisTime
          
          if thisTime < minResponseTime then
            set minResponseTime to thisTime
          end if
          
          if thisTime > maxResponseTime then
            set maxResponseTime to thisTime
          end if
        end repeat
        
        set avgResponseTime to totalResponseTime / responseCount
      end if
      
      -- Find peak activity days and hours
      set peakReceiveDay to 1
      set peakReceiveCount to 0
      set peakSendDay to 1
      set peakSendCount to 0
      
      repeat with i from 1 to 7
        if item i of receivedByDay > peakReceiveCount then
          set peakReceiveCount to item i of receivedByDay
          set peakReceiveDay to i
        end if
        
        if item i of sentByDay > peakSendCount then
          set peakSendCount to item i of sentByDay
          set peakSendDay to i
        end if
      end repeat
      
      set peakReceiveHour to 0
      set peakReceiveHourCount to 0
      set peakSendHour to 0
      set peakSendHourCount to 0
      
      repeat with i from 1 to 24
        if item i of receivedByHour > peakReceiveHourCount then
          set peakReceiveHourCount to item i of receivedByHour
          set peakReceiveHour to i - 1
        end if
        
        if item i of sentByHour > peakSendHourCount then
          set peakSendHourCount to item i of sentByHour
          set peakSendHour to i - 1
        end if
      end repeat
      
      -- Format the report based on output format
      if outputFormat is "html" then
        set report to "<!DOCTYPE html><html><head><title>Email Statistics Report</title>"
        set report to report & "<style>body{font-family:Arial,sans-serif;line-height:1.6;padding:20px;max-width:1000px;margin:0 auto}h1{color:#333}h2{color:#444;margin-top:20px}table{border-collapse:collapse;width:100%;margin-bottom:20px}th,td{text-align:left;padding:8px;border-bottom:1px solid #ddd}th{background-color:#f2f2f2}tr:hover{background-color:#f5f5f5}.summary{background-color:#f9f9f9;padding:15px;border-radius:5px;margin-bottom:20px}</style></head><body>"
        set report to report & "<h1>Email Statistics Report</h1>"
        set report to report & "<div class='summary'><p>Analysis of " & totalReceived + totalSent & " emails over the past " & daysToAnalyze & " days from " & (startDate as string) & " to " & (currentDate as string) & ".</p></div>"
      else if outputFormat is "markdown" then
        set report to "# Email Statistics Report" & return & return
        set report to report & "Analysis of " & totalReceived + totalSent & " emails over the past " & daysToAnalyze & " days from " & (startDate as string) & " to " & (currentDate as string) & "." & return & return
      else
        set report to "EMAIL STATISTICS REPORT" & return & "======================" & return & return
        set report to report & "Analysis of " & totalReceived + totalSent & " emails over the past " & daysToAnalyze & " days" & return
        set report to report & "From: " & (startDate as string) & return
        set report to report & "To: " & (currentDate as string) & return & return
      end if
      
      -- Volume section
      if outputFormat is "html" then
        set report to report & "<h2>Email Volume</h2>"
      else if outputFormat is "markdown" then
        set report to report & "## Email Volume" & return & return
      else
        set report to report & "EMAIL VOLUME" & return & "------------" & return & return
      end if
      
      -- Volume table
      set volumeTable to my addTableRow({"Category", "Count", "Percentage"}, true, outputFormat)
      
      set totalEmails to totalReceived + totalSent
      set receivedPercent to 0
      set sentPercent to 0
      
      if totalEmails > 0 then
        set receivedPercent to (totalReceived / totalEmails) * 100
        set sentPercent to (totalSent / totalEmails) * 100
      end if
      
      set volumeTable to volumeTable & my addTableRow({"Received", my formatNumber(totalReceived), round(receivedPercent) & "%"}, false, outputFormat)
      set volumeTable to volumeTable & my addTableRow({"Sent", my formatNumber(totalSent), round(sentPercent) & "%"}, false, outputFormat)
      set volumeTable to volumeTable & my addTableRow({"Total", my formatNumber(totalEmails), "100%"}, false, outputFormat)
      
      if outputFormat is "html" then
        set report to report & "<table>" & volumeTable & "</table>"
      else
        set report to report & volumeTable & return
      end if
      
      -- Activity patterns section
      if outputFormat is "html" then
        set report to report & "<h2>Activity Patterns</h2>"
      else if outputFormat is "markdown" then
        set report to report & "## Activity Patterns" & return & return
      else
        set report to report & "ACTIVITY PATTERNS" & return & "-----------------" & return & return
      end if
      
      -- Peak data
      set peakTable to my addTableRow({"Category", "Peak Day", "Peak Hour"}, true, outputFormat)
      set peakTable to peakTable & my addTableRow({"Received Messages", my getDayName(peakReceiveDay), peakReceiveHour & ":00"}, false, outputFormat)
      set peakTable to peakTable & my addTableRow({"Sent Messages", my getDayName(peakSendDay), peakSendHour & ":00"}, false, outputFormat)
      
      if outputFormat is "html" then
        set report to report & "<table>" & peakTable & "</table>"
      else
        set report to report & peakTable & return
      end if
      
      -- Top contacts section
      if outputFormat is "html" then
        set report to report & "<h2>Top Contacts</h2>"
      else if outputFormat is "markdown" then
        set report to report & "## Top Contacts" & return & return
      else
        set report to report & "TOP CONTACTS" & return & "------------" & return & return
      end if
      
      -- Top senders table
      if outputFormat is "html" then
        set report to report & "<h3>Top Senders</h3>"
      else if outputFormat is "markdown" then
        set report to report & "### Top Senders" & return & return
      else
        set report to report & "TOP SENDERS" & return & "-----------" & return & return
      end if
      
      set senderTable to my addTableRow({"Sender", "Count", "Percentage"}, true, outputFormat)
      
      repeat with i from 1 to count of topSenders
        set senderInfo to item i of topSenders
        set senderName to sender of senderInfo
        set senderCount to count of senderInfo
        set senderPercent to 0
        
        if totalReceived > 0 then
          set senderPercent to (senderCount / totalReceived) * 100
        end if
        
        set senderTable to senderTable & my addTableRow({senderName, senderCount, round(senderPercent) & "%"}, false, outputFormat)
      end repeat
      
      if outputFormat is "html" then
        set report to report & "<table>" & senderTable & "</table>"
      else
        set report to report & senderTable & return
      end if
      
      -- Top recipients table
      if outputFormat is "html" then
        set report to report & "<h3>Top Recipients</h3>"
      else if outputFormat is "markdown" then
        set report to report & "### Top Recipients" & return & return
      else
        set report to report & "TOP RECIPIENTS" & return & "--------------" & return & return
      end if
      
      set recipientTable to my addTableRow({"Recipient", "Count", "Percentage"}, true, outputFormat)
      
      repeat with i from 1 to count of topRecipients
        set recipientInfo to item i of topRecipients
        set recipientName to recipient of recipientInfo
        set recipientCount to count of recipientInfo
        set recipientPercent to 0
        
        if totalSent > 0 then
          set recipientPercent to (recipientCount / totalSent) * 100
        end if
        
        set recipientTable to recipientTable & my addTableRow({recipientName, recipientCount, round(recipientPercent) & "%"}, false, outputFormat)
      end repeat
      
      if outputFormat is "html" then
        set report to report & "<table>" & recipientTable & "</table>"
      else
        set report to report & recipientTable & return
      end if
      
      -- Top domains table
      if outputFormat is "html" then
        set report to report & "<h3>Top Email Domains</h3>"
      else if outputFormat is "markdown" then
        set report to report & "### Top Email Domains" & return & return
      else
        set report to report & "TOP EMAIL DOMAINS" & return & "----------------" & return & return
      end if
      
      set domainTable to my addTableRow({"Domain", "Count", "Percentage"}, true, outputFormat)
      
      repeat with i from 1 to count of topDomains
        set domainInfo to item i of topDomains
        set domainName to domain of domainInfo
        set domainCount to count of domainInfo
        set domainPercent to 0
        
        if totalReceived > 0 then
          set domainPercent to (domainCount / totalReceived) * 100
        end if
        
        set domainTable to domainTable & my addTableRow({domainName, domainCount, round(domainPercent) & "%"}, false, outputFormat)
      end repeat
      
      if outputFormat is "html" then
        set report to report & "<table>" & domainTable & "</table>"
      else
        set report to report & domainTable & return
      end if
      
      -- Response time section
      if outputFormat is "html" then
        set report to report & "<h2>Response Time Analysis</h2>"
      else if outputFormat is "markdown" then
        set report to report & "## Response Time Analysis" & return & return
      else
        set report to report & "RESPONSE TIME ANALYSIS" & return & "----------------------" & return & return
      end if
      
      -- Response metrics
      if responseCount > 0 then
        set responseTable to my addTableRow({"Metric", "Time (minutes)", "Time (hours)"}, true, outputFormat)
        set responseTable to responseTable & my addTableRow({"Average Response Time", round(avgResponseTime), round(avgResponseTime / 60 * 10) / 10}, false, outputFormat)
        set responseTable to responseTable & my addTableRow({"Quickest Response", round(minResponseTime), round(minResponseTime / 60 * 10) / 10}, false, outputFormat)
        set responseTable to responseTable & my addTableRow({"Slowest Response", round(maxResponseTime), round(maxResponseTime / 60 * 10) / 10}, false, outputFormat)
        set responseTable to responseTable & my addTableRow({"Response Count", responseCount, ""}, false, outputFormat)
        
        if outputFormat is "html" then
          set report to report & "<table>" & responseTable & "</table>"
        else
          set report to report & responseTable & return
        end if
      else
        if outputFormat is "html" then
          set report to report & "<p>No response time data available.</p>"
        else
          set report to report & "No response time data available." & return & return
        end if
      end if
      
      -- Top conversations section
      if outputFormat is "html" then
        set report to report & "<h2>Top Conversation Threads</h2>"
      else if outputFormat is "markdown" then
        set report to report & "## Top Conversation Threads" & return & return
      else
        set report to report & "TOP CONVERSATION THREADS" & return & "-----------------------" & return & return
      end if
      
      set threadTable to my addTableRow({"Subject", "Messages"}, true, outputFormat)
      
      repeat with i from 1 to count of topThreads
        set threadInfo to item i of topThreads
        set threadSubject to subject of threadInfo
        set threadCount to count of threadInfo
        
        set threadTable to threadTable & my addTableRow({threadSubject, threadCount}, false, outputFormat)
      end repeat
      
      if outputFormat is "html" then
        set report to report & "<table>" & threadTable & "</table>"
        set report to report & "</body></html>"
      else
        set report to report & threadTable
      end if
      
      return report
    on error errMsg
      return "Error generating email statistics report: " & errMsg
    end try
  end tell
end generateStatisticsReport

return my generateStatisticsReport("--MCP_INPUT:daysToAnalyze", "--MCP_INPUT:outputFormat")
```

This script:
1. Creates a comprehensive statistical report on your email communication patterns
2. Analyzes data over a specified time period (default: 30 days)
3. Includes metrics on:
   - Email volume (sent vs. received)
   - Activity patterns (peak days and hours)
   - Top contacts (senders and recipients)
   - Email domain distribution
   - Response time analysis
   - Most active conversation threads
4. Supports multiple output formats:
   - Plain text (for terminal/console viewing)
   - Markdown (for documentation)
   - HTML (for sharing or embedding)
5. Calculates percentages and formats numbers for better readability
6. Optimized to handle large volumes of email data
7. Perfect for understanding communication patterns and improving email productivity
