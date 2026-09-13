# Debugging AppleScript and JXA Execution

Executing AppleScript or JXA scripts, especially through an intermediary layer like this MCP server, can sometimes be challenging to debug. AppleScript's error messages can be cryptic, and issues might arise from the script content itself, placeholder substitution, or macOS permissions.

This guide provides tips and techniques based on common scenarios encountered.

## Key Debugging Strategies

### 1. Enable Detailed Substitution Logging

When using knowledge base scripts (`kb_script_id`) with the `execute_script` tool, placeholders like `--MCP_INPUT:keyName` and `--MCP_ARG_N` are substituted with values from `input_data` and `arguments` respectively. If this substitution is incorrect, it can lead to AppleScript syntax errors (like the common `-2741 "Expected , or } but found class name."`).

To understand exactly how these substitutions are being performed:

- **Use `include_substitution_logs: true`**: Add this parameter to your `execute_script` call.
  ```json
  {
    "toolName": "execute_script",
    "input": {
      "kb_script_id": "your_script_id",
      "input_data": { "some_key": "someValue" },
      "include_substitution_logs": true
    }
  }
  ```
- **Inspect the Output**: The server will then include a detailed log of each substitution step in the output. On success, these logs are prepended to the script's standard output. On failure, they are appended to the error message. This allows you to see:
  - The source placeholder that matched.
  - The language-specific literal inserted in its place.

Substitution scans the source once, so placeholder-like text inside input values stays literal. Named placeholders map camelCase to snake_case input keys; positional placeholders use zero-based `${arguments[N]}` or one-based `--MCP_ARG_N`.

### 2. Check Placeholder Context and Language

Use placeholders as complete expressions, such as `return ${inputData.message}` in AppleScript or `JSON.stringify(${inputData.value})` in JXA. A whole quoted placeholder is also supported; embedding a placeholder inside a larger string literal is not supported.

For a failing KB script, compare its code-block language with the substituted source. AppleScript lists and records use braces; JXA arrays and objects use JSON syntax. Missing values become `missing value` in AppleScript and `null` in JXA. Test a small synthetic input first, especially when values contain quotes, backslashes, or newlines.

### 3. Test Snippets in Script Editor

If a script fails and substitution seems correct, or if it's an inline script or script file:

1.  **Isolate the AppleScript/JXA**: Take the final, substituted script content (available from `include_executed_script_in_output: true` or the error message).
2.  **Run in Script Editor (for AppleScript) or a JXA environment**: macOS's Script Editor provides better error highlighting and a more direct execution environment.
    - Paste the script content.
    - Run it.
    - Observe any errors. Script Editor often gives more precise locations for syntax errors.

### 4. Check macOS Permissions

Many AppleScript/JXA operations require specific permissions:

- **Automation Permissions**: To control other applications (e.g., Finder, Safari, Mail).
  - System Settings > Privacy & Security > Automation.
  - Ensure the application running the MCP server (e.g., Terminal) has permissions for target applications.
- **Accessibility Permissions**: For UI scripting (e.g., `tell application "System Events" to keystroke...`).
  - System Settings > Privacy & Security > Accessibility.
  - Ensure the application running the MCP server is listed and enabled.
- **Full Disk Access**: May be needed for scripts interacting with a wide range of files.
  - System Settings > Privacy & Security > Full Disk Access.

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

- **-2741 (errAEParsingFailed)**: Syntax error. Often "Expected , or } but found..." This was the primary error encountered due to failed placeholder substitution.
- **-1728 (errAEValueNotSettable)**: Tried to set a read-only property or an element that doesn't exist (e.g., `set property of missing value`).
- **-1708 (errAEHandlerNotFound)**: A command or handler doesn't exist for the target application.
- **-1743 (errAEEventNotPermitted)**: Often a permissions issue (see Automation/Accessibility above).
- **-1712 (errAEEventTimedOut)**: Script took too long, or a hidden permissions dialog might be blocking execution.
- **-10004 (errAEAccessDenied)**: Typically a file access or permissions issue.

By using these techniques, particularly the `include_substitution_logs` feature and iterative debugging, you can more effectively diagnose and resolve issues with your AppleScript and JXA automations executed via this server.
