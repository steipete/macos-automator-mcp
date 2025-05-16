---
title: Folder Cleanup Operations
category: 03_file_system_and_finder
id: folder_cleanup_operations
description: Comprehensive folder cleanup script to organize and maintain folder structures, including removing empty directories, sorting files by type, and cleaning up old files.
language: applescript
keywords: [cleanup, organize, folders, files, sort, remove, empty, duplicates]
---

# Folder Cleanup Operations

This script provides functionality to clean up and organize folders on macOS. It includes operations to:

1. Remove empty directories
2. Find and remove duplicate files
3. Organize files by type
4. Clean up files older than a specified date
5. Remove temporary files

## Usage

The script can accept a folder path and specific cleanup operation as input, or can prompt the user for these details.

```applescript
-- Folder Cleanup Operations Script
-- A comprehensive tool for organizing and cleaning up folders

on run
	-- When run without arguments, show a dialog to select folder and options
	try
		set targetFolder to choose folder with prompt "Select a folder to clean up:"
		
		set cleanupOptions to {"Remove empty folders", "Find and remove duplicates", "Organize files by type", "Clean up old files", "Remove temporary files"}
		
		set selectedOption to choose from list cleanupOptions with prompt "Select cleanup operation:" default items {"Remove empty folders"}
		
		if selectedOption is false then
			return "Operation cancelled."
		end if
		
		set selectedOption to item 1 of selectedOption
		
		if selectedOption is "Remove empty folders" then
			return removeEmptyFolders(targetFolder)
		else if selectedOption is "Find and remove duplicates" then
			return findAndRemoveDuplicates(targetFolder)
		else if selectedOption is "Organize files by type" then
			return organizeFilesByType(targetFolder)
		else if selectedOption is "Clean up old files" then
			set daysOld to text returned of (display dialog "Remove files older than how many days?" default answer "30")
			return cleanupOldFiles(targetFolder, daysOld as integer)
		else if selectedOption is "Remove temporary files" then
			return removeTemporaryFiles(targetFolder)
		end if
		
	on error errMsg
		return "Error: " & errMsg
	end try
end run

-- Handler for processing input parameters when running with MCP
on processMCPParameters(inputParams)
	set folderPath to "--MCP_INPUT:folderPath"
	set operation to "--MCP_INPUT:operation"
	set olderThan to "--MCP_INPUT:olderThan"
	
	if folderPath is equal to "" then
		set folderPath to choose folder with prompt "Select a folder to clean up:"
	end if
	
	if operation is equal to "removeEmpty" then
		return removeEmptyFolders(folderPath)
	else if operation is equal to "removeDuplicates" then
		return findAndRemoveDuplicates(folderPath)
	else if operation is equal to "organizeByType" then
		return organizeFilesByType(folderPath)
	else if operation is equal to "cleanupOld" then
		if olderThan is equal to "" then
			set olderThan to 30
		end if
		return cleanupOldFiles(folderPath, olderThan as integer)
	else if operation is equal to "removeTemp" then
		return removeTemporaryFiles(folderPath)
	else
		return "Invalid operation specified. Valid operations: removeEmpty, removeDuplicates, organizeByType, cleanupOld, removeTemp"
	end if
end processMCPParameters

-- Remove empty folders recursively
on removeEmptyFolders(theFolder)
	set emptyFoldersCount to 0
	set removedFoldersCount to 0
	
	tell application "Finder"
		try
			-- Get all folders in the target folder
			set allFolders to every folder of theFolder
			
			-- Process each subfolder first (depth-first recursion)
			repeat with aFolder in allFolders
				set folderResult to removeEmptyFolders(aFolder)
				set emptyFoldersCount to emptyFoldersCount + (item 1 of folderResult)
				set removedFoldersCount to removedFoldersCount + (item 2 of folderResult)
			end repeat
			
			-- Check if current folder is empty after processing subfolders
			set folderItems to every item of theFolder
			if count of folderItems is 0 then
				set emptyFoldersCount to emptyFoldersCount + 1
				
				-- Ask for confirmation before deleting
				set folderName to name of theFolder
				set shouldDelete to button returned of (display dialog "Empty folder found: " & folderName & ". Delete it?" buttons {"Skip", "Delete"} default button "Delete")
				
				if shouldDelete is "Delete" then
					delete theFolder
					set removedFoldersCount to removedFoldersCount + 1
				end if
			end if
			
			return {emptyFoldersCount, removedFoldersCount}
		on error errMsg
			log "Error processing folder: " & errMsg
			return {emptyFoldersCount, removedFoldersCount}
		end try
	end tell
end removeEmptyFolders

-- Find and remove duplicate files based on content (MD5 hash)
on findAndRemoveDuplicates(theFolder)
	-- Create a temporary script to calculate MD5 hashes
	set tempScript to "#!/bin/bash
for file in \"$@\"; do
  if [ -f \"$file\" ]; then
    md5=$(md5 -q \"$file\")
    echo \"$md5:$file\"
  fi
done"
	
	-- Save the script to a temporary file
	set tempScriptFile to (path to temporary items as text) & "md5calc.sh"
	do shell script "echo '" & tempScript & "' > " & quoted form of POSIX path of tempScriptFile & " && chmod +x " & quoted form of POSIX path of tempScriptFile
	
	tell application "Finder"
		-- Get all files in the folder and subfolders
		set allFiles to {}
		my findAllFiles(theFolder, allFiles)
		
		-- Convert file references to POSIX paths
		set filePaths to {}
		repeat with aFile in allFiles
			set end of filePaths to POSIX path of (aFile as text)
		end repeat
		
		-- Calculate MD5 hashes
		set fileHashes to {}
		set batchSize to 50 -- Process files in batches to avoid command line length issues
		set fileCount to count of filePaths
		set batchCount to (fileCount + batchSize - 1) div batchSize
		
		repeat with i from 1 to batchCount
			set startIndex to (i - 1) * batchSize + 1
			set endIndex to min(i * batchSize, fileCount)
			set batchPaths to items startIndex thru endIndex of filePaths
			
			set filePathsString to ""
			repeat with aPath in batchPaths
				set filePathsString to filePathsString & " " & quoted form of aPath
			end repeat
			
			set hashOutput to do shell script POSIX path of tempScriptFile & filePathsString
			set hashLines to paragraphs of hashOutput
			
			repeat with aLine in hashLines
				if aLine is not "" then
					set hashParts to my splitString(aLine, ":")
					set theHash to item 1 of hashParts
					set thePath to item 2 of hashParts
					set end of fileHashes to {hash:theHash, path:thePath}
				end if
			end repeat
		end repeat
		
		-- Find duplicates
		set duplicateGroups to {}
		set processedHashes to {}
		
		repeat with i from 1 to (count of fileHashes)
			set fileInfo to item i of fileHashes
			set currentHash to hash of fileInfo
			
			if currentHash is not in processedHashes then
				set duplicateFiles to {}
				
				-- Find all files with the same hash
				repeat with j from i to (count of fileHashes)
					set compareInfo to item j of fileHashes
					if hash of compareInfo is currentHash then
						set end of duplicateFiles to path of compareInfo
					end if
				end repeat
				
				-- If we found duplicates, add them to our groups
				if (count of duplicateFiles) > 1 then
					set end of duplicateGroups to duplicateFiles
				end if
				
				set end of processedHashes to currentHash
			end if
		end repeat
		
		-- Clean up temporary script
		do shell script "rm " & quoted form of POSIX path of tempScriptFile
		
		-- Report findings and ask what to do
		set duplicateCount to count of duplicateGroups
		if duplicateCount is 0 then
			return "No duplicate files found."
		else
			set reportText to "Found " & duplicateCount & " groups of duplicate files:

"
			set removedCount to 0
			
			-- Process each group of duplicates
			repeat with i from 1 to duplicateCount
				set duplicateFiles to item i of duplicateGroups
				set groupSize to count of duplicateFiles
				
				set groupText to "Group " & i & " (" & groupSize & " duplicates):
"
				repeat with j from 1 to groupSize
					set groupText to groupText & "  " & j & ". " & item j of duplicateFiles & "
"
				end repeat
				
				set reportText to reportText & groupText & "
"
				
				-- Ask what to do with this group
				set actionMessage to "Group " & i & " of " & duplicateCount & ": Keep which file? (1-" & groupSize & ", or 'All' to keep all)"
				set userResponse to text returned of (display dialog actionMessage default answer "1")
				
				if userResponse is not "All" then
					try
						set keepIndex to userResponse as integer
						if keepIndex ≥ 1 and keepIndex ≤ groupSize then
							-- Remove all files except the one to keep
							repeat with j from 1 to groupSize
								if j is not keepIndex then
									set fileToRemove to item j of duplicateFiles
									do shell script "rm " & quoted form of fileToRemove
									set removedCount to removedCount + 1
								end if
							end repeat
						end if
					on error
						-- Invalid response, keep all files in this group
					end try
				end if
			end repeat
			
			return "Removed " & removedCount & " duplicate files."
		end if
	end tell
end findAndRemoveDuplicates

-- Recursive helper to find all files in folder and subfolders
on findAllFiles(theFolder, fileList)
	tell application "Finder"
		set folderItems to every item of theFolder
		repeat with anItem in folderItems
			if class of anItem is file then
				set end of fileList to anItem
			else if class of anItem is folder then
				my findAllFiles(anItem, fileList)
			end if
		end repeat
	end tell
end findAllFiles

-- Helper function to split strings
on splitString(theString, theDelimiter)
	set oldDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theArray to every text item of theString
	set AppleScript's text item delimiters to oldDelimiters
	return theArray
end splitString

-- Organize files by type into subfolders
on organizeFilesByType(theFolder)
	set fileTypes to {¬
		{extensions:{"jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic"}, folder:"Images"}, ¬
		{extensions:{"mp3", "m4a", "wav", "aiff", "aac", "flac"}, folder:"Audio"}, ¬
		{extensions:{"mp4", "mov", "avi", "mkv", "m4v", "wmv"}, folder:"Videos"}, ¬
		{extensions:{"doc", "docx", "pdf", "txt", "rtf", "pages", "odt"}, folder:"Documents"}, ¬
		{extensions:{"xls", "xlsx", "numbers", "csv"}, folder:"Spreadsheets"}, ¬
		{extensions:{"zip", "rar", "7z", "tar", "gz", "dmg"}, folder:"Archives"}, ¬
		{extensions:{"app", "exe", "msi", "pkg", "dmg"}, folder:"Applications"}, ¬
		{extensions:{"html", "css", "js", "php", "xml", "json"}, folder:"Web"}, ¬
		{extensions:{"c", "cpp", "h", "java", "py", "rb", "pl", "swift"}, folder:"Code"} ¬
	}
	
	set totalMoved to 0
	set skippedCount to 0
	
	tell application "Finder"
		-- Create the necessary folders if they don't exist
		repeat with typeInfo in fileTypes
			set folderName to folder of typeInfo
			if not (exists folder folderName of theFolder) then
				make new folder at theFolder with properties {name:folderName}
			end if
		end repeat
		
		-- Create an "Other" folder for unclassified files
		if not (exists folder "Other" of theFolder) then
			make new folder at theFolder with properties {name:"Other"}
		end if
		
		-- Get all files in the current folder (not recursive)
		set allFiles to every file of theFolder
		repeat with aFile in allFiles
			set wasProcessed to false
			set fileExtension to name extension of aFile
			
			if fileExtension is not "" then
				-- Try to find a matching category
				repeat with typeInfo in fileTypes
					set extList to extensions of typeInfo
					set categoryFolder to folder of typeInfo
					
					if fileExtension is in extList then
						-- Move the file to appropriate folder
						set targetFolder to folder categoryFolder of theFolder
						set wasProcessed to true
						
						try
							move aFile to targetFolder
							set totalMoved to totalMoved + 1
						on error
							set skippedCount to skippedCount + 1
						end try
						
						exit repeat
					end if
				end repeat
			end if
			
			-- If no category matched, move to "Other"
			if not wasProcessed then
				try
					move aFile to folder "Other" of theFolder
					set totalMoved to totalMoved + 1
				on error
					set skippedCount to skippedCount + 1
				end try
			end if
		end repeat
	end tell
	
	return "Organized " & totalMoved & " files by type. Skipped " & skippedCount & " files."
end organizeFilesByType

-- Clean up files older than specified number of days
on cleanupOldFiles(theFolder, daysOld)
	set currentDate to current date
	set cutoffDate to currentDate - (daysOld * days)
	
	set deletedCount to 0
	set filesFound to 0
	
	tell application "Finder"
		-- Get all files in the folder and subfolders
		set allFiles to {}
		my findAllFiles(theFolder, allFiles)
		
		repeat with aFile in allFiles
			set fileModDate to modification date of aFile
			if fileModDate < cutoffDate then
				set filesFound to filesFound + 1
				
				-- Get relative path for display
				set filePath to aFile as text
				set folderPath to theFolder as text
				set displayPath to text 1 thru (length of folderPath) of filePath
				if displayPath is folderPath then
					set displayPath to text ((length of folderPath) + 1) thru (length of filePath) of filePath
				else
					set displayPath to filePath
				end if
				
				-- Ask for confirmation
				set confirmMessage to "Delete file older than " & daysOld & " days?
" & displayPath & "
Modified: " & fileModDate
				set userChoice to button returned of (display dialog confirmMessage buttons {"Skip", "Delete"} default button "Skip")
				
				if userChoice is "Delete" then
					delete aFile
					set deletedCount to deletedCount + 1
				end if
			end if
		end repeat
	end tell
	
	return "Found " & filesFound & " files older than " & daysOld & " days. Deleted " & deletedCount & " files."
end cleanupOldFiles

-- Remove temporary and cache files
on removeTemporaryFiles(theFolder)
	set tempExtensions to {"tmp", "temp", "bak", "log", "cache", "DS_Store"}
	set tempPatterns to {"~$*", "*.swp", "*.tmp", "Thumbs.db", ".Spotlight-*", "._.Trashes", ".fseventsd", "*.part"}
	
	set deletedCount to 0
	set skippedCount to 0
	
	tell application "Finder"
		-- Get all files in the folder and subfolders
		set allFiles to {}
		my findAllFiles(theFolder, allFiles)
		
		-- Process each file
		repeat with aFile in allFiles
			set fileName to name of aFile
			set fileExt to name extension of aFile
			set shouldDelete to false
			
			-- Check if it matches any of our temp extensions
			if fileExt is in tempExtensions then
				set shouldDelete to true
			else
				-- Check if it matches any pattern
				repeat with aPattern in tempPatterns
					if my matchesPattern(fileName, aPattern) then
						set shouldDelete to true
						exit repeat
					end if
				end repeat
			end if
			
			-- If it's a temp file, ask to delete
			if shouldDelete then
				set confirmMessage to "Delete temporary file?
" & (aFile as text)
				set userChoice to button returned of (display dialog confirmMessage buttons {"Skip", "Delete"} default button "Skip")
				
				if userChoice is "Delete" then
					try
						delete aFile
						set deletedCount to deletedCount + 1
					on error
						set skippedCount to skippedCount + 1
					end try
				else
					set skippedCount to skippedCount + 1
				end if
			end if
		end repeat
	end tell
	
	return "Removed " & deletedCount & " temporary files. Skipped " & skippedCount & " files."
end removeTemporaryFiles

-- Helper function to check if a filename matches a pattern (simple wildcard matching)
on matchesPattern(fileName, pattern)
	-- Very simple pattern matching - only handles * at beginning, end, or both
	if pattern starts with "*" and pattern ends with "*" then
		-- *text* pattern
		set patternText to text 2 thru ((length of pattern) - 1) of pattern
		return fileName contains patternText
	else if pattern starts with "*" then
		-- *text pattern
		set patternEnd to text 2 thru (length of pattern) of pattern
		return fileName ends with patternEnd
	else if pattern ends with "*" then
		-- text* pattern
		set patternStart to text 1 thru ((length of pattern) - 1) of pattern
		return fileName starts with patternStart
	else
		-- exact match
		return fileName is pattern
	end if
end matchesPattern
```

## Example Input Parameters

When using with MCP, you can provide these parameters:

- `folderPath`: POSIX path to the folder to clean up
- `operation`: One of "removeEmpty", "removeDuplicates", "organizeByType", "cleanupOld", "removeTemp"
- `olderThan`: For cleanupOld operation, number of days threshold (default: 30)

## Example Usage

### Remove empty folders

```json
{
  "folderPath": "/Users/username/Documents/Projects",
  "operation": "removeEmpty"
}
```

### Clean up old files

```json
{
  "folderPath": "/Users/username/Downloads",
  "operation": "cleanupOld",
  "olderThan": 90
}
```

### Organize files by type

```json
{
  "folderPath": "/Users/username/Downloads",
  "operation": "organizeByType"
}
```