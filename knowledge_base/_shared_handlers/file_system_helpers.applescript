-- AppleScript File System Helper Handlers
-- Common file system operations for AppleScript
-- These can be included in other scripts as needed

-- Converts HFS path to POSIX path (for shell scripts)
on hfsPathToPOSIX(hfsPath)
  if hfsPath starts with "Macintosh HD:" then
    -- Strip volume name if present
    set hfsPath to text 14 thru -1 of hfsPath
  end if
  
  -- Handle paths with colons
  set posixPath to do shell script "echo " & quoted form of hfsPath & " | sed 's/:/\\//g' | sed 's/^/\\//' | sed 's/\\/$//'"
  return posixPath
end hfsPathToPOSIX

-- Converts POSIX path to HFS path
on posixPathToHFS(posixPath)
  set hfsPath to do shell script "echo " & quoted form of posixPath & " | sed 's/^\\///' | sed 's/\\//:/g'"
  return "Macintosh HD:" & hfsPath
end posixPathToHFS

-- Gets the extension of a file from its name
on getFileExtension(fileName)
  if fileName does not contain "." then return ""
  
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to "."
  set fileNameParts to text items of fileName
  set extension to item -1 of fileNameParts
  set AppleScript's text item delimiters to oldDelimiters
  
  return extension
end getFileExtension

-- Creates a directory at the specified POSIX path if it doesn't exist
on createDirectory(posixPath)
  try
    do shell script "mkdir -p " & quoted form of posixPath
    return true
  on error errMsg
    return false
  end try
end createDirectory

-- Checks if a file exists at the specified POSIX path
on fileExists(posixPath)
  try
    do shell script "test -e " & quoted form of posixPath & " && echo 'exists' || echo 'not exists'"
    if result is "exists" then
      return true
    else
      return false
    end if
  on error
    return false
  end try
end fileExists

-- Reads the contents of a text file at the specified POSIX path
on readTextFile(posixPath)
  try
    set fileContents to do shell script "cat " & quoted form of posixPath
    return fileContents
  on error errMsg
    error "Error reading file: " & errMsg
  end try
end readTextFile

-- Writes text to a file at the specified POSIX path
on writeTextFile(posixPath, textContent)
  try
    do shell script "echo " & quoted form of textContent & " > " & quoted form of posixPath
    return true
  on error errMsg
    error "Error writing file: " & errMsg
  end try
end writeTextFile

-- Gets file modification date as date object
on getFileModDate(posixPath)
  try
    set modDateString to do shell script "stat -f %Sm -t '%Y-%m-%d %H:%M:%S' " & quoted form of posixPath
    
    set yearStr to text 1 thru 4 of modDateString
    set monthStr to text 6 thru 7 of modDateString
    set dayStr to text 9 thru 10 of modDateString
    set hourStr to text 12 thru 13 of modDateString
    set minuteStr to text 15 thru 16 of modDateString
    set secondStr to text 18 thru 19 of modDateString
    
    set fileDate to current date
    set year of fileDate to yearStr as integer
    set month of fileDate to monthStr as integer
    set day of fileDate to dayStr as integer
    set hours of fileDate to hourStr as integer
    set minutes of fileDate to minuteStr as integer
    set seconds of fileDate to secondStr as integer
    
    return fileDate
  on error errMsg
    error "Error getting file modification date: " & errMsg
  end try
end getFileModDate