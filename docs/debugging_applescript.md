# Debugging AppleScript and JXA Execution

Executing AppleScript or JXA scripts, especially through an intermediary layer like this MCP server, can sometimes be challenging to debug. AppleScript's error messages can be cryptic, and issues might arise from the script content itself, placeholder substitution, or macOS permissions.

This guide provides tips and techniques based on common scenarios encountered.

## Key Debugging Strategies

### 1. Enable Detailed Substitution Logging

When using knowledge base scripts (`knowledgeBaseScriptId`) with the `execute_script` tool, placeholders like `--MCP_INPUT:keyName` and `--MCP_ARG_N` are substituted with values from `inputData` and `arguments` respectively. If this substitution is incorrect, it can lead to AppleScript syntax errors (like the common `-2741 "Expected , or } but found class name."`).

To understand exactly how these substitutions are being performed:

*   **Use `includeSubstitutionLogs: true`**: Add this parameter to your `execute_script` call.
    ```json
    {
      "method": "execute_script",
      "params": {
        "knowledgeBaseScriptId": "your_script_id",
        "inputData": { "someKey": "someValue" },
        "includeSubstitutionLogs": true 
      }
    }
    ```
*   **Inspect the Output**: The server will then include a detailed log of each substitution step in the output. On success, these logs are prepended to the script's standard output. On failure, they are appended to the error message. This allows you to see:
    *   Which regex patterns were applied.
    *   What parts of the script were matched.
    *   What the placeholder values were resolved to.
    *   The script content length before and after each major substitution stage.

This was crucial in diagnosing an issue where the regex for matching quoted placeholders was not working as expected. The logs showed that the script content length wasn't changing, indicating no matches were being found, which led to a step-by-step simplification and rebuilding of the problematic regex.

### 2. Iterative Regex Simplification (When Substitution Fails)

If substitution logs indicate that a specific regex pattern is not matching as expected (e.g., `scriptContentLength` doesn't change after its application):

1.  **Isolate the Problematic Regex**: Identify the regex responsible for the failing substitution (e.g., `quotedMcpInputRegex` in our case).
2.  **Drastically Simplify**: Change the regex to its simplest possible form that should still match *some* part of the target placeholder string. For example, to debug `/(?:['"])--MCP_INPUT:(\w+)(?:[''])/g`, we first simplified it to `/--MCP_INPUT:/g`.
3.  **Test**: Run the script. If this extremely simple regex works (i.e., makes replacements and changes `scriptContentLength`), it confirms that the core string replacement mechanism is functional in that part of the code.
4.  **Incrementally Rebuild**: Gradually add parts back to the regex, testing at each step:
    *   Test capture groups: e.g., `/--MCP_INPUT:(\w+)/g` to ensure `keyName` is captured.
    *   Test character sets or specific quoting: e.g., try matching only double quotes `/"--MCP_INPUT:(\w+)\"/g`, then add single quotes.
    *   Test non-capturing groups or more complex constructs like backreferences (e.g., `/(["\'])--MCP_INPUT:(\w+)\1/g` which eventually solved our problem for matching surrounding quotes).
5.  **Examine Replacement Logic**: Ensure the replacement function uses the captured groups correctly and that the replacement value (e.g., from `valueToAppleScriptLiteral`) is what you expect.

This methodical approach helps pinpoint exactly which part of a complex regex is causing the failure.

### 3. Test Snippets in Script Editor

If a script fails and substitution seems correct, or if it's an inline script or script file:

1.  **Isolate the AppleScript/JXA**: Take the final, substituted script content (available from `includeExecutedScriptInOutput: true` or the error message).
2.  **Run in Script Editor (for AppleScript) or a JXA environment**: macOS's Script Editor provides better error highlighting and a more direct execution environment.
    *   Paste the script content.
    *   Run it.
    *   Observe any errors. Script Editor often gives more precise locations for syntax errors.

### 4. Check macOS Permissions

Many AppleScript/JXA operations require specific permissions:

*   **Automation Permissions**: To control other applications (e.g., Finder, Safari, Mail).
    *   System Settings > Privacy & Security > Automation.
    *   Ensure the application running the MCP server (e.g., Terminal) has permissions for target applications.
*   **Accessibility Permissions**: For UI scripting (e.g., `tell application "System Events" to keystroke...`).
    *   System Settings > Privacy & Security > Accessibility.
    *   Ensure the application running the MCP server is listed and enabled.
*   **Full Disk Access**: May be needed for scripts interacting with a wide range of files.
    *   System Settings > Privacy & Security > Full Disk Access.

Permissions issues often result in errors like `-1743` (errAEEventNotPermitted), `-1712` (errAEEventTimedOut, often when a permission dialog is hidden), or scripts failing silently.

### 5. Use `display dialog` or `log` (AppleScript)

For complex AppleScript logic, insert `display dialog` or `log` statements to track variable values or execution flow. These will appear in Script Editor's results or log window.

```applescript
set myVar to "test"
display dialog "myVar is: " & myVar
log "myVar is: " & myVar
```

For JXA, use `console.log()`.

## Common AppleScript Error Codes

*   **-2741 (errAEParsingFailed)**: Syntax error. Often "Expected , or } but found..." This was the primary error encountered due to failed placeholder substitution.
*   **-1728 (errAEValueNotSettable)**: Tried to set a read-only property or an element that doesn't exist (e.g., `set property of missing value`).
*   **-1708 (errAEHandlerNotFound)**: A command or handler doesn't exist for the target application.
*   **-1743 (errAEEventNotPermitted)**: Often a permissions issue (see Automation/Accessibility above).
*   **-1712 (errAEEventTimedOut)**: Script took too long, or a hidden permissions dialog might be blocking execution.
*   **-10004 (errAEAccessDenied)**: Typically a file access or permissions issue.

By using these techniques, particularly the `includeSubstitutionLogs` feature and iterative debugging, you can more effectively diagnose and resolve issues with your AppleScript and JXA automations executed via this server. 