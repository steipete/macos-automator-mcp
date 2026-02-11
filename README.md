# macOS Automator MCP 🤖 - Your Friendly Neighborhood RoboScripter™

![macOS Automator MCP Server](assets/logo.png)

## 🎯 Mission Control: Teaching Robots to Click Buttons Since 2024

Welcome to the automated future where your Mac finally does what you tell it to! This Model Context Protocol (MCP) server transforms your AI assistant into a silicon-based intern who actually knows AppleScript and JavaScript for Automation (JXA). 

No more copy-pasting scripts like a caveman - let the robots handle the robot work! Our knowledge base contains over 200 pre-programmed automation sequences, loaded faster than you can say "Hey Siri, why don't you work like this?"

## 🚀 Why Let Robots Run Your Mac?
- **Remote Control Reality**: Execute AppleScript/JXA scripts via MCP - it's like having a tiny robot inside your Mac!
- **Knowledge Base of Power**: 200+ pre-built automation recipes. From "toggle dark mode" to "extract all URLs from Safari" - we've got your robot needs covered.
- **App Whisperer**: Control any macOS application programmatically. Make Finder dance, Safari sing, and Terminal... well, terminate things.
- **AI Workflow Integration**: Connect your Mac to the AI revolution. Your LLM can now actually DO things instead of just talking about them!

## 🔧 Robot Requirements (Prerequisites)
- **Node.js** (version >=18.0.0) - Because even robots need a runtime
- **macOS** - Sorry Windows users, this is an Apple-only party 🍎
- **⚠️ CRITICAL: Permission to Automate (Your Mac's Trust Issues):**
    - The application running THIS MCP server (e.g., Terminal, your Node.js application) requires explicit user permissions on the macOS machine where the server is running.
    - **Automation Permissions:** To control other applications (Finder, Safari, Mail, etc.).
        - Go to: System Settings > Privacy & Security > Automation.
        - Find the application running the server (e.g., Terminal) in the list.
        - Ensure it has checkboxes ticked for all applications it needs to control.
        - See example: `docs/automation-permissions-example.png` (placeholder image).
    - **Accessibility Permissions:** For UI scripting via "System Events" (e.g., simulating clicks, keystrokes).
        - Go to: System Settings > Privacy & Security > Accessibility.
        - Add the application running the server (e.g., Terminal) to the list and ensure its checkbox is ticked.
    - First-time attempts to control a new application or use accessibility features may still trigger a macOS confirmation prompt, even if pre-authorized. The server itself cannot grant these permissions.

## 🏃‍♂️ Quick Start: Release the Robots!

The easiest way to deploy your automation army is via `npx`. No installation needed - just pure robot magic!

### Claude Desktop / Claude Code

Add this to your MCP client's `mcp.json`:

```json
{
  "mcpServers": {
    "macos_automator": {
      "command": "npx",
      "args": [
        "-y",
        "@steipete/macos-automator-mcp"
      ]
    }
  }
}
```

### VS Code (GitHub Copilot)

Add this to your `.vscode/mcp.json`:

```json
{
  "servers": {
    "macos_automator": {
      "command": "npx",
      "args": [
        "-y",
        "@steipete/macos-automator-mcp"
      ]
    }
  }
}
```

> **Note:** Don't use `@latest` version tag - some MCP clients (like VS Code) don't support it. The package will automatically use the latest version.

### 🛠️ Robot Workshop Mode (Local Development)

Want to tinker with the robot's brain? Clone the repo and become a robot surgeon!

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/steipete/macos-automator-mcp.git
    cd macos-automator-mcp
    npm install # Ensure dependencies are installed
    ```

2.  **Configure your MCP client:**
    Update your MCP client's configuration to point to the absolute path of the `start.sh` script within your cloned repository.

    Example `mcp.json` configuration snippet:
    ```json
    {
      "mcpServers": {
        "macos_automator_local": {
          "command": "/absolute/path/to/your/cloned/macos-automator-mcp/start.sh",
          "env": {
            "LOG_LEVEL": "DEBUG"
          }
        }
      }
    }
    ```
    **Important:** Replace `/absolute/path/to/your/cloned/macos-automator-mcp/start.sh` with the correct absolute path on your system.

    The `start.sh` script will automatically use `tsx` to run the TypeScript source directly if a compiled version is not found, or run the compiled version from `dist/` if available. It respects the `LOG_LEVEL` environment variable.

    **Note for Developers:** The `start.sh` script, particularly if modified to remove any pre-existing compiled `dist/server.js` before execution (e.g., by adding `rm -f dist/server.js`), is designed to ensure you are always running the latest TypeScript code from the `src/` directory via `tsx`. This is ideal for development to prevent issues with stale builds. For production deployment (e.g., when published to npm), a build process would typically create a definitive `dist/server.js` which would then be the entry point for the published package.

## 🤖 Robot Toolbox

### 1. `execute_script` - The Script Launcher 9000

Your robot's primary weapon for macOS domination. Feed it AppleScript or JXA, and watch the magic happen! 
Scripts can be provided as inline content (`script_content`), an absolute file path (`script_path`), or by referencing a script from the built-in knowledge base using its unique `kb_script_id`.

**Script Sources (mutually exclusive):**
-   `script_content` (string): Raw script code.
-   `script_path` (string): Absolute POSIX path to a script file (e.g., `.applescript`, `.scpt`, `.js`).
-   `kb_script_id` (string): The ID of a pre-defined script from the server's knowledge base. Use the `get_scripting_tips` tool to discover available script IDs and their functionalities.

**Language Specification:**
-   `language` (enum: 'applescript' | 'javascript', optional): Specify the language.
    -   If using `kb_script_id`, the language is inferred from the knowledge base script.
    -   If using `script_content` or `script_path` and `language` is omitted, it defaults to 'applescript'.

**Passing Inputs to Scripts:**
-   `arguments` (array of strings, optional): 
    -   For `script_path`: Passed as standard arguments to the script's `on run argv` (AppleScript) or `run(argv)` (JXA) handler.
    -   For `kb_script_id`: Used if the pre-defined script is designed to accept positional string arguments (e.g., replaces placeholders like `--MCP_ARG_1`, `--MCP_ARG_2`). Check the script's `argumentsPrompt` from `get_scripting_tips`.
-   `input_data` (JSON object, optional): 
    -   Primarily for `kb_script_id` scripts designed to accept named, structured inputs.
    -   Values from this object replace placeholders in the script (e.g., `--MCP_INPUT:yourKeyName`). See `argumentsPrompt` from `get_scripting_tips`.
    -   Values (strings, numbers, booleans, simple arrays/objects) are converted to their AppleScript literal equivalents.

**Other Options:**
-   `timeout_seconds` (integer, optional, default: 60): Maximum execution time.
-   `output_format_mode` (enum, optional, default: 'auto'): Controls `osascript` output formatting flags.
    *   `'auto'`: (Default) Uses human-readable for AppleScript (`-s h`), and direct output (no `-s` flags) for JXA.
    *   `'human_readable'`: Forces `-s h` (human-readable output, mainly for AppleScript).
    *   `'structured_error'`: Forces `-s s` (structured error reporting, mainly for AppleScript).
    *   `'structured_output_and_error'`: Forces `-s ss` (structured output for main result and errors, mainly for AppleScript).
    *   `'direct'`: No `-s` flags are used (recommended for JXA, also the behavior for JXA in `auto` mode).
-   `include_executed_script_in_output` (boolean, optional, default: false): If true, the output will include the full script content (after any placeholder substitutions for knowledge base scripts) or the script path that was executed. This is appended as an additional text part in the output content array.
-   `include_substitution_logs` (boolean, optional, default: false): If true, detailed logs of placeholder substitutions performed on knowledge base scripts are included in the output. This is useful for debugging how `input_data` and `arguments` are processed and inserted into the script. The logs are prepended to the script output on success or appended to the error message on failure.
-   `report_execution_time` (boolean, optional, default: false): If `true`, an additional message with the formatted script execution time will be included in the response content array.

**SECURITY WARNING & MACOS PERMISSIONS:** (Same critical warnings as before about arbitrary script execution and macOS Automation/Accessibility permissions).

**Examples:**
-   (Existing examples for inline/file path remain relevant)
-   **Using Knowledge Base Script by ID:**
    ```json
    {
      "toolName": "execute_script",
      "input": {
        "kb_script_id": "safari_get_active_tab_url",
        "timeout_seconds": 10
      }
    }
    ```
-   **Using Knowledge Base Script by ID with `input_data`:**
    ```json
    {
      "toolName": "execute_script",
      "input": {
        "kb_script_id": "finder_create_folder_at_path",
        "input_data": {
          "folder_name": "New MCP Folder",
          "parent_path": "~/Desktop"
        }
      }
    }
    ```

**Response Format:**

The `execute_script` tool returns a response in the following format:

```typescript
{
  content: Array<{
    type: 'text';
    text: string;
  }>;
  isError?: boolean;
}
```

- `content`: An array of text content items containing the script output
- `isError`: (boolean, optional) Set to `true` when the script execution produced an error. This flag is set when:
  - The script output (stdout) starts with "Error" (case-insensitive)
  - This helps clients easily determine if the execution failed without parsing the output text

**Example Response (Success):**
```json
{
  "content": [{
    "type": "text",
    "text": "Script executed successfully"
  }]
}
```

**Example Response (Error):**
```json
{
  "content": [{
    "type": "text",
    "text": "Error: Cannot find application 'Safari'"
  }],
  "isError": true
}
```

### 2. `get_scripting_tips` - The Robot's Encyclopedia

Your personal automation librarian! Searches through 200+ pre-built scripts faster than you can Google "how to AppleScript". Perfect for when your robot needs inspiration.

**Arguments:**
-   `list_categories` (boolean, optional, default: false): If true, returns only the list of available knowledge base categories and their descriptions. Overrides other parameters.
-   `category` (string, optional): Filters tips by a specific category ID (e.g., "finder", "safari").
-   `search_term` (string, optional): Searches for a keyword within tip titles, descriptions, script content, keywords, or IDs.
-   `refresh_database` (boolean, optional, default: false): If true, forces a reload of the entire knowledge base from disk before processing the request. This is useful during development if you are actively modifying knowledge base files and want to ensure the latest versions are used without restarting the server.
-   `limit` (integer, optional, default: 10): Maximum number of results to return.

**Output:**
-   Returns a Markdown formatted string containing the requested tips, including their title, description, script content, language, runnable ID (if applicable), argument prompts, and notes.

**Example Usage:**
-   List all categories:
    `{ "toolName": "get_scripting_tips", "input": { "list_categories": true } }`
-   Get tips for "safari" category:
    `{ "toolName": "get_scripting_tips", "input": { "category": "safari" } }`
-   Search for tips related to "clipboard":
    `{ "toolName": "get_scripting_tips", "input": { "search_term": "clipboard" } }`

### 3. `accessibility_query` - The UI X-Ray Vision

Give your robot superhero powers to see and click ANY button in ANY app! This tool peers into the soul of macOS applications using the accessibility framework. Powered by the mystical `ax` binary, it's like having X-ray vision for user interfaces.

The `ax` binary, and therefore this tool, can accept its JSON command input in multiple ways:
1.  **Direct JSON String Argument:** If `ax` is invoked with a single command-line argument that is not a valid file path, it will attempt to parse this argument as a complete JSON string.
2.  **File Path Argument:** If `ax` is invoked with a single command-line argument that is a valid file path, it will read the complete JSON command from this file.
3.  **STDIN:** If `ax` is invoked with no command-line arguments, it will read the complete JSON command (which can be multi-line) from standard input.

This tool exposes the complete macOS accessibility API capabilities, allowing detailed inspection of UI elements and their properties. It's particularly useful for automating interactions with applications that don't have robust AppleScript support or when you need to inspect the UI structure in detail.

**Input Parameters:**

*   `command` (enum: 'query' | 'perform', required): The operation to perform.
    *   `query`: Retrieves information about UI elements.
    *   `perform`: Executes an action on a UI element (like clicking a button).

*   `locator` (object, required): Specifications to find the target element(s).
    *   `app` (string, required): The application to target, specified by either bundle ID or display name (e.g., "Safari", "com.apple.Safari").
    *   `role` (string, required): The accessibility role of the target element (e.g., "AXButton", "AXStaticText").
    *   `match` (object, required): Key-value pairs of attributes to match. Can be empty (`{}`) if not needed.
    *   `navigation_path_hint` (array of strings, optional): Path to navigate within the application hierarchy (e.g., `["window[1]", "toolbar[1]"]`).

*   `return_all_matches` (boolean, optional): When `true`, returns all matching elements rather than just the first match. Default is `false`.

*   `attributes_to_query` (array of strings, optional): Specific attributes to query for matched elements. If not provided, common attributes will be included. Examples: `["AXRole", "AXTitle", "AXValue"]`

*   `required_action_name` (string, optional): Filter elements to only those supporting a specific action (e.g., "AXPress" for clickable elements).

*   `action_to_perform` (string, optional, required when `command="perform"`): The accessibility action to perform on the matched element (e.g., "AXPress" to click a button).

*   `report_execution_time` (boolean, optional): If true, the tool will return an additional message containing the formatted script execution time. Defaults to false.

*   `limit` (integer, optional): Maximum number of lines to return in the output. Defaults to 500. Output will be truncated if it exceeds this limit.

*   `max_elements` (integer, optional): For `return_all_matches: true` queries, this specifies the maximum number of UI elements the `ax` binary will fully process and return attributes for. If omitted, an internal default (e.g., 200) is used. This helps manage performance when querying UIs with a very large number of matching elements (like numerous text fields on a complex web page). This is different from `limit`, which truncates the final text output based on lines.

*   `debug_logging` (boolean, optional): If true, enables detailed debug logging from the underlying `ax` binary. This diagnostic information will be included in the response, which can be helpful for troubleshooting complex queries or unexpected behavior. Defaults to false.

*   `output_format` (enum: 'smart' | 'verbose' | 'text_content', optional, default: 'smart'): Controls the format and verbosity of the attribute output from the `ax` binary.
    *   `'smart'`: (Default) Optimized for readability. Omits attributes with empty or placeholder values. Returns key-value pairs.
    *   `'verbose'`: Maximum detail. Includes all attributes, even empty/placeholders. Key-value pairs. Best for debugging element properties.
    *   `'text_content'`: Highly compact for text extraction. Returns only concatenated text values of common textual attributes (e.g., AXValue, AXTitle). No keys are returned. Ideal for quickly getting all text from elements; the `attributes_to_query` parameter is ignored in this mode.

**Example Queries (Note: key names have changed to snake_case):**

1.  **Find all text elements in the front Safari window:**
    ```json
    {
      "command": "query",
      "return_all_matches": true,
      "locator": {
        "app": "Safari",
        "role": "AXStaticText",
        "match": {},
        "navigation_path_hint": ["window[1]"]
      }
    }
    ```

2.  **Find and click a button with a specific title:**
    ```json
    {
      "command": "perform",
      "locator": {
        "app": "System Settings",
        "role": "AXButton",
        "match": {"AXTitle": "General"}
      },
      "action_to_perform": "AXPress"
    }
    ```

3.  **Get detailed information about the focused UI element:**
    ```json
    {
      "command": "query",
      "locator": {
        "app": "Mail",
        "role": "AXTextField",
        "match": {"AXFocused": "true"}
      },
      "attributes_to_query": ["AXRole", "AXTitle", "AXValue", "AXDescription", "AXHelp", "AXPosition", "AXSize"]
    }
    ```

**Note:** Using this tool requires that the application running this server has the necessary Accessibility permissions in macOS System Settings > Privacy & Security > Accessibility.

## 🎮 Robot Playground: Cool Things Your New Robot Friend Can Do

-   **Application Control (Teaching Apps Who's Boss):**
    -   Get the current URL from Safari: `{ "input": { "script_content": "tell application \"Safari\" to get URL of front document" } }`
    -   Get subjects of unread emails in Mail: `{ "input": { "script_content": "tell application \"Mail\" to get subject of messages of inbox whose read status is false" } }`
-   **File System Operations (Digital Housekeeping):**
    -   List files on the Desktop: `{ "input": { "script_content": "tell application \"Finder\" to get name of every item of desktop" } }`
    -   Create a new folder: `{ "input": { "script_content": "tell application \"Finder\" to make new folder at desktop with properties {name:\"Robot's Secret Stash\"}" } }`
-   **System Interactions (Mac Mind Control):**
    -   Display a system notification: `{ "input": { "script_content": "display notification \"🤖 Beep boop! Task complete!\" with title \"Robot Report\"" } }`
    -   Set system volume: `{ "input": { "script_content": "set volume output volume 50" } }` (0-100)
    -   Get current clipboard content: `{ "input": { "script_content": "the clipboard" } }`

## 🔧 When Robots Rebel (Troubleshooting)

-   **"Access Denied" Drama:** Your robot lacks permissions! Check System Settings > Privacy & Security. Give your Terminal the keys to the kingdom.
-   **Script Syntax Sadness:** Even robots make typos. Test scripts in Script Editor first - it's like spell-check for automation.
-   **Timeout Tantrums:** Some tasks take time. Increase `timeout_seconds` if your robot needs more than 60 seconds to complete its mission.
-   **File Not Found Fiasco:** Robots need absolute paths, not relative ones. No shortcuts in robot land!
-   **JXA Output Oddities:** JavaScript robots are picky. Use `output_format_mode: 'direct'` or let `'auto'` mode handle it.

## 🎛️ Robot Control Panel (Configuration)

Fine-tune your robot's behavior with these environment variables:

-   **`LOG_LEVEL`**: How chatty should your robot be?
    -   `DEBUG`: Robot tells you EVERYTHING (TMI mode)
    -   `INFO`: Normal robot chatter
    -   `WARN`: Only important stuff
    -   `ERROR`: Silent mode (robot speaks only when things explode)
    -   Example: `LOG_LEVEL=DEBUG npx @steipete/macos-automator-mcp@latest`

-   **`KB_PARSING`**: When should the robot load its brain?
    -   `lazy` (default): Loads knowledge on-demand (fast startup, lazy robot)
    -   `eager`: Loads everything at startup (slower start, ready-to-go robot)
    -   Example: `KB_PARSING=eager ./start.sh`

## 👨‍🔬 Robot Scientists Welcome!

Want to upgrade your robot? Check out [DEVELOPMENT.md](DEVELOPMENT.md) for the full technical manual on teaching new tricks to your automation assistant.

## 🧠 Teach Your Robot New Tricks (Local Knowledge Base)

Your robot can learn custom skills! Create your own automation recipes and watch your robot evolve.

By default, the application will look for this local knowledge base at `~/.macos-automator/knowledge_base`.
You can customize this path by setting the `LOCAL_KB_PATH` environment variable.

**Example:**

Suppose you have a local knowledge base at `/Users/yourname/my-custom-kb`.
Set the environment variable:
`export LOCAL_KB_PATH=/Users/yourname/my-custom-kb`

Or, if you are running the validator script, you can use the `--local-kb-path` argument:
`npm run validate:kb -- --local-kb-path /Users/yourname/my-custom-kb`

**Structure and Overrides:**

*   Your local knowledge base should mirror the category structure of the main `knowledge_base` (e.g., `01_applescript_core`, `05_web_browsers/safari`, etc.).
*   You can add new `.md` tip files or `_shared_handlers` (e.g., `.applescript` or `.js` files).
*   If a tip ID (either from frontmatter `id:` or generated from filename/path) in your local knowledge base matches an ID in the embedded knowledge base, your local version will **override** the embedded one.
*   Similarly, shared handlers with the same name and language (e.g., `my_utility.applescript`) in your local `_shared_handlers` directory will override any embedded ones with the same name and language within the same category (or globally if you place them at the root of your local KB's `_shared_handlers`).
*   Category descriptions from `_category_info.md` in your local KB can also override those from the embedded KB for the same category.

This allows for personalization and extension of the available automation scripts and tips without modifying the core application files.

## 🤝 Join the Robot Revolution!

Found a bug? Got a cool automation idea? Your robot army needs YOU! Submit issues and pull requests to the [GitHub repository](https://github.com/steipete/macos-automator-mcp).

## 💪 Robot Superpowers Showcase

Here's what your new silicon sidekick can do out of the box:

### 🖥️ Terminal Tamer
- **Command Line Wizardry:** Open new tabs, run commands, capture output - your robot speaks fluent bash!
  ```
  { "input": { "kb_script_id": "terminal_app_run_command_new_tab", "input_data": { "command": "echo '🤖 Hello World!'" } } }
  ```

### 🌐 Browser Bot
- **Web Automation Master:** Control Chrome and Safari like a puppet master!
  ```
  { "input": { "kb_script_id": "safari_get_front_tab_url" } }
  ```
- **JavaScript Injection:** Make web pages dance to your robot's tune
- **Screenshot Sniper:** Capture any webpage faster than you can say "cheese"

### ⚙️ System Sorcerer
- **Dark Mode Toggle:** Because robots have sensitive optical sensors
  ```
  { "input": { "kb_script_id": "systemsettings_toggle_dark_mode_ui" } }
  ```
- **Clipboard Commander:** Copy, paste, and manipulate like a pro
- **Notification Ninja:** Send alerts that actually get noticed

### 📁 File System Feng Shui
- **Folder Creator 3000:** Organize your digital life with robotic precision
  ```
  { "input": { "kb_script_id": "finder_create_new_folder_desktop", "input_data": { "folder_name": "Robot Paradise" } } }
  ```
- **Text File Telepathy:** Read and write files faster than humanly possible

### 📱 App Whisperer
- **Calendar Conductor:** Schedule meetings while you sleep
- **Email Automator:** Send emails without lifting a finger
- **Music Maestro:** DJ your playlists programmatically
  ```
  { "input": { "kb_script_id": "music_playback_controls", "input_data": { "action": "play" } } }
  ```

🎯 **Pro Tip:** Use `get_scripting_tips` to discover all 200+ automation recipes!

## 📜 Legal Stuff (Robot Rights)

This project is licensed under the MIT License - which means your robot is free to roam! See the [LICENSE](LICENSE) file for the fine print.

---

🤖 **Remember:** With great automation power comes great responsibility. Use your robot wisely!

<a href="https://glama.ai/mcp/servers/@steipete/macos-automator-mcp">
  <img width="380" height="200" src="https://glama.ai/mcp/servers/@steipete/macos-automator-mcp/badge" alt="macOS Automator Server MCP server" />
</a>
