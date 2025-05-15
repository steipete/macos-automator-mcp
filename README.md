# macOS Automator MCP Server

## Overview
This project provides a Model Context Protocol (MCP) server, `macos_automator`, that allows execution of AppleScript and JavaScript for Automation (JXA) scripts on macOS. It features a knowledge base of pre-defined scripts accessible by ID and supports inline scripts, script files, and argument passing.
The knowledge base is loaded lazily on first use for fast server startup.

## Benefits
- Execute AppleScript/JXA scripts remotely via MCP.
- Utilize a rich, extensible knowledge base of common macOS automation tasks.
- Control macOS applications and system functions programmatically.
- Integrate macOS automation into larger AI-driven workflows.

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

## Tools Provided

### 1. `execute_script`

Executes an AppleScript or JavaScript for Automation (JXA) script on macOS. 
Scripts can be provided as inline content (`scriptContent`), an absolute file path (`scriptPath`), or by referencing a script from the built-in knowledge base using its unique `knowledgeBaseScriptId`.

**Script Sources (mutually exclusive):**
-   `scriptContent` (string): Raw script code.
-   `scriptPath` (string): Absolute POSIX path to a script file (e.g., `.applescript`, `.scpt`, `.js`).
-   `knowledgeBaseScriptId` (string): The ID of a pre-defined script from the server's knowledge base. Use the `get_scripting_tips` tool to discover available script IDs and their functionalities.

**Language Specification:**
-   `language` (enum: 'applescript' | 'javascript', optional): Specify the language.
    -   If using `knowledgeBaseScriptId`, the language is inferred from the knowledge base script.
    -   If using `scriptContent` or `scriptPath` and `language` is omitted, it defaults to 'applescript'.

**Passing Inputs to Scripts:**
-   `arguments` (array of strings, optional): 
    -   For `scriptPath`: Passed as standard arguments to the script's `on run argv` (AppleScript) or `run(argv)` (JXA) handler.
    -   For `knowledgeBaseScriptId`: Used if the pre-defined script is designed to accept positional string arguments (e.g., replaces placeholders like `--MCP_ARG_1`, `--MCP_ARG_2`). Check the script's `argumentsPrompt` from `get_scripting_tips`.
-   `inputData` (JSON object, optional): 
    -   Primarily for `knowledgeBaseScriptId` scripts designed to accept named, structured inputs.
    -   Values from this object replace placeholders in the script (e.g., `--MCP_INPUT:yourKeyName`). See `argumentsPrompt` from `get_scripting_tips`.
    -   Values (strings, numbers, booleans, simple arrays/objects) are converted to their AppleScript literal equivalents.

**Other Options:**
-   `timeoutSeconds` (integer, optional, default: 30): Maximum execution time.
-   `useScriptFriendlyOutput` (boolean, optional, default: false): Uses `osascript -ss` flag for potentially more structured output, especially for lists and records.

**SECURITY WARNING & MACOS PERMISSIONS:** (Same critical warnings as before about arbitrary script execution and macOS Automation/Accessibility permissions).

**Examples:**
-   (Existing examples for inline/file path remain relevant)
-   **Using Knowledge Base Script by ID:**
    ```json
    {
      "toolName": "execute_script",
      "input": {
        "knowledgeBaseScriptId": "safari_get_active_tab_url", // Example ID
        "timeoutSeconds": 10
      }
    }
    ```
-   **Using Knowledge Base Script by ID with `inputData`:**
    ```json
    {
      "toolName": "execute_script",
      "input": {
        "knowledgeBaseScriptId": "finder_create_folder_at_path", // Example ID
        "inputData": {
          "folderName": "New MCP Folder",
          "parentPath": "~/Desktop"
        }
      }
    }
    ```

### 2. `get_scripting_tips`

Retrieves AppleScript/JXA tips, examples, and runnable script details from the server's knowledge base. Useful for discovering available scripts, their functionalities, and how to use them with `execute_script` (especially `knowledgeBaseScriptId`).

**Arguments:**
-   `listCategories` (boolean, optional, default: false): If true, returns only the list of available knowledge base categories and their descriptions. Overrides other parameters.
-   `category` (string, optional): Filters tips by a specific category ID (e.g., "finder", "safari").
-   `searchTerm` (string, optional): Searches for a keyword within tip titles, descriptions, script content, keywords, or IDs.

**Output:**
-   Returns a Markdown formatted string containing the requested tips, including their title, description, script content, language, runnable ID (if applicable), argument prompts, and notes.

**Example Usage:**
-   List all categories:
    `{ "toolName": "get_scripting_tips", "input": { "listCategories": true } }`
-   Get tips for "safari" category:
    `{ "toolName": "get_scripting_tips", "input": { "category": "safari" } }`
-   Search for tips related to "clipboard":
    `{ "toolName": "get_scripting_tips", "input": { "searchTerm": "clipboard" } }`

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

For detailed instructions on local development, project structure (including the `knowledge_base`), and contribution guidelines, please see [DEVELOPMENT.md](DEVELOPMENT.md).

## Contributing

Contributions are welcome! Please submit issues and pull requests to the [GitHub repository](https://github.com/steipete/macos-automator-mcp).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details. 