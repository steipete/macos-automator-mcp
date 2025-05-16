---
title: Mail Automation Core Components
category: 09_productivity
id: mail_automation_core
description: Core functionality, initialization, and logging for the Mail Automation system
keywords:
  - email
  - mail
  - automation
  - initialization
  - logging
  - configuration
  - account management
language: applescript
---

# Mail Automation Core Components

This script provides the core functionality, initialization, and logging capabilities for the Mail Automation system.

## Configuration Properties

```applescript
-- Configuration properties
property defaultAccount : "" -- Leave empty to use default account
property defaultSignature : "" -- Leave empty to use default account signature
property templateFolder : "~/Library/Application Support/MailTemplates/"
property emailArchiveFolder : "Archive"
property logEnabled : true
property logFile : "~/Library/Logs/MailAutomation.log"
```

## Initialization

```applescript
-- Initialize the mail automation script
on initializeMailAutomation()
  -- Check if Mail app is available
  try
    tell application "Mail" to get name
  on error
    display dialog "Error: Cannot access Apple Mail application. Make sure it's installed." buttons {"OK"} default button "OK" with icon stop
    return false
  end try
  
  -- Create template folder if it doesn't exist
  try
    set templateFolderPath to do shell script "echo " & quoted form of templateFolder
    do shell script "mkdir -p " & quoted form of templateFolderPath
  end try
  
  -- Initialize log file
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    do shell script "touch " & quoted form of fullLogPath
    logMessage("Mail automation initialized")
  end if
  
  return true
end initializeMailAutomation
```

## Logging System

```applescript
-- Log a message to the log file
on logMessage(message)
  if logEnabled then
    set fullLogPath to do shell script "echo " & quoted form of logFile
    set timeStamp to do shell script "date '+%Y-%m-%d %H:%M:%S'"
    set logLine to timeStamp & " - " & message
    do shell script "echo " & quoted form of logLine & " >> " & quoted form of fullLogPath
  end if
end logMessage
```

## Mail Account Management

```applescript
-- Get list of mail accounts
on getMailAccounts()
  tell application "Mail"
    set accountList to {}
    set allAccounts to accounts
    
    repeat with anAccount in allAccounts
      set accountName to name of anAccount
      set end of accountList to accountName
    end repeat
    
    return accountList
  end tell
end getMailAccounts

-- Get list of signatures
on getMailSignatures()
  tell application "Mail"
    set signatureList to {}
    set allSignatures to signatures
    
    repeat with aSignature in allSignatures
      set signatureName to name of aSignature
      set end of signatureList to signatureName
    end repeat
    
    return signatureList
  end tell
end getMailSignatures

-- Get mail folders for an account
on getMailFolders(accountName)
  tell application "Mail"
    set folderList to {}
    
    if accountName is "" then
      -- Get folders from all accounts
      set allAccounts to accounts
      repeat with anAccount in allAccounts
        set accName to name of anAccount
        set mailboxes of anAccount to mailboxes of anAccount -- Refresh mailboxes
        
        set accountFolders to mail folders of anAccount
        repeat with aFolder in accountFolders
          set folderName to name of aFolder
          set end of folderList to {account:accName, folder:folderName}
        end repeat
      end repeat
    else
      -- Get folders from the specified account
      try
        set targetAccount to account accountName
        set mailboxes of targetAccount to mailboxes of targetAccount -- Refresh mailboxes
        
        set accountFolders to mail folders of targetAccount
        repeat with aFolder in accountFolders
          set folderName to name of aFolder
          set end of folderList to {account:accountName, folder:folderName}
        end repeat
      on error
        -- Account not found
      end try
    end if
    
    return folderList
  end tell
end getMailFolders
```

## Helper Functions

```applescript
-- Helper function to parse email addresses
on parseEmailAddresses(emailString)
  -- Split the string by commas
  set AppleScript's text item delimiters to ","
  set emailItems to text items of emailString
  set AppleScript's text item delimiters to ""
  
  set emailList to {}
  
  repeat with anEmail in emailItems
    -- Trim whitespace
    set trimmedEmail to do shell script "echo " & quoted form of anEmail & " | xargs"
    if trimmedEmail is not "" then
      set end of emailList to trimmedEmail
    end if
  end repeat
  
  return emailList
end parseEmailAddresses

-- Helper function to replace text
on replaceText(theText, searchString, replacementString)
  set AppleScript's text item delimiters to searchString
  set textItems to text items of theText
  set AppleScript's text item delimiters to replacementString
  set newText to textItems as text
  set AppleScript's text item delimiters to ""
  return newText
end replaceText
```

## Script Execution

```applescript
-- Run the Mail Automation script
on run
  return showMailMenu()
end run

-- Show the main Mail Automation menu
on showMailMenu()
  if not initializeMailAutomation() then
    return "Failed to initialize Mail Automation"
  end if
  
  set menuOptions to {"New Email", "Search/Organize Emails", "Manage Templates", "Save Draft as Template", "Cancel"}
  
  set selectedOption to choose from list menuOptions with prompt "Mail Automation:" default items {"New Email"}
  
  if selectedOption is false then
    return "Mail automation cancelled"
  end if
  
  set menuChoice to item 1 of selectedOption
  
  if menuChoice is "New Email" then
    return showNewEmailDialog()
    
  else if menuChoice is "Search/Organize Emails" then
    return showSearchOrganizeDialog()
    
  else if menuChoice is "Manage Templates" then
    return showTemplateDialog()
    
  else if menuChoice is "Save Draft as Template" then
    return showSaveDraftDialog()
    
  else
    return "Mail automation cancelled"
  end if
end showMailMenu
```

These core components provide the foundation for the Mail Automation system, handling initialization, logging, account management, and other essential functions. They establish the infrastructure needed by the other specialized components of the system.