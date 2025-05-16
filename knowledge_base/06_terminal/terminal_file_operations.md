---
title: 'Terminal: Direct File Operations'
id: terminal_file_operations
category: 06_terminal
description: >-
  Performs common file operations directly through terminal without requiring
  manual command entry, supporting drag-and-drop paths.
keywords:
  - terminal
  - file
  - operations
  - copy
  - move
  - delete
  - create
  - extract
  - compress
  - chmod
  - permissions
language: applescript
argumentsPrompt: >-
  Expects inputData with: { "operation": "copy", "move", "delete", "create",
  "extract", "compress", "chmod", "source": "/path/to/source", "destination":
  "/path/to/destination", "content": "file content if creating", "permissions":
  "755 for chmod" }
isComplex: true
---

This script performs common file operations directly through the terminal environment, making it easy to manipulate files without having to manually type complex commands. It supports a variety of operations including copying, moving, deleting, creating files, extracting archives, compressing directories, and changing file permissions.

**Features:**
- Execute common file operations through terminal commands
- Support for drag-and-drop paths from Finder
- Handles spaces and special characters in file paths
- Provides detailed feedback on operation results
- Includes safety checks before destructive operations
- Works with any terminal application that can execute shell commands

```applescript
on runWithInput(inputData, legacyArguments)
    set defaultOperation to ""
    set defaultSource to ""
    set defaultDestination to ""
    set defaultContent to ""
    set defaultPermissions to ""
    
    -- Parse input parameters
    set theOperation to defaultOperation
    set theSource to defaultSource
    set theDestination to defaultDestination
    set theContent to defaultContent
    set thePermissions to defaultPermissions
    
    if inputData is not missing value then
        if inputData contains {operation:""} then
            set theOperation to operation of inputData
            --MCP_INPUT:operation
        end if
        if inputData contains {source:""} then
            set theSource to source of inputData
            --MCP_INPUT:source
        end if
        if inputData contains {destination:""} then
            set theDestination to destination of inputData
            --MCP_INPUT:destination
        end if
        if inputData contains {content:""} then
            set theContent to content of inputData
            --MCP_INPUT:content
        end if
        if inputData contains {permissions:""} then
            set thePermissions to permissions of inputData
            --MCP_INPUT:permissions
        end if
    end if
    
    -- Validate required parameters based on operation
    if theOperation is "" then
        return "Error: No operation specified. Valid operations are: copy, move, delete, create, extract, compress, chmod."
    end if
    
    -- Convert operation to lowercase
    set theOperation to my toLower(theOperation)
    
    -- Validate operation
    set validOperations to {"copy", "move", "delete", "create", "extract", "compress", "chmod"}
    if theOperation is not in validOperations then
        return "Error: Invalid operation '" & theOperation & "'. Valid operations are: " & my joinList(validOperations, ", ") & "."
    end if
    
    -- Validate source path for operations that require it
    if theOperation is in {"copy", "move", "delete", "extract", "compress", "chmod"} and theSource is "" then
        return "Error: Source path is required for '" & theOperation & "' operation."
    end if
    
    -- Validate destination path for operations that require it
    if theOperation is in {"copy", "move", "compress"} and theDestination is "" then
        return "Error: Destination path is required for '" & theOperation & "' operation."
    end if
    
    -- Execute the requested operation
    if theOperation is "copy" then
        return copyFiles(theSource, theDestination)
    else if theOperation is "move" then
        return moveFiles(theSource, theDestination)
    else if theOperation is "delete" then
        return deleteFiles(theSource)
    else if theOperation is "create" then
        return createFile(theDestination, theContent)
    else if theOperation is "extract" then
        return extractArchive(theSource, theDestination)
    else if theOperation is "compress" then
        return compressFiles(theSource, theDestination)
    else if theOperation is "chmod" then
        return changePermissions(theSource, thePermissions)
    end if
end runWithInput

-- Function to copy files or directories
on copyFiles(sourcePath, destPath)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Source path does not exist: " & sourcePath
    end if
    
    -- Check if source is a file or directory
    set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
    
    -- Construct the appropriate cp command
    set cpCommand to "cp "
    
    if sourceType is "directory" then
        set cpCommand to cpCommand & "-R " -- Recursive for directories
    end if
    
    -- Add source and destination
    set cpCommand to cpCommand & quoted form of sourcePath & " " & quoted form of destPath
    
    -- Execute the command
    try
        do shell script cpCommand
        
        if sourceType is "directory" then
            return "Successfully copied directory from " & sourcePath & " to " & destPath
        else
            return "Successfully copied file from " & sourcePath & " to " & destPath
        end if
    on error errMsg
        return "Error copying: " & errMsg
    end try
end copyFiles

-- Function to move files or directories
on moveFiles(sourcePath, destPath)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Source path does not exist: " & sourcePath
    end if
    
    -- Check if source is a file or directory
    set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
    
    -- Execute the move command
    try
        do shell script "mv " & quoted form of sourcePath & " " & quoted form of destPath
        
        if sourceType is "directory" then
            return "Successfully moved directory from " & sourcePath & " to " & destPath
        else
            return "Successfully moved file from " & sourcePath & " to " & destPath
        end if
    on error errMsg
        return "Error moving: " & errMsg
    end try
end moveFiles

-- Function to delete files or directories
on deleteFiles(sourcePath)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Path does not exist: " & sourcePath
    end if
    
    -- Check if source is a file or directory
    set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
    
    -- Ask for confirmation before deleting
    set confirmMessage to "Are you sure you want to delete this " & sourceType & "?"
    set confirmButton to "Delete"
    
    if sourceType is "directory" then
        -- Check if directory is empty
        set dirEmpty to do shell script "[ \"$(ls -A " & quoted form of sourcePath & ")\" ] && echo 'not empty' || echo 'empty'"
        
        if dirEmpty is "not empty" then
            set confirmMessage to "Warning: The directory is not empty. Are you sure you want to delete it and all its contents?"
            set confirmButton to "Delete All"
        end if
    end if
    
    display dialog confirmMessage buttons {"Cancel", confirmButton} default button "Cancel" with icon caution
    
    -- Construct the appropriate rm command
    set rmCommand to "rm "
    
    if sourceType is "directory" then
        set rmCommand to rmCommand & "-rf " -- Recursive and force for directories
    else
        set rmCommand to rmCommand & "-f " -- Force for files
    end if
    
    -- Add source path
    set rmCommand to rmCommand & quoted form of sourcePath
    
    -- Execute the command
    try
        do shell script rmCommand
        
        if sourceType is "directory" then
            return "Successfully deleted directory: " & sourcePath
        else
            return "Successfully deleted file: " & sourcePath
        end if
    on error errMsg
        return "Error deleting: " & errMsg
    end try
end deleteFiles

-- Function to create a new file with optional content
on createFile(filePath, fileContent)
    if filePath is "" then
        return "Error: Destination path is required for file creation."
    end if
    
    -- Check if file already exists
    set fileExists to do shell script "[ -e " & quoted form of filePath & " ] && echo 'exists' || echo 'not exists'"
    
    if fileExists is "exists" then
        set overwriteResponse to display dialog "File already exists. Do you want to overwrite it?" buttons {"Cancel", "Overwrite"} default button "Cancel" with icon caution
        
        if button returned of overwriteResponse is "Cancel" then
            return "File creation cancelled."
        end if
    end if
    
    -- Create the parent directory if it doesn't exist
    set parentDir to do shell script "dirname " & quoted form of filePath
    do shell script "mkdir -p " & quoted form of parentDir
    
    -- Create the file with content
    try
        if fileContent is not "" then
            -- Write content to the file
            do shell script "cat > " & quoted form of filePath & " << 'EOFMARKER'
" & fileContent & "
EOFMARKER"
        else
            -- Create an empty file
            do shell script "touch " & quoted form of filePath
        end if
        
        return "Successfully created file: " & filePath
    on error errMsg
        return "Error creating file: " & errMsg
    end try
end createFile

-- Function to extract various archive formats
on extractArchive(archivePath, extractDir)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of archivePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Archive file does not exist: " & archivePath
    end if
    
    -- Determine archive type based on extension
    set archiveExtension to my getFileExtension(archivePath)
    set archiveExtension to my toLower(archiveExtension)
    
    -- Set default extract directory if not provided
    if extractDir is "" then
        set extractDir to do shell script "dirname " & quoted form of archivePath
    end if
    
    -- Create the extract directory if it doesn't exist
    do shell script "mkdir -p " & quoted form of extractDir
    
    -- Construct and execute the appropriate extract command based on file type
    set extractCommand to ""
    
    if archiveExtension is "zip" then
        set extractCommand to "unzip -o " & quoted form of archivePath & " -d " & quoted form of extractDir
    else if archiveExtension is in {"tar", "tgz", "gz", "bz2", "xz"} then
        set extractCommand to "tar -xf " & quoted form of archivePath & " -C " & quoted form of extractDir
    else if archiveExtension is "rar" then
        -- Check if unrar is installed
        try
            do shell script "which unrar"
            set extractCommand to "unrar x " & quoted form of archivePath & " " & quoted form of extractDir
        on error
            return "Error: Unrar is not installed. Please install it using Homebrew: brew install unrar"
        end try
    else if archiveExtension is "7z" then
        -- Check if 7zip is installed
        try
            do shell script "which 7z"
            set extractCommand to "7z x " & quoted form of archivePath & " -o" & quoted form of extractDir
        on error
            return "Error: 7zip is not installed. Please install it using Homebrew: brew install p7zip"
        end try
    else
        return "Error: Unsupported archive format: " & archiveExtension & ". Supported formats are: zip, tar, tgz, gz, bz2, xz, rar, 7z."
    end if
    
    -- Execute extraction command
    try
        do shell script extractCommand
        return "Successfully extracted " & archivePath & " to " & extractDir
    on error errMsg
        return "Error extracting archive: " & errMsg
    end try
end extractArchive

-- Function to compress files or directories
on compressFiles(sourcePath, destArchive)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of sourcePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Source path does not exist: " & sourcePath
    end if
    
    -- Determine archive type based on destination extension
    set archiveExtension to my getFileExtension(destArchive)
    set archiveExtension to my toLower(archiveExtension)
    
    -- Get source basename for archive creation
    set sourceBasename to do shell script "basename " & quoted form of sourcePath
    
    -- Construct and execute the appropriate compress command based on file type
    set compressCommand to ""
    
    if archiveExtension is "zip" then
        -- Check if source is a directory
        set sourceType to do shell script "[ -d " & quoted form of sourcePath & " ] && echo 'directory' || echo 'file'"
        
        if sourceType is "directory" then
            -- For directories, we need to change to the parent dir and zip from there
            set parentDir to do shell script "dirname " & quoted form of sourcePath
            set compressCommand to "cd " & quoted form of parentDir & " && zip -r " & quoted form of destArchive & " " & quoted form of sourceBasename
        else
            -- For files, we can zip directly
            set compressCommand to "zip -j " & quoted form of destArchive & " " & quoted form of sourcePath
        end if
    else if archiveExtension is "tar" then
        set compressCommand to "tar -cf " & quoted form of destArchive & " -C " & quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & quoted form of sourceBasename
    else if archiveExtension is in {"tgz", "tar.gz"} then
        set compressCommand to "tar -czf " & quoted form of destArchive & " -C " & quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & quoted form of sourceBasename
    else if archiveExtension is in {"tbz2", "tar.bz2"} then
        set compressCommand to "tar -cjf " & quoted form of destArchive & " -C " & quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & quoted form of sourceBasename
    else if archiveExtension is in {"txz", "tar.xz"} then
        set compressCommand to "tar -cJf " & quoted form of destArchive & " -C " & quoted form of (do shell script "dirname " & quoted form of sourcePath) & " " & quoted form of sourceBasename
    else if archiveExtension is "7z" then
        -- Check if 7zip is installed
        try
            do shell script "which 7z"
            set compressCommand to "7z a " & quoted form of destArchive & " " & quoted form of sourcePath
        on error
            return "Error: 7zip is not installed. Please install it using Homebrew: brew install p7zip"
        end try
    else
        return "Error: Unsupported archive format: " & archiveExtension & ". Supported formats are: zip, tar, tgz, tar.gz, tbz2, tar.bz2, txz, tar.xz, 7z."
    end if
    
    -- Execute compression command
    try
        do shell script compressCommand
        return "Successfully compressed " & sourcePath & " to " & destArchive
    on error errMsg
        return "Error compressing: " & errMsg
    end try
end compressFiles

-- Function to change file permissions
on changePermissions(filePath, permissions)
    -- Check if source exists
    set sourceExists to do shell script "[ -e " & quoted form of filePath & " ] && echo 'exists' || echo 'not exists'"
    
    if sourceExists is "not exists" then
        return "Error: Path does not exist: " & filePath
    end if
    
    -- Validate permissions format
    if permissions is "" then
        return "Error: Permissions must be specified (e.g., 755, 644, etc.)."
    end if
    
    -- Basic validation of permission format
    try
        set permValue to permissions as integer
        if permValue < 0 or permValue > 777 then
            return "Error: Permission value must be between 0 and 777."
        end if
    on error
        return "Error: Invalid permission format. Use octal notation (e.g., 755, 644)."
    end try
    
    -- Execute chmod command
    try
        do shell script "chmod " & permissions & " " & quoted form of filePath
        
        -- Check if it's a directory and user wants to apply recursively
        set isDir to do shell script "[ -d " & quoted form of filePath & " ] && echo 'yes' || echo 'no'"
        
        if isDir is "yes" then
            set recursiveResponse to display dialog "Do you want to apply these permissions recursively to all files and subdirectories?" buttons {"No", "Yes"} default button "No"
            
            if button returned of recursiveResponse is "Yes" then
                do shell script "chmod -R " & permissions & " " & quoted form of filePath
                return "Successfully changed permissions recursively to " & permissions & " for: " & filePath
            end if
        end if
        
        return "Successfully changed permissions to " & permissions & " for: " & filePath
    on error errMsg
        return "Error changing permissions: " & errMsg
    end try
end changePermissions

-- Helper function to get file extension
on getFileExtension(filePath)
    set fileName to do shell script "basename " & quoted form of filePath
    
    -- Check for double extensions like .tar.gz
    if fileName ends with ".tar.gz" then
        return "tar.gz"
    else if fileName ends with ".tar.bz2" then
        return "tar.bz2"
    else if fileName ends with ".tar.xz" then
        return "tar.xz"
    end if
    
    -- Regular extension
    if fileName contains "." then
        set AppleScript's text item delimiters to "."
        set textItems to text items of fileName
        set lastItem to item (count of textItems) of textItems
        set AppleScript's text item delimiters to ""
        return lastItem
    else
        return ""
    end if
end getFileExtension

-- Helper function to join list items with a delimiter
on joinList(theList, theDelimiter)
    set resultText to ""
    set itemCount to count of theList
    
    repeat with i from 1 to itemCount
        set resultText to resultText & item i of theList
        if i < itemCount then
            set resultText to resultText & theDelimiter
        end if
    end repeat
    
    return resultText
end joinList

-- Helper function to convert text to lowercase
on toLower(theText)
    set lowercaseText to ""
    repeat with i from 1 to length of theText
        set currentChar to character i of theText
        if ASCII number of currentChar ≥ 65 and ASCII number of currentChar ≤ 90 then
            -- Convert uppercase letter to lowercase
            set lowercaseText to lowercaseText & (ASCII character ((ASCII number of currentChar) + 32))
        else
            -- Keep the character as is
            set lowercaseText to lowercaseText & currentChar
        end if
    end repeat
    return lowercaseText
end toLower
```

## Direct File Operations from Terminal

Managing files is a common task in terminal environments. This script provides a simplified interface to perform common file operations without having to remember complex command-line syntax, while still leveraging the power and flexibility of terminal commands.

### Supported Operations

#### 1. Copy Files and Directories

Copies files or directories from a source location to a destination:

- Automatically determines if the source is a file or directory
- Uses the appropriate command-line flags for recursive copying when needed
- Handles spaces and special characters in file paths correctly

**Example Use Case**: Backing up configuration files or creating copies of project directories.

#### 2. Move Files and Directories

Moves or renames files and directories:

- Works with both single files and entire directory structures
- Preserves file attributes during the move operation
- Can be used for both moving and renaming

**Example Use Case**: Organizing files into different directories or renaming files with consistent patterns.

#### 3. Delete Files and Directories

Safely removes files or directories:

- Asks for confirmation before deletion
- Provides extra warnings for non-empty directories
- Uses appropriate flags for different types of deletions

**Example Use Case**: Cleaning up temporary files or removing obsolete project directories.

#### 4. Create Files

Creates new files with optional content:

- Creates parent directories if they don't exist
- Allows specifying initial file content
- Prompts for confirmation if the file already exists

**Example Use Case**: Creating configuration files, templates, or placeholder files.

#### 5. Extract Archives

Extracts various archive formats:

- Supports common formats: zip, tar, tar.gz, tar.bz2, tar.xz, rar, 7z
- Automatically determines the appropriate extraction command
- Creates the destination directory if it doesn't exist

**Example Use Case**: Unpacking downloaded software, extracting backup archives, or working with compressed data sets.

#### 6. Compress Files and Directories

Creates compressed archives in various formats:

- Supports creating zip, tar, tar.gz, tar.bz2, tar.xz, and 7z archives
- Automatically adjusts compression commands based on the source type
- Uses efficient compression methods for different archive formats

**Example Use Case**: Creating distribution packages, compressing log files, or preparing files for transfer.

#### 7. Change File Permissions

Modifies file or directory permissions:

- Uses chmod with octal notation (e.g., 755, 644)
- Offers optional recursive permission changes for directories
- Validates permission values before applying

**Example Use Case**: Setting appropriate access permissions for scripts, configuration files, or web content.

### Key Benefits

#### 1. Simplified Syntax

This script removes the need to remember complex command-line flags and syntax:

- No need to recall the specific flags for recursive operations
- Don't worry about properly escaping spaces and special characters
- Consistent interface across different operations

#### 2. Safety Features

Built-in safeguards help prevent accidental data loss:

- Confirmation dialogs for potentially destructive operations
- Validation of inputs before commands are executed
- Descriptive error messages when operations fail

#### 3. Workflow Integration

The script can be integrated into broader automation workflows:

- Chain multiple file operations together
- Incorporate file operations into larger scripts
- Use with other terminal automation tools

### Usage with Drag and Drop

One particularly useful feature is the ability to use this script with drag-and-drop file paths:

1. Drag a file from Finder into the terminal to get its path
2. Incorporate that path into your operation parameters
3. Execute the operation without having to manually type long file paths

### Example Usage Patterns

#### Backing Up Configuration Files

```json
{
  "operation": "copy",
  "source": "~/.config/",
  "destination": "~/backup/configs/"
}
```

This makes a backup copy of all configuration files.

#### Organizing Downloaded Files

```json
{
  "operation": "move",
  "source": "~/Downloads/*.pdf",
  "destination": "~/Documents/PDFs/"
}
```

This moves all PDF files from Downloads to a dedicated PDFs folder.

#### Creating a Project Structure

```json
{
  "operation": "create",
  "destination": "~/Projects/newapp/README.md",
  "content": "# New Application\n\nThis is a new project."
}
```

This creates a new README file in a project directory.

#### Archiving Old Projects

```json
{
  "operation": "compress",
  "source": "~/Projects/oldproject/",
  "destination": "~/Archives/oldproject.tar.gz"
}
```

This compresses an entire project directory into a tar.gz archive.

### Advanced Use Cases

#### File Permission Management for Web Projects

```json
{
  "operation": "chmod",
  "source": "~/Sites/mywebsite/cgi-bin/",
  "permissions": "755"
}
```

This sets appropriate permissions for CGI scripts.

#### Batch Extract Multiple Archives

For more complex scenarios, you can call this script multiple times:

```applescript
repeat with archivePath in {"~/Downloads/archive1.zip", "~/Downloads/archive2.zip", "~/Downloads/archive3.zip"}
  my runWithInput({operation:"extract", source:archivePath, destination:"~/extracted/"})
end repeat
```

This extracts multiple archives to the same destination folder.
