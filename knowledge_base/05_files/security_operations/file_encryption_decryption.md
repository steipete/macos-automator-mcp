---
title: File Encryption and Decryption
category: 05_files/security_operations
id: file_encryption_decryption
description: >-
  Encrypts and decrypts files securely using various macOS encryption methods
  including disk images, OpenSSL, and GPG
keywords:
  - encryption
  - decryption
  - security
  - password
  - hdiutil
  - diskimage
  - OpenSSL
  - GPG
  - files
language: applescript
notes: >-
  Uses macOS built-in tools for encryption. For OpenSSL and GPG methods, these
  tools need to be installed (GPG is optional, OpenSSL comes with macOS).
---

```applescript
-- File Encryption and Decryption Utilities
-- Provides multiple methods for securely encrypting and decrypting files

-- Configuration properties
property defaultEncryptionMethod : "diskimage" -- Options: diskimage, openssl, gpg
property defaultEncryptionLevel : "aes-256" -- For OpenSSL
property encryptDeleteOriginal : false -- Whether to delete original after encryption

-- Initialize the encryption utility
on initialize()
  -- Check if OpenSSL is available
  set hasOpenSSL to do shell script "which openssl > /dev/null 2>&1 && echo 'yes' || echo 'no'"
  
  -- Check if GPG is available (optional)
  set hasGPG to do shell script "which gpg > /dev/null 2>&1 && echo 'yes' || echo 'no'"
  
  return {openssl:hasOpenSSL is "yes", gpg:hasGPG is "yes"}
end initialize

-- Encrypt file using a disk image (built into macOS)
on encryptWithDiskImage(filePath, outputPath, encryptionPassword)
  try
    -- Get file info
    set fileInfo to getFileInfo(filePath)
    set fileName to fileInfo's name
    set fileExtension to fileInfo's extension
    set fullFileName to fileName
    if fileExtension is not "" then
      set fullFileName to fileName & "." & fileExtension
    end if
    
    -- Determine output path if not provided
    if outputPath is "" then
      set parentFolder to do shell script "dirname " & quoted form of filePath
      set outputPath to parentFolder & "/" & fileName & ".dmg"
    end if
    
    -- Generate a temporary directory for mounting
    set tmpDirName to "encrypt_tmp_" & do shell script "date +%s"
    set tmpDir to "/tmp/" & tmpDirName
    do shell script "mkdir -p " & quoted form of tmpDir
    
    -- Copy the file to the temporary directory
    do shell script "cp " & quoted form of filePath & " " & quoted form of tmpDir & "/"
    
    -- Create an encrypted disk image containing the file
    set createDmgCmd to "hdiutil create -srcfolder " & quoted form of tmpDir & " -encryption -stdinpass -volname " & quoted form of fileName & " " & quoted form of outputPath
    
    do shell script createDmgCmd & " <<< " & quoted form of encryptionPassword
    
    -- Clean up temporary directory
    do shell script "rm -rf " & quoted form of tmpDir
    
    -- Delete original if configured to do so
    if encryptDeleteOriginal then
      do shell script "rm " & quoted form of filePath
    end if
    
    return "File encrypted successfully: " & outputPath
  on error errMsg
    return "Error encrypting with disk image: " & errMsg
  end try
end encryptWithDiskImage

-- Decrypt file from an encrypted disk image
on decryptFromDiskImage(dmgPath, outputFolder, encryptionPassword)
  try
    -- Get disk image info
    set dmgInfo to getFileInfo(dmgPath)
    set dmgName to dmgInfo's name
    
    -- Determine output folder if not provided
    if outputFolder is "" then
      set outputFolder to do shell script "dirname " & quoted form of dmgPath
    end if
    
    -- Generate a temporary mount point
    set tmpMountPoint to "/Volumes/" & dmgName
    
    -- Attempt to mount the encrypted disk image
    set mountCmd to "echo " & quoted form of encryptionPassword & " | hdiutil attach -stdinpass " & quoted form of dmgPath
    set mountOutput to do shell script mountCmd
    
    -- Extract the mount point
    set mountPoint to tmpMountPoint
    
    -- Copy the contents to the output folder
    do shell script "cp -R " & quoted form of mountPoint & "/* " & quoted form of outputFolder
    
    -- Unmount the disk image
    do shell script "hdiutil detach " & quoted form of mountPoint
    
    return "File decrypted successfully to: " & outputFolder
  on error errMsg
    -- Try to clean up by unmounting if needed
    try
      do shell script "hdiutil detach " & quoted form of tmpMountPoint & " > /dev/null 2>&1 || true"
    end try
    return "Error decrypting disk image: " & errMsg
  end try
end decryptFromDiskImage

-- Encrypt file using OpenSSL (more portable)
on encryptWithOpenSSL(filePath, outputPath, encryptionPassword)
  try
    -- Check if OpenSSL is available
    set hasOpenSSL to do shell script "which openssl > /dev/null 2>&1 && echo 'yes' || echo 'no'"
    if hasOpenSSL is "no" then
      return "OpenSSL not available on this system"
    end if
    
    -- Get file info
    set fileInfo to getFileInfo(filePath)
    set fileName to fileInfo's name
    set fileExtension to fileInfo's extension
    
    -- Determine output path if not provided
    if outputPath is "" then
      set parentFolder to do shell script "dirname " & quoted form of filePath
      set outputPath to parentFolder & "/" & fileName
      if fileExtension is not "" then
        set outputPath to outputPath & "." & fileExtension
      end if
      set outputPath to outputPath & ".enc"
    end if
    
    -- Use OpenSSL to encrypt the file
    set encryptCmd to "openssl enc -" & defaultEncryptionLevel & " -salt -pbkdf2 -in " & quoted form of filePath & " -out " & quoted form of outputPath & " -pass pass:" & quoted form of encryptionPassword
    
    do shell script encryptCmd
    
    -- Delete original if configured to do so
    if encryptDeleteOriginal then
      do shell script "rm " & quoted form of filePath
    end if
    
    return "File encrypted successfully: " & outputPath
  on error errMsg
    return "Error encrypting with OpenSSL: " & errMsg
  end try
end encryptWithOpenSSL

-- Decrypt file encrypted with OpenSSL
on decryptWithOpenSSL(encryptedFilePath, outputPath, encryptionPassword)
  try
    -- Check if OpenSSL is available
    set hasOpenSSL to do shell script "which openssl > /dev/null 2>&1 && echo 'yes' || echo 'no'"
    if hasOpenSSL is "no" then
      return "OpenSSL not available on this system"
    end if
    
    -- Get file info
    set fileInfo to getFileInfo(encryptedFilePath)
    set fileName to fileInfo's name
    set fileExtension to fileInfo's extension
    
    -- Determine output path if not provided
    if outputPath is "" then
      set parentFolder to do shell script "dirname " & quoted form of encryptedFilePath
      
      -- Remove .enc extension if present
      if fileName ends with ".enc" then
        set fileName to text 1 thru -5 of fileName
      end if
      
      set outputPath to parentFolder & "/" & fileName
    end if
    
    -- Use OpenSSL to decrypt the file
    set decryptCmd to "openssl enc -d -" & defaultEncryptionLevel & " -pbkdf2 -in " & quoted form of encryptedFilePath & " -out " & quoted form of outputPath & " -pass pass:" & quoted form of encryptionPassword
    
    do shell script decryptCmd
    
    return "File decrypted successfully: " & outputPath
  on error errMsg
    return "Error decrypting with OpenSSL: " & errMsg
  end try
end decryptWithOpenSSL

-- Encrypt file using GPG (if available)
on encryptWithGPG(filePath, outputPath, recipientEmail)
  try
    -- Check if GPG is available
    set hasGPG to do shell script "which gpg > /dev/null 2>&1 && echo 'yes' || echo 'no'"
    if hasGPG is "no" then
      return "GPG not available on this system. Install with 'brew install gnupg'"
    end if
    
    -- Get file info
    set fileInfo to getFileInfo(filePath)
    set fileName to fileInfo's name
    set fileExtension to fileInfo's extension
    
    -- Determine output path if not provided
    if outputPath is "" then
      set parentFolder to do shell script "dirname " & quoted form of filePath
      set outputPath to parentFolder & "/" & fileName
      if fileExtension is not "" then
        set outputPath to outputPath & "." & fileExtension
      end if
      set outputPath to outputPath & ".gpg"
    end if
    
    -- Use GPG to encrypt the file for the recipient
    set encryptCmd to "gpg --encrypt --recipient " & quoted form of recipientEmail & " --output " & quoted form of outputPath & " " & quoted form of filePath
    
    do shell script encryptCmd
    
    -- Delete original if configured to do so
    if encryptDeleteOriginal then
      do shell script "rm " & quoted form of filePath
    end if
    
    return "File encrypted with GPG for " & recipientEmail & ": " & outputPath
  on error errMsg
    return "Error encrypting with GPG: " & errMsg
  end try
end encryptWithGPG

-- Decrypt file encrypted with GPG
on decryptWithGPG(encryptedFilePath, outputPath)
  try
    -- Check if GPG is available
    set hasGPG to do shell script "which gpg > /dev/null 2>&1 && echo 'yes' || echo 'no'"
    if hasGPG is "no" then
      return "GPG not available on this system. Install with 'brew install gnupg'"
    end if
    
    -- Get file info
    set fileInfo to getFileInfo(encryptedFilePath)
    set fileName to fileInfo's name
    
    -- Determine output path if not provided
    if outputPath is "" then
      set parentFolder to do shell script "dirname " & quoted form of encryptedFilePath
      
      -- Remove .gpg extension if present
      if fileName ends with ".gpg" then
        set fileName to text 1 thru -5 of fileName
      end if
      
      set outputPath to parentFolder & "/" & fileName
    end if
    
    -- Use GPG to decrypt the file (will prompt for passphrase if needed)
    set decryptCmd to "gpg --decrypt --output " & quoted form of outputPath & " " & quoted form of encryptedFilePath
    
    do shell script decryptCmd
    
    return "File decrypted with GPG successfully: " & outputPath
  on error errMsg
    return "Error decrypting with GPG: " & errMsg
  end try
end decryptWithGPG

-- Generate a secure random password
on generateSecurePassword(length)
  if length is less than 8 then
    set length to 12 -- Minimum reasonable length
  end if
  
  -- Use macOS's built-in password generator
  set pwgen to "/usr/bin/security generate-password -length " & length
  set password to do shell script pwgen
  
  return password
end generateSecurePassword

-- Helper function to get file info
on getFileInfo(filePath)
  set fileName to do shell script "basename " & quoted form of filePath
  
  -- Split filename and extension
  set tid to AppleScript's text item delimiters
  set AppleScript's text item delimiters to "."
  set nameParts to text items of fileName
  
  if (count of nameParts) > 1 then
    set baseName to items 1 thru -2 of nameParts as text
    set fileExtension to item -1 of nameParts
  else
    set baseName to fileName
    set fileExtension to ""
  end if
  
  -- Restore text item delimiters
  set AppleScript's text item delimiters to tid
  
  return {name:baseName, extension:fileExtension}
end getFileInfo

-- Show dialog to select encryption method
on selectEncryptionMethod()
  set availableMethods to {"Disk Image (Built-in)", "OpenSSL (Portable)", "GPG (Requires Key)"}
  
  -- Check if OpenSSL and GPG are available
  set toolsAvailable to initialize()
  
  if not toolsAvailable's openssl then
    set availableMethods to {"Disk Image (Built-in)"}
  else if not toolsAvailable's gpg then
    set availableMethods to {"Disk Image (Built-in)", "OpenSSL (Portable)"}
  end if
  
  set selectedMethod to choose from list availableMethods with prompt "Select encryption method:" default items item 1 of availableMethods
  
  if selectedMethod is false then
    return "cancel"
  else
    set methodName to item 1 of selectedMethod
    
    if methodName is "Disk Image (Built-in)" then
      return "diskimage"
    else if methodName is "OpenSSL (Portable)" then
      return "openssl"
    else if methodName is "GPG (Requires Key)" then
      return "gpg"
    end if
  end if
end selectEncryptionMethod

-- Encrypt file with selected method
on encryptFile(filePath, encryptionMethod)
  -- Validate file exists
  set fileExists to do shell script "test -f " & quoted form of filePath & " && echo 'yes' || echo 'no'"
  if fileExists is "no" then
    return "Error: File does not exist: " & filePath
  end if
  
  -- Use default method if not specified
  if encryptionMethod is "" then
    set encryptionMethod to selectEncryptionMethod()
    if encryptionMethod is "cancel" then
      return "Encryption cancelled"
    end if
  end if
  
  -- Ask for password or recipient based on method
  if encryptionMethod is "diskimage" or encryptionMethod is "openssl" then
    -- Ask for password
    set pwPrompt to display dialog "Enter encryption password:" default answer "" with hidden answer buttons {"Cancel", "Generate", "Encrypt"} default button "Encrypt"
    
    if button returned of pwPrompt is "Cancel" then
      return "Encryption cancelled"
    else if button returned of pwPrompt is "Generate" then
      set encryptionPassword to generateSecurePassword(16)
      display dialog "Generated password (copy this somewhere safe):" default answer encryptionPassword buttons {"Cancel", "Use This Password"} default button "Use This Password"
      if button returned of result is "Cancel" then
        return "Encryption cancelled"
      end if
    else
      set encryptionPassword to text returned of pwPrompt
      if encryptionPassword is "" then
        return "Error: Password cannot be empty"
      end if
    end if
    
    -- Perform encryption
    if encryptionMethod is "diskimage" then
      return encryptWithDiskImage(filePath, "", encryptionPassword)
    else
      return encryptWithOpenSSL(filePath, "", encryptionPassword)
    end if
  else if encryptionMethod is "gpg" then
    -- Ask for GPG recipient
    set recipientPrompt to display dialog "Enter GPG recipient email:" default answer "" buttons {"Cancel", "Encrypt"} default button "Encrypt"
    
    if button returned of recipientPrompt is "Cancel" then
      return "Encryption cancelled"
    end if
    
    set recipientEmail to text returned of recipientPrompt
    if recipientEmail is "" then
      return "Error: Recipient email cannot be empty"
    end if
    
    return encryptWithGPG(filePath, "", recipientEmail)
  else
    return "Unknown encryption method: " & encryptionMethod
  end if
end encryptFile

-- Decrypt file with selected method
on decryptFile(filePath)
  -- Validate file exists
  set fileExists to do shell script "test -f " & quoted form of filePath & " && echo 'yes' || echo 'no'"
  if fileExists is "no" then
    return "Error: File does not exist: " & filePath
  end if
  
  -- Determine decryption method based on file extension
  set fileInfo to getFileInfo(filePath)
  set fileExtension to fileInfo's extension
  
  if fileExtension is "dmg" then
    -- Disk image decryption
    set pwPrompt to display dialog "Enter disk image password:" default answer "" with hidden answer buttons {"Cancel", "Decrypt"} default button "Decrypt"
    
    if button returned of pwPrompt is "Cancel" then
      return "Decryption cancelled"
    end if
    
    set decryptionPassword to text returned of pwPrompt
    if decryptionPassword is "" then
      return "Error: Password cannot be empty"
    end if
    
    return decryptFromDiskImage(filePath, "", decryptionPassword)
    
  else if fileExtension is "enc" then
    -- OpenSSL decryption
    set pwPrompt to display dialog "Enter OpenSSL decryption password:" default answer "" with hidden answer buttons {"Cancel", "Decrypt"} default button "Decrypt"
    
    if button returned of pwPrompt is "Cancel" then
      return "Decryption cancelled"
    end if
    
    set decryptionPassword to text returned of pwPrompt
    if decryptionPassword is "" then
      return "Error: Password cannot be empty"
    end if
    
    return decryptWithOpenSSL(filePath, "", decryptionPassword)
    
  else if fileExtension is "gpg" then
    -- GPG decryption (will prompt for passphrase if needed)
    return decryptWithGPG(filePath, "")
    
  else
    -- Ask user for decryption method
    set decryptionMethod to choose from list {"Disk Image", "OpenSSL", "GPG"} with prompt "Select decryption method for: " & filePath default items {"Disk Image"}
    
    if decryptionMethod is false then
      return "Decryption cancelled"
    end if
    
    set selectedMethod to item 1 of decryptionMethod
    
    if selectedMethod is "Disk Image" then
      set pwPrompt to display dialog "Enter disk image password:" default answer "" with hidden answer buttons {"Cancel", "Decrypt"} default button "Decrypt"
      
      if button returned of pwPrompt is "Cancel" then
        return "Decryption cancelled"
      end if
      
      set decryptionPassword to text returned of pwPrompt
      if decryptionPassword is "" then
        return "Error: Password cannot be empty"
      end if
      
      return decryptFromDiskImage(filePath, "", decryptionPassword)
      
    else if selectedMethod is "OpenSSL" then
      set pwPrompt to display dialog "Enter OpenSSL decryption password:" default answer "" with hidden answer buttons {"Cancel", "Decrypt"} default button "Decrypt"
      
      if button returned of pwPrompt is "Cancel" then
        return "Decryption cancelled"
      end if
      
      set decryptionPassword to text returned of pwPrompt
      if decryptionPassword is "" then
        return "Error: Password cannot be empty"
      end if
      
      return decryptWithOpenSSL(filePath, "", decryptionPassword)
      
    else if selectedMethod is "GPG" then
      return decryptWithGPG(filePath, "")
      
    end if
  end if
end decryptFile

-- Show the encryption/decryption menu
on showEncryptionMenu()
  set operation to choose from list {"Encrypt File", "Decrypt File", "Settings", "Cancel"} with prompt "File Encryption Utility:" default items {"Encrypt File"}
  
  if operation is false then
    return "Operation cancelled"
  else
    set selectedOperation to item 1 of operation
    
    if selectedOperation is "Encrypt File" then
      -- Ask user to select a file
      set chosenFile to (choose file with prompt "Select a file to encrypt:")
      return encryptFile(POSIX path of chosenFile, "")
      
    else if selectedOperation is "Decrypt File" then
      -- Ask user to select a file
      set chosenFile to (choose file with prompt "Select a file to decrypt:")
      return decryptFile(POSIX path of chosenFile)
      
    else if selectedOperation is "Settings" then
      return showSettingsMenu()
      
    else
      return "Operation cancelled"
    end if
  end if
end showEncryptionMenu

-- Show encryption settings menu
on showSettingsMenu()
  set settingOperation to choose from list {"Default Encryption Method", "Delete Original After Encryption", "Encryption Strength", "Back"} with prompt "Encryption Settings:" default items {"Default Encryption Method"}
  
  if settingOperation is false then
    return "Settings cancelled"
  else
    set selectedSetting to item 1 of settingOperation
    
    if selectedSetting is "Default Encryption Method" then
      set newMethod to choose from list {"diskimage", "openssl", "gpg"} with prompt "Select default encryption method:" default items {defaultEncryptionMethod}
      
      if newMethod is not false then
        set defaultEncryptionMethod to item 1 of newMethod
        return "Default encryption method set to: " & defaultEncryptionMethod
      end if
      
    else if selectedSetting is "Delete Original After Encryption" then
      set newValue to choose from list {"Yes", "No"} with prompt "Delete original files after encryption?" default items {if encryptDeleteOriginal then "Yes" else "No"}
      
      if newValue is not false then
        set encryptDeleteOriginal to item 1 of newValue is "Yes"
        return "Delete original setting: " & if encryptDeleteOriginal then "Yes" else "No"
      end if
      
    else if selectedSetting is "Encryption Strength" then
      set newStrength to choose from list {"aes-128", "aes-192", "aes-256"} with prompt "Select OpenSSL encryption strength:" default items {defaultEncryptionLevel}
      
      if newStrength is not false then
        set defaultEncryptionLevel to item 1 of newStrength
        return "Encryption strength set to: " & defaultEncryptionLevel
      end if
      
    end if
    
    return showEncryptionMenu()
  end if
end showSettingsMenu

-- Run the encryption utility menu
showEncryptionMenu()
```

This comprehensive file encryption and decryption script offers multiple secure methods to protect sensitive files:

1. **Built-in Disk Image Encryption**:
   - Creates encrypted disk images using macOS's native `hdiutil`
   - Password-protected with AES encryption
   - Cross-compatible with all macOS systems
   - Files appear as standard `.dmg` files

2. **OpenSSL Encryption**:
   - Uses industry-standard OpenSSL for portable encryption
   - Configurable encryption strength (AES-128, AES-192, AES-256)
   - Encrypted files can be opened on any system with OpenSSL
   - Creates `.enc` files that are compact and easily transferable

3. **GPG Encryption (Optional)**:
   - Public key encryption using GPG (if installed)
   - Recipient only needs your public key to receive encrypted files
   - No password sharing required
   - Ideal for secure file sharing between trusted parties

4. **Security Features**:
   - Option to delete original files after encryption
   - Built-in secure password generator
   - Option to save encryption settings
   - User-friendly menus for all operations

5. **Versatile Decryption**:
   - Automatic detection of encryption method based on file extension
   - Support for all three encryption formats
   - Intelligent handling of decryption parameters

The script includes a simple menu-driven interface that guides users through the encryption and decryption process, making it accessible even to those with limited technical knowledge.

For maximum security when using password-based methods (disk image or OpenSSL), the script offers a random password generator that creates strong, complex passwords.
