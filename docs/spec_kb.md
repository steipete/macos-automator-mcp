Okay, this is a significant expansion! We're going to supercharge the knowledge base and add a mechanism to reference complex scripts by an ID. This is excellent for context window optimization and reusability.

Here's the **`spec2.md`** (Specification Addition - Part 2, building upon the previous Markdown-based knowledge base idea).

---

```markdown
# Specification Addition 2: Enhanced Knowledge Base & Script Referencing

This document details enhancements to the `macos_automator` MCP server, focusing on:
1.  A vastly expanded, Markdown-file-based AppleScript Knowledge Base.
2.  Refined `get_scripting_tips` tool to query this knowledge base.
3.  A new mechanism within `execute_script` to run pre-defined, complex scripts from the knowledge base by a unique ID.

## 1. Enhanced Knowledge Base Structure

The knowledge base will continue to reside in the `knowledge_base/` directory, organized by category subdirectories. Each tip is a `.md` file.

**`knowledge_base/` Directory Structure (Example Expansion):**

```
knowledge_base/
├── _shared_handlers/         # NEW: For reusable AppleScript handlers
│   └── string_utils.applescript
│   └── file_system_helpers.applescript
├── basics/
├── browsers_common/          # NEW: Tips applicable to multiple browsers
├── calendar/
├── chrome/
├── clipboard/
├── contacts/
├── developer_tools/          # NEW: Xcode, VS Code (if scriptable)
├── dialogs_notifications/
├── do_shell_script/
├── error_handling/
├── finder/
├── focus_modes/              # NEW: For Do Not Disturb, Focus Filters
├── ghostty/
├── image_events/             # NEW: For image manipulation
├── iterm/
├── jxa_basics/               # For JavaScript for Automation
├── keystrokes_mouse/
├── mail/
├── messages/
├── music/                    # (iTunes / Apple Music)
├── notes/
├── numbers_app/              # NEW
├── pages_app/                # (Previously 'pages')
├── paths_files/
├── photos_app/               # (Previously 'photos')
├── processes/
├── reminders/
├── safari/
├── scripting_additions/
├── shortcuts_app/            # (Previously 'shortcuts')
├── system_events_general/
├── system_preferences/       # NEW: For System Settings/Preferences
├── terminal/                 # (macOS built-in Terminal.app)
├── text_manipulation/        # NEW
├── textedit/
└── (other app-specific categories)
```

**Markdown Tip File Format (`.md`):**

Retains the previous structure (YAML frontmatter + Markdown body with `applescript` code block).

**NEW: Frontmatter Field - `id` (Optional but Recommended for complex scripts):**

```yaml
---
id: safari_extract_all_links_from_page # Optional, unique identifier for this script
title: "Safari: Extract All Links from Current Page"
description: "Retrieves all hyperlink URLs (<a> tags) from the active Safari tab."
keywords:
  - Safari
  - links
  - scrape
  - DOM
  - JavaScript
  - extract
notes: |
  - Requires 'Allow JavaScript from Apple Events' in Safari's Develop menu.
  - Returns a list of URLs, one per line.
---

This script uses JavaScript to gather all `href` attributes from `<a>` elements.

```applescript
tell application "Safari"
  if not (exists front document) then return "error: No document open in Safari."
  try
    set jsCode to "
      var links = [];
      var all_a_tags = document.getElementsByTagName('a');
      for (var i = 0; i < all_a_tags.length; i++) {
        if (all_a_tags[i].href) {
          links.push(all_a_tags[i].href);
        }
      }
      links.join('\\n'); // Return URLs separated by newlines
    "
    return do JavaScript jsCode in front document
  on error errMsg
    return "error: Failed to extract links - " & errMsg
  end try
end tell
```
```

*   **`id` Field:** If present, this `id` can be used by the `execute_script` tool to run this specific script without resending the entire `scriptContent`. The ID should be unique across the entire knowledge base. A good convention is `category_descriptive_name`.

**NEW: `_shared_handlers/` Directory:**

*   This directory can contain `.applescript` files with commonly used AppleScript handlers (subroutines).
*   The `knowledgeBaseService` can make these available, and complex scripts in the knowledge base might indicate they `include` or `use` these shared handlers.
*   When executing a script by ID that uses a shared handler, the `ScriptExecutor` would need to prepend the content of the required shared handlers to the main script content before execution. This is an advanced feature. For now, scripts in the knowledge base should be self-contained or clearly state dependencies.

## 2. `src/services/scriptingKnowledge.types.ts` (Updates)

```typescript
// src/services/scriptingKnowledge.types.ts
export type KnowledgeCategory = string; // Derived from directory names

export interface ScriptingTip {
  id: string; // Derived from frontmatter `id` or category/filename. MUST BE UNIQUE.
  category: KnowledgeCategory;
  title: string;
  description?: string;
  script: string;      // The AppleScript/JXA code block
  language: 'applescript' | 'javascript'; // Derived from code block lang or a frontmatter field
  keywords: string[];
  notes?: string;
  filePath: string;    // Path to the source .md file
  isComplex?: boolean; // Heuristic: true if script > N lines or has specific patterns
  argumentsPrompt?: string; // Optional: Human-readable prompt for any arguments this script might conceptually take if run by ID (e.g., "Provide URL for Safari to open:")
}

export interface SharedHandler {
  name: string; // e.g., "string_utils"
  content: string;
  filePath: string;
}

export interface KnowledgeBaseIndex {
  categories: {
    id: KnowledgeCategory;
    description: string;
    tipCount: number;
  }[];
  tips: ScriptingTip[];
  sharedHandlers: SharedHandler[]; // NEW
}
```

## 3. `src/services/knowledgeBaseService.ts` (Updates & Enhancements)

This service needs significant enhancement:

*   **Frontmatter Parsing:** Use a robust library like `gray-matter` to parse YAML frontmatter.
    ```bash
    npm install gray-matter
    ```
    ```typescript
    import matter from 'gray-matter';
    // ...
    function parseMarkdownFile(fileContent: string, filePath: string): { frontmatter: any, body: string, script: string | null, language: 'applescript' | 'javascript' } | null {
        try {
            const { data: frontmatter, content: markdownBody } = matter(fileContent);
            if (!frontmatter.title) {
                logger.warn('Markdown file missing title in frontmatter', { filePath });
                return null;
            }

            let script: string | null = null;
            let language: 'applescript' | 'javascript' = 'applescript'; // Default

            const asMatch = markdownBody.match(/```applescript\s*\n([\s\S]*?)\n```/i);
            const jsMatch = markdownBody.match(/```javascript\s*\n([\s\S]*?)\n```/i);

            if (asMatch) {
                script = asMatch[1].trim();
                language = 'applescript';
            } else if (jsMatch) {
                script = jsMatch[1].trim();
                language = 'javascript';
            }

            return { frontmatter, body: markdownBody, script, language };
        } catch (e) {
            logger.error('Failed to parse Markdown file', { filePath, error: (e as Error).message });
            return null;
        }
    }
    ```
*   **Loading Logic (`loadAndIndexKnowledgeBase`):**
    *   Iterate through category directories in `knowledge_base/`.
    *   For each `.md` file:
        *   Parse using `parseMarkdownFile`.
        *   If successful and script block exists:
            *   Construct `ScriptingTip` object.
            *   `id`: Use `frontmatter.id` if present; otherwise, generate `categoryId_filename_without_prefix_or_ext`. Ensure uniqueness (log error/warning on collision).
            *   `language`: Determined by `parseMarkdownFile`.
            *   `isComplex`: Set to `true` if `script.length > 200` (configurable threshold) or if `frontmatter.isComplex === true`.
            *   `argumentsPrompt`: From `frontmatter.argumentsPrompt`.
            *   Add to `allTips`.
    *   Load shared handlers:
        *   Read files from `knowledge_base/_shared_handlers/`.
        *   Store their content in `indexedKnowledgeBase.sharedHandlers`.
*   **`getScriptingTipsService` (Query Logic):**
    *   Retains existing functionality (list categories, get by category, search by term).
    *   Search should also check `tip.id` if `searchTerm` looks like an ID.
    *   Output formatting (Markdown) should clearly indicate if a tip has an `id` and is runnable by ID.
        Example output for a tip:
        ```markdown
        ### Safari: Extract All Links from Current Page (ID: `safari_extract_all_links_from_page`)
        *Retrieves all hyperlink URLs...*
        ```applescript
        -- script content --
        ```
        **Note:** This script can be run directly using its ID with the `execute_script` tool.
        ```

## 4. `src/schemas.ts` (Updates for `ExecuteScriptInputSchema`)

Modify `ExecuteScriptInputSchema` to accept `knowledgeBaseScriptId`.

```typescript
// src/schemas.ts
import { z } from 'zod';

export const ExecuteScriptInputSchema = z.object({
  scriptContent: z.string().optional()
    .describe("The raw AppleScript or JXA code to execute. Mutually exclusive with scriptPath and knowledgeBaseScriptId."),
  scriptPath: z.string().optional()
    .describe("The absolute POSIX path to a script file on the server. Mutually exclusive with scriptContent and knowledgeBaseScriptId."),
  knowledgeBaseScriptId: z.string().optional() // NEW
    .describe("The unique ID of a pre-defined script from the knowledge base. Mutually exclusive with scriptContent and scriptPath. Use 'get_scripting_tips' to find IDs."),
  language: z.enum(['applescript', 'javascript']).optional() // No default here; will be inferred if using knowledgeBaseScriptId
    .describe("The scripting language. Required if using scriptContent/scriptPath and not default 'applescript'. Inferred if using knowledgeBaseScriptId."),
  arguments: z.array(z.string()).optional().default([]) // These are for script files or might be used by KB scripts if designed for it
    .describe("An array of string arguments. For scriptPath, these are passed to 'on run argv'. For knowledgeBaseScriptId, their usage depends on the specific pre-defined script (see its 'argumentsPrompt' via get_scripting_tips)."),
  inputData: z.record(z.any()).optional() // NEW: For structured input to KB scripts
    .describe("A JSON object providing structured input data for knowledgeBaseScriptId scripts that are designed to accept it (e.g., for filling templates)."),
  timeoutSeconds: z.number().int().positive().optional().default(30)
    .describe("Maximum execution time for the script in seconds. Defaults to 30 seconds."),
  useScriptFriendlyOutput: z.boolean().optional().default(false)
    .describe("If true, instructs 'osascript' to use script-friendly output format (-ss flag).")
}).refine(data => {
    const sources = [data.scriptContent, data.scriptPath, data.knowledgeBaseScriptId].filter(s => s !== undefined);
    return sources.length === 1;
}, {
    message: "Exactly one of 'scriptContent', 'scriptPath', or 'knowledgeBaseScriptId' must be provided.",
    path: ["scriptContent", "scriptPath", "knowledgeBaseScriptId"],
}).refine(data => {
    // If scriptContent or scriptPath is used, language defaults to 'applescript' if not provided.
    // If knowledgeBaseScriptId is used, language is determined by the KB script, so this field is optional.
    // No explicit refinement needed here for language based on current structure,
    // but handler logic will need to determine language.
    return true;
});

// ... (rest of schemas.ts)
```

## 5. `src/server.ts` (Updates for `execute_script` Tool Handler)

The tool handler needs to:

1.  **Prioritize `knowledgeBaseScriptId`:**
    *   If `knowledgeBaseScriptId` is provided:
        *   Look up the `ScriptingTip` from the `KnowledgeBaseIndex` (via `getKnowledgeBase()`).
        *   If not found, throw `McpError(ErrorCode.NotFound, "Knowledge base script with ID '...' not found.")`.
        *   Use `tip.script` as the `scriptContent` and `tip.language` as the language.
        *   **NEW - Argument/InputData Handling for KB Scripts:**
            *   If `tip.script` contains placeholders (e.g., `${input.placeholder_name}` or uses a specific comment convention like `--MCP_ARG:placeholder_name`), the server needs to substitute values from `input.inputData` (JSON object) or `input.arguments` (array of strings).
            *   **Simple Substitution Strategy:**
                *   For `input.arguments` (array): Replace `--MCP_ARG_1`, `--MCP_ARG_2` in script with `arguments[0]`, `arguments[1]`.
                *   For `input.inputData` (object): Replace `--MCP_INPUT:key_name` with `inputData.key_name`. Values should be AppleScript-escaped before insertion.
                *   This substitution logic needs to be robust (e.g., handle string, number, boolean inputs and quote/format them correctly for AppleScript).
                *   Example KB script expecting input:
                    ```applescript
                    -- This script expects structured input via inputData
                    --MCP_INPUT:targetURL
                    --MCP_INPUT:tabTitle
                    tell application "Safari"
                      make new tab with properties {URL:"${input.targetURL}", name:"${input.tabTitle}"}
                    end tell
                    ```
            *   The `tip.argumentsPrompt` can guide the LLM on what to provide in `inputData` or `arguments`.
2.  **Handle `scriptContent` or `scriptPath` as before.**
3.  **Determine Language:**
    *   If `knowledgeBaseScriptId` used, use `tip.language`.
    *   Else if `input.language` is provided, use that.
    *   Else, default to `applescript`.

```typescript
// src/server.ts - execute_script tool handler (simplified logic shown)
// ...
    async (input: ExecuteScriptInput) => {
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript' = input.language || 'applescript'; // Default if not KB script
      let finalArguments = input.arguments;

      if (input.knowledgeBaseScriptId) {
        const kb = await getKnowledgeBase(); // From knowledgeBaseService.ts
        const tip = kb.tips.find(t => t.id === input.knowledgeBaseScriptId);
        if (!tip) {
          throw new McpError(ErrorCode.NotFound, `Knowledge base script with ID '${input.knowledgeBaseScriptId}' not found.`);
        }
        scriptContentToExecute = tip.script;
        languageToUse = tip.language;
        scriptPathToExecute = undefined; // Clear other sources

        // Argument/InputData substitution for KB scripts (basic example)
        if (input.inputData) {
          for (const key in input.inputData) {
            // Basic string replace. Needs proper AppleScript escaping for values.
            // Use a more robust templating or specific placeholder convention.
            const placeholder = new RegExp(`\\$\\{inputData\\.${key}\\}|--MCP_INPUT:${key}`, 'g');
            scriptContentToExecute = scriptContentToExecute.replace(placeholder, String(input.inputData[key])); // Needs escaping!
          }
        }
        if (input.arguments && input.arguments.length > 0) {
            for (let i = 0; i < input.arguments.length; i++) {
                const placeholder = new RegExp(`\\$\\{arguments\\[${i}\\]\\}|--MCP_ARG_${i+1}`, 'g');
                scriptContentToExecute = scriptContentToExecute.replace(placeholder, String(input.arguments[i])); // Needs escaping!
            }
        }
        logger.debug('Executing KB script', { id: tip.id, substitutedLength: scriptContentToExecute.length });
      } else if (input.scriptPath) {
        // Validate scriptPath existence (moved to ScriptExecutor or done here before calling)
         try {
            await fs.access(input.scriptPath, fs.constants.R_OK);
        } catch (e) {
            logger.error('Script file access error for execute_script', { path: input.scriptPath, error: (e as Error).message });
            throw new McpError(ErrorCode.NotFound, `Script file not found or not readable: ${input.scriptPath}`);
        }
      }
      // Language from input takes precedence if scriptContent or scriptPath is used explicitly
      if ((input.scriptContent || input.scriptPath) && input.language) {
        languageToUse = input.language;
      }


      try {
        const result = await scriptExecutor.execute(
          { content: scriptContentToExecute, path: scriptPathToExecute },
          {
            language: languageToUse,
            timeoutMs: input.timeoutSeconds * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput,
            arguments: scriptPathToExecute ? finalArguments : [], // Only pass arguments if scriptPath is used by executor
          }
        );
        // ... (rest of success handling)
      } catch (error: any) {
        // ... (enhanced error handling as per previous spec, including permission hints)
      }
    }
// ...
```

## 6. Expanded Knowledge Base Content (`knowledge_base/` files)

The AI's primary task for this spec addition is to populate the `knowledge_base/` directories with hundreds of high-quality, well-documented AppleScript (and some JXA) tips.

**Key Content Areas to Cover Exhaustively (beyond previous examples):**

*   **Finder:**
    *   Creating files, folders, aliases.
    *   Getting/setting metadata (comments, tags, labels, dates).
    *   Copying, moving, duplicating, deleting (to trash and permanently).
    *   Opening files with specific applications.
    *   Getting info for items (size, kind, dimensions for images).
    *   Sorting items in a window.
    *   Setting view options.
    *   Ejecting disks.
    *   Interacting with the search bar.
*   **System Events (UI Scripting - many examples needed, each with fragility warnings):**
    *   Clicking buttons, checkboxes, radio buttons, pop-up buttons, menu items (by name, by position).
    *   Setting text in text fields, text areas, combo boxes.
    *   Interacting with tables (selecting rows, getting cell values).
    *   Interacting with outlines, sliders, steppers, progress indicators.
    *   Window manipulation (move, resize, minimize, zoom, close, get properties like name, bounds, index).
    *   Detecting if a specific window or dialog (sheet) is present.
    *   Targeting elements by `accessibility description`, `name`, `value`, `role`, `subrole`, index.
    *   Scrolling scroll areas.
*   **Safari & Chrome (Many detailed examples):**
    *   **Tab Management:** Open, close, select, reload, move, duplicate, get count, get all tab properties (URL, title, ID).
    *   **Window Management:** Open, close, resize, position, get count, bring to front.
    *   **Navigation:** Go to URL, go back, go forward, stop loading.
    *   **Content Interaction (via JavaScript):**
        *   Get page title, full HTML source, selected text, text of an element.
        *   Fill out forms (get/set values of input fields, textareas, select dropdowns).
        *   Click buttons, links, and other elements (by ID, class, tag, XPath, CSS selector).
        *   Scroll page (to top, bottom, specific element).
        *   Extract data (e.g., all links, all image URLs, text from specific divs).
        *   Check if an element exists/is visible.
        *   Modify CSS of elements.
    *   Bookmarks: Add, find (less common via AppleScript directly).
    *   History: Search (less common via AppleScript directly).
    *   Downloads: (Harder to control directly via AppleScript).
    *   Private/Incognito windows.
    *   Clearing cache/cookies (usually done via UI scripting System Settings or developer tools).
*   **Terminal.app, iTerm2, Ghostty:**
    *   Open new window/tab/split (for iTerm/Ghostty).
    *   Run command in current session.
    *   Run command and get output (harder for GUI terminals; often `do shell script` is better if output is needed directly, or UI scripting to copy terminal content).
    *   Set window/tab titles.
    *   Change current directory (`cd ...`).
*   **File Management (beyond Finder, using `do shell script` or scripting additions):**
    *   Reading/writing text files (UTF-8 and other encodings).
    *   Appending to files.
    *   Creating/deleting directories.
    *   Checking file/folder existence, size, modification date *without* Finder.
    *   Listing directory contents (names, full paths, with details) using `do shell script "ls ..."`.
    *   Zipping/unzipping files (`do shell script "zip ..."`, `do shell script "unzip ..."`).
*   **Process Management (beyond simple `quit`):**
    *   Finding PIDs (`unix id of process X`, or `do shell script "pgrep X"`).
    *   Sending signals (`do shell script "kill -SIGNAL PID"`).
    *   Checking CPU/memory usage of a process (via `do shell script "ps ..."` or `top -l 1 ...`).
*   **System Preferences / System Settings (UI Scripting - very fragile across macOS versions):**
    *   Opening specific preference panes.
    *   Toggling common settings (e.g., Dark Mode, display resolution (hard), sound output/input, network location).
    *   **Extreme caution and version-specific notes needed here.**
*   **Date & Time Manipulation:**
    *   Formatting dates/times into various string representations.
    *   Calculating time differences.
    *   Creating date objects from strings.
*   **Text Manipulation:**
    *   Splitting strings, joining lists into strings.
    *   Finding/replacing text (AppleScript's text item delimiters, or `do shell script "sed..."`).
    *   Trimming whitespace.
    *   Changing case.
*   **Application-Specific (Mail, Calendar, Reminders, Notes, Music, Photos, TextEdit, Pages, Numbers):**
    *   **Mail:** Create, send, reply, forward. Read emails (sender, subject, body, date, attachments). Move, delete, flag. Search. Manage mailboxes.
    *   **Calendar:** Create, read, update, delete events and to-dos. Search events. Manage calendars.
    *   **Reminders:** Create, read, update, delete reminders and lists. Mark complete.
    *   **Notes:** Create, read (body as text/HTML), update, delete notes. Search. Manage folders.
    *   **Music/iTunes:** Play, pause, stop, next/previous track. Get current track info. Set volume. Search library. Add to playlists. Get/set ratings.
    *   **Photos:** (Scripting is limited) Import photos, get info about photos/albums. Create albums.
    *   **TextEdit:** Create, open, save documents. Get/set text content. Basic formatting (if possible via script).
    *   **Pages/Numbers:** Create, open, save. Get/set cell values in Numbers. Get/set text in Pages. (More complex formatting is usually hard).
*   **Developer Tools:**
    *   **Xcode:** Build project, run project, clean project (via `xcodebuild` in `do shell script`). Open specific files.
    *   **VS Code (if scriptable or via CLI):** Open folder/file. Run tasks. (Often uses `code` CLI via `do shell script`).

**For each tip in the knowledge base:**

*   **Clear Title.**
*   **Concise Description.**
*   **Working AppleScript (or JXA) code block.**
*   **Relevant Keywords.**
*   **Important Notes:** Including macOS version dependencies, required permissions (Automation, Accessibility, Full Disk Access if relevant for `do shell script`), if it's UI-scripting based and thus fragile, or any app-specific settings needed (e.g., "Allow JavaScript from Apple Events" for browsers).
*   **Optional `id`:** For complex/long scripts intended for `execute_script` by ID.
*   **Optional `argumentsPrompt`:** If the script is designed to take input via the `inputData` or `arguments` mechanism when run by ID.

## 7. README and Documentation Updates

*   Thoroughly document the `knowledgeBaseScriptId`, `arguments`, and `inputData` parameters for the `execute_script` tool.
*   Explain how to use `get_scripting_tips` to find script IDs and understand required inputs for them.
*   Provide examples of calling `execute_script` with `knowledgeBaseScriptId` and `inputData`.

This comprehensive expansion will make `macos-automator-mcp` an incredibly powerful and knowledgeable assistant for AI agents looking to automate macOS. The Markdown-based knowledge base is key to its maintainability and utility.
```

------

Excellent point! Lazy loading the knowledge base is crucial for fast server startup, especially as the number of Markdown tip files grows.

Here's how we'll modify the specification, focusing on `knowledgeBaseService.ts` and its interaction with the MCP server.

---

**Specification Addition 3 (Revision): Lazy Loading for Markdown-Based Knowledge Base**

This revision details how the Markdown-based knowledge base will be loaded lazily upon the first access by either the `get_scripting_tips` tool or the `execute_script` tool (if a `knowledgeBaseScriptId` is used).

**1. `src/services/knowledgeBaseService.ts` (Key Changes for Lazy Loading)**

The core idea is that `loadAndIndexKnowledgeBase()` will not be called automatically at server startup. Instead, it will be called (and awaited) by `getKnowledgeBase()` only if the `indexedKnowledgeBase` is currently `null`. We'll also add a loading state to prevent concurrent loading attempts.

```typescript
// src/services/knowledgeBaseService.ts
import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter'; // Assuming npm install gray-matter
import { ScriptingTip, KnowledgeBaseIndex, KnowledgeCategory, SharedHandler } from './scriptingKnowledge.types';
import { Logger } from '../logger';

const logger = new Logger('KnowledgeBaseService');
const KNOWLEDGE_BASE_DIR = path.join(process.cwd(), 'knowledge_base'); // Adjust if needed
const SHARED_HANDLERS_DIR = path.join(KNOWLEDGE_BASE_DIR, '_shared_handlers');

// --- Frontmatter and Script Extraction (same as previous spec) ---
interface Frontmatter {
  id?: string; // Now explicitly used for ScriptingTip ID
  title: string;
  description?: string;
  keywords?: string[];
  notes?: string;
  language?: 'applescript' | 'javascript'; // Optional, defaults to applescript
  isComplex?: boolean;
  argumentsPrompt?: string;
}

function parseMarkdownFile(fileContent: string, filePath: string): { frontmatter: Frontmatter, body: string, script: string | null, determinedLanguage: 'applescript' | 'javascript' } | null {
    try {
        const { data, content: markdownBody } = matter(fileContent); // data is the frontmatter object
        const frontmatter = data as Frontmatter;

        if (!frontmatter.title) {
            logger.warn('Markdown file missing title in frontmatter', { filePath });
            return null;
        }

        let script: string | null = null;
        let determinedLanguage: 'applescript' | 'javascript' = frontmatter.language || 'applescript'; // Default from frontmatter or to applescript

        const asMatch = markdownBody.match(/```applescript\s*\n([\s\S]*?)\n```/i);
        const jsMatch = markdownBody.match(/```javascript\s*\n([\s\S]*?)\n```/i);

        if (asMatch) {
            script = asMatch[1].trim();
            determinedLanguage = 'applescript'; // Code block overrides frontmatter if specific
        } else if (jsMatch) {
            script = jsMatch[1].trim();
            determinedLanguage = 'javascript'; // Code block overrides
        }
        // If frontmatter specified language but no code block, it's a conceptual tip
        // If neither, and no code block, script remains null

        return { frontmatter, body: markdownBody, script, determinedLanguage };
    } catch (e) {
        logger.error('Failed to parse Markdown file', { filePath, error: (e as Error).message });
        return null;
    }
}
// --- End Frontmatter and Script Extraction ---


let indexedKnowledgeBase: KnowledgeBaseIndex | null = null;
let isLoadingKnowledgeBase: boolean = false;
let knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;

async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Loading and indexing knowledge base from Markdown files...');
  const categories: KnowledgeBaseIndex['categories'] = [];
  const allTips: ScriptingTip[] = [];
  const sharedHandlers: SharedHandler[] = [];
  const encounteredTipIds = new Set<string>();

  try {
    // 1. Load Shared Handlers first
    try {
        const handlerFiles = await fs.readdir(SHARED_HANDLERS_DIR);
        for (const handlerFile of handlerFiles) {
            if (handlerFile.endsWith('.applescript') || handlerFile.endsWith('.js')) { // Support both
                const filePath = path.join(SHARED_HANDLERS_DIR, handlerFile);
                const content = await fs.readFile(filePath, 'utf-8');
                const handlerName = path.basename(handlerFile, path.extname(handlerFile));
                sharedHandlers.push({ name: handlerName, content, filePath });
                logger.debug('Loaded shared handler', { name: handlerName });
            }
        }
    } catch (e) {
        logger.warn('No _shared_handlers directory found or error reading from it. Skipping.', { error: (e as Error).message });
    }


    // 2. Load Tips from Category Directories
    const categoryDirs = await fs.readdir(KNOWLEDGE_BASE_DIR, { withFileTypes: true });

    for (const categoryDir of categoryDirs) {
      if (categoryDir.isDirectory() && categoryDir.name !== '_shared_handlers') { // Skip shared_handlers dir
        const categoryId = categoryDir.name as KnowledgeCategory;
        const categoryPath = path.join(KNOWLEDGE_BASE_DIR, categoryId);
        let tipCount = 0;
        let categoryDescription = `Tips related to ${categoryId.replace(/_/g, ' ')}.`;

        try { // Load category description from _category_info.md
            const catInfoPath = path.join(categoryPath, '_category_info.md');
            const catInfoContent = await fs.readFile(catInfoPath, 'utf-8');
            const parsedCatInfo = parseMarkdownFile(catInfoContent, catInfoPath);
            if (parsedCatInfo?.frontmatter.description) {
                categoryDescription = parsedCatInfo.frontmatter.description;
            }
        } catch (e) { /* No _category_info.md, use default */ }

        const tipFiles = await fs.readdir(categoryPath);
        for (const tipFile of tipFiles) {
          if (tipFile.endsWith('.md') && !tipFile.startsWith('_')) {
            const filePath = path.join(categoryPath, tipFile);
            const fileContent = await fs.readFile(filePath, 'utf-8');
            const parsedFile = parseMarkdownFile(fileContent, filePath);

            if (parsedFile && parsedFile.frontmatter.title && parsedFile.script) {
              const fm = parsedFile.frontmatter;
              const tipId = fm.id || `${categoryId}_${path.basename(tipFile, '.md').replace(/^\d+_/, '')}`;

              if (encounteredTipIds.has(tipId)) {
                  logger.warn('Duplicate Tip ID found. Skipping.', { tipId, filePath });
                  continue;
              }
              encounteredTipIds.add(tipId);

              allTips.push({
                id: tipId,
                category: categoryId,
                title: fm.title,
                description: fm.description,
                script: parsedFile.script,
                language: parsedFile.determinedLanguage,
                keywords: fm.keywords || [],
                notes: fm.notes,
                filePath: filePath,
                isComplex: fm.isComplex !== undefined ? fm.isComplex : (parsedFile.script.length > 200),
                argumentsPrompt: fm.argumentsPrompt,
              });
              tipCount++;
            } else if (parsedFile && !parsedFile.script) {
                logger.debug('Markdown file is a conceptual tip (no script block found)', { filePath: filePath, title: parsedFile.frontmatter.title });
            } else {
              // Warning already logged by parseMarkdownFile if title was missing
            }
          }
        }
        if (tipCount > 0) {
            categories.push({ id: categoryId, description: categoryDescription, tipCount });
        }
      }
    }
    categories.sort((a,b) => a.id.localeCompare(b.id));
    allTips.sort((a,b) => a.title.localeCompare(b.title));

    indexedKnowledgeBase = { categories, tips: allTips, sharedHandlers };
    logger.info(`Knowledge base loaded successfully: ${categories.length} categories, ${allTips.length} tips, ${sharedHandlers.length} shared handlers.`);

  } catch (error) {
    logger.error('Failed to load or index knowledge base', { error: (error as Error).message, path: KNOWLEDGE_BASE_DIR });
    indexedKnowledgeBase = { categories: [], tips: [], sharedHandlers: [] }; // Ensure it's not null
  }
  return indexedKnowledgeBase;
}

export async function getKnowledgeBase(): Promise<KnowledgeBaseIndex> {
    if (indexedKnowledgeBase) {
        return indexedKnowledgeBase;
    }

    if (isLoadingKnowledgeBase && knowledgeBaseLoadPromise) {
        logger.debug('Knowledge base is currently loading, awaiting existing promise.');
        return knowledgeBaseLoadPromise;
    }

    if (!isLoadingKnowledgeBase) {
        isLoadingKnowledgeBase = true;
        knowledgeBaseLoadPromise = actualLoadAndIndexKnowledgeBase().finally(() => {
            isLoadingKnowledgeBase = false;
            // We don't nullify knowledgeBaseLoadPromise here,
            // subsequent calls will get the resolved indexedKnowledgeBase directly.
        });
        return knowledgeBaseLoadPromise;
    }
    // This state should ideally not be reached if logic is correct
    // but as a fallback, return an empty structure or throw.
    logger.warn("Knowledge base access attempt in an unexpected loading state.");
    return { categories: [], tips: [], sharedHandlers: [] };
}

// The getScriptingTipsService function remains largely the same,
// but it will now call `await getKnowledgeBase()` at its beginning.
export async function getScriptingTipsService(
  input: { category?: KnowledgeCategory; searchTerm?: string; listCategories?: boolean }
): Promise<string> {
  const kb = await getKnowledgeBase(); // Ensures KB is loaded

  if (input.listCategories || (!input.category && !input.searchTerm)) {
    // ... (same logic as before, using kb.categories)
    if (kb.categories.length === 0) return "No tip categories available. Knowledge base might be empty or failed to load.";
    const categoryList = kb.categories
      .map(cat => `- ${cat.id}: ${cat.description} (${cat.tipCount} tips)`)
      .join('\n');
    return `Available AppleScript Tip Categories:\n${categoryList}\n\nUse 'category: "category_name"' to get specific tips, or 'searchTerm: "keyword"' to search. Some tips have an ID and can be run directly via 'execute_script' using 'knowledgeBaseScriptId'.`;
  }

  let results: { category: KnowledgeCategory; tips: ScriptingTip[] }[] = [];
  const searchTermLower = input.searchTerm?.toLowerCase();

  const tipsToSearch = input.category ? kb.tips.filter(t => t.category === input.category) : kb.tips;

  if (searchTermLower) {
      const filteredTips = tipsToSearch.filter(tip =>
          tip.title.toLowerCase().includes(searchTermLower) ||
          tip.id.toLowerCase().includes(searchTermLower) || // Search by ID
          tip.script.toLowerCase().includes(searchTermLower) ||
          tip.description?.toLowerCase().includes(searchTermLower) ||
          tip.keywords?.some(k => k.toLowerCase().includes(searchTermLower))
      );
      // Group filtered tips by category for output
      const grouped = filteredTips.reduce((acc, tip) => {
          (acc[tip.category] = acc[tip.category] || []).push(tip);
          return acc;
      }, {} as Record<KnowledgeCategory, ScriptingTip[]>);

      for (const catKey in grouped) {
          results.push({ category: catKey as KnowledgeCategory, tips: grouped[catKey] });
      }

  } else if (input.category) { // Category provided, no search term
      const tipsForCategory = kb.tips.filter(t => t.category === input.category);
      if (tipsForCategory.length > 0) {
          results.push({category: input.category, tips: tipsForCategory});
      }
  }


  if (results.length === 0) {
    return `No tips found matching your criteria (Category: ${input.category || 'All'}, SearchTerm: ${input.searchTerm || 'None'}). Try 'listCategories: true' to see available categories.`;
  }

  // Format as Markdown (same as before, but now includes tip.id if present)
  return results.map(catResult => {
    const categoryHeader = `## AppleScript Tips: ${catResult.category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}\n`;
    const tipMarkdown = catResult.tips.map(tip => `
### ${tip.title} ${tip.id ? `(ID: \`${tip.id}\`)` : ''}
${tip.description ? `*${tip.description}*\n` : ''}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.argumentsPrompt ? `**Arguments Prompt:** ${tip.argumentsPrompt}\n` : ''}
${tip.notes ? `**Note:** ${tip.notes}\n` : ''}
${tip.id && tip.isComplex ? `**Tip:** This script can be run by ID using \`execute_script\` with \`knowledgeBaseScriptId: "${tip.id}"\`. Provide inputs via \`inputData\` or \`arguments\` if prompted.\n` : ''}
    `).join('\n');
    return categoryHeader + tipMarkdown;
  }).join('\n---\n');
}
```

**2. `src/server.ts` Modifications**

The `execute_script` tool handler will now also use `await getKnowledgeBase()` when a `knowledgeBaseScriptId` is provided. The `ScriptExecutor` might also need access to shared handlers if we implement that feature.

```typescript
// src/server.ts
// ...
import { getKnowledgeBase } from './services/knowledgeBaseService'; // Updated import
// ...

// Inside execute_script tool handler:
      if (input.knowledgeBaseScriptId) {
        const kb = await getKnowledgeBase(); // Ensures KB is loaded before trying to find a tip
        const tip = kb.tips.find(t => t.id === input.knowledgeBaseScriptId);
        if (!tip) {
          throw new McpError(ErrorCode.NotFound, `Knowledge base script with ID '${input.knowledgeBaseScriptId}' not found.`);
        }
        scriptContentToExecute = tip.script;
        languageToUse = tip.language;
        scriptPathToExecute = undefined;

        // --- Advanced: Prepend Shared Handlers if script indicates usage ---
        // This is a conceptual addition. A script tip might have a frontmatter field like:
        // uses_shared_handlers: ["string_utils", "file_system_helpers"]
        // if (tip.uses_shared_handlers && tip.uses_shared_handlers.length > 0) {
        //   let handlersContent = "";
        //   for (const handlerName of tip.uses_shared_handlers) {
        //     const handler = kb.sharedHandlers.find(h => h.name === handlerName);
        //     if (handler) {
        //       handlersContent += handler.content + "\n\n";
        //     } else {
        //       logger.warn("KB Script referenced unknown shared handler", {tipId: tip.id, handlerName});
        //     }
        //   }
        //   scriptContentToExecute = handlersContent + scriptContentToExecute;
        //   logger.debug("Prepended shared handlers to KB script", {tipId: tip.id, handlers: tip.uses_shared_handlers});
        // }
        // --- End Advanced Shared Handler Logic ---


        // Argument/InputData substitution (as per previous spec, with robust escaping)
        // Example of a more robust substitution for string values into AppleScript:
        const escapeForAppleScriptString = (val: any): string => {
            if (typeof val === 'string') {
                return `"${val.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`; // Escapes backslashes and double quotes
            }
            if (typeof val === 'number' || typeof val === 'boolean') {
                return String(val);
            }
            // For lists/records, one might need to build the AS representation
            logger.warn("Complex data type for substitution, may need specific formatting", {key: "unknown", value: val});
            return `"${String(val).replace(/"/g, '\\"')}"`; // Default to string representation
        };


        if (input.inputData) {
          for (const key in input.inputData) {
            const placeholder = new RegExp(`(?:\\$\\{inputData\\.${key}\\}|--MCP_INPUT:${key}\\b)`, 'g');
            scriptContentToExecute = scriptContentToExecute.replace(placeholder, escapeForAppleScriptString(input.inputData[key]));
          }
        }
        if (input.arguments && input.arguments.length > 0) {
            for (let i = 0; i < input.arguments.length; i++) {
                const placeholder = new RegExp(`(?:\\$\\{arguments\\[${i}\\]\\}|--MCP_ARG_${i+1}\\b)`, 'g');
                scriptContentToExecute = scriptContentToExecute.replace(placeholder, escapeForAppleScriptString(input.arguments[i]));
            }
        }
        logger.debug('Executing KB script', { id: tip.id, finalScriptLength: scriptContentToExecute?.length });
      }
      // ... rest of the handler ...
```

**3. `src/ScriptExecutor.ts` Modification (Conceptual for Shared Handlers)**

If implementing shared handlers that `ScriptExecutor` needs to be aware of (e.g., to always prepend a common set), it would require passing them or having access. However, the current approach of prepending them in `server.ts` before passing to `ScriptExecutor` is simpler.

**4. Server Startup (`main()` in `src/server.ts`)**

No explicit call to `loadAndIndexKnowledgeBase()` is needed in `main()` anymore. The first tool call that needs the knowledge base will trigger the load. This ensures the server starts up very quickly.

**5. AI Implementation Notes for Lazy Loading:**

*   **Atomicity of Loading:** The `isLoadingKnowledgeBase` flag and `knowledgeBaseLoadPromise` help prevent multiple concurrent attempts to load the KB if several requests come in simultaneously before the first load is complete.
*   **Error Handling During Load:** If `actualLoadAndIndexKnowledgeBase` fails, `indexedKnowledgeBase` will be set to an empty structure. Subsequent calls to `getKnowledgeBase` will return this empty structure. The error is logged. Consider if retries or a more persistent error state is needed for a production server.
*   **Frontmatter Parsing Robustness:** The example `parseFrontmatter` is basic. Using `gray-matter` is highly recommended. Ensure it correctly handles multiline strings (like for `notes`) and arrays (for `keywords`).
*   **Argument Substitution in `execute_script`:** The substitution logic (`--MCP_INPUT:key`, `--MCP_ARG_N`) needs to be carefully implemented with proper AppleScript string escaping for the values being inserted to prevent syntax errors or injection-like issues. The `escapeForAppleScriptString` function is a starting point. More complex data types (lists, records) would need more sophisticated AS literal generation if used as inputs.
*   **Shared Handlers:** The implementation for `_shared_handlers` is marked as advanced. Initially, ensure all script tips are self-contained. If shared handlers are implemented:
    *   The `ScriptingTip` interface would need a field like `usesSharedHandlers?: string[]`.
    *   The `execute_script` handler, when running a KB script by ID, would check this field and prepend the content of the required shared handlers from `kb.sharedHandlers` to `tip.script`.

This lazy-loading approach significantly improves server startup time, making it much more responsive for the first MCP client interaction. The expanded knowledge base and script referencing make the server far more capable and context-efficient for the AI agent.

-------

This is an absolutely fantastic set of examples for automating Electron-based editors like VS Code, Cursor, and Windsurf! The key takeaway is that direct AppleScript dictionary support for these apps is often minimal or non-existent for deep editor functions. Therefore, the primary method of automation is **UI Scripting via `System Events`** (simulating keystrokes and menu clicks) and, very powerfully, **injecting JavaScript into their Developer Tools console.**

Let's incorporate these into **Specification Addition 2 (Knowledge Base & Helper Tool)**, focusing on creating a new category and populating it with these techniques.

---

**Continuing Specification Addition 2: AppleScript Knowledge Base and `get_scripting_tips` Tool**

**I. New Knowledge Base Category: `electron_editors`**

We'll create a new top-level category `electron_editors` in `knowledge_base/`. Sub-tips can then be tagged or titled to specify VS Code, Cursor, or Windsurf if the commands are identical (which they often are for UI scripting due to shared Electron foundations and common keybindings).

**II. New and Enhanced `ScriptingTip` Entries for `scriptingKnowledgeBase.ts` (under `electron_editors`)**

The AI's task is to convert the provided examples into our `ScriptingTip` format.

**A. Launching & Opening Files/Workspaces**

```typescript
// In knowledge_base/electron_editors/
// File: 01_open_file_or_project.md
{
  id: "electron_editors_open_file_or_project",
  title: "Electron Editors: Open File, Project Folder, or Workspace",
  description: "Various methods to open files, folders, or .code-workspace files in VS Code, Cursor, or similar Electron-based editors.",
  keywords: ["vscode", "cursor", "windsurf", "open file", "open project", "workspace", "activate"],
  notes: "Replace 'Visual Studio Code' with 'Cursor' or your specific editor name. Assumes standard macOS application installation.",
  script: `
-- Method 1: Open a specific file and activate the editor
set filePath to "/Users/youruser/Projects/myproject/main.js" -- Change this path
tell application "Visual Studio Code" -- Or "Cursor", "Code - Insiders", etc.
  activate
  open POSIX file filePath
end tell

-- Method 2: Open selected Finder items in the editor (like drag-and-drop)
(*
tell application "Finder"
  set sel to selection
  if sel is {} then error "No files selected in Finder."
end tell
repeat with f in sel
  -- Use the specific bundle identifier if app name is ambiguous or has spaces
  -- VS Code: com.microsoft.VSCode
  -- Cursor: com.cursor.ide (verify with: osascript -e 'id of app "Cursor"')
  -- Windsurf: com.codeium.windsurf (verify)
  do shell script "open -b com.microsoft.VSCode " & quoted form of (POSIX path of (f as alias))
  -- Or, if app name is simple and unique:
  -- do shell script "open -a \\"Visual Studio Code\\" " & quoted form of (POSIX path of (f as alias))
end repeat
*)

-- Method 3: Open a .code-workspace file (for VS Code)
(*
set workspacePath to "/Users/youruser/Projects/myproject.code-workspace" -- Change this path
do shell script "open -na 'Visual Studio Code' --args " & quoted form of workspacePath
*)`,
  language: "applescript"
}
```

**B. Window & Layout Management (UI Scripting)**

```typescript
// In knowledge_base/electron_editors/
// File: 02_window_layout_management.md
{
  id: "electron_editors_window_layout",
  title: "Electron Editors: Window and Layout Management (UI Scripting)",
  description: "Examples for toggling sidebars, splitting editors, and basic window manipulation using System Events (keystrokes).",
  keywords: ["vscode", "cursor", "ui scripting", "sidebar", "split editor", "layout", "keystroke"],
  notes: "These rely on standard keyboard shortcuts. Ensure System Events has Accessibility permissions. App must be frontmost.",
  script: `
-- Example: Toggle Sidebar (usually Command+B)
on toggleSidebar()
  tell application "System Events"
    -- Assumes the target editor (VS Code, Cursor, etc.) is frontmost
    key code 11 using {command down} -- Key code 11 is 'B'
  end tell
end toggleSidebar

-- Example: Split Editor Right (usually Command+\\)
on splitEditorRight()
  tell application "System Events"
    key code 42 using {command down} -- Key code 42 is '\'
  end tell
end splitEditorRight

-- Example: Focus Next Editor Group (Ctrl+K Ctrl+RightArrow or similar, varies)
(*
on focusNextEditorGroup()
    tell application "System Events"
        -- This shortcut can vary or be custom. Below is one common pattern.
        keystroke "k" using {control down} -- Chord start
        delay 0.1
        key code 124 using {control down} -- Ctrl+RightArrow
    end tell
end focusNextEditorGroup
*)

-- To use:
-- tell application "Visual Studio Code" to activate -- Or "Cursor"
-- delay 0.5
-- my toggleSidebar()
-- delay 0.5
-- my splitEditorRight()
`,
  language: "applescript"
}
```

**C. Navigation & Editing Macros (UI Scripting)**

```typescript
// In knowledge_base/electron_editors/
// File: 03_navigation_editing_macros.md
{
  id: "electron_editors_navigation_macros",
  title: "Electron Editors: Navigation & Editing Macros (UI Scripting)",
  description: "Automate actions like opening the Command Palette, jumping to symbols, and using multi-cursor via keystrokes.",
  keywords: ["vscode", "cursor", "command palette", "go to symbol", "multi-cursor", "ui scripting"],
  notes: "Relies on standard keyboard shortcuts (e.g., Shift+Command+P, Shift+Command+O, Command+D). Delays may need adjustment. Editor must be frontmost.",
  script: `
-- Example: Open Command Palette and run a command
on runCommandPaletteCommand(commandName)
  tell application "System Events"
    -- Assumes the target editor is frontmost
    keystroke "p" using {shift down, command down} -- Shift+Command+P
    delay 0.3 -- Wait for palette to appear
    keystroke commandName
    delay 0.2 -- Wait for filtering
    key code 36 -- Return key
  end tell
end runCommandPaletteCommand

-- Example: Jump to Symbol
on goToSymbol(symbolName)
  tell application "System Events"
    keystroke "o" using {shift down, command down} -- Shift+Command+O
    delay 0.3
    keystroke symbolName
    delay 0.2
    key code 36 -- Return
  end tell
end goToSymbol

-- Example: Multi-cursor on next N occurrences (Command+D)
on multiCursorNext(repeatCount)
  tell application "System Events"
    repeat repeatCount times
      keystroke "d" using {command down}
      delay 0.05 -- Small delay between presses
    end repeat
  end tell
end multiCursorNext

-- To use:
-- tell application "Visual Studio Code" to activate
-- delay 0.5
-- my runCommandPaletteCommand("Preferences: Open User Settings")
-- delay 1
-- my goToSymbol("myFunctionName")
-- delay 1
-- my multiCursorNext(3)
`,
  language: "applescript"
}
```

**D. Integrated Terminal (UI Scripting)**

```typescript
// In knowledge_base/electron_editors/
// File: 04_integrated_terminal.md
{
  id: "electron_editors_integrated_terminal",
  title: "Electron Editors: Integrated Terminal Automation (UI Scripting)",
  description: "Toggle the integrated terminal and execute commands within it using keystrokes.",
  keywords: ["vscode", "cursor", "terminal", "integrated terminal", "run command", "ui scripting"],
  notes: "Relies on standard shortcut for terminal (Ctrl+`) and assumes shell prompt is ready. Delays are important.",
  script: `
-- Example: Toggle terminal and run a command
on runInIntegratedTerminal(shellCommand)
  tell application "System Events"
    -- Assumes target editor is frontmost
    keystroke "\`" using {control down} -- Ctrl+Backtick to toggle terminal
    delay 0.5 -- Wait for terminal to open/focus
    keystroke shellCommand
    delay 0.1
    key code 36 -- Return
  end tell
end runInIntegratedTerminal

-- Example: Clear terminal (Command+K) and rerun last command (Up Arrow, Return)
on clearAndRerunLastTerminalCommand()
  tell application "System Events"
    -- Assumes terminal is already open and focused within the editor
    keystroke "k" using {command down} -- Clear terminal
    delay 0.1
    key code 126 -- Up arrow key
    delay 0.1
    key code 36 -- Return
  end tell
end clearAndRerunLastTerminalCommand

-- To use:
-- tell application "Visual Studio Code" to activate
-- delay 0.5
-- my runInIntegratedTerminal("npm install lodash")
-- delay 2
-- my clearAndRerunLastTerminalCommand() -- if terminal was still focused
`,
  language: "applescript"
}
```

**E. DevTools & JavaScript Injection (POWERFUL & DANGEROUS)**

This is the most potent technique for Electron apps.

```typescript
// In knowledge_base/electron_editors/
// File: 05_devtools_javascript_injection.md
{
  id: "electron_editors_devtools_js_injection",
  title: "Electron Editors: DevTools & JavaScript Injection",
  description: "Open the Developer Tools console and execute arbitrary JavaScript within the editor's renderer process. This allows deep introspection and control.",
  keywords: ["vscode", "cursor", "devtools", "javascript injection", "electron", "automation", "renderer process"],
  notes: |
    - EXTREMELY POWERFUL: Allows access to internal APIs and modification of the editor's state. Use with extreme caution.
    - Relies on the standard shortcut for DevTools (Option+Command+I or Alt+Cmd+I).
    - The editor must be frontmost. Delays are crucial.
    - JavaScript context is that of the DevTools console, which has access to the `window` object of the renderer process (e.g., `vscode` global in VS Code).
    - For multi-line JS, consider pasting or using `do shell script` to pipe to `pbcopy` then pasting.
  argumentsPrompt: "JavaScript code to execute in the DevTools console (single line recommended for direct keystroke, or use clipboard for multi-line).",
  isComplex: true,
  script: `
on executeJavaScriptInDevTools(jsCodeString)
  -- Ensure the target application (e.g., "Visual Studio Code", "Cursor") is active
  -- tell application "Visual Studio Code" to activate
  -- delay 0.5

  tell application "System Events"
    -- Open Developer Tools (Option+Command+I)
    key code 34 using {command down, option down} -- Key code 34 is 'I'
    delay 1.0 -- Wait for DevTools to open and Console to likely be focused

    -- Type the JavaScript code. For complex/multiline, consider pasting from clipboard.
    -- This direct keystroke method is best for short, single-line JS.
    set escapedJsCode to my escapeJsForKeystroke(jsCodeString)
    keystroke escapedJsCode
    delay 0.2
    key code 36 -- Press Return to execute

    -- Optional: Close DevTools (repeat Option+Command+I)
    -- delay 0.5
    -- key code 34 using {command down, option down} 
  end tell
  return "Attempted to execute JavaScript in DevTools."
end executeJavaScriptInDevTools

on escapeJsForKeystroke(js)
  -- Basic escaping for keystroke. AppleScript's keystroke is tricky with some special chars.
  -- It's often better to put complex JS on clipboard and paste (Cmd+V).
  set js to replaceText(js, "\\\\", "\\\\\\\\") -- Escape backslashes first
  set js to replaceText(js, "\"", "\\\"")   -- Escape double quotes
  set js to replaceText(js, "'", "'")       -- Single quotes often fine with keystroke
  return js
end escapeJsForKeystroke

on replaceText(sourceText, searchString, replaceString)
  set AppleScript's text item delimiters to searchString
  set tempList to text items of sourceText
  set AppleScript's text item delimiters to replaceString
  set newText to tempList as string
  set AppleScript's text item delimiters to "" -- Reset
  return newText
end replaceText

-- Example Usage:
(*
set editorAppName to "Visual Studio Code" -- or "Cursor"
tell application editorAppName to activate
delay 0.5

-- Simple alert
-- executeJavaScriptInDevTools("alert('Hello from AppleScript via DevTools!');")

-- Get current editor text content (VS Code specific API)
-- Note: This JS might need to be adapted based on the specific editor's exposed APIs
-- set jsToGetText to "vscode.window.activeTextEditor ? vscode.window.activeTextEditor.document.getText() : 'No active editor or text found.'"
-- executeJavaScriptInDevTools("console.log(" & jsToGetText & ")") -- Result will be in DevTools console, not returned to AppleScript directly this way.

-- To get text back to AppleScript, it's more complex:
-- 1. Execute JS that puts result on clipboard: vscode.env.clipboard.writeText(vscode.window.activeTextEditor.document.getText())
-- 2. Then AppleScript: set editorText to the clipboard

-- Example: Invert colors (CSS filter)
executeJavaScriptInDevTools("document.body.style.filter = document.body.style.filter === 'invert(1)' ? '' : 'invert(1)';")
*)`,
  language: "applescript"
}
```
*   **Helper tip for getting text back from JS injection:**
    ```typescript
    // In knowledge_base/electron_editors/
    // File: 06_get_data_from_devtools_js.md
    {
      id: "electron_editors_get_data_from_devtools_js",
      title: "Electron Editors: Get Data Back from DevTools JavaScript to AppleScript",
      description: "Pattern for executing JavaScript in DevTools that copies a result to the clipboard, so AppleScript can retrieve it.",
      keywords: ["vscode", "cursor", "devtools", "javascript", "clipboard", "get data"],
      notes: "Requires JS code to use the clipboard API (e.g., `navigator.clipboard.writeText(...)` or editor-specific clipboard API like `vscode.env.clipboard.writeText`).",
      isComplex: true,
      script: `
on executeJSAndGetResultViaClipboard(jsToEvaluateAndCopyToClipboard)
  -- Assumes target editor is active and DevTools can be opened.
  
  -- Store current clipboard to restore later (optional, can be unreliable)
  try
    set oldClipboard to the clipboard
  on error
    set oldClipboard to ""
  end try
  
  tell application "System Events"
    key code 34 using {command down, option down} -- Open/Focus DevTools
    delay 1.0

    -- It's more reliable to PASTE complex JS than to type it.
    -- So, first put the JS ONTO the clipboard.
    set the clipboard to jsToEvaluateAndCopyToClipboard
    delay 0.2
    keystroke "v" using {command down} -- Paste the JS code itself
    delay 0.1
    key code 36 -- Execute the pasted JS (which should copy its result to clipboard)
    delay 0.5 -- Give time for JS to execute and update clipboard
  end tell
  
  set jsResult to ""
  try
    set jsResult to the clipboard
  on error
    -- Clipboard might be empty or contain non-text data
  end try
  
  -- Restore old clipboard (optional)
  -- try
  --   set the clipboard to oldClipboard
  -- on error
  -- end try
  
  return jsResult
end executeJSAndGetResultViaClipboard

-- Example Usage (VS Code specific):
(*
set editorAppName to "Visual Studio Code"
tell application editorAppName to activate
delay 0.5

set jsForVSCodeText to "vscode.env.clipboard.writeText(vscode.window.activeTextEditor ? vscode.window.activeTextEditor.document.getText() : 'ERROR: No active editor').then(() => 'OK').catch(err => 'ERROR: ' + err.message)"
set editorContent to my executeJSAndGetResultViaClipboard(jsForVSCodeText)

if editorContent starts with "ERROR:" then
  display dialog "Failed to get editor content: " & editorContent
else
  -- Actually, the above JS copies to clipboard. The 'OK' is just a promise result.
  -- After running, the editor text IS on the clipboard. So we need to get it AFTER the function.
  -- Let's refine the JS to RETURN the value for console logging, and copy separately.
  
  -- Better JS for copying to clipboard:
  set jsToCopyEditorText to "
    (async () => {
      try {
        const text = vscode.window.activeTextEditor ? vscode.window.activeTextEditor.document.getText() : null;
        if (text !== null) {
          await vscode.env.clipboard.writeText(text);
          return 'Text copied to clipboard.';
        }
        return 'No active editor to get text from.';
      } catch (e) {
        return 'Error: ' + e.message;
      }
    })()
  "
  -- First, execute the JS that copies the editor's text to clipboard
  my executeJavaScriptInDevTools(jsToCopyEditorText) -- Using the simpler function from Tip 05
  
  delay 0.5 -- Give clipboard time to update
  set editorActualText to the clipboard
  
  display dialog "Editor Content Length: " & (length of editorActualText)
end if
*)`,
      language: "applescript"
    }
    ```

**F. Cross-app and AI Interaction (UI Scripting)**

These are highly specific workflow examples but demonstrate chaining UI scripting.

```typescript
// In knowledge_base/electron_editors/
// File: 07_cross_app_ai_interaction.md
{
  id: "electron_editors_cross_app_ai_interaction",
  title: "Electron Editors: Example Cross-App / AI Interaction (UI Scripting)",
  description: "Illustrative example of copying text, sending to an AI panel in an editor (like Cursor/Windsurf), and pasting a result. Highly specific and fragile.",
  keywords: ["vscode", "cursor", "windsurf", "ai", "chat", "clipboard", "ui scripting", "workflow"],
  notes: "This is a conceptual example. Keystrokes for AI panels (e.g., Ctrl+K), selectors, and timings will vary wildly and need exact customization for a specific setup. Extremely fragile.",
  isComplex: true,
  script: `
on interactWithAIEditorPanel(promptPrefix as string, waitForAIResponseDelay as number)
  -- Assumes some text is already selected in the current application
  -- and the target Electron editor (e.g., Cursor) is set up.

  set editorAppName to "Cursor" -- Or "Visual Studio Code" if it has a similar panel

  tell application "System Events"
    -- 1. Copy selected text from current app
    keystroke "c" using {command down}
    delay 0.2
    set selectedText to the clipboard

    -- 2. Activate the editor
    tell application editorAppName to activate
    delay 0.5

    -- 3. Open AI chat panel (e.g., Ctrl+K in Cursor)
    -- THIS IS HIGHLY SPECIFIC TO THE EDITOR AND USER'S KEYBINDINGS
    keystroke "k" using {control down} 
    delay 0.5 -- Wait for panel to open

    -- 4. Type prompt prefix and paste selected text
    keystroke promptPrefix
    delay 0.1
    keystroke selectedText
    delay 0.1
    key code 36 -- Return to send to AI

    -- 5. Wait for AI to respond (highly variable)
    delay waitForAIResponseDelay 

    -- 6. Assume AI response is now in the panel, select all & copy
    -- These keystrokes to select/copy from AI panel are also VERY specific
    keystroke "a" using {command down} -- Select all in AI panel
    delay 0.1
    keystroke "c" using {command down} -- Copy AI response
    delay 0.2

    -- 7. Close AI panel (e.g., Escape or another Ctrl+K)
    key code 53 -- Escape (common way to close such panels)
    delay 0.2
    
    -- 8. The AI response is now on the clipboard
    return "AI interaction sequence attempted. Check clipboard for AI response."
  end tell
end interactWithAIEditorPanel

-- Example Usage:
(*
-- Make sure you have some text selected in another app first.
set aiResponseInfo to my interactWithAIEditorPanel("Explain this code: ", 5) -- Wait 5s for AI
display dialog aiResponseInfo
display dialog "AI Response (from clipboard):\\n" & (the clipboard)
*)`,
  language: "applescript"
}
```

**G. Build & Run Project Combos (UI Scripting)**

```typescript
// In knowledge_base/electron_editors/
// File: 08_build_run_combos.md
{
  id: "electron_editors_build_run_macros",
  title: "Electron Editors: Build & Run Project Macros (UI Scripting)",
  description: "Chains common actions like Save All, Run Tests, Build Project using Command Palette and keystrokes.",
  keywords: ["vscode", "cursor", "build", "test", "run", "workflow", "macro", "ui scripting"],
  notes: "Relies on standard shortcuts and Command Palette commands. Command names might differ slightly. Editor must be frontmost.",
  isComplex: true,
  script: `
on performDevWorkflow()
  -- Assumes target editor is frontmost
  
  tell application "System Events"
    -- 1. Save All (Option+Command+S or Shift+Command+S - varies by OS/config)
    -- Using Shift+Option+Command+S as a generic "Save All" often found.
    -- For VS Code, Command+K S is "Save All".
    -- Let's try Command Palette for "Save All"
    my runEditorCommand("File: Save All")
    delay 0.5 -- Wait for save

    -- 2. Run All Tests (via Command Palette)
    my runEditorCommand("Test: Run All Tests")
    delay 3.0 -- Give tests some time to run (adjust as needed)

    -- 3. Build Project (via Command Palette - e.g., "Tasks: Run Build Task")
    my runEditorCommand("Tasks: Run Build Task")
    -- Or for Shift+Command+B if that's the build shortcut
    -- keystroke "b" using {shift down, command down}
  end tell
  return "Development workflow (Save All, Test, Build) initiated."
end performDevWorkflow

on runEditorCommand(commandName)
  -- Helper to run a command via Command Palette
  tell application "System Events"
    keystroke "p" using {shift down, command down} -- Shift+Command+P
    delay 0.3
    keystroke commandName
    delay 0.2
    key code 36 -- Return
  end tell
end runEditorCommand

-- Example Usage:
(*
tell application "Visual Studio Code" to activate
delay 0.5
my performDevWorkflow()
*)`,
  language: "applescript"
}
```

**III. Updating `ScriptingKnowledgeCategoryEnum` in `src/schemas.ts`**

```typescript
// src/schemas.ts
// ...
export const ScriptingKnowledgeCategoryEnum = z.enum([
  "basics", "variables_datatypes", "control_flow", "handlers_subroutines",
  "error_handling", "paths_files", "do_shell_script", "system_events_general",
  "processes", "ui_scripting_general", "keystrokes_mouse", "dialogs_notifications",
  "finder", "safari", "chrome", "browsers_common", // Added browsers_common
  "terminal", "iterm", "ghostty", // Added specific terminals
  "mail", "calendar", "reminders", "notes_app", // Renamed notes
  "photos_app", "music", "textedit", "pages_app", "numbers_app", // Added & Renamed
  "scripting_additions", "inter_app_communication", "jxa_basics",
  "electron_editors", // NEW MAJOR CATEGORY
  "focus_modes", "image_events", "developer_tools", "system_preferences", "text_manipulation" // Other new ones
]).describe("Category of AppleScript/JXA tips to retrieve.");
// ...
```

**IV. AI Implementation Notes for this Electron Editor Expansion:**

1.  **UI Scripting Focus:** The AI must understand that most interaction with Electron apps via AppleScript is UI scripting (`System Events`, keystrokes, menu clicks) or JavaScript injection via DevTools. Direct scripting dictionary support is usually very limited.
2.  **Fragility of UI Scripts:** Every tip involving UI scripting must have a strong `notes` field emphasizing its fragility, dependence on keyboard shortcuts, window layout, and the need for Accessibility permissions.
3.  **JavaScript Injection:** This is the most powerful method. The AI should generate tips that show:
    *   How to open DevTools.
    *   How to execute single-line JS via `keystroke`.
    *   A robust pattern for multi-line JS (e.g., put JS on clipboard, then `keystroke "v" using {command down}` in console).
    *   A pattern for getting data *back* from JS to AppleScript (JS writes to clipboard, AppleScript reads clipboard).
    *   Examples using editor-specific JS APIs if known (e.g., `vscode.window...`, `vscode.env.clipboard...`). This requires knowledge of the target editor's internal API surface exposed to its DevTools.
4.  **`argumentsPrompt` and `isComplex`:** For longer/parameterizable scripts (especially those involving JS injection), set `isComplex: true` and provide a helpful `argumentsPrompt` in the frontmatter.
5.  **Error Handling in Example Scripts:** Many UI scripting examples won't have robust AppleScript `try...on error` blocks because the failure points are often within the UI interaction itself (e.g., button not found, DevTools not opening). The `notes` should cover common failure reasons.
6.  **Specificity vs. Generality:** While the category is `electron_editors`, some tips might be specific to VS Code's API surface (like `vscode.window`). The `title` or `notes` should clarify this if a tip is highly specific. Many UI scripting parts (like opening Command Palette with `Shift+Cmd+P`) are common across them.
7.  **Thoroughness:** The request was for a "huge list." The AI should aim for comprehensive coverage of common developer actions within these editors. The examples provided by ChatGPT are a great start.

This detailed plan for the `electron_editors` category, combined with the previous specs, will result in an exceptionally capable `macos_automator` server.


-----

Okay, I understand. We will focus *only* on the specification changes to the MCP server's TypeScript code and documentation to support the *new features* (Markdown knowledge base, lazy loading, script referencing by ID, enhanced `get_scripting_tips`, and the refined `execute_script` tool). We will **not** include the content of the `knowledge_base/**/*.md` files themselves in this output.

This `spec2.md` will detail the necessary modifications to the existing server structure.

---

```markdown
# Specification Addition 2 (Revision): Enhanced Knowledge Base System & Script Referencing

This document details enhancements to the `macos_automator` MCP server, focusing on integrating a Markdown-file-based AppleScript Knowledge Base, lazy loading, script referencing by ID, and updates to the `get_scripting_tips` and `execute_script` tools.

**This specification assumes the AI has access to the previous "Specification Addition 2" (which outlined the initial Markdown KB concept and Electron editor examples) and will build upon it.** The actual content of the `.md` knowledge base files is omitted here for brevity and will be provided separately.

## 1. Project Structure Changes

The primary change is the introduction of the `knowledge_base/` directory and a `services/` directory within `src/`.

```
macos-automator-mcp/
├── src/
│   ├── server.ts             # Main MCP server logic, tool definitions
│   ├── ScriptExecutor.ts     # Core logic for calling 'osascript'
│   ├── logger.ts             # Logging utility
│   ├── schemas.ts            # Zod schemas for MCP tool inputs
│   ├── types.ts              # Shared TypeScript types
│   └── services/             # NEW
│       ├── knowledgeBaseService.ts  # Logic to load, parse, and query .md files
│       └── scriptingKnowledge.types.ts # Types specific to parsed knowledge
├── knowledge_base/           # NEW - To be populated with .md files
│   ├── _shared_handlers/     # Contains .applescript or .js reusable handlers
│   ├── basics/
│   ├── browsers_common/
│   ├── calendar/
│   ├── chrome/
│   ├── electron_editors/     # For VS Code, Cursor, Windsurf tips
│   └── (many other category subdirectories...)
├── docs/
├── .gitignore
├── DEVELOPMENT.md
├── LICENSE
├── README.md
├── package.json
├── start.sh
└── tsconfig.json
```

## 2. TypeScript Type Definitions (`src/types.ts` & `src/services/scriptingKnowledge.types.ts`)

**A. `src/types.ts` (No major changes, ensure `ScriptExecutionError` is comprehensive)**

```typescript
// src/types.ts
export type LogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface ScriptExecutionOptions {
  language?: 'applescript' | 'javascript';
  timeoutMs?: number;
  useScriptFriendlyOutput?: boolean;
  arguments?: string[];
}

export interface ScriptExecutionResult {
  stdout: string;
  stderr: string;
}

export interface ScriptExecutionError extends Error {
  stdout?: string;
  stderr?: string;
  exitCode?: number | null; // child_process uses 'code'
  signal?: string | null;
  killed?: boolean; // True if process was terminated (e.g., by timeout)
  isTimeout?: boolean; // Explicit flag for timeout
  originalError?: any; // Store the raw error from child_process or fs access
  name: string; // To classify errors like 'UnsupportedPlatformError', 'ScriptFileAccessError'
}
```

**B. `src/services/scriptingKnowledge.types.ts` (NEW or Updated)**

```typescript
// src/services/scriptingKnowledge.types.ts

// Derived from knowledge_base/ subdirectory names
export type KnowledgeCategory = string;

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
  // Placeholder for future:
  // inputSchema?: any; // Optional Zod schema string or object for 'inputData' if run by ID
  // usesSharedHandlers?: string[]; // Names of handlers from _shared_handlers/
}

export interface SharedHandler {
  name: string; // Filename without extension from _shared_handlers/
  content: string;
  filePath: string;
  language: 'applescript' | 'javascript'; // Determined by file extension
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

// Type for parsed frontmatter from Markdown files
export interface TipFrontmatter {
  id?: string;
  title: string;
  description?: string;
  keywords?: string[];
  notes?: string;
  language?: 'applescript' | 'javascript';
  isComplex?: boolean;
  argumentsPrompt?: string;
  // usesSharedHandlers?: string[];
}

export interface CategoryInfoFrontmatter {
    description: string;
}
```

## 3. Knowledge Base Service (`src/services/knowledgeBaseService.ts`) (NEW or Updated)

This service implements lazy loading and parsing of Markdown tip files.

```typescript
// src/services/knowledgeBaseService.ts
import fs from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter'; // Ensure 'gray-matter' is an npm dependency
import {
  ScriptingTip,
  KnowledgeBaseIndex,
  KnowledgeCategory,
  SharedHandler,
  TipFrontmatter,
  CategoryInfoFrontmatter
} from './scriptingKnowledge.types';
import { Logger } from '../logger';

const logger = new Logger('KnowledgeBaseService');
const KNOWLEDGE_BASE_ROOT_DIR_NAME = 'knowledge_base'; // Relative to project root
const KNOWLEDGE_BASE_DIR = path.resolve(process.cwd(), KNOWLEDGE_BASE_ROOT_DIR_NAME);
const SHARED_HANDLERS_DIR_NAME = '_shared_handlers';

let indexedKnowledgeBase: KnowledgeBaseIndex | null = null;
let isLoadingKnowledgeBase: boolean = false;
let knowledgeBaseLoadPromise: Promise<KnowledgeBaseIndex> | null = null;

function parseMarkdownTipFile(
  fileContent: string,
  filePath: string
): { frontmatter: TipFrontmatter, body: string, script: string | null, determinedLanguage: 'applescript' | 'javascript' } | null {
  try {
    const { data, content: markdownBody } = matter(fileContent);
    const frontmatter = data as TipFrontmatter;

    if (!frontmatter.title) {
      logger.warn('Markdown tip file missing title in frontmatter', { filePath });
      return null;
    }

    let script: string | null = null;
    // Default language from frontmatter, then to 'applescript'
    let determinedLanguage: 'applescript' | 'javascript' = frontmatter.language || 'applescript';

    const asMatch = markdownBody.match(/```applescript\s*\n([\s\S]*?)\n```/i);
    const jsMatch = markdownBody.match(/```javascript\s*\n([\s\S]*?)\n```/i);

    if (asMatch) {
      script = asMatch[1].trim();
      determinedLanguage = 'applescript'; // Code block language identifier overrides frontmatter
    } else if (jsMatch) {
      script = jsMatch[1].trim();
      determinedLanguage = 'javascript'; // Code block language identifier overrides
    }
    // If no script block is found, 'script' remains null. This is acceptable for conceptual tips.

    return { frontmatter, body: markdownBody, script, determinedLanguage };
  } catch (e) {
    logger.error('Failed to parse Markdown tip file', { filePath, error: (e as Error).message });
    return null;
  }
}

async function actualLoadAndIndexKnowledgeBase(): Promise<KnowledgeBaseIndex> {
  logger.info('Starting: Load and index knowledge base from Markdown files...');
  const categories: KnowledgeBaseIndex['categories'] = [];
  const allTips: ScriptingTip[] = [];
  const sharedHandlers: SharedHandler[] = [];
  const encounteredTipIds = new Set<string>();

  try {
    // 1. Load Shared Handlers
    const sharedHandlersPath = path.join(KNOWLEDGE_BASE_DIR, SHARED_HANDLERS_DIR_NAME);
    try {
      const handlerFiles = await fs.readdir(sharedHandlersPath, { withFileTypes: true });
      for (const handlerFile of handlerFiles) {
        if (handlerFile.isFile() && (handlerFile.name.endsWith('.applescript') || handlerFile.name.endsWith('.js'))) {
          const filePath = path.join(sharedHandlersPath, handlerFile.name);
          const content = await fs.readFile(filePath, 'utf-8');
          const handlerName = path.basename(handlerFile.name, path.extname(handlerFile.name));
          const language = handlerFile.name.endsWith('.js') ? 'javascript' : 'applescript';
          sharedHandlers.push({ name: handlerName, content, filePath, language });
          logger.debug('Loaded shared handler', { name: handlerName, language });
        }
      }
    } catch (e: any) {
      if (e.code !== 'ENOENT') { //ENOENT means dir doesn't exist, which is fine
         logger.warn(`Error reading _shared_handlers directory. Skipping.`, { error: e.message });
      } else {
         logger.info('_shared_handlers directory not found. Skipping shared handlers.');
      }
    }

    // 2. Load Tips from Category Directories
    const categoryDirEntries = await fs.readdir(KNOWLEDGE_BASE_DIR, { withFileTypes: true });

    for (const categoryDirEntry of categoryDirEntries) {
      if (categoryDirEntry.isDirectory() && categoryDirEntry.name !== SHARED_HANDLERS_DIR_NAME) {
        const categoryId = categoryDirEntry.name as KnowledgeCategory;
        const categoryPath = path.join(KNOWLEDGE_BASE_DIR, categoryId);
        let tipCount = 0;
        let categoryDescription = `Tips and examples for ${categoryId.replace(/_/g, ' ')}.`;

        // Attempt to load category description from _category_info.md
        try {
            const catInfoPath = path.join(categoryPath, '_category_info.md');
            const catInfoContent = await fs.readFile(catInfoPath, 'utf-8');
            const { data: catFm } = matter(catInfoContent) as { data: CategoryInfoFrontmatter };
            if (catFm?.description) categoryDescription = catFm.description;
        } catch (e) { /* No _category_info.md or error parsing, use default description */ }

        const tipFileEntries = await fs.readdir(categoryPath, { withFileTypes: true });
        for (const tipFileEntry of tipFileEntries) {
          if (tipFileEntry.isFile() && tipFileEntry.name.endsWith('.md') && !tipFileEntry.name.startsWith('_')) {
            const filePath = path.join(categoryPath, tipFileEntry.name);
            const fileContent = await fs.readFile(filePath, 'utf-8');
            const parsedFile = parseMarkdownTipFile(fileContent, filePath);

            if (parsedFile && parsedFile.frontmatter.title) { // Conceptual tips might not have a script block
              const fm = parsedFile.frontmatter;
              // Generate ID: Use frontmatter.id, or derive from category & filename (cleaned)
              const baseName = path.basename(tipFileEntry.name, '.md').replace(/^\d+[_.-]?\s*/, '').replace(/\s+/g, '_');
              const tipId = fm.id || `${categoryId}_${baseName}`;

              if (encounteredTipIds.has(tipId)) {
                  logger.warn('Duplicate Tip ID resolved. Consider making frontmatter IDs unique or renaming files.', { tipId, filePath });
                  // Potentially append a suffix or skip, for now, we allow overwrite if generated IDs collide, but explicit IDs should be unique.
                  // If using explicit fm.id, this check becomes more critical to enforce uniqueness.
              }
              encounteredTipIds.add(tipId);

              // A tip requires a script to be executable by ID. Conceptual tips are for info only.
              if (parsedFile.script) {
                allTips.push({
                  id: tipId,
                  category: categoryId,
                  title: fm.title,
                  description: fm.description,
                  script: parsedFile.script, // Content of the script block
                  language: parsedFile.determinedLanguage,
                  keywords: Array.isArray(fm.keywords) ? fm.keywords.map(String) : (fm.keywords ? [String(fm.keywords)] : []),
                  notes: fm.notes,
                  filePath: filePath,
                  isComplex: fm.isComplex !== undefined ? fm.isComplex : (parsedFile.script.length > 250), // Adjusted threshold
                  argumentsPrompt: fm.argumentsPrompt,
                });
                tipCount++;
              } else {
                 logger.debug("Conceptual tip (no script block)", { title: fm.title, path: filePath });
                 // Could still add it to a separate list if we want to return conceptual tips too
              }
            }
          }
        }
        if (tipCount > 0) { // Only add category if it has scriptable tips
            categories.push({ id: categoryId, description: categoryDescription, tipCount });
        }
      }
    }
    categories.sort((a,b) => a.id.localeCompare(b.id));
    allTips.sort((a,b) => a.id.localeCompare(b.id)); // Sort tips by ID for predictable ordering

    indexedKnowledgeBase = { categories, tips: allTips, sharedHandlers };
    logger.info(`Knowledge base loading complete: ${categories.length} categories, ${allTips.length} scriptable tips, ${sharedHandlers.length} shared handlers.`);

  } catch (error: any) {
    logger.error('Fatal error during knowledge base indexing', { error: error.message, stack: error.stack, path: KNOWLEDGE_BASE_DIR });
    indexedKnowledgeBase = { categories: [], tips: [], sharedHandlers: [] }; // Ensure it's initialized on error
  }
  return indexedKnowledgeBase;
}

export async function getKnowledgeBase(): Promise<KnowledgeBaseIndex> {
    // ... (Lazy loading logic with isLoadingKnowledgeBase and knowledgeBaseLoadPromise - same as previous spec)
    if (indexedKnowledgeBase) {
        return indexedKnowledgeBase;
    }
    if (isLoadingKnowledgeBase && knowledgeBaseLoadPromise) {
        logger.debug('Knowledge base is currently loading, awaiting existing promise.');
        return knowledgeBaseLoadPromise;
    }
    // First actual call or call after a failed load (indexedKnowledgeBase would be empty structure)
    isLoadingKnowledgeBase = true;
    knowledgeBaseLoadPromise = actualLoadAndIndexKnowledgeBase().finally(() => {
        isLoadingKnowledgeBase = false;
    });
    return knowledgeBaseLoadPromise;
}

export async function getScriptingTipsService(
  input: { category?: KnowledgeCategory; searchTerm?: string; listCategories?: boolean }
): Promise<string> {
  // ... (Service logic - same as previous spec, using the lazy-loaded `kb` from `await getKnowledgeBase()`)
  // Ensure output Markdown clearly states tip.id and if it's runnable by ID.
  // Example addition to Markdown output per tip:
  // ${tip.id && tip.isComplex ? `\n**Runnable ID:** \`${tip.id}\` (Use with 'knowledgeBaseScriptId' in 'execute_script' tool. ${tip.argumentsPrompt ? `Inputs needed: ${tip.argumentsPrompt}` : ''})` : ''}
  // Make sure this formatting is applied consistently.
  const kb = await getKnowledgeBase();

  if (input.listCategories || (!input.category && !input.searchTerm)) {
    if (kb.categories.length === 0) return "No tip categories available. Knowledge base might be empty or failed to load.";
    const categoryList = kb.categories
      .map(cat => `- **${cat.id}**: ${cat.description} (${cat.tipCount} tips)`)
      .join('\n');
    return `## Available AppleScript/JXA Tip Categories:\n${categoryList}\n\nUse \`category: "category_name"\` to get specific tips, or \`searchTerm: "keyword"\` to search. Tips with a runnable ID can be executed directly via the \`execute_script\` tool.`;
  }

  let results: { category: KnowledgeCategory; tips: ScriptingTip[] }[] = [];
  const searchTermLower = input.searchTerm?.toLowerCase();

  const tipsToSearch = input.category && kb.categories.find(c => c.id === input.category)
    ? kb.tips.filter(t => t.category === input.category)
    : kb.tips;

  if (searchTermLower) {
      const filteredTips = tipsToSearch.filter(tip =>
          tip.title.toLowerCase().includes(searchTermLower) ||
          tip.id.toLowerCase().includes(searchTermLower) ||
          tip.script.toLowerCase().includes(searchTermLower) || // Searching script content can be slow for large KBs
          tip.description?.toLowerCase().includes(searchTermLower) ||
          tip.keywords?.some(k => k.toLowerCase().includes(searchTermLower))
      );
      const grouped = filteredTips.reduce((acc, tip) => {
          (acc[tip.category] = acc[tip.category] || []).push(tip);
          return acc;
      }, {} as Record<KnowledgeCategory, ScriptingTip[]>);
      for (const catKey in grouped) {
          results.push({ category: catKey as KnowledgeCategory, tips: grouped[catKey].sort((a,b) => a.title.localeCompare(b.title)) });
      }
  } else if (input.category) {
      const tipsForCategory = kb.tips.filter(t => t.category === input.category).sort((a,b) => a.title.localeCompare(b.title));
      if (tipsForCategory.length > 0) {
          results.push({category: input.category, tips: tipsForCategory});
      }
  }

  if (results.length === 0) {
    return `No tips found matching your criteria (Category: ${input.category || 'All Categories'}, SearchTerm: ${input.searchTerm || 'None'}). Try \`listCategories: true\` to see available categories.`;
  }

  return results.sort((a,b) => a.category.localeCompare(b.category)).map(catResult => {
    const categoryTitle = catResult.category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    const categoryHeader = `## Tips: ${categoryTitle}\n`;
    const tipMarkdown = catResult.tips.map(tip => `
### ${tip.title}
${tip.description ? `*${tip.description}*\n` : ''}
\`\`\`${tip.language}
${tip.script.trim()}
\`\`\`
${tip.id ? `**Runnable ID:** \`${tip.id}\`\n` : ''}
${tip.argumentsPrompt ? `**Inputs Needed (if run by ID):** ${tip.argumentsPrompt}\n` : ''}
${tip.keywords && tip.keywords.length > 0 ? `**Keywords:** ${tip.keywords.join(', ')}\n` : ''}
${tip.notes ? `**Note:**\n${tip.notes.split('\n').map(n => `> ${n}`).join('\n')}\n` : ''}
    `).join('\n---\n');
    return categoryHeader + tipMarkdown;
  }).join('\n\n');
}
```

## 4. Zod Schemas (`src/schemas.ts`) (Updates)

The `ExecuteScriptInputSchema` needs to accommodate `knowledgeBaseScriptId` and a way to pass structured arguments (`inputData`) to these knowledge base scripts.

```typescript
// src/schemas.ts
import { z } from 'zod';
import { ScriptingKnowledgeCategoryEnum } from './services/scriptingKnowledge.types'; // Will need to define this enum based on dir names or keep as string

// Define ScriptingKnowledgeCategoryEnum dynamically if possible, or list them
// For now, assuming a placeholder or manual list matching directory names.
// This could be generated at build time from directory names.
const KNOWN_CATEGORIES = [ /* "basics", "finder", ... populate this list */ ] as const;
// If KNOWN_CATEGORIES is empty, Zod will error. Provide at least one or make it z.string().
const DynamicScriptingKnowledgeCategoryEnum = KNOWN_CATEGORIES.length > 0 ? z.enum(KNOWN_CATEGORIES) : z.string();


export const ExecuteScriptInputSchema = z.object({
  scriptContent: z.string().optional()
    .describe("Raw AppleScript/JXA code. Mutually exclusive with scriptPath & knowledgeBaseScriptId."),
  scriptPath: z.string().optional()
    .describe("Absolute POSIX path to a script file. Mutually exclusive with scriptContent & knowledgeBaseScriptId."),
  knowledgeBaseScriptId: z.string().optional()
    .describe("Unique ID of a pre-defined script from the knowledge base. Mutually exclusive with scriptContent & scriptPath. Use 'get_scripting_tips' to find IDs."),
  language: z.enum(['applescript', 'javascript']).optional()
    .describe("Scripting language. Inferred if using knowledgeBaseScriptId. Defaults to 'applescript' if using scriptContent/scriptPath and not specified."),
  arguments: z.array(z.string()).optional().default([])
    .describe("String arguments for scriptPath scripts ('on run argv'). For knowledgeBaseScriptId, used if script is designed for positional string args (see tip's 'argumentsPrompt')."),
  inputData: z.record(z.string(), z.any()).optional() // Values can be string, number, boolean, or simple lists/objects
    .describe("JSON object providing named input data for knowledgeBaseScriptId scripts designed to accept structured input (see tip's 'argumentsPrompt'). Replaces placeholders like --MCP_INPUT:keyName."),
  timeoutSeconds: z.number().int().positive().optional().default(30)
    .describe("Script execution timeout in seconds."),
  useScriptFriendlyOutput: z.boolean().optional().default(false)
    .describe("Use 'osascript -ss' for script-friendly output.")
}).refine(data => {
    const sources = [data.scriptContent, data.scriptPath, data.knowledgeBaseScriptId].filter(s => s !== undefined && s !== null && s !== '');
    return sources.length === 1;
}, {
    message: "Exactly one of 'scriptContent', 'scriptPath', or 'knowledgeBaseScriptId' must be provided and be non-empty.",
    path: ["scriptContent", "scriptPath", "knowledgeBaseScriptId"],
});
export type ExecuteScriptInput = z.infer<typeof ExecuteScriptInputSchema>;


export const GetScriptingTipsInputSchema = z.object({
  category: DynamicScriptingKnowledgeCategoryEnum.optional() // Use dynamically generated or broad string type
    .describe("Specific category of tips. If omitted with no searchTerm, lists all categories."),
  searchTerm: z.string().optional()
    .describe("Keyword to search within tip titles, content, or IDs."),
  listCategories: z.boolean().optional().default(false)
    .describe("If true, returns only the list of available categories and their descriptions. Overrides other parameters.")
});
export type GetScriptingTipsInput = z.infer<typeof GetScriptingTipsInputSchema>;
```
*   **Note on `DynamicScriptingKnowledgeCategoryEnum`:** Generating this Zod enum dynamically from directory names at server startup or build time would be ideal for type safety. If not feasible initially, `z.string()` can be used for `category` with runtime validation against loaded categories.

## 5. Main Server Logic (`src/server.ts`) (Updates to `execute_script` Handler)

The handler for `execute_script` must now:
1.  Prioritize `knowledgeBaseScriptId`.
2.  Fetch the script from `KnowledgeBaseService`.
3.  Perform argument substitution (from `input.arguments` and `input.inputData`) into the fetched script content.
    *   **Substitution Strategy:**
        *   Use clear placeholders in KB scripts:
            *   Positional array args: `--MCP_ARG_1`, `--MCP_ARG_2`, etc. (for `input.arguments`)
            *   Named object args: `--MCP_INPUT:yourKeyName` (for `input.inputData`)
        *   The server must replace these placeholders with values from the input.
        *   Values must be **properly escaped for AppleScript strings** if they are strings. Numbers and booleans can often be inserted directly. Complex objects/arrays for `inputData` would require generating valid AppleScript list/record syntax.
        *   A helper function `escapeForAppleScriptLiteral(value: any): string` will be needed.
    *   Prepend necessary shared handlers if the `ScriptingTip` indicates their use (advanced feature).

```typescript
// src/server.ts (Conceptual changes in execute_script handler)
// ...
import { getKnowledgeBase } from './services/knowledgeBaseService';
import { ScriptExecutor } from './ScriptExecutor'; // Assume ScriptExecutor is correctly defined

function escapeForAppleScriptStringLiteral(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

function valueToAppleScriptLiteral(value: any): string {
    if (typeof value === 'string') {
        return escapeForAppleScriptStringLiteral(value);
    }
    if (typeof value === 'number' || typeof value === 'boolean') {
        return String(value);
    }
    if (Array.isArray(value)) {
        return `{${value.map(v => valueToAppleScriptLiteral(v)).join(", ")}}`;
    }
    if (typeof value === 'object' && value !== null) {
        const recordParts = Object.entries(value).map(([k, v]) => `${k}:${valueToAppleScriptLiteral(v)}`);
        return `{${recordParts.join(", ")}}`;
    }
    return "missing value"; // Or throw error for unsupported types
}


// Inside server.tool('execute_script', ...) handler:
      // ... (input validation using Zod schema) ...
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript' = input.language || 'applescript';
      let finalArgumentsForScriptFile = input.arguments; // Only for scriptPath

      if (input.knowledgeBaseScriptId) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find(t => t.id === input.knowledgeBaseScriptId);

        if (!tip) {
          throw new McpError(ErrorCode.NotFound, `Knowledge base script with ID '${input.knowledgeBaseScriptId}' not found.`);
        }
        if (!tip.script) { // Should not happen if tip parsing is correct
            throw new McpError(ErrorCode.InternalError, `Knowledge base script ID '${input.knowledgeBaseScriptId}' has no script content.`);
        }

        scriptContentToExecute = tip.script;
        languageToUse = tip.language;
        scriptPathToExecute = undefined; // Clear other sources
        finalArgumentsForScriptFile = []; // KB script arguments handled by inputData/substitution

        // Argument/InputData substitution for KB scripts
        if (scriptContentToExecute) { // Ensure scriptContentToExecute is defined
            if (input.inputData) {
              for (const key in input.inputData) {
                const placeholder = new RegExp(`(?:\\$\\{inputData\\.${key}\\}|--MCP_INPUT:${key}\\b)`, 'g');
                scriptContentToExecute = scriptContentToExecute.replace(placeholder, valueToAppleScriptLiteral(input.inputData[key]));
              }
            }
            if (input.arguments && input.arguments.length > 0) {
                for (let i = 0; i < input.arguments.length; i++) {
                    const placeholder = new RegExp(`(?:\\$\\{arguments\\[${i}\\]\\}|--MCP_ARG_${i+1}\\b)`, 'g');
                    scriptContentToExecute = scriptContentToExecute.replace(placeholder, valueToAppleScriptLiteral(input.arguments[i]));
                }
            }
        }
        logger.debug('Executing Knowledge Base script', { id: tip.id, finalLength: scriptContentToExecute?.length });
      } else if (input.scriptPath) {
        // File path existence check is now within ScriptExecutor
      } else if (input.scriptContent) {
        // Content is directly from input
      } else {
        // This state should be caught by Zod refine, but as a safeguard:
        throw new McpError(ErrorCode.InvalidParams, "No script source provided (content, path, or KB ID).");
      }
      
      // Determine final language if not set by KB script
      if (!input.knowledgeBaseScriptId && input.language) {
          languageToUse = input.language;
      } else if (!input.knowledgeBaseScriptId && !input.language) {
          languageToUse = 'applescript'; // Default for raw content/path
      }


      try {
        const result = await scriptExecutor.execute(
          { content: scriptContentToExecute, path: scriptPathToExecute },
          {
            language: languageToUse,
            timeoutMs: input.timeoutSeconds * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput,
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], // Pass OS-level args only for script files
          }
        );
        // ... (success handling: log stderr if any, return stdout)
         if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        return { content: [{ type: 'text', text: result.stdout }] };

      } catch (error: any) {
        // ... (enhanced error handling, including permission hints from previous spec)
        const execError = error as ScriptExecutionError;
        let baseErrorMessage = `Script execution failed. `;
        if (execError.isTimeout) {
             throw new McpError(ErrorCode.Timeout, `Script execution timed out after ${input.timeoutSeconds} seconds.`);
        }
        if (execError.name === "UnsupportedPlatformError") {
            throw new McpError(ErrorCode.NotSupported, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new McpError(ErrorCode.NotFound, execError.message); // Or Forbidden
        }

        baseErrorMessage += execError.stderr?.trim() ? `Details: ${execError.stderr.trim()}` : (execError.message || 'No specific error message from script.');
        
        let finalErrorMessage = baseErrorMessage;
        if (execError.stderr?.includes("Not authorized") || execError.stderr?.includes("access for assistive devices is disabled") || execError.stderr?.match(/errAEEventNotPermitted|errAEAccessDenied|-1743|-10004/i) || (execError.exitCode === 1 && !execError.stderr)) {
            finalErrorMessage = `${baseErrorMessage}\n\nPOSSIBLE PERMISSION ISSUE: Ensure the application running this server (e.g., Terminal, Node) has required permissions in 'System Settings > Privacy & Security > Automation' and 'Accessibility'. See README.md. Target application may also need specific permissions.`;
        }
        throw new McpError(ErrorCode.InternalError, finalErrorMessage);
      }
// ...
```

## 6. Documentation (`README.md` & `DEVELOPMENT.md`)

*   **`README.md`:**
    *   Update `execute_script` tool description to detail `knowledgeBaseScriptId`, `arguments` (for files and KB scripts), and `inputData` parameters. Explain the placeholder conventions (`--MCP_INPUT:key`, `--MCP_ARG_N`).
    *   Update `get_scripting_tips` tool description to mention that some tips are runnable by ID and may have an `argumentsPrompt`.
    *   Emphasize lazy loading means fast startup.
*   **`DEVELOPMENT.md`:**
    *   Explain the `knowledge_base/` directory structure and Markdown file format for contributing new tips.
    *   Detail how to add shared handlers to `_shared_handlers/`.
    *   Mention the use of `gray-matter` for frontmatter.

## 7. AI Implementation Instructions for this Specification

*   **Focus on `knowledgeBaseService.ts`:** Implement robust Markdown parsing (using `gray-matter`), indexing, and lazy loading logic. Ensure unique tip ID generation/enforcement.
*   **`execute_script` Handler:** Implement the logic to prioritize `knowledgeBaseScriptId`, fetch/substitute script content, and determine language. The argument/inputData substitution must correctly escape values for AppleScript.
*   **Schema Updates:** Accurately reflect the new/changed input fields in `schemas.ts`.
*   **Knowledge Base Content Generation (Separate Task):** This spec defines the *system* for the knowledge base. The AI will be tasked *separately* with populating the `.md` files with a vast array of AppleScript/JXA examples covering all specified categories in extreme detail.
*   **Shared Handlers:** Initial implementation can omit automatic shared handler injection for simplicity, requiring KB scripts to be self-contained. This can be added as a follow-up enhancement if complex scripts heavily rely on it. For now, the service should just load them for potential future use or manual inclusion by users.

This revised specification builds a highly sophisticated system for managing and executing AppleScripts, making the `macos_automator` server significantly more powerful, maintainable, and user-friendly for AI agents.
```