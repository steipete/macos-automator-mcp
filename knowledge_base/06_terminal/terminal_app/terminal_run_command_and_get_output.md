---
title: "Terminal: Run Command and Get Output"
id: terminal_run_command_and_get_output
category: "04_terminal_emulators"
description: "Opens Terminal.app (or uses an existing window), runs a specified shell command in a chosen working directory, and captures its standard output."
keywords: ["Terminal.app", "command", "execute", "shell", "output", "capture", "stdout"]
language: applescript
argumentsPrompt: "Expects inputData with: { \"commandToRun\": \"your command here\", \"workingDirectory\": \"/optional/path/to/run/in\" } (workingDirectory defaults to '~' if omitted or empty)."
isComplex: true
---

This script allows you to execute a shell command in `Terminal.app` and retrieve its output.

**Features:**
- Activates `Terminal.app`.
- Uses the frontmost window, or creates one if none exist.
- Executes the provided command in the selected tab.
- Optionally changes to a specified `workingDirectory` before running the command. If not specified, defaults to the user's home directory (`~`).
- Captures the standard output of the command.

**Important Considerations:**
- The script waits for the command to complete by checking the 'busy' status of the terminal tab.
- It attempts to parse the output from the tab's history using unique markers.
- For commands that produce a very large amount of output, there might be limitations to what `history` captures or how it's processed.
- This script does not capture `stderr`. Output from `stderr` will not be included.

```applescript
on runWithInput(inputData, legacyArguments)
    set commandToRun to ""
    set workingDirectory to "~" -- Default to home directory

    if inputData is not missing value then
        if inputData contains {commandToRun:""} then
            set commandToRun to commandToRun of inputData
        end if
        if inputData contains {workingDirectory:""} then
            set workingDirectory to workingDirectory of inputData
            if workingDirectory is "" then set workingDirectory to "~"
        end if
    end if

    if commandToRun is "" then
        return "Error: commandToRun not provided in inputData."
    end if

    -- Validate workingDirectory slightly. If it's invalid, default to home.
    if workingDirectory is not "~" then
        try
            set tempPath to POSIX path of workingDirectory -- Test if it can be coerced
        on error
            set workingDirectory to "~"
        end try
    end if
    
    set baseCommand to "cd " & quoted form of workingDirectory & " && " & commandToRun
    
    set randNum to (random number from 10000 to 99999) as string
    set startMarker to "---MCP_OUTPUT_START---" & randNum
    set endMarker to "---MCP_OUTPUT_END---" & randNum
    
    set commandWithMarkers to "clear; echo " & quoted form of startMarker & "; " & baseCommand & "; echo " & quoted form of endMarker

    set tabHistory to ""

    tell application "Terminal"
        activate
        if not (exists window 1) then
            do script "" 
            delay 1 
        end if
        
        set frontWindow to window 1
        set currentTab to selected tab of frontWindow
        
        do script commandWithMarkers in currentTab
        
        repeat while busy of currentTab
            delay 0.2
        end repeat
        delay 0.5 

        try
            set tabHistory to history of currentTab
            
            if not (tabHistory contains startMarker) then
                error "Start marker (" & startMarker & ") not found in Terminal history. Command output capture failed."
            end if
            
            set AppleScript's text item delimiters to startMarker
            set textParts to text items of tabHistory
            if (count of textParts) < 2 then
                error "Start marker (" & startMarker & ") was found, but no content followed it. Command output capture failed."
            end if
            set stringAfterStartMarker to item 2 of textParts
            if (count of textParts) > 2 then
                set stringAfterStartMarker to items 2 thru -1 of textParts as string
            end if

            if not (stringAfterStartMarker contains endMarker) then
                error "End marker (" & endMarker & ") not found after start marker in Terminal history. Command output capture may be incomplete."
            end if
            
            set AppleScript's text item delimiters to endMarker
            set commandOutput to text item 1 of stringAfterStartMarker
            
            set AppleScript's text item delimiters to "" 
            
            set finalOutput to commandOutput
            if (count of finalOutput) > 0 then
                if finalOutput starts with linefeed then
                    try
                        set finalOutput to text 2 thru -1 of finalOutput
                    on error 
                        set finalOutput to ""
                    end try
                end if
            end if
            if (count of finalOutput) > 0 then
                 if finalOutput ends with linefeed then
                    try
                        set finalOutput to text 1 thru -2 of finalOutput
                    on error 
                        set finalOutput to ""
                    end try
                end if
            end if
            
            return finalOutput
        on error errMsg number errNum
            set errorResult to "Error (" & errNum & ") processing Terminal output: " & errMsg
            if tabHistory is not "" and tabHistory does not contain "Error processing Terminal output" then
                 set errorResult to errorResult & "\\n--- Full Tab History ---\\n" & tabHistory & "\\n--- End Tab History ---"
            else if tabHistory is "" then
                 set errorResult to errorResult & "\\n(Tab history was empty or could not be retrieved before error)"
            end if
            return errorResult
        end try
    end tell
end runWithInput
```