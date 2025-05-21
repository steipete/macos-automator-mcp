--------------------------------------------------------------------------------
-- terminator.scpt - v0.4.4 "T-800"
-- Instruct Cursor: Run the command `osascript .cursor/scripts/terminator.scpt`
-- Run any terminal command without blocking the loop.
-- Call without arguments to understand syntax.
--------------------------------------------------------------------------------

--#region Configuration Properties
property maxCommandWaitTime : 10.0 
property pollIntervalForBusyCheck : 0.1 
property startupDelayForTerminal : 0.7 
property minTailLinesOnWrite : 15 
property defaultTailLines : 30 
property tabTitlePrefix : "Terminator 🤖💥 " -- string: Prefix for the Terminal window/tab title.
property scriptInfoPrefix : "Terminator 🤖💥: " -- string: Prefix for all informational messages.
--#endregion Configuration Properties


--#region Main Script Logic (on run)
on run argv
    set appSpecificErrorOccurred to false
    try
        tell application "System Events"
            if not (exists process "Terminal") then
                launch application id "com.apple.Terminal"
                delay startupDelayForTerminal
            end if
        end tell

        if (count argv) < 1 then return my usageText()

        --#region Argument Parsing
        set tagName to item 1 of argv
        if (length of tagName) > 40 or (not my tagOK(tagName)) then
            set errorMsg to scriptInfoPrefix & "Tag missing or invalid." & linefeed & linefeed & ¬
                "A 'tag' is a short name (1-40 letters, digits, -, _) to identify a Terminal session." & linefeed & linefeed
            return errorMsg & my usageText()
        end if

        set doWrite to false
        set shellCmd to ""
        set currentTailLines to defaultTailLines
        set explicitLinesProvided to false -- Flag to track if user gave a line count
        set commandParts to {} 

        if (count argv) > 1 then
            set commandParts to items 2 thru -1 of argv 
        end if

        if (count commandParts) > 0 then
            set lastArg to item -1 of commandParts
            if my isInteger(lastArg) then
                set currentTailLines to (lastArg as integer)
                set explicitLinesProvided to true
                if (count commandParts) > 1 then
                    set commandParts to items 1 thru -2 of commandParts 
                else
                    set commandParts to {}
                end if
            end if
        end if

        if (count commandParts) > 0 then
            set shellCmd to my joinList(commandParts, " ")
            if shellCmd is not "" and (my trimWhitespace(shellCmd) is not "") then
                set doWrite to true
            else
                set shellCmd to "" 
                set doWrite to false 
            end if
        end if
        --#endregion Argument Parsing

        if currentTailLines < 1 then set currentTailLines to 1
        if doWrite and shellCmd is not "" and currentTailLines < minTailLinesOnWrite then
            set currentTailLines to minTailLinesOnWrite
        end if
        
        -- Determine if creation is allowed based on arguments
        set allowCreation to false
        if doWrite and shellCmd is not "" then
            set allowCreation to true
        else if explicitLinesProvided then -- e.g., "tag" 30
            set allowCreation to true
        else if (count argv) = 2 and not my isInteger(item 2 of argv) and my trimWhitespace(item 2 of argv) is "" then
            -- Special case: "tag" "" (empty command string to explicitly create/prepare)
            set allowCreation to true
            set doWrite to false -- Ensure it's treated as a setup/read context
            set shellCmd to ""
        end if

        set tabInfo to my ensureTabAndWindow(tagName, tabTitlePrefix, allowCreation)

        if tabInfo is missing value then
            if not allowCreation and not doWrite then -- Read-only attempt on non-existent tag
                set errorMsg to scriptInfoPrefix & "Error: Terminal session with tag “" & tabTitlePrefix & tagName & "” not found." & linefeed & ¬
                    "To create it, first run a command or specify lines to read (e.g., ... \"" & tagName & "\" \"\" 30)." & linefeed & linefeed
                return errorMsg & my usageText()
            else -- General creation failure
                return scriptInfoPrefix & "Error: Could not find or create Terminal tab for tag: '" & tagName & "'. Check permissions/Terminal state."
            end if
        end if

        set targetTab to targetTab of tabInfo
        set parentWindow to parentWindow of tabInfo
        set wasNewlyCreated to wasNewlyCreated of tabInfo 

        set bufferText to ""
        set commandTimedOut to false
        set tabWasBusyOnRead to false
        set previousCommandActuallyStopped to true 
        set attemptMadeToStopPreviousCommand to false
        set identifiedBusyProcessName to ""
        set theTTYForInfo to "" 

        -- If it's a read operation on a tab that was just made by us (and creation was allowed), return a clean message.
        if not doWrite and wasNewlyCreated then
            return scriptInfoPrefix & "New tab “" & tabTitlePrefix & tagName & "” created and ready."
        end if

        tell application id "com.apple.Terminal"
            try
                set index of parentWindow to 1
                set selected tab of parentWindow to targetTab
                if wasNewlyCreated and doWrite then 
                    delay 0.4 
                else
                    delay 0.1 
                end if

                --#region Write Operation Logic
                if doWrite and shellCmd is not "" then
                    set canProceedWithWrite to true 
                    if busy of targetTab then
                        if not wasNewlyCreated then 
                            set attemptMadeToStopPreviousCommand to true
                            set previousCommandActuallyStopped to false 
                            try
                                set theTTYForInfo to my trimWhitespace(tty of targetTab)
                            end try
                            set processesBefore to {}
                            try
                                set processesBefore to processes of targetTab
                            end try
                            set commonShells to {"login", "bash", "zsh", "sh", "tcsh", "ksh", "-bash", "-zsh", "-sh", "-tcsh", "-ksh", "dtterm", "fish"}
                            set identifiedBusyProcessName to "" 
                            if (count of processesBefore) > 0 then
                                repeat with i from (count of processesBefore) to 1 by -1
                                    set aProcessName to item i of processesBefore
                                    if aProcessName is not in commonShells then
                                        set identifiedBusyProcessName to aProcessName
                                        exit repeat
                                    end if
                                end repeat
                            end if
                            set processToTargetForKill to identifiedBusyProcessName
                            
                            set killedViaPID to false
                            if theTTYForInfo is not "" and processToTargetForKill is not "" then
                                set shortTTY to text 6 thru -1 of theTTYForInfo 
                                set pidsToKillText to ""
                                try
                                    set psCommand to "ps -t " & shortTTY & " -o pid,comm | awk '$2 == \"" & processToTargetForKill & "\" {print $1}'"
                                    set pidsToKillText to do shell script psCommand
                                end try
                                if pidsToKillText is not "" then
                                    set oldDelims to AppleScript's text item delimiters
                                    set AppleScript's text item delimiters to linefeed
                                    set pidList to text items of pidsToKillText
                                    set AppleScript's text item delimiters to oldDelims
                                    repeat with aPID in pidList
                                        set aPID to my trimWhitespace(aPID)
                                        if aPID is not "" then
                                            try
                                                do shell script "kill -INT " & aPID
                                                delay 0.3 
                                                do shell script "kill -0 " & aPID 
                                                try
                                                    do shell script "kill -KILL " & aPID
                                                    delay 0.2
                                                    try
                                                        do shell script "kill -0 " & aPID
                                                    on error 
                                                        set previousCommandActuallyStopped to true
                                                    end try
                                                end try
                                            on error 
                                                set previousCommandActuallyStopped to true
                                            end try
                                        end if
                                        if previousCommandActuallyStopped then
                                            set killedViaPID to true
                                            exit repeat 
                                        end if
                                    end repeat
                                end if
                            end if
                            if not previousCommandActuallyStopped and busy of targetTab then 
                                activate 
                                delay 0.5 
                                tell application "System Events" to keystroke "c" using control down
                                delay 0.6 
                                if not (busy of targetTab) then
                                    set previousCommandActuallyStopped to true 
                                    if identifiedBusyProcessName is not "" and (identifiedBusyProcessName is in (processes of targetTab)) then
                                        set previousCommandActuallyStopped to false 
                                    end if
                                end if
                            else if not busy of targetTab then 
                                 set previousCommandActuallyStopped to true
                            end if
                            if not previousCommandActuallyStopped then
                                set canProceedWithWrite to false
                            end if
                        else if wasNewlyCreated and busy of targetTab then
                            delay 0.4 
                            if busy of targetTab then
                                set attemptMadeToStopPreviousCommand to true 
                                set previousCommandActuallyStopped to false 
                                set identifiedBusyProcessName to "extended initialization"
                                set canProceedWithWrite to false
                            else
                                set previousCommandActuallyStopped to true 
                            end if
                        end if
                    end if 

                    if canProceedWithWrite then 
                        if not wasNewlyCreated then
                            do script "clear" in targetTab
                            delay 0.1
                        end if
                        do script shellCmd in targetTab
                        set commandStartTime to current date
                        set commandFinished to false
                        repeat while ((current date) - commandStartTime) < maxCommandWaitTime
                            if not (busy of targetTab) then
                                set commandFinished to true
                                exit repeat
                            end if
                            delay pollIntervalForBusyCheck 
                        end repeat
                        if not commandFinished then set commandTimedOut to true
                        if commandFinished then delay 0.1
                    end if
                --#endregion Write Operation Logic
                --#region Read Operation Logic
                else if not doWrite then 
                    if busy of targetTab then
                        set tabWasBusyOnRead to true
                        try
                            set theTTYForInfo to my trimWhitespace(tty of targetTab)
                        end try
                        set processesReading to processes of targetTab
                        set commonShells to {"login", "bash", "zsh", "sh", "tcsh", "ksh", "-bash", "-zsh", "-sh", "-tcsh", "-ksh", "dtterm", "fish"}
                        set identifiedBusyProcessName to "" 
                        if (count of processesReading) > 0 then
                            repeat with i from (count of processesReading) to 1 by -1
                                set aProcessName to item i of processesReading
                                if aProcessName is not in commonShells then
                                    set identifiedBusyProcessName to aProcessName
                                    exit repeat
                                end if
                            end repeat
                        end if
                    end if
                end if
                --#endregion Read Operation Logic
                set bufferText to history of targetTab
            on error errMsg number errNum
                set appSpecificErrorOccurred to true
                return scriptInfoPrefix & "Terminal Interaction Error (" & errNum & "): " & errMsg
            end try
        end tell

        --#region Message Construction & Output Processing
        set appendedMessage to ""
        set ttyInfoStringForMessage to "" 
        if theTTYForInfo is not "" then set ttyInfoStringForMessage to " (TTY " & theTTYForInfo & ")"

        if attemptMadeToStopPreviousCommand then
            set processNameToReport to "process"
            if identifiedBusyProcessName is not "" and identifiedBusyProcessName is not "extended initialization" then
                set processNameToReport to "'" & identifiedBusyProcessName & "'"
            else if identifiedBusyProcessName is "extended initialization" then
                set processNameToReport to "tab's extended initialization"
            end if
            if previousCommandActuallyStopped then
                set appendedMessage to linefeed & scriptInfoPrefix & "Previous " & processNameToReport & ttyInfoStringForMessage & " was interrupted. ---"
            else
                set appendedMessage to linefeed & scriptInfoPrefix & "Attempted to interrupt previous " & processNameToReport & ttyInfoStringForMessage & ", but it may still be running. New command NOT executed. ---"
            end if
        end if
        if commandTimedOut then 
            set appendedMessage to appendedMessage & linefeed & scriptInfoPrefix & "Command '" & shellCmd & "' may still be running. Returned after " & maxCommandWaitTime & "s timeout. ---"
        else if tabWasBusyOnRead then 
            set processNameToReportOnRead to "process"
            if identifiedBusyProcessName is not "" then set processNameToReportOnRead to "'" & identifiedBusyProcessName & "'"
            set busyProcessInfoString to ""
            if identifiedBusyProcessName is not "" then set busyProcessInfoString to " with " & processNameToReportOnRead
            set appendedMessage to appendedMessage & linefeed & scriptInfoPrefix & "Tab" & ttyInfoStringForMessage & " was busy" & busyProcessInfoString & " during read. Output may be from an ongoing process. ---"
        end if

        if appendedMessage is not "" then
            if bufferText is "" or my lineIsEffectivelyEmptyAS(bufferText) then
                set bufferText to my trimWhitespace(appendedMessage)
            else
                set bufferText to bufferText & appendedMessage
            end if
        end if
        
        set scriptInfoPresent to (appendedMessage is not "")
        set contentBeforeInfoIsEmpty to false
        if scriptInfoPresent and bufferText is not "" then
            set tempDelims to AppleScript's text item delimiters
            set AppleScript's text item delimiters to scriptInfoPrefix 
            set firstPart to text item 1 of bufferText
            set AppleScript's text item delimiters to tempDelims
            if my trimBlankLinesAS(firstPart) is "" then
                set contentBeforeInfoIsEmpty to true
            end if
        end if
        
        if bufferText is "" or my lineIsEffectivelyEmptyAS(bufferText) or (scriptInfoPresent and contentBeforeInfoIsEmpty) then
            set baseMsg to "Tag “" & tabTitlePrefix & tagName & "”, requested " & currentTailLines & " lines."
            set anAppendedMessageForReturn to my trimWhitespace(appendedMessage)
            set messageSuffix to ""
            if anAppendedMessageForReturn is not "" then set messageSuffix to linefeed & anAppendedMessageForReturn
            
            if attemptMadeToStopPreviousCommand and not previousCommandActuallyStopped then
                 return scriptInfoPrefix & "Previous command in tag “" & tabTitlePrefix & tagName & "”" & ttyInfoStringForMessage & " may not have terminated. New command '" & shellCmd & "' NOT executed." & messageSuffix
            else if commandTimedOut then
                return scriptInfoPrefix & "Command '" & shellCmd & "' timed out after " & maxCommandWaitTime & "s. No other output. " & baseMsg & messageSuffix
            else if tabWasBusyOnRead then
                return scriptInfoPrefix & "Tab was busy during read. No other output. " & baseMsg & messageSuffix
            else if doWrite and shellCmd is not "" then
                return scriptInfoPrefix & "Command '" & shellCmd & "' executed. No output captured. " & baseMsg
            else
                return scriptInfoPrefix & "No text content (history) found. " & baseMsg
            end if
        end if
        
        set tailedOutput to my tailBufferAS(bufferText, currentTailLines)
        set finalResult to my trimBlankLinesAS(tailedOutput)

        if finalResult is not "" then
            set tempCompareResult to finalResult
            if tempCompareResult starts with linefeed then
                try
                    set tempCompareResult to text 2 thru -1 of tempCompareResult
                on error
                    set tempCompareResult to ""
                end try
            end if
            if (tempCompareResult starts with scriptInfoPrefix) then
                set finalResult to my trimWhitespace(finalResult) 
            end if
        end if
        
        if finalResult is "" and bufferText is not "" and not my lineIsEffectivelyEmptyAS(bufferText) then
            set baseMsgDetailPart to "Tag “" & tabTitlePrefix & tagName & "”, command '" & shellCmd & "'. Original history had content."
            set trimmedAppendedMessageForDetail to my trimWhitespace(appendedMessage)
            set messageSuffixForDetail to ""
            if trimmedAppendedMessageForDetail is not "" then set messageSuffixForDetail to linefeed & trimmedAppendedMessageForDetail
            set descriptiveMessage to scriptInfoPrefix 
            if attemptMadeToStopPreviousCommand and not previousCommandActuallyStopped then
                 set descriptiveMessage to descriptiveMessage & baseMsgDetailPart & " Previous command/initialization not terminated, new command not run." & messageSuffixForDetail
            else if commandTimedOut then
                set descriptiveMessage to descriptiveMessage & baseMsgDetailPart & " Final output empty after processing due to timeout." & messageSuffixForDetail
            else if tabWasBusyOnRead then
                set descriptiveMessage to descriptiveMessage & baseMsgDetailPart & " Final output empty after processing while tab was busy." & messageSuffixForDetail
            else if doWrite and shellCmd is not "" then
                set descriptiveMessage to descriptiveMessage & baseMsgDetailPart & " Output empty after processing last " & currentTailLines & " lines."
            else if not doWrite and (appendedMessage is not "" and (bufferText contains appendedMessage)) then
                return my trimWhitespace(appendedMessage)
            else
                set descriptiveMessage to scriptInfoPrefix & baseMsgDetailPart & " Content present but became empty after processing."
            end if
            if descriptiveMessage is not "" and descriptiveMessage is not scriptInfoPrefix then return descriptiveMessage
        end if
        
        return finalResult
        --#endregion Message Construction & Output Processing

    on error generalErrorMsg number generalErrorNum
        if appSpecificErrorOccurred then error generalErrorMsg number generalErrorNum 
        return scriptInfoPrefix & "AppleScript Execution Error (" & generalErrorNum & "): " & generalErrorMsg
    end try
end run
--#endregion Main Script Logic (on run)


--#region Helper Functions
on ensureTabAndWindow(tagName, prefix, allowCreate as boolean)
    set wantTitle to prefix & tagName
    set wasCreated to false 
    tell application id "com.apple.Terminal"
        -- First, try to find an existing tab with the specified title
        try
            repeat with w in windows
                repeat with tb in tabs of w
                    try
                        if custom title of tb is wantTitle then
                            set selected tab of w to tb
                            return {targetTab:tb, parentWindow:w, wasNewlyCreated:false}
                        end if
                    end try
                end repeat
            end repeat
        on error errMsg number errNum
            -- Log "Error searching for existing tab: " & errMsg
            -- Continue to creation phase if allowed
        end try

        -- If not found, and creation is allowed, create a new tab/window context
        if allowCreate then
            try
                set newTab to do script "clear" -- 'clear' is an initial command to establish the new context
                set wasCreated to true
                delay 0.3 -- Allow tab to fully create and become responsive
                set custom title of newTab to wantTitle
                delay 0.2 -- Allow title to set

                set parentWin to missing value
                repeat with w_search in windows
                    try
                        if selected tab of w_search is newTab then
                            set parentWin to w_search
                            exit repeat
                        end if
                    end try
                end repeat
                if parentWin is missing value then
                     if (count of windows) > 0 then set parentWin to front window
                end if

                if parentWin is not missing value and newTab is not missing value then
                    set finalNewTabRef to selected tab of parentWin 
                    if custom title of finalNewTabRef is wantTitle then 
                        return {targetTab:finalNewTabRef, parentWindow:parentWin, wasNewlyCreated:wasCreated}
                    else if custom title of newTab is wantTitle then 
                        return {targetTab:newTab, parentWindow:parentWin, wasNewlyCreated:wasCreated}
                    end if
                end if
                return missing value -- Failed to identify/confirm the new tab
            on error errMsgNC number errNumNC
                -- Log "Error during new tab creation: " & errMsgNC
                return missing value 
            end try
        else
            -- Creation not allowed and tab not found
            return missing value
        end if
    end tell
end ensureTabAndWindow

on tailBufferAS(txt, n)
    set AppleScript's text item delimiters to linefeed
    set lst to text items of txt
    if (count lst) = 0 then return ""
    set startN to (count lst) - (n - 1)
    if startN < 1 then set startN to 1
    set slice to items startN thru -1 of lst 
    set outText to slice as text
    set AppleScript's text item delimiters to "" 
    return outText
end tailBufferAS

on lineIsEffectivelyEmptyAS(aLine)
    if aLine is "" then return true
    set trimmedLine to my trimWhitespace(aLine)
    return (trimmedLine is "")
end lineIsEffectivelyEmptyAS

on trimBlankLinesAS(txt)
    if txt is "" then return ""
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to {linefeed}
    set originalLines to text items of txt
    set linesToProcess to {}
    repeat with aLineRef in originalLines
        set aLine to contents of aLineRef
        if my lineIsEffectivelyEmptyAS(aLine) then
            set end of linesToProcess to ""
        else
            set end of linesToProcess to aLine
        end if
    end repeat
    set firstContentLine to 1
    repeat while firstContentLine ≤ (count linesToProcess) and (item firstContentLine of linesToProcess is "")
        set firstContentLine to firstContentLine + 1
    end repeat
    set lastContentLine to count linesToProcess
    repeat while lastContentLine ≥ firstContentLine and (item lastContentLine of linesToProcess is "")
        set lastContentLine to lastContentLine - 1
    end repeat
    if firstContentLine > lastContentLine then
        set AppleScript's text item delimiters to oldDelims
        return ""
    end if
    set resultLines to items firstContentLine thru lastContentLine of linesToProcess
    set AppleScript's text item delimiters to linefeed
    set trimmedTxt to resultLines as text
    set AppleScript's text item delimiters to oldDelims
    return trimmedTxt
end trimBlankLinesAS

on trimWhitespace(theText)
    set whitespaceChars to {" ", tab}
    set newText to theText
    repeat while (newText is not "") and (character 1 of newText is in whitespaceChars)
        if (length of newText) > 1 then
            set newText to text 2 thru -1 of newText
        else
            set newText to ""
        end if
    end repeat
    repeat while (newText is not "") and (character -1 of newText is in whitespaceChars)
        if (length of newText) > 1 then
            set newText to text 1 thru -2 of newText
        else
            set newText to ""
        end if
    end repeat
    return newText
end trimWhitespace

on isInteger(v)
    try
        v as integer
        return true
    on error
        return false
    end try
end isInteger

on tagOK(t)
    try
        do shell script "/bin/echo " & quoted form of t & " | /usr/bin/grep -E -q '^[A-Za-z0-9_-]+$'"
        return true
    on error
        return false
    end try
end tagOK

on joinList(theList, theDelimiter)
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to theDelimiter
    set theText to theList as text
    set AppleScript's text item delimiters to oldDelims
    return theText
end joinList

on usageText()
    set LF to linefeed
    set scriptName to "terminator.scpt"
    set exampleTag to "my-project-folder"
    set examplePath to "/path/to/your/project"
    set exampleCommand to "npm install"
    
    set outText to scriptName & " - v0.4.4 \"T-800\" – AppleScript Terminal helper" & LF & LF
    set outText to outText & "Manages dedicated, tagged Terminal sessions for your projects." & LF & LF
    
    set outText to outText & "Core Concept:" & LF
    set outText to outText & "  1. Choose a unique 'tag' for each project (e.g., its folder name)." & LF
    set outText to outText & "  2. ALWAYS use the same tag for subsequent commands for that project." & LF
    set outText to outText & "  3. The FIRST command for a new tag MUST 'cd' into your project directory." & LF
    set outText to outText & "     Alternatively, to just create/prepare a new tagged session without running a command:" & LF
    set outText to outText & "     osascript " & scriptName & " \"<new_tag_name>\" \"\" [lines_to_read_e.g._1]" & LF & LF
    
    set outText to outText & "Features:" & LF
    set outText to outText & "  • Creates or reuses a Terminal context titled “" & tabTitlePrefix & "<tag>”." & LF
    set outText to outText & "    (If tag is new AND a command/explicit lines are given, a new Terminal window/tab is usually created)." & LF
    set outText to outText & "    (Initial read of a new tag (e.g. '... \"tag\" \"\" 1') will show: " & scriptInfoPrefix & "New tab... created)." & LF
    set outText to outText & "  • If ONLY a tag is provided (e.g. '... \"tag\"') for a read, it MUST already exist." & LF
    set outText to outText & "  • If executing a command in a busy, REUSED tab:" & LF
    set outText to outText & "    - Attempts to interrupt the busy process (using TTY 'kill', then Ctrl-C)." & LF
    set outText to outText & "    - If interrupt fails, new command is NOT executed." & LF
    set outText to outText & "  • Clears screen before running new command (if not a newly created tab or if interrupt succeeded)." & LF
    set outText to outText & "  • Reads last lines from tab history, trimming blank lines." & LF
    set outText to outText & "  • Appends " & scriptInfoPrefix & " messages for timeouts, busy reads, or interruptions." & LF
    set outText to outText & "  • Minimizes focus stealing (interrupt attempts may briefly activate Terminal)." & LF & LF
    
    set outText to outText & "Usage Modes:" & LF & LF
    
    set outText to outText & "1. Create/Prepare or Read from Tag (if lines specified for new tag):" & LF
    set outText to outText & "   osascript " & scriptName & " \"<tag_name>\" \"\" [lines_to_read]  -- Empty command string for creation/preparation" & LF
    set outText to outText & "   Example (create/prepare & read 1 line): osascript " & scriptName & " \"" & exampleTag & "\" \"\" 1" & LF & LF

    set outText to outText & "2. Establish/Reuse Session & Run Command:" & LF
    set outText to outText & "   osascript " & scriptName & " \"<tag_name>\" \"cd " & examplePath & " && " & exampleCommand & "\" [lines_to_read]" & LF
    set outText to outText & "   Example: osascript " & scriptName & " \"" & exampleTag & "\" \"cd " & examplePath & " && npm install -ddd\" 50" & LF
    set outText to outText & "   Subsequent: osascript " & scriptName & " \"" & exampleTag & "\" \"git status\"" & LF & LF
    
    set outText to outText & "3. Read from Existing Tagged Session (Tag MUST exist):" & LF
    set outText to outText & "   osascript " & scriptName & " \"<tag_name>\"" & LF
    set outText to outText & "   osascript " & scriptName & " \"<tag_name>\" [lines_to_read_if_tag_exists]" & LF
    set outText to outText & "   Example (read default " & defaultTailLines & " lines): osascript " & scriptName & " \"" & exampleTag & "\"" & LF & LF
    
    set outText to outText & "Parameters:" & LF
    set outText to outText & "  \"<tag_name>\": Required. A unique name for the session." & LF
    set outText to outText & "                  (Letters, digits, hyphen, underscore only; 1-40 chars)." & LF
    set outText to outText & "  \"<shell_command_parts...>\": (Optional) The full command string. Use \"\" for no command if specifying lines for a new tag." & LF
    set outText to outText & "                                  IMPORTANT: For commands needing a specific directory, include 'cd /your/path && '." & LF
    set outText to outText & "  [lines_to_read]: (Optional) Number of history lines. Default: " & defaultTailLines & "." & LF
    set outText to outText & "                   If writing, min " & minTailLinesOnWrite & " lines are fetched if user requests less." & LF & LF
    
    set outText to outText & "Notes:" & LF
    set outText to outText & "  • Automation systems should consistently reuse 'tag_name' for a project." & LF
    set outText to outText & "  • Ensure Automation permissions for Terminal.app & System Events.app." & LF
    
    return outText
end usageText