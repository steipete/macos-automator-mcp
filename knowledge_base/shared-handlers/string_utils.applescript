-- AppleScript String Utility Handlers
-- Common string manipulation functions for AppleScript
-- These can be included in other scripts as needed

-- Trims whitespace from beginning and end of a string
on trimString(theString)
  -- Check for empty string
  if theString is "" then return ""
  
  -- First, remove leading spaces
  set tempString to theString
  repeat while tempString begins with " " or tempString begins with tab
    set tempString to text 2 thru end of tempString
    if length of tempString is 0 then return ""
  end repeat
  
  -- Then remove trailing spaces
  repeat while tempString ends with " " or tempString ends with tab
    set tempString to text 1 thru ((length of tempString) - 1) of tempString
    if length of tempString is 0 then return ""
  end repeat
  
  return tempString
end trimString

-- Splits a string into a list using a delimiter
on splitString(theString, theDelimiter)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theDelimiter
  set theItems to every text item of theString
  set AppleScript's text item delimiters to oldDelimiters
  return theItems
end splitString

-- Joins a list of strings with a delimiter
on joinList(theList, theDelimiter)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to theDelimiter
  set theString to theList as string
  set AppleScript's text item delimiters to oldDelimiters
  return theString
end joinList

-- Returns true if string contains specified substring
on stringContains(theString, subString)
  if theString contains subString then
    return true
  else
    return false
  end if
end stringContains

-- Replaces all occurrences of a substring with another string
on replaceString(theString, oldSubString, newSubString)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to oldSubString
  set theItems to every text item of theString
  set AppleScript's text item delimiters to newSubString
  set theString to theItems as string
  set AppleScript's text item delimiters to oldDelimiters
  return theString
end replaceString

-- Converts string to lowercase
on toLowerCase(theString)
  return do shell script "echo " & quoted form of theString & " | tr '[:upper:]' '[:lower:]'"
end toLowerCase

-- Converts string to uppercase
on toUpperCase(theString)
  return do shell script "echo " & quoted form of theString & " | tr '[:lower:]' '[:upper:]'"
end toUpperCase

-- Capitalizes first letter of each word
on capitalizeWords(theString)
  set oldDelimiters to AppleScript's text item delimiters
  set AppleScript's text item delimiters to " "
  set theWords to every text item of theString
  set newWords to {}
  repeat with aWord in theWords
    if length of aWord > 0 then
      set capitalizedWord to (text 1 thru 1 of aWord as string) & text 2 thru (length of aWord) of aWord
      set end of newWords to capitalizedWord
    end if
  end repeat
  set AppleScript's text item delimiters to " "
  set theResult to newWords as string
  set AppleScript's text item delimiters to oldDelimiters
  return theResult
end capitalizeWords