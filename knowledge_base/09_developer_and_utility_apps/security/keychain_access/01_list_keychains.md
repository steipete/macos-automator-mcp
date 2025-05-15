---
title: "Keychain Access: List Available Keychains"
category: "11_developer_and_utility_apps" # Subdir: security/keychain_access
id: keychain_list_keychains
description: "Lists all available keychains on the system using the security command-line tool."
keywords: ["keychain", "security", "macOS", "passwords", "credentials", "keychain access", "list keychains"]
language: applescript
notes: |
  - Uses the security command-line tool which ships with macOS
  - Provides information about system and user keychains
  - Helps identify keychains to use with other security operations
  - No special privileges required to list keychains
---

macOS uses keychains to securely store passwords, certificates, and other sensitive data. This script demonstrates how to list all available keychains on the system.

```applescript
try
  -- List all available keychains
  set keychainListCmd to "security list-keychains"
  set keychainOutput to do shell script keychainListCmd
  
  -- Process the raw output into a more readable format
  set keychainLines to paragraphs of keychainOutput
  set keychainList to {}
  
  repeat with keyLine in keychainLines
    if keyLine is not "" then
      -- Extract keychain path from quotes
      if keyLine contains "\"" then
        set quotedPath to text from ((offset of "\"" in keyLine) + 1) to -2 of keyLine
        set end of keychainList to quotedPath
      else
        set end of keychainList to keyLine
      end if
    end if
  end repeat
  
  -- Get the default keychain
  set defaultKeychainCmd to "security default-keychain"
  set defaultKeychainOutput to do shell script defaultKeychainCmd
  set defaultKeychain to text from ((offset of "\"" in defaultKeychainOutput) + 1) to -2 of defaultKeychainOutput
  
  -- Format the result as a readable string
  set resultText to "Available Keychains:" & return
  set resultText to resultText & "================" & return
  
  repeat with kcPath in keychainList
    set keychainName to last text item of kcPath delimited by "/"
    if kcPath is equal to defaultKeychain then
      set resultText to resultText & "* " & keychainName & " (Default)" & return
    else
      set resultText to resultText & "• " & keychainName & return
    end if
    set resultText to resultText & "  Path: " & kcPath & return
  end repeat
  
  set resultText to resultText & return & "Default Keychain: " & defaultKeychain
  return resultText
on error errMsg
  return "Error listing keychains: " & errMsg
end try
```

This script:
1. Uses the `security list-keychains` command to get all available keychains
2. Parses the output to extract each keychain path
3. Determines the default keychain with `security default-keychain`
4. Formats the information into a readable report

Common macOS keychains include:
- `login.keychain-db`: The user's default login keychain
- `System.keychain`: System-wide credentials and certificates
- `System Roots.keychain`: Trusted root certificates

Understanding which keychains are available is the first step before performing operations like retrieving passwords, adding credentials, or managing certificates.

For security operations that require accessing or modifying keychains, you'll often need to specify which keychain to target.
END_TIP