# macOS Automator MCP Server

## Overview
This project provides a Model Context Protocol (MCP) server, `macos_automator`, that exposes a single tool (`execute_script`) to run AppleScript and JavaScript for Automation (JXA) scripts on macOS.

## Benefits
- Execute AppleScript and JXA scripts remotely via the MCP.
- Control macOS applications and system functions programmatically.
- Integrate macOS automation into larger workflows.

## Prerequisites
- Node.js (version >=18.0.0 recommended, see `package.json` engines).
- macOS.
- **CRITICAL PERMISSIONS SETUP:**
    - The application running THIS MCP server (e.g., Terminal, your Node.js application) requires explicit user permissions on the macOS machine where the server is running.
    - **Automation Permissions:** To control other applications (Finder, Safari, Mail, etc.).
        - Go to: System Settings > Privacy & Security > Automation.
        - Find the application running the server (e.g., Terminal) in the list.
        - Ensure it has checkboxes ticked for all applications it needs to control.
        - See example: `docs/automation-permissions-example.png` (placeholder image).
    - **Accessibility Permissions:** For UI scripting via "System Events" (e.g., simulating clicks, keystrokes).
        - Go to: System Settings > Privacy & Security > Accessibility.
        - Add the application running the server (e.g., Terminal) to the list and ensure its checkbox is ticked.
        - See example: `docs/accessibility-permissions-example.png` (placeholder image).
    - First-time attempts to control a new application or use accessibility features may still trigger a macOS confirmation prompt, even if pre-authorized. The server itself cannot grant these permissions.

## Installation & Usage

The primary way to run this server is via `npx`. This ensures you're using the latest version without needing a global install.

Add the following configuration to your MCP client's `mcp.json` (or equivalent configuration):

```json
{
  "mcpServers": {
    "macos_automator": {
      "command": "npx",
      "args": [
        "-y", // Auto-accept npx install prompt if not already cached
        "@steipete/macos-automator-mcp@latest" // Replace @steipete with your npm username if you publish
      ],
      "env": {
        "LOG_LEVEL": "INFO" // Optional: "DEBUG", "INFO", "WARN", "ERROR"
      }
    }
    // ... other MCP server configurations
  }
}
```

## Tool Provided: `execute_script`

Executes an AppleScript or JavaScript for Automation (JXA) script on macOS.
The script can be provided as inline content or by specifying an absolute POSIX path to a script file on the server.
Returns the standard output (stdout) of the script.

SECURITY WARNING:
- Executing arbitrary scripts carries inherent security risks. Ensure the source of scripts is trusted.
- This tool can interact with ANY scriptable application, access the file system, and run shell commands via AppleScript's 'do shell script'.

MACOS PERMISSIONS (CRITICAL - SEE README.MD FOR FULL DETAILS):
- The application running THIS MCP server (e.g., Terminal, Node.js app) requires explicit user permission.
- Set in: System Settings > Privacy & Security > Automation (to control other apps like Finder, Safari, Mail).
- Set in: System Settings > Privacy & Security > Accessibility (for UI scripting via "System Events").
- These permissions must be granted ON THE MACOS MACHINE WHERE THIS SERVER IS RUNNING.
- First-time attempts to control a new app may still trigger a macOS confirmation prompt.

LANGUAGE SUPPORT:
- AppleScript (default): Powerful for controlling macOS applications and UI.
- JavaScript for Automation (JXA): Use JavaScript syntax for macOS automation. Specify with 'language: "javascript"'.

SCRIPT ARGUMENTS (for scriptPath):
- Arguments passed in the 'arguments' array are available to the script.
- AppleScript: 'on run argv ... end run' (argv is a list of strings).
- JXA: 'function run(argv) { ... }' (argv is an array of strings).

OUTPUT:
- The result of the last evaluated expression in the script is returned as text.
- Use 'useScriptFriendlyOutput: true' for '-ss' flag, which can provide more structured output for lists, etc.

EXAMPLES (AppleScript):
1. Get current Safari URL:
   { "scriptContent": "tell application \"Safari\" to get URL of front document" }
2. Display a notification:
   { "scriptContent": "display notification \"Task complete!\" with title \"MCP\"" }
3. Get files on Desktop:
   { "scriptContent": "tell application \"Finder\" to get name of every item of desktop" }
4. Use script-friendly output for a list:
   { "scriptContent": "return {\"item a\", \"item b\"}", "useScriptFriendlyOutput": true }
5. Run a shell command:
   { "scriptContent": "do shell script \"ls -la ~/Desktop\"" }
6. Execute a script file with arguments:
   { "scriptPath": "/Users/Shared/myscripts/greet.applescript", "arguments": ["Alice"] }
   (greet.applescript: 'on run argv\n display dialog (\"Hello \" & item 1 of argv)\nend run')

EXAMPLES (JXA - set 'language: "javascript"'):
1. Get Finder version:
   { "scriptContent": "Application('Finder').version()", "language": "javascript" }
2. Display a dialog:
   { "scriptContent": "Application.currentApplication().includeStandardAdditions = true; Application.currentApplication().displayDialog('Hello from JXA!')", "language": "javascript" }

### Arguments

The `execute_script` tool accepts the following arguments (defined in `src/schemas.ts`):

-   `scriptContent` (string, optional): The raw AppleScript or JXA code to execute. Mutually exclusive with `scriptPath`.
-   `scriptPath` (string, optional): The absolute POSIX path to a script file (.scpt, .applescript, .js for JXA) on the server. Mutually exclusive with `scriptContent`.
-   `language` (enum: 'applescript' | 'javascript', optional, default: 'applescript'): The scripting language.
-   `arguments` (array of strings, optional, default: []): Arguments for script files.
-   `timeoutSeconds` (integer, optional, default: 30): Maximum execution time in seconds.
-   `useScriptFriendlyOutput` (boolean, optional, default: false): Use `osascript -ss` for script-friendly output.

## Key Use Cases & Examples

-   **Application Control:**
    -   Get the current URL from Safari: `{ "scriptContent": "tell application \"Safari\" to get URL of front document" }`
    -   Get subjects of unread emails in Mail: `{ "scriptContent": "tell application \"Mail\" to get subject of messages of inbox whose read status is false" }`
-   **File System Operations:**
    -   List files on the Desktop: `{ "scriptContent": "tell application \"Finder\" to get name of every item of desktop" }`
    -   Create a new folder: `{ "scriptContent": "tell application \"Finder\" to make new folder at desktop with properties {name:\"My New Folder\"}" }`
-   **System Interactions:**
    -   Display a system notification: `{ "scriptContent": "display notification \"Important Update!\" with title \"System Alert\"" }`
    -   Set system volume: `{ "scriptContent": "set volume output volume 50" }` (0-100)
    -   Get current clipboard content: `{ "scriptContent": "the clipboard" }`

## Troubleshooting

-   **Permissions Errors:** If scripts fail to control apps or perform UI actions, double-check Automation and Accessibility permissions in System Settings for the application running the MCP server (e.g., Terminal).
-   **Script Syntax Errors:** `osascript` errors will be returned in the `stderr` or error message. Test complex scripts locally using Script Editor (for AppleScript) or a JXA runner first.
-   **Timeouts:** If a script takes longer than `timeoutSeconds` (default 30s), it will be terminated. Increase the timeout for long-running scripts.
-   **File Not Found:** Ensure `scriptPath` is an absolute POSIX path accessible by the user running the MCP server.
-   **Incorrect Output:** Experiment with `useScriptFriendlyOutput: true` if the default human-readable output is not suitable for parsing (especially for lists or records).

## Configuration via Environment Variables

-   `LOG_LEVEL`: Set the logging level for the server.
    -   Values: `DEBUG`, `INFO`, `WARN`, `ERROR`
    -   Example: `LOG_LEVEL=DEBUG npx @steipete/macos-automator-mcp@latest`

## For Developers

For instructions on local development, setup, and contribution guidelines, please see [DEVELOPMENT.md](DEVELOPMENT.md).

## Contributing

Contributions are welcome! Please submit issues and pull requests to the [GitHub repository](https://github.com/steipete/macos-automator-mcp).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 