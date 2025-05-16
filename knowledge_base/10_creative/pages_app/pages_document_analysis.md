---
title: 'Pages: Document Analysis and Statistics'
category: 10_creative/pages_app
id: pages_document_analysis
description: >-
  Analyzes a Pages document to extract statistics, structure, and readability
  information.
keywords:
  - Pages
  - document
  - statistics
  - word count
  - character count
  - analysis
  - readability
  - document structure
language: applescript
argumentsPrompt: Enter the path to the Pages document to analyze (optional)
notes: >-
  Extracts comprehensive document statistics including word count, character
  count, page count, sections, headings, and readability metrics. Returns data
  in a structured JSON format. If no path is provided, analyzes the currently
  open document.
---

```applescript
on run {documentPath}
  tell application "Pages"
    try
      -- Handle placeholder substitution
      if documentPath is "" or documentPath is missing value then
        set documentPath to "--MCP_INPUT:documentPath"
      end if
      
      -- Initialize variables
      set docStats to {}
      set docReference to missing value
      
      -- Check if a path was provided or we should use the frontmost document
      if documentPath is not equal to "" and documentPath is not equal to "--MCP_INPUT:documentPath" then
        -- Verify path format and existence
        if documentPath does not start with "/" then
          return "Error: Document path must be a valid absolute POSIX path starting with /"
        end if
        
        -- Try to open the document
        open POSIX file documentPath
        set docReference to front document
      else
        -- Check if Pages is already open with a document
        if not (exists front document) then
          return "Error: No document is currently open in Pages. Please open a document or provide a valid path."
        end if
        set docReference to front document
      end if
      
      -- Get basic document information
      set docName to name of docReference
      set docStats to {documentName:docName}
      
      -- Get document statistics
      tell docReference
        -- Basic statistics
        set wordCount to count of words of text of body text
        set charCount to count of characters of text of body text
        set charCountNoSpaces to count of characters of (text of body text whose character is not in {space, tab, return, linefeed})
        set paragraphCount to count of paragraphs of text of body text
        
        -- Add to the stats dictionary
        set docStats to docStats & {wordCount:wordCount, characterCount:charCount, characterCountNoSpaces:charCountNoSpaces, paragraphCount:paragraphCount}
        
        -- Extract page count (this is approximate based on view)
        set pageCount to 0
        try
          -- This is not directly accessible, but we can estimate
          set pageCount to (get count of pages)
        on error
          -- Fallback method - less accurate
          set pageCount to ((count of characters of text of body text) / 3000) as integer
          if ((count of characters of text of body text) mod 3000) > 0 then
            set pageCount to pageCount + 1
          end if
        end try
        set docStats to docStats & {pageCount:pageCount}
        
        -- Analyze document structure
        set headingCount to 0
        set sectionCount to 0
        set listCount to 0
        set imageCount to 0
        set tableCount to 0
        
        -- Count headings (paragraphs with heading styles)
        tell body text
          repeat with i from 1 to count of paragraphs
            set pStyle to ""
            try
              set pStyle to paragraph style of paragraph i
              if pStyle contains "Heading" or pStyle contains "Title" or pStyle contains "header" then
                set headingCount to headingCount + 1
              end if
            end try
          end repeat
        end tell
        
        -- Count tables and images
        try
          set tableCount to count of tables
        on error
          set tableCount to 0
        end try
        
        try
          set imageCount to count of images
        on error
          set imageCount to 0
        end try
        
        -- Estimate section count (can be refined based on header levels)
        set sectionCount to headingCount
        
        -- Add structure info to stats
        set docStats to docStats & {headingCount:headingCount, sectionCount:sectionCount, tableCount:tableCount, imageCount:imageCount}
        
        -- Calculate readability metrics
        set totalSentences to 0
        set rawText to text of body text
        
        -- Count sentences (approximately by counting periods, question marks, exclamation points)
        set sentenceEndCount to 0
        set oldDelimiters to AppleScript's text item delimiters
        set AppleScript's text item delimiters to {". ", "! ", "? "}
        set textItems to text items of rawText
        set sentenceEndCount to (count of textItems) - 1
        set AppleScript's text item delimiters to oldDelimiters
        
        -- Add a sentence if the document doesn't end with delimiter
        if rawText does not end with ". " and rawText does not end with "! " and rawText does not end with "? " and (count of characters of rawText) > 0 then
          set sentenceEndCount to sentenceEndCount + 1
        end if
        
        set averageWordsPerSentence to 0
        if sentenceEndCount > 0 then
          set averageWordsPerSentence to wordCount / sentenceEndCount
        end if
        
        -- Calculate approximate readability score (simplified Flesch-Kincaid)
        set readabilityScore to 0
        if sentenceEndCount > 0 and wordCount > 0 then
          -- Simple formula: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
          -- Since we can't count syllables easily, we'll use a rough approximation
          set readabilityScore to 206.835 - (1.015 * (wordCount / sentenceEndCount)) - (84.6 * (charCount / wordCount / 3))
          
          -- Clamp value to sensible range (0-100)
          if readabilityScore < 0 then
            set readabilityScore to 0
          else if readabilityScore > 100 then
            set readabilityScore to 100
          end if
          
          -- Round to integer
          set readabilityScore to readabilityScore as integer
        end if
        
        -- Add readability metrics to stats
        set docStats to docStats & {sentenceCount:sentenceEndCount, averageWordsPerSentence:averageWordsPerSentence, estimatedReadabilityScore:readabilityScore}
      end tell
      
      -- Create a structured JSON string (manually since AppleScript doesn't have built-in JSON)
      set jsonString to "{"
      set jsonString to jsonString & "\"documentName\": \"" & (docName as string) & "\", "
      set jsonString to jsonString & "\"statistics\": {"
      set jsonString to jsonString & "\"wordCount\": " & wordCount & ", "
      set jsonString to jsonString & "\"characterCount\": " & charCount & ", "
      set jsonString to jsonString & "\"characterCountNoSpaces\": " & charCountNoSpaces & ", "
      set jsonString to jsonString & "\"paragraphCount\": " & paragraphCount & ", "
      set jsonString to jsonString & "\"pageCount\": " & pageCount & ", "
      set jsonString to jsonString & "\"sentenceCount\": " & sentenceEndCount
      set jsonString to jsonString & "}, "
      
      set jsonString to jsonString & "\"structure\": {"
      set jsonString to jsonString & "\"headingCount\": " & headingCount & ", "
      set jsonString to jsonString & "\"sectionCount\": " & sectionCount & ", "
      set jsonString to jsonString & "\"tableCount\": " & tableCount & ", "
      set jsonString to jsonString & "\"imageCount\": " & imageCount
      set jsonString to jsonString & "}, "
      
      set jsonString to jsonString & "\"readability\": {"
      set jsonString to jsonString & "\"averageWordsPerSentence\": " & averageWordsPerSentence & ", "
      set jsonString to jsonString & "\"estimatedReadabilityScore\": " & readabilityScore
      set jsonString to jsonString & "}"
      
      set jsonString to jsonString & "}"
      
      return jsonString
      
    on error errMsg number errNum
      return "Error (" & errNum & "): Failed to analyze document - " & errMsg
    end try
  end tell
end run
```
