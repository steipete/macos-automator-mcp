---
title: "Mail: Create Mail Rule"
category: "07_productivity_apps"
id: mail_create_rule
description: "Creates a new rule in Mail app for automatically handling incoming messages."
keywords: ["Mail", "mail rule", "filter", "email automation", "message rule"]
language: applescript
argumentsPrompt: "Enter rule name, search criteria, and action details"
notes: "Creates a rule that can automatically process incoming messages based on specified criteria."
---

```applescript
on run {ruleName, searchField, searchText, actionType, actionTarget}
  tell application "Mail"
    try
      -- Handle placeholder substitution
      if ruleName is "" or ruleName is missing value then
        set ruleName to "--MCP_INPUT:ruleName"
      end if
      
      if searchField is "" or searchField is missing value then
        set searchField to "--MCP_INPUT:searchField" -- e.g., "From", "Subject", "To", "Entire Message"
      end if
      
      if searchText is "" or searchText is missing value then
        set searchText to "--MCP_INPUT:searchText"
      end if
      
      if actionType is "" or actionType is missing value then
        set actionType to "--MCP_INPUT:actionType" -- e.g., "Move Message", "Copy Message", "Set Color", "Mark as Read"
      end if
      
      if actionTarget is "" or actionTarget is missing value then
        set actionTarget to "--MCP_INPUT:actionTarget" -- e.g., mailbox name for move/copy, or color name
      end if
      
      -- Activate Mail and open Rules preferences
      activate
      
      tell application "System Events"
        tell process "Mail"
          -- Open Rules preferences
          click menu item "Rules…" of menu "Preferences" of menu item "Preferences" of menu "Mail" of menu bar 1
          delay 1
          
          -- Click Add Rule button
          if exists button "Add Rule" of window "Rules" then
            click button "Add Rule" of window "Rules"
          else
            -- For older versions of Mail
            click button "+" of window "Rules"
          end if
          
          delay 0.5
          
          -- Set rule name
          if exists window "New Rule" then
            set value of text field 1 of window "New Rule" to ruleName
            
            -- Set rule criteria (condition)
            -- Find the popup for condition type (e.g., From, Subject, etc.)
            if exists pop up button 1 of group 1 of window "New Rule" then
              click pop up button 1 of group 1 of window "New Rule"
              delay 0.3
              
              -- Select the search field from the popup
              click menu item searchField of menu 1 of pop up button 1 of group 1 of window "New Rule"
              delay 0.3
              
              -- Enter the search text
              set value of text field 1 of group 1 of window "New Rule" to searchText
            end if
            
            -- Set rule action
            if exists pop up button 1 of group 2 of window "New Rule" then
              -- Click action type popup
              click pop up button 1 of group 2 of window "New Rule"
              delay 0.3
              
              -- Select the action type
              click menu item actionType of menu 1 of pop up button 1 of group 2 of window "New Rule"
              delay 0.3
              
              -- For actions that require a target (like move to mailbox)
              if actionType is "Move Message" or actionType is "Copy Message" then
                -- Click mailbox selection popup
                if exists pop up button 2 of group 2 of window "New Rule" then
                  click pop up button 2 of group 2 of window "New Rule"
                  delay 0.3
                  
                  -- Try to find and select the target mailbox
                  -- This is complex because of the hierarchical menu structure
                  -- Basic version assuming mailbox is at the top level:
                  click menu item actionTarget of menu 1 of pop up button 2 of group 2 of window "New Rule"
                end if
              end if
              
              -- Click OK to save the rule
              click button "OK" of window "New Rule"
              delay 0.5
              
              -- Click OK to close Rules preferences
              click button "OK" of window "Rules"
              
              return "Successfully created mail rule: " & ruleName
            else
              -- Cancel if we couldn't set up the action
              click button "Cancel" of window "New Rule"
              return "Could not set up rule action. The Mail app interface may have changed."
            end if
          else
            return "Could not create new rule. The Mail app interface may have changed."
          end if
        end tell
      end tell
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to create mail rule - " & errMsg
    end try
  end tell
end run
```
END_TIP