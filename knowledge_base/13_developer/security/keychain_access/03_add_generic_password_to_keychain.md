---
title: "Keychain Access: Add Generic Password"
category: "developer"
id: keychain_add_generic_password
description: "Adds a new generic password item to the macOS Keychain using the security command-line tool."
keywords: ["keychain", "security", "macOS", "passwords", "credentials", "add-generic-password", "password storage"]
language: applescript
isComplex: true
argumentsPrompt: "Provide service name as 'serviceName', account name as 'accountName', password as 'passwordValue', and optionally a comment as 'commentText' in inputData."
notes: |
  - This script stores credentials securely in the macOS Keychain
  - Use this for storing app passwords, API keys, and other sensitive data
  - Requires user authentication to add to the keychain
  - Password value is passed securely without being logged
---

This script demonstrates how to safely add a generic password to the macOS Keychain using the `security` command-line tool.

```applescript
--MCP_INPUT:serviceName
--MCP_INPUT:accountName
--MCP_INPUT:passwordValue
--MCP_INPUT:commentText

on addGenericPasswordToKeychain(serviceName, accountName, passwordValue, commentText)
  -- Validate required inputs
  if serviceName is missing value or serviceName is "" then
    return "error: Service name is required."
  end if
  if accountName is missing value or accountName is "" then
    return "error: Account name is required."
  end if
  if passwordValue is missing value or passwordValue is "" then
    return "error: Password value is required."
  end if
  
  try
    -- Build the base command for adding a generic password
    set passwordCmd to "security add-generic-password"
    
    -- Add required parameters
    set passwordCmd to passwordCmd & " -s " & quoted form of serviceName
    set passwordCmd to passwordCmd & " -a " & quoted form of accountName
    
    -- Add optional parameters if provided
    if commentText is not missing value and commentText is not "" then
      set passwordCmd to passwordCmd & " -j " & quoted form of commentText
    end if
    
    -- Add the password securely using stdin
    -- This prevents the password from appearing in process listings or logs
    set passwordCmd to passwordCmd & " -w"
    
    -- Execute the command with the password provided via stdin
    do shell script passwordCmd & " << EOF
" & passwordValue & "
EOF"
    
    -- Return success message
    return "Successfully added password for service '" & serviceName & "' and account '" & accountName & "' to the keychain."
  on error errMsg
    if errMsg contains "The specified item already exists in the keychain" then
      return "Error: A password for this service and account already exists in the keychain. Use 'security delete-generic-password' first to update it."
    else
      return "Error adding password to keychain: " & errMsg
    end if
  end try
end addGenericPasswordToKeychain

-- Using the script with values from MCP_INPUT placeholders
return my addGenericPasswordToKeychain("--MCP_INPUT:serviceName", "--MCP_INPUT:accountName", "--MCP_INPUT:passwordValue", "--MCP_INPUT:commentText")
```

This script:
1. Takes a service name, account name, password, and optional comment as input
2. Constructs a secure command to add the password to the keychain
3. Passes the password securely to avoid exposing it in process listings
4. Returns a success message or error details if the operation fails

Security best practices:
- The password is passed via stdin, not as a command-line argument
- The script validates required inputs before attempting to add the password
- Error handling specifically catches the common case of trying to add a duplicate item
- User authentication will be required to add items to the keychain (macOS security feature)

Common use cases:
- Storing API keys for automated scripts
- Saving database connection credentials
- Managing application passwords
- Storing private tokens and secrets

To update an existing password, you'll need to delete the old entry first using `security delete-generic-password` with the same service and account names.
END_TIP