---
title: "StandardAdditions: summarize Command"
category: "01_applescript_core" # Subdir: scripting_additions_osax
id: osax_summarize
description: "Attempts to create a summary of a given text or the content of a text file. The length of the summary can be specified in sentences."
keywords: ["StandardAdditions", "summarize", "text summary", "osax", "natural language"]
language: applescript
isComplex: true
argumentsPrompt: "Text to summarize as 'textToSummarize', OR an alias to a text file as 'fileAliasToSummarize'. Number of sentences for summary as 'numberOfSentences' (integer) in inputData. Provide one of textToSummarize or fileAliasToSummarize."
notes: |
  - The quality of summarization can vary.
  - Works best with well-structured prose.
  - Input can be a string or a file alias.
---

```applescript
--MCP_INPUT:textToSummarize
--MCP_INPUT:fileAliasToSummarize
--MCP_INPUT:numberOfSentences

on getSummary(sourceText, sourceFileAlias, numSentences)
  set sentencesCount to 3 -- Default summary length
  if numSentences is not missing value then
    try
      set sentencesCount to numSentences as integer
      if sentencesCount < 1 then set sentencesCount to 1
    on error
      log "Invalid numberOfSentences, using default."
    end try
  end if
  
  try
    if sourceText is not missing value and sourceText is not "" then
      return summarize sourceText in sentencesCount
    else if sourceFileAlias is not missing value then
      -- Assuming fileAliasToSummarize is already an alias or can be made into one
      -- For MCP input, it would be a POSIX path string that needs conversion
      -- set actualAlias to POSIX file sourceFileAlias as alias 
      -- For the purpose of this function, we assume sourceFileAlias IS an alias if provided
      return summarize sourceFileAlias in sentencesCount
    else
      return "error: No text or file alias provided to summarize."
    end if
  on error errMsg
    return "error: Failed to summarize - " & errMsg
  end try
end getSummary

-- This script requires careful input handling due to 'alias' type.
-- For MCP, if fileAliasToSummarize is a POSIX path string:
set filePathArg to "--MCP_INPUT:fileAliasToSummarize"
set textArg to "--MCP_INPUT:textToSummarize"
set sentencesArg to "--MCP_INPUT:numberOfSentences" -- This will be a string from inputData, needs coercion

set anAliasToPass to missing value
set theTextToPass to missing value

if filePathArg is not missing value and filePathArg is not "" and filePathArg is not "--MCP_INPUT:fileAliasToSummarize" then
  try
    set anAliasToPass to (POSIX file filePathArg as alias)
  on error
    return "error: Invalid file path provided for summarization: " & filePathArg
  end try
else if textArg is not missing value and textArg is not "" and textArg is not "--MCP_INPUT:textToSummarize" then
  set theTextToPass to textArg
else
  return "error: No text or file path provided to summarize. Ensure one input is correctly set."
end if

set numSentencesCoerced to 3 -- default
if sentencesArg is not missing value and sentencesArg is not "" and sentencesArg is not "--MCP_INPUT:numberOfSentences" then
    try
        set numSentencesCoerced to sentencesArg as integer
        if numSentencesCoerced < 1 then set numSentencesCoerced to 1
    on error
        log "Invalid sentencesArg, using default 3"
        set numSentencesCoerced to 3 
    end try
else
    log "sentencesArg not provided or is placeholder, using default 3"
    set numSentencesCoerced to 3
end if


return my getSummary(theTextToPass, anAliasToPass, numSentencesCoerced)
```
END_TIP 