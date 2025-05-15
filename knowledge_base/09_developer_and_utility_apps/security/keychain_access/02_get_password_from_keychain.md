---
title: "Keychain Access: Retrieve Password"
category: "09_developer_and_utility_apps"
id: keychain_get_password
description: "Retrieves a stored password from the macOS Keychain using the security command-line tool."
keywords: ["keychain", "security", "macOS", "passwords", "credentials", "find-generic-password", "find-internet-password"]
language: applescript
isComplex: true
argumentsPrompt: "Provide account name as 'accountName' and, optionally, the service name as 'serviceName' (for generic passwords) or server name as 'serverName' (for internet passwords) in inputData."
notes: |
  - This script may trigger a keychain access prompt for the user
  - Handling passwords requires careful security considerations
  - For internet passwords, use find-internet-password instead of find-generic-password
  - Never store or log retrieved passwords in clear text
---

This script demonstrates how to retrieve a password from the macOS Keychain securely.

```applescript
--MCP_INPUT:accountName
--MCP_INPUT:serviceName
--MCP_INPUT:serverName

on getPasswordFromKeychain(accountName, serviceName, serverName)
  -- Validate inputs
  if accountName is missing value or accountName is "" then
    return "error: Account name is required."
  end if
  
  try
    set cmdArgs to ""
    set cmdType to ""
    
    -- Determine which type of password to retrieve
    if serviceName is not missing value and serviceName is not "" then
      -- Find generic password (application/service password)
      set cmdType to "find-generic-password"
      set cmdArgs to "-a " & quoted form of accountName & " -s " & quoted form of serviceName
    else if serverName is not missing value and serverName is not "" then
      -- Find internet password (website/server password)
      set cmdType to "find-internet-password"
      set cmdArgs to "-a " & quoted form of accountName & " -s " & quoted form of serverName
    else
      -- Default to generic password search with just the account
      set cmdType to "find-generic-password"
      set cmdArgs to "-a " & quoted form of accountName
    end if
    
    -- Build the security command with password output
    set securityCmd to "security " & cmdType & " " & cmdArgs & " -w"
    
    -- Execute the command and capture the password
    -- NOTE: This may trigger a keychain prompt for user approval
    set thePassword to do shell script securityCmd
    
    -- Return a success message (intentionally NOT returning the actual password)
    if cmdType is "find-generic-password" then
      if serviceName is not missing value and serviceName is not "" then
        return "Successfully retrieved password for account '" & accountName & "' and service '" & serviceName & "'."
      else
        return "Successfully retrieved password for account '" & accountName & "'."
      end if
    else
      return "Successfully retrieved password for account '" & accountName & "' on server '" & serverName & "'."
    end if
  on error errMsg
    if errMsg contains "could not be found" then
      return "No password found matching your criteria."
    else
      return "Error retrieving password: " & errMsg
    end if
  end try
end getPasswordFromKeychain

-- Using the script with values from MCP_INPUT placeholders
return my getPasswordFromKeychain("--MCP_INPUT:accountName", "--MCP_INPUT:serviceName", "--MCP_INPUT:serverName")
```

This script:
1. Takes an account name and optionally a service or server name
2. Determines whether to search for a generic password or internet password
3. Uses the `security` command-line tool to retrieve the password
4. Returns a success message (without exposing the actual password)

Important security notes:
- This script may trigger a user authorization dialog if the keychain item is protected
- For security reasons, the script returns a success message rather than the actual password
- In a real application, you would use the password immediately but never store or display it
- For more robust security, consider using one of these approaches:
  - Use the password immediately and discard it
  - Pass the password to another process through a secure mechanism
  - Store it briefly in a variable that will be cleared when the script finishes

Additional keychain options:
- You can specify a keychain file with `-k /path/to/keychain`
- View more details about an item with the `-g` option instead of `-w`
- List all keychain items with `security dump-keychain`
END_TIP