# macOS Automator MCP Server: System and Knowledge Base Specification

https://aistudio.google.com/prompts/1Uj4Cs_wt6Yt7tndf8bUy6BSTZDHIlU74

This document details the `macos_automator` MCP server, focusing on its architecture, features, and the specification for its extensive Markdown-file-based AppleScript/JXA Knowledge Base.

## Part 1: Server Implementation Specification

This part details the server's TypeScript code, tool definitions, and core functionalities including lazy loading of the knowledge base, script execution by ID, and placeholder substitution.

### 1. Project Structure

The server is organized as follows:

```
macos-automator-mcp/
├── src/
│   ├── server.ts             # Main MCP server logic, tool definitions
│   ├── ScriptExecutor.ts     # Core logic for calling 'osascript'
│   ├── logger.ts             # Logging utility
│   ├── placeholderSubstitutor.ts # Logic for substituting placeholders in scripts
│   ├── schemas.ts            # Zod schemas for MCP tool inputs
│   ├── types.ts              # Shared TypeScript types
│   └── services/
│       ├── KnowledgeBaseManager.ts # Manages KB loading, indexing, lazy loading
│       ├── kbLoader.ts             # Parses Markdown/frontmatter for KB tips & categories
│       ├── knowledgeBaseService.ts # Provides query interface for KB tips
│       └── scriptingKnowledge.types.ts # Types specific to parsed knowledge
├── knowledge_base/           # Contains .md tip files and shared handlers
│   ├── _shared_handlers/     # .applescript or .js reusable handlers
│   ├── 00_readme_and_conventions/
│   ├── 01_applescript_core/
│   └── (many other category subdirectories...)
├── docs/
│   └── spec.md (this file)
├── .gitignore
├── DEVELOPMENT.md
├── LICENSE
├── README.md
├── package.json
├── start.sh
└── tsconfig.json
```

### 2. Core TypeScript Types

#### A. `src/types.ts`
Defines general types for script execution and logging.

```typescript
// src/types.ts
export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface ScriptExecutionOptions {
  language?: 'applescript' | 'javascript';
  timeoutMs?: number;
  output_format_mode?: 'auto' | 'human_readable' | 'structured_error' | 'structured_output_and_error' | 'direct';
  arguments?: string[]; // For script files executed via path
}

export interface ScriptExecutionResult {
  stdout: string;
  stderr: string; // To capture warnings even on success
  execution_time_seconds: number;
}

// Error structure returned by ScriptExecutor on failure
export interface ScriptExecutionError extends Error {
  stdout?: string;
  stderr?: string;
  exitCode?: number | string | null;
  signal?: string | null;
  killed?: boolean;
  originalError?: unknown;
  isTimeout?: boolean;
  execution_time_seconds?: number;
}

// MCP Tool Response Types (simplified, actual response structure handled by SDK)
export interface ExecuteScriptResponse {
  content: Array<{
    type: 'text';
    text: string;
  }>;
  isError?: boolean;
  timings?: {
    execution_time_seconds?: number;
  };
}
```

#### B. `src/services/scriptingKnowledge.types.ts`
Defines types related to the parsed knowledge base content.

```typescript
// src/services/scriptingKnowledge.types.ts
export type KnowledgeCategory = string; // Derived from knowledge_base/ subdirectory names

export interface ScriptingTip {
  id: string; // Unique ID: frontmatter.id or generated (e.g., "safari_get_front_tab_url")
  category: KnowledgeCategory;
  title: string;
  description?: string;
  script: string;      // The AppleScript/JXA code block content
  language: 'applescript' | 'javascript'; // Determined from code block or frontmatter
  keywords: string[];
  notes?: string;
  filePath: string;    // Absolute path to the source .md file
  isComplex?: boolean; // Heuristic (e.g., script length) or from frontmatter
  argumentsPrompt?: string; // Human-readable prompt for arguments if run by ID
  isLocal?: boolean; // Indicates if the tip is from the local KB override
}

export interface SharedHandler {
  name: string; // Filename without extension from _shared_handlers/
  content: string;
  filePath: string;
  language: 'applescript' | 'javascript'; // Determined by file extension
  isLocal?: boolean; // Indicates if the handler is from the local KB override
}

export interface KnowledgeBaseIndex {
  categories: {
    id: KnowledgeCategory;
    description: string; // From _category_info.md or default
    tipCount: number;
  }[];
  tips: ScriptingTip[];       // Flat list of all parsed tips
  sharedHandlers: SharedHandler[]; // Parsed shared handlers
}

// Type for parsed frontmatter from Markdown tip files
export interface TipFrontmatter {
  id?: string;
  title: string;
  description?: string;
  keywords?: string[];
  notes?: string;
  language?: 'applescript' | 'javascript';
  isComplex?: boolean;
  argumentsPrompt?: string;
}

// Type for parsed frontmatter from _category_info.md files
export interface CategoryInfoFrontmatter {
    description: string;
}
```

### 3. Knowledge Base Management and Services

#### A. `src/services/kbLoader.ts`
Responsible for low-level file reading and parsing of individual Markdown files.

*   `parseMarkdownTipFile(fileContent: string, filePath: string)`:
    *   Uses `gray-matter` to parse YAML frontmatter and Markdown body.
    *   Extracts `title`, `description`, `keywords`, `notes`, `language`, `isComplex`, `argumentsPrompt`, `id` from frontmatter.
    *   Detects and extracts AppleScript or JavaScript code blocks (e.g., ` ```applescript ... ``` `). The language specified in the code block (e.g., ` ```applescript`) overrides any `language` field in frontmatter for the script itself.
    *   Returns a structured object with parsed data or `null` on error.
*   `loadTipsAndHandlersFromPath(basePath: string, isLocalKb: boolean)`:
    *   Scans the specified `basePath` (either embedded KB or local override KB).
    *   Identifies category directories and `_shared_handlers/` directory.
    *   Reads `_category_info.md` in each category directory for category descriptions.
    *   For each `.md` tip file in category directories (not starting with `_`):
        *   Calls `parseMarkdownTipFile`.
        *   Generates a `ScriptingTip` object if a script block is found. The `id` is taken from `frontmatter.id` or generated (e.g., `categoryId_cleanedFilename`).
        *   Marks tip with `isLocalKb` flag.
    *   For each `.applescript` or `.js` file in `_shared_handlers/`:
        *   Reads content and creates a `SharedHandler` object.
        *   Marks handler with `isLocalKb` flag.
    *   Returns an object containing lists of loaded categories, tips, and shared handlers from that path.

#### B. `src/services/KnowledgeBaseManager.ts`
Manages the lifecycle of the knowledge base, including loading, indexing, merging, and lazy access.

*   **Path Management**:
    *   Determines paths for the embedded knowledge base (packaged with the server) and an optional local user-specific knowledge base (e.g., `~/.macos-automator/knowledge_base/` via `LOCAL_KB_PATH` env var or default).
*   `actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex>`:
    *   Orchestrates the full loading process.
    *   Calls `loadTipsAndHandlersFromPath` for the embedded KB path.
    *   Calls `loadTipsAndHandlersFromPath` for the local KB path (if it exists).
    *   **Merges Data**:
        *   Tips and shared handlers from the local KB override those from the embedded KB if they have the same ID (for tips) or name+language (for handlers).
        *   New tips/handlers from the local KB are added.
        *   Category descriptions from local `_category_info.md` can update embedded ones. New categories from local KB are added.
        *   Recalculates `tipCount` for categories after merging.
    *   Stores the final merged `KnowledgeBaseIndex`.
    *   Handles errors gracefully, potentially returning an empty or minimal KB.
*   **Lazy Loading**:
    *   `indexedKnowledgeBase: KnowledgeBaseIndex | null = null;`
    *   `isLoadingKnowledgeBase: boolean = false;`
    *   `knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;`
    *   `getKnowledgeBase(): Promise<KnowledgeBaseIndex>`:
        *   If `indexedKnowledgeBase` is populated, returns it.
        *   If `isLoadingKnowledgeBase` is true, returns the existing `knowledgeBaseLoadPromise`.
        *   Otherwise, sets `isLoadingKnowledgeBase` to true, calls `actualLoadAndIndexKnowledgeBase()`, stores the promise in `knowledgeBaseLoadPromise`, and returns it. The promise resolution will populate `indexedKnowledgeBase`.
*   `forceReloadKnowledgeBase(): Promise<KnowledgeBaseIndex>`:
    *   Resets `indexedKnowledgeBase`, `knowledgeBaseLoadPromise`, and `isLoadingKnowledgeBase` to trigger a fresh load on the next `getKnowledgeBase()` call.
*   `conditionallyInitializeKnowledgeBase(eagerMode: boolean)`:
    *   If `eagerMode` is true (e.g., based on `KB_PARSING=eager` env var), calls `getKnowledgeBase()` at server startup to pre-load the KB. Otherwise, logs that loading is lazy.

#### C. `src/services/knowledgeBaseService.ts`
Provides the primary interface for querying the knowledge base.

*   Re-exports `getKnowledgeBase`, `forceReloadKnowledgeBase`, `conditionallyInitializeKnowledgeBase` from `KnowledgeBaseManager`.
*   `getScriptingTipsService(input: GetScriptingTipsInput, serverInfo?: {...}): Promise<string>`:
    *   Calls `await getKnowledgeBase()` to ensure the KB is loaded.
    *   Handles `input.refresh_database` by calling `forceReloadKnowledgeBase()`.
    *   **Functionality**:
        *   If `input.list_categories` is true (or no other parameters are provided), formats and returns a list of all available categories with descriptions and tip counts.
        *   If `input.category` is provided, filters tips for that category.
        *   If `input.search_term` is provided, performs a search (e.g., using Fuse.js) across tip `id`, `title`, `description`, `keywords`, and `script` content.
        *   Applies `input.limit` to search results (defaulting to 10).
    *   **Output Formatting**:
        *   Returns results as a Markdown string.
        *   Each tip clearly displays its title, description, script (in a code block), language, runnable ID (if applicable), arguments prompt (if applicable), keywords, and notes.
        *   Includes notices for truncated output (due to line limits or result limits).
        *   May include server version/info if `serverInfo` is passed.

### 4. Zod Input Schemas (`src/schemas.ts`)

Defines the expected structure for tool inputs using Zod. All input fields are `snake_case`.

*   `DynamicScriptingKnowledgeCategoryEnum`: A Zod schema for categories, ideally dynamically derived from loaded category IDs, or `z.string()` if dynamic enum is complex.
*   `ExecuteScriptInputSchema = z.object({...})`:
    *   `script_content: z.string().optional()`
    *   `script_path: z.string().optional()`
    *   `kb_script_id: z.string().optional()`
    *   `language: z.enum(['applescript', 'javascript']).optional()`
    *   `arguments: z.array(z.string()).optional().default([])`
    *   `input_data: z.record(z.string(), z.any()).optional()`
    *   `timeout_seconds: z.number().int().positive().optional().default(60)` (Default is 60 seconds)
    *   `output_format_mode: z.enum(['auto', 'human_readable', 'structured_error', 'structured_output_and_error', 'direct']).optional().default('auto')`
    *   `include_executed_script_in_output: z.boolean().optional().default(false)`
    *   `include_substitution_logs: z.boolean().optional().default(false)`
    *   `.refine()` ensures exactly one of `script_content`, `script_path`, or `kb_script_id` is provided.
*   `GetScriptingTipsInputSchema = z.object({...})`:
    *   `category: DynamicScriptingKnowledgeCategoryEnum.optional()`
    *   `search_term: z.string().optional()`
    *   `list_categories: z.boolean().optional().default(false)`
    *   `refresh_database: z.boolean().optional().default(false)`
    *   `limit: z.number().int().positive().optional().default(10)`

### 5. Placeholder Substitution (`src/placeholderSubstitutor.ts`)
Handles replacing placeholders in scripts fetched from the knowledge base.

*   `camelToSnake(str: string): string`: Helper to convert `camelCase` script placeholders to `snake_case` for `input_data` lookup.
*   `valueToAppleScriptLiteral(value: unknown): string`: Converts JavaScript values (string, number, boolean, array, simple object) into their AppleScript literal representations. Strings are properly escaped.
*   `substitutePlaceholders(args: { scriptContent, inputData?, args?, includeSubstitutionLogs }): SubstitutionResult`:
    *   Takes the raw script content from a knowledge base tip.
    *   Replaces placeholders:
        *   `--MCP_INPUT:someKeyName`: Looks up `input_data['some_key_name']` (after `camelToSnake` conversion of `someKeyName`). Value is converted using `valueToAppleScriptLiteral`.
        *   `--MCP_ARG_1`, `--MCP_ARG_2`, etc.: Uses values from the `arguments` array (e.g., `arguments[0]`, `arguments[1]`). Values are converted.
        *   Supports other placeholder styles like `${inputData.keyName}` and `${arguments[N]}`.
        *   Handles quoted placeholders (e.g. `"--MCP_INPUT:keyName"`).
        *   Handles expression-context placeholders (e.g. `myFunction(--MCP_INPUT:keyName)`).
    *   Returns the script with substitutions made and optionally a log of substitutions.

### 6. Main Server Logic (`src/server.ts`)

*   **Initialization**:
    *   Loads `package.json` for server version.
    *   Sets up a `Logger` instance.
    *   Initializes `ScriptExecutor`.
    *   Calls `conditionallyInitializeKnowledgeBase()` from `KnowledgeBaseManager` to respect `KB_PARSING` environment variable (eager or lazy loading).
    *   `hasEmittedFirstCallInfo` flag and `serverInfoMessage` (containing version and startup time) for emitting server details on the first tool call.
*   **Tool Definition (`execute_script`)**:
    *   Description outlines usage with `script_content`, `script_path`, or `kb_script_id`, and options like `input_data`, `arguments`, `language`, `timeout_seconds`.
    *   Input schema is `ExecuteScriptInputSchema`.
    *   **Handler Logic**:
        1.  Parses input using `ExecuteScriptInputSchema`.
        2.  **If `kb_script_id` is provided**:
            *   Calls `await getKnowledgeBase()` (from `KnowledgeBaseManager` via `knowledgeBaseService`).
            *   Finds the `ScriptingTip` by ID. Throws error if not found or script content is missing.
            *   Sets `scriptContentToExecute = tip.script` and `languageToUse = tip.language`.
            *   Calls `substitutePlaceholders()` (from `placeholderSubstitutor.ts`) with `tip.script`, `input.input_data`, and `input.arguments` to perform substitutions. Updates `scriptContentToExecute`.
        3.  Else if `script_path` or `script_content` is used, sets those directly. `languageToUse` is from `input.language` or defaults to 'applescript'.
        4.  Calls `scriptExecutor.execute()` with the determined script (content or path), language, timeout (converted from `input.timeout_seconds`), `output_format_mode`, and `arguments` (only for `script_path` mode at executor level).
        5.  **Response**:
            *   If first tool call (`!hasEmittedFirstCallInfo`), prepends `serverInfoMessage` and a separator to the output. Sets flag to true.
            *   Includes `result.stdout` (and potentially `result.stderr` if relevant, or substitution logs if requested) in the response content.
            *   Sets `timings: { execution_time_seconds: result.execution_time_seconds }`.
            *   Handles errors from `scriptExecutor` (e.g., timeouts, script errors, file access errors), enriching them with permission hints if applicable, and throws `sdkTypes.McpError`. Captures `execution_time_seconds` for errors too.
*   **Tool Definition (`get_scripting_tips`)**:
    *   Description explains how to discover scripts, list categories, and search.
    *   Input schema is `GetScriptingTipsInputSchema`.
    *   **Handler Logic**:
        1.  Parses input using `GetScriptingTipsInputSchema`.
        2.  Calls `await getScriptingTipsService()` (passing input and server info) to get Markdown formatted tip information.
        3.  **Response**:
            *   If first tool call, prepends `serverInfoMessage` and separator.
            *   Returns the Markdown string from the service.
            *   Handles errors by throwing `sdkTypes.McpError`.
*   **Connection**: Connects to MCP transport (e.g., `StdioServerTransport`).

### 7. Script Execution (`src/ScriptExecutor.ts`)

*   `execute(scriptSource: { content?: string; path?: string }, options: ScriptExecutionOptions)`:
    *   Checks for macOS platform; throws `UnsupportedPlatformError` if not darwin.
    *   Constructs `osascript` arguments based on `language` ('-l JavaScript' if JXA), and `options.output_format_mode`.
        *   If `output_format_mode` is `'auto'`, it resolves to `'direct'` for JXA and `'human_readable'` for AppleScript.
        *   `'human_readable'` maps to `-s h`.
        *   `'structured_error'` maps to `-s s`.
        *   `'structured_output_and_error'` maps to `-s ss`.
        *   `'direct'` uses no `-s` flags.
    *   If `scriptSource.path` is used, checks for file readability; throws `ScriptFileAccessError` if not accessible.
    *   Appends `options.arguments` if `scriptSource.path` is used.
    *   Records `scriptStartTime` before execution.
    *   Calls `execFileAsync('osascript', osaArgs, { timeout: options.timeoutMs })`.
    *   Calculates `execution_time_seconds = (Date.now() - scriptStartTime) / 1000`.
    *   On success: Returns `{ stdout, stderr, execution_time_seconds }`. Logs `stderr` if present.
    *   On error (from `execFileAsync`): Enriches the error object with `stdout`, `stderr`, `exitCode`, `signal`, `isTimeout`, `originalError`, and `execution_time_seconds`. Rethrows the enriched error.

### 8. Documentation and Startup

*   `README.md` should detail tool usage, including `kb_script_id`, `input_data`, placeholder conventions, and permissions.
*   `DEVELOPMENT.md` should explain KB contribution guidelines.
*   Server startup logs current working directory and critical permission warnings.

## Part 2: Knowledge Base Content Specification and Generation

This part outlines the structure, content, and generation strategy for the `.md` tip files that populate the server's knowledge base.

### 1. Introduction and Purpose

The knowledge base aims to provide a comprehensive collection of AppleScript and JXA tips, scripts, and examples for macOS automation. These tips are primarily designed to be discovered and utilized by AI agents via the `get_scripting_tips` and `execute_script` tools.

The generation of these `.md` files can be assisted by AI, following the structure and examples laid out below.

### 2. Knowledge Base File Structure (`knowledge_base/`)

The `knowledge_base/` directory is organized into category subdirectories. Each scriptable tip or piece of information is a separate `.md` file.

*   **Category Directories**: Named descriptively (e.g., `01_applescript_core/`, `04_web_browsers/safari/`).
*   **Tip Files (`.md`)**:
    *   Contain YAML frontmatter and a Markdown body, usually including a script block.
    *   Filename can be prefixed with numbers for ordering (e.g., `01_get_url.md`).
*   **Category Information (`_category_info.md`)**:
    *   Each category directory can optionally contain a `_category_info.md` file.
    *   Its frontmatter can provide a `description` for the category, which is used by `get_scripting_tips` when listing categories.
*   **Shared Handlers (`_shared_handlers/`)**:
    *   Contains reusable AppleScript (`.applescript`) or JXA (`.js`) code snippets (handlers/subroutines).
    *   These are loaded by the server but are not currently automatically prepended to KB scripts. Scripts needing them should ideally be self-contained or clearly document dependencies in their `notes`. Future enhancements might allow automatic inclusion.

### 3. Markdown Tip File Format

Each `.md` tip file follows this structure:

```yaml
---
id: category_verb_noun_short # Optional but recommended for complex/runnable scripts. Must be unique.
title: "Category: Descriptive Title of Tip"
description: "Briefly explains what this script does and its primary use case."
keywords:
  - keyword1
  - keyword2
  - relevant_app_name
language: applescript # or javascript. Defines the language of the script block.
isComplex: false # true for longer scripts or those intended for execution by ID with params.
argumentsPrompt: "Example: Provide the application name as 'appName' in inputData." # If script takes input when run by ID via --MCP_INPUT or --MCP_ARG.
notes: |
  - Any specific macOS version dependencies.
  - Required permissions (Automation for AppName, Accessibility for System Events UI scripting, Full Disk Access for some shell scripts).
  - Potential points of failure or common gotchas.
  - If it's UI scripting based: "This script uses UI scripting and may be fragile if the application's UI changes."
---

Further explanation or context for the script can go here in Markdown.

\`\`\`applescript
-- AppleScript code block (or javascript for JXA)
-- For scripts designed to be run by ID with parameters:
-- Use --MCP_INPUT:yourKeyName for inputData (e.g., --MCP_INPUT:appName). The server expects 'yourKeyName' in camelCase here.
-- Use --MCP_ARG_1, --MCP_ARG_2 for items from the 'arguments' array input.
tell application "System Events"
  return name of first application process whose frontmost is true -- Example placeholder: --MCP_ARG_1
end tell
\`\`\`
```

### 4. Detailed Knowledge Base Outline

The following outlines the desired categories and specific tips. (Content from `docs/spec_kb_1.md`'s outline is integrated here).

#### `00_readme_and_conventions/`
*   `01_how_to_use_this_knowledge_base.md`
    *   Explains `get_scripting_tips` (list categories, search by category/term/ID).
    *   Explains `execute_script` with `script_content`, `script_path`, and `kb_script_id`.
    *   Details placeholder conventions: `--MCP_INPUT:keyName` (maps to `input_data['key_name']` after server converts `keyName` to `key_name` for lookup) and `--MCP_ARG_N` (maps to `arguments[N-1]`).
    *   Mentions `input_data` for structured input and `arguments` for positional string args.
*   `02_applescript_basics_for_llms.md`
    *   Core syntax, common data types, error interpretation.
    *   Role of `System Events`, Accessibility/Automation permissions.
*   `03_jxa_basics_for_llms.md` (If JXA tips are prevalent)
    *   Similar to AppleScript basics but for JavaScript for Automation.
*   `04_macos_permissions_guide.md`
    *   Detailed guide on Automation, Accessibility, Full Disk Access permissions: how they work, how to grant them, how errors manifest.

#### `01_applescript_core/`
*   **`control_flow/`**: `if/else`, `repeat` loops, `try/on error`.
*   **`dialogs_and_notifications_core/`**: `display dialog`, `display notification`, `say` (StandardAdditions).
*   **`paths_and_files_core/`**: POSIX vs. HFS paths, `path to` standard folders, `quoted form of`, `choose file/folder/file name`.
*   **`text_manipulation_core/`**: Concatenation, `text item delimiters`, substrings.
*   **`do_shell_script_core/`**: Basic usage, passing variables (`quoted form of`), `with administrator privileges`, capturing output.
*   **`variables_and_data_types/`**: `set`, `copy`, string, integer, boolean, list, record, date, constants.
*   **`handlers_and_subroutines/`**: Defining `on run`, custom handlers with parameters, return values.
*   **`scripting_additions_osax/`**: Overview of StandardAdditions and other common OSAX.
*   **`reference_forms/`**: `a reference to`, `contents of`.
*   **`operators/`**: Comparison, logical, arithmetic.

#### `02_system_interaction/` (Primarily using System Events or shell commands)
*   **`system_information/`**: macOS version, computer/user name, screen dimensions, IP address, battery status, uptime, serial number.
*   **`processes/`**: List running processes (names, details like PID, bundle ID, frontmost), check if app/process is running, get PID by name, get frontmost app, activate/quit/force-quit app, kill process by PID/port.
*   **`clipboard_system/`**: Get/set clipboard text, get file paths from clipboard.
*   **`ui_scripting_systemwide/`**: Simulate keystrokes (chars, modifiers, key codes), click menu bar items (generic, not app-specific). See also app-specific UI scripting.
*   **`power_management/`**: Sleep, restart, shut down (with warnings), check sleep settings.
*   **`volume_control/`**: Get/set output/input volume, mute/unmute.
*   **`display_control/`**: Get/set brightness (limited), information about connected displays. (Deep control is hard without third-party tools or advanced methods).
*   **`notifications_system/`**: (Covered by `dialogs_and_notifications_core` if using `display notification`). Focus on system-level interaction if different.
*   **`system_settings_preferences/`**: (Highly UI-scripting dependent and fragile)
    *   Opening specific panes (e.g., "Displays", "Sound", "Network").
    *   Toggling common settings (Dark Mode, basic accessibility features). **Extreme caution notes needed.**
*   **`window_management_generic/`**: (System Events for frontmost app's windows if not targeting a specific app) List windows, get properties (name, bounds), minimize, zoom, close.
*   **`focus_modes_dnd/`**: Check DND status, toggle DND (if possible via UI or Shortcuts).

#### `03_file_system_and_finder/`
*   **`paths_and_references/`**: POSIX vs. HFS, `path to`, `alias` vs. `file` objects, `container of`, `name of`, `parent folder`.
*   **`file_operations_finder/`**: (Using `tell application "Finder"`) List items, get selection, open, reveal, get/set info (comments, label index), duplicate, move to trash, empty trash, create alias.
*   **`folder_operations_finder/`**: Create new folder, navigate, `entire contents of`.
*   **`file_operations_no_finder/`**: (Using StandardAdditions or shell) Read/write/append text files, check existence, get size/dates (`info for`), delete file.
*   **`metadata_and_attributes/`**: (Finder for basic, shell for advanced) Get/set Finder comments, Spotlight comments (via `mdutil` or `xattr`), extended attributes (`xattr` command).
*   **`do_shell_script_for_files/`**: `mkdir`, `cp`, `mv`, `rm`, `touch`, `cat`, `head`, `tail`, `grep`, `find`, `zip/unzip`, `tar`, `chmod/chown`.
*   **`security_operations_files/`**: (Mostly shell) Check/set permissions with `chmod`, ownership with `chown`.

#### `04_terminal_emulators/`
*   **`_common_terminal_concepts/`**: `do script` (new shell) vs. `write text` (current session).
*   **`terminal_app/`**: (macOS built-in) `do script` in new window/tab, target specific window/tab, get content (difficult reliably), close window/tab.
*   **`iterm2/`**: Create window/tab (with profile), `write text` to session, split panes, get session content, select tab/window. (Relies on iTerm2's extensive AppleScript dictionary).
*   **`ghostty/`**: (Likely UI Scripting or CLI interaction) Activate, send command (e.g., via clipboard paste), new window/tab/split via keystrokes.
*   **`warp/`**: (Investigate CLI or UI Scripting).

#### `05_web_browsers/`
*   **`_common_browser_js_snippets/`**: `.js.md` files containing common JavaScript DOM manipulations (getElement, click, getValue, scroll, extract links, etc.) to be used within `do JavaScript` commands.
*   **`safari/`**:
    *   Tab/Window management: Open, close, select, reload, get URL/title (current, all).
    *   Navigation: Go to URL, back, forward.
    *   Content Interaction (via `do JavaScript`): Execute JS, get HTML source, fill forms, click elements, wait for page load (using JS snippets from common).
    *   Private windows (UI scripting).
    *   **Note on "Allow JavaScript from Apple Events"**.
*   **`chrome/` (and Chromium-based like Edge, Brave, Arc, Vivaldi)**:
    *   Similar to Safari: Tab/Window management, navigation.
    *   Incognito windows.
    *   Open with specific profile (via shell command).
    *   Content Interaction (via `execute javascript` command in its dictionary).
    *   **Note on "Allow JavaScript from Apple Events"**.
*   **`firefox/`**: (Scriptability is more limited, often requires extensions or UI scripting).
    *   Open URL, basic window/tab control if possible.
    *   Likely involves `do shell script "open -a Firefox --args ..."`.

#### `06_ides_and_editors/`
*   **`_common_ide_ui_patterns/`**: Open Command Palette, toggle sidebar/panels, save file(s) via common keystrokes.
*   **`electron_editors/` (VS Code, Cursor, Windsurf, etc.)**:
    *   Open file/folder/workspace (via `open` command or specific CLI).
    *   UI Keystroke Macros: Go to Symbol, multi-cursor, find/replace.
    *   **DevTools JavaScript Injection**:
        *   Open DevTools (Option+Cmd+I).
        *   Execute JS in console (keystroke for simple, paste for complex).
        *   Pattern to get data back from JS to AppleScript (JS copies to clipboard, AS reads clipboard).
        *   Using editor-specific APIs (e.g., `vscode.window...`, `vscode.env.clipboard...`).
    *   UI interaction with specific panels (e.g., AI chat panels - very fragile).
    *   Manage extensions (UI for Extensions view).
    *   Edit `settings.json` (UI or JXA for direct file manipulation).
*   **`textedit/`**: Create, open, save, get/set content, basic formatting.
*   **`xcode/` (via `xcodebuild` shell command or UI Scripting)**:
    *   Build, clean, run project.
    *   Open specific files/projects.

#### `07_productivity_apps/`
*   **`mail_app/`**: Create/send/reply/forward email, read emails (sender, subject, body), manage mailboxes, search.
*   **`calendar_app/`**: Create/read/update/delete events & todos, search, manage calendars.
*   **`contacts_app/`**: Create/find/update contacts, get contact details.
*   **`reminders_app/`**: Create/read/update/delete reminders & lists, mark complete.
*   **`notes_app/`**: Create/read/update/delete notes, search, manage folders.
*   **`messages_app/`**: Send message to contact/service, get unread messages (limited).
*   **`facetime_app/`**: Initiate call (limited).
*   **`maps_app/`**: Search for location, get directions (limited).
*   **`shortcuts_app/`**: Run shortcut by name.

#### `08_creative_and_media_apps/`
*   **`music_app/` (iTunes)**: Play/pause/stop, next/previous, volume, get current track info, search library, manage playlists.
*   **`photos_app/`**: (Limited scripting) Import, get info about photos/albums, create albums.
*   **`preview_app/`**: Open files, get document properties, basic export (UI scripting for more).
*   **`quicktime_player_app/`**: Open/play media, get properties.
*   **`garageband/`, `logic_pro/`**: (Very advanced, likely UI scripting for basic tasks).
*   **`pages_app/`, `numbers_app/`, `keynote_app/`**: Create/open/save, basic content get/set (text in Pages, cell values in Numbers). Complex formatting is hard.

#### `09_jxa_specifics/` (JavaScript for Automation)
*   **`jxa_basics/`**: Syntax, `Application()`, Objective-C bridge basics.
*   **`jxa_vs_applescript/`**: Key differences, when to choose one over the other.
*   **`jxa_common_tasks/`**: Examples of file I/O, HTTP requests (using ObjC bridge), JSON processing.

#### `10_advanced_topics/`
*   **`inter_app_communication_advanced/`**: Beyond simple `tell`; custom URL schemes if apps support them.
*   **`ui_element_inspection/`**: Tools and techniques to inspect UI elements for UI scripting (Accessibility Inspector, third-party tools).
*   **`error_handling_advanced/`**: Robust error logging, custom error messages, retries.
*   **`performance_and_large_data/`**: Tips for optimizing scripts, handling large lists or text.
*   **`security_and_scripting/`**: Sandboxing considerations, `with administrator privileges` implications.

### 5. Monolithic Knowledge Base Source File Generation (Optional Strategy)

To facilitate bulk generation or management of tips, a single Markdown file can be used as a source. This file would contain all tips, each demarcated by `START_TIP` and `END_TIP` markers. A script can then process this monolithic file to create the individual `.md` files in their respective category subdirectories.

**Format for Monolithic Source:**

```markdown
# macOS Automator MCP Server - Comprehensive Knowledge Base Source

This document contains all AppleScript and JXA tips...
Each tip is defined by a `START_TIP` marker, followed by YAML frontmatter, then Markdown content including a script block, and an `END_TIP` marker.

**Instructions for Processing this File:**
1.  Read this file content.
2.  For each block between `START_TIP` and `END_TIP`:
    a.  Parse the YAML frontmatter.
    b.  Extract `category`, `id` (or generate if missing), and `title`.
    c.  Create filename (e.g., `knowledge_base/[category_name]/[id_or_sanitized_title].md`).
    d.  Create category subdirectory if it doesn't exist.
    e.  Write the tip content (frontmatter + body) into the `.md` file.
---

START_TIP
---
title: "How to Use This Knowledge Base"
category: "00_readme_and_conventions"
id: conventions_how_to_use_kb
description: "Explains how to query and use the tips provided by this MCP server."
# ... (rest of frontmatter)
---
This knowledge base provides AppleScript and JXA examples...
\`\`\`applescript
-- Conceptual example script
-- ...
\`\`\`
END_TIP

---
START_TIP
---
title: "Safari: Get URL of Front Tab"
category: "04_web_browsers/safari" # Category can include subpath
id: safari_get_front_tab_url
description: "Retrieves the web address (URL) of the currently active tab..."
# ... (rest of frontmatter)
---
This script targets Safari...
\`\`\`applescript
tell application "Safari"
  -- ... script content ...
end tell
\`\`\`
END_TIP

---
START_TIP
---
title: "Paths: Understanding POSIX and HFS+ Paths"
category: "03_file_system_and_finder/paths_and_references"
id: paths_posix_vs_hfs
description: "Explains the difference between POSIX (slash-separated) and HFS+ (colon-separated) paths..."
# ... (rest of frontmatter from spec_kb_2.md example)
---
macOS uses POSIX paths...
\`\`\`applescript
-- ... script content ...
\`\`\`
END_TIP

---
(Include other examples from spec_kb_1.md and spec_kb_2.md here, correctly formatted)
---
<!-- AI: CONTINUE POPULATING ALL OTHER CATEGORIES AND TIPS FROM THE DETAILED OUTLINE -->
<!-- Ensure each tip is wrapped in START_TIP and END_TIP and has correct YAML frontmatter -->
```

This unified `spec.md` should now accurately reflect the server's capabilities and provide a clear roadmap for the knowledge base content.
