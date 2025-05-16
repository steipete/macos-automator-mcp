#!/usr/bin/env node
// server.ts - MCP server entrypoint
// NOTE: SDK ESM/CJS hybrid: imports work at runtime, but types are mapped via tsconfig.json "paths". Suppress TS errors for imports.
// TODO: Replace 'unknown' with proper input types if/when SDK types are available.

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as sdkTypes from '@modelcontextprotocol/sdk/types.js';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger.js';
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema, AXQueryInputSchema } from './schemas.js';
import { ScriptExecutor } from './ScriptExecutor.js';
import { AXQueryExecutor } from './AXQueryExecutor.js';
import type { ScriptExecutionError }  from './types.js';
// import pkg from '../package.json' with { type: 'json' }; // Import package.json // REMOVED
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { substitutePlaceholders } from './placeholderSubstitutor.js'; // Value import
import type { SubstitutionResult } from './placeholderSubstitutor.js'; // Type import
import { z } from 'zod';

// Added imports for robust package.json loading
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { realpathSync } from 'node:fs';

// Robustly load package.json
const __filenameServer = fileURLToPath(import.meta.url);
const packageRootServer = path.resolve(path.dirname(__filenameServer), '..'); // from dist/server.js to package root
const packageJsonPathServer = path.join(packageRootServer, 'package.json');
let pkg: { version: string }; // Define type for pkg
try {
  pkg = JSON.parse(await fs.readFile(packageJsonPathServer, 'utf-8'));
} catch (error) {
  // Fallback or error handling if package.json cannot be read
  // This is critical for npx environments if pathing is an issue
  console.error("Failed to load package.json:", error);
  pkg = { version: "0.0.0-error" }; // Provide a fallback
}

const SERVER_START_TIME_ISO = new Date().toISOString();
const SCRIPT_PATH_EXECUTED = process.argv[1] || 'unknown_path';
const IS_RUNNING_FROM_SRC = SCRIPT_PATH_EXECUTED.includes('/src/server.ts') || SCRIPT_PATH_EXECUTED.endsWith('src/server.ts');
const EXECUTION_MODE_INFO = IS_RUNNING_FROM_SRC ? 'TypeScript source (e.g., via tsx)' : 'Compiled JavaScript (e.g., dist/server.js)';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();
const axQueryExecutor = new AXQueryExecutor();

// Define raw shapes for tool registration (required by newer SDK versions)
const ExecuteScriptInputShape = {
  scriptContent: z.string().optional(),
  scriptPath: z.string().optional(),
  kbScriptId: z.string().optional(),
  language: z.enum(['applescript', 'javascript']).optional(),
  arguments: z.array(z.string()).optional(),
  inputData: z.record(z.any()).optional(),
  timeoutSeconds: z.number().optional(),
  useScriptFriendlyOutput: z.boolean().optional(),
  includeExecutedScriptInOutput: z.boolean().optional(),
  includeSubstitutionLogs: z.boolean().optional(),
} as const;

const GetScriptingTipsInputShape = {
  category: z.string().optional(),
  searchTerm: z.string().optional(),
  listCategories: z.boolean().optional(),
  refreshDatabase: z.boolean().optional(),
  limit: z.number().int().positive().optional(),
} as const;

const AXQueryInputShape = {
  cmd: z.enum(['query', 'perform']),
  multi: z.boolean().optional(),
  locator: z.object({
      app: z.string(),
      role: z.string(),
      match: z.record(z.string()),
      pathHint: z.array(z.string()).optional(),
  }),
  attributes: z.array(z.string()).optional(),
  requireAction: z.string().optional(),
  action: z.string().optional(),
} as const;

async function main() {
  logger.info('Starting macos_automator MCP Server...');
  logger.warn("CRITICAL: Ensure macOS Automation & Accessibility permissions are correctly configured for the application running this server (e.g., Terminal, Node). See README.md for details.");

  // Eagerly initialize Knowledge Base if KB_PARSING is set to eager
  const eagerParseEnv = process.env.KB_PARSING?.toLowerCase();
  if (eagerParseEnv === 'eager') {
    await conditionallyInitializeKnowledgeBase(true);
  } else {
    conditionallyInitializeKnowledgeBase(false); // Log that it's lazy
  }

  const server = new McpServer({
    name: 'macos_automator', // Matches the key in mcp.json
    version: pkg.version, // Dynamically use version from package.json
    onLog: (level: "DEBUG" | "INFO" | "WARN" | "ERROR", message: string, data?: Record<string, unknown>) => {
      logger[level.toLowerCase() as 'debug' | 'info' | 'warn' | 'error']?.(`[MCP_SDK] ${message}`, data);
    }
  });

  server.tool(
    'execute_script',
    'Unlock the full potential of your Mac by automating virtually any application or task with AppleScript or JavaScript for Automation (JXA). This is your primary tool to command macOS, from simple actions to complex cross-application workflows.\\n\\nWhether it\'s controlling **Terminal, Google Chrome, Safari, Firefox, Finder, System Settings,** or any other scriptable application on your Mac, this tool gives you the power. If an app is on your Mac, chances are you can automate it.\\n\\n**1. Script Source (Exactly one of these MUST be provided):**\\n\\n*   `kbScriptId` (string):\\n    *   **Highly Preferred Method.** Executes a pre-defined, tested script from the server\'s knowledge base using its unique ID.\\n    *   **Discovery:** Use the `get_scripting_tips` tool to find available scripts, their `Runnable ID`s (which become this `kbScriptId`), and any required inputs (see `argumentsPrompt` from `get_scripting_tips`).\\n    *   Example: `kbScriptId: "safari_get_front_tab_url"`.\\n    *   Placeholder Substitution: Scripts from the knowledge base can contain placeholders like `--MCP_INPUT:keyName` or `--MCP_ARG_N` which will be substituted using the `inputData` or `arguments` parameters respectively.\\n\\n*   `scriptContent` (string):\\n    *   Executes raw AppleScript or JXA code provided directly as a string.\\n    *   Useful for simple, one-off commands or dynamically generated scripts.\\n    *   Example: `scriptContent: "tell application \\"Finder\\" to empty trash"`.\\n    *   Example: Use Terminal to open a web browser in the background: `scriptContent: "do shell script \\"open -g -a Safari https://www.google.com\\""`. (Note: `-g` opens it in the background, replace Safari with your desired browser if needed).\\n\\n*   `scriptPath` (string):\\n    *   Executes a script from a local file on the server machine.\\n    *   The path MUST be an absolute POSIX path to the script file (e.g., `/Users/user/myscripts/myscript.applescript`).\\n    *   Useful for complex or proprietary scripts not in the knowledge base.\\n\\n**2. Providing Inputs to Scripts:**\\n\\n*   `inputData` (JSON object, optional):\\n    *   **Primarily for `kbScriptId` scripts.**\\n    *   Used to provide named inputs that replace `--MCP_INPUT:keyName` placeholders within the knowledge base script.\\n    *   The keys in the object should match the `keyName` in the placeholders. Values (strings, numbers, booleans, simple arrays/objects) are automatically converted to their AppleScript/JXA literal equivalents.\\n    *   Example: `inputData: { "folderName": "New Docs", "targetPath": "~/Desktop" }` for a script with `--MCP_INPUT:folderName` and `--MCP_INPUT:targetPath`.\\n\\n*   `arguments` (array of strings, optional):\\n    *   For `scriptPath`: Passed as an array of string arguments to the script\'s main handler (e.g., `on run argv` in AppleScript, `run(argv)` in JXA).\\n    *   For `kbScriptId`: Used if a script is specifically designed for positional string arguments (replaces `--MCP_ARG_1`, `--MCP_ARG_2`, etc.). Check the script\'s `argumentsPrompt` from `get_scripting_tips`. Less common for KB scripts than `inputData`.\\n\\n**3. Execution Options:**\\n\\n*   `language` (enum: \'applescript\' | \'javascript\', optional):\\n    *   Specifies the scripting language.\\n    *   **Crucial for `scriptContent` and `scriptPath`** if not `applescript`. Defaults to \'applescript\' if omitted for these sources.\\n    *   Automatically inferred from the metadata if using `kbScriptId`.\\n\\n*   `timeoutSeconds` (integer, optional, default: 30):\\n    *   Sets the maximum time (in seconds) the script is allowed to run before being terminated. Increase for potentially long-running operations.\\n\\n*   `useScriptFriendlyOutput` (boolean, optional, default: false):\\n    *   If `true`, uses `osascript -ss` flag. This can provide more structured output (e.g., proper lists/records) from AppleScript, which might be easier for a program to parse than the default human-readable format.\\n\\n*   `includeExecutedScriptInOutput` (boolean, optional, default: false):\\n    *   If `true`, the full script content (after placeholder substitutions for knowledge base scripts) or the `scriptPath` will be appended to the successful output. Useful for verification and debugging.\\n\\n*   `includeSubstitutionLogs` (boolean, optional, default: false):\\n    *   **Only applies to `kbScriptId` scripts.**\\n    *   If `true`, detailed logs of each placeholder substitution step performed on the knowledge base script are included in the output (prepended on success, appended on error). Extremely useful for debugging issues with `inputData`/`arguments` processing and how they are inserted into the script.\\n\\n**Security Note:** Exercise caution, as this tool executes arbitrary code on the macOS machine. Ensure any user-provided script content or files are from trusted sources. macOS permissions (Automation, Accessibility) must be correctly configured for the server process.',
    ExecuteScriptInputShape,
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript';
      let finalArgumentsForScriptFile = input.arguments || [];
      let substitutionLogs: string[] = []; // Changed from const to let

      logger.debug('execute_script called with input:', input);

      if (input.kbScriptId) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find((t: { id: string }) => t.id === input.kbScriptId);

        if (!tip) {
          throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, `Knowledge base script with ID '${input.kbScriptId}' not found.`);
        }
        if (!tip.script) {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Knowledge base script ID '${input.kbScriptId}' has no script content.`);
        }

        languageToUse = tip.language;
        scriptPathToExecute = undefined; 
        finalArgumentsForScriptFile = []; 

        if (tip.script) { // Check if tip.script exists before substitution
            const substitutionResult: SubstitutionResult = substitutePlaceholders({
                scriptContent: tip.script, // Use tip.script directly
                inputData: input.inputData,
                args: input.arguments, // Pass input.arguments which might be undefined
                includeSubstitutionLogs: input.includeSubstitutionLogs || false,
            });

            scriptContentToExecute = substitutionResult.substitutedScript;
            substitutionLogs = substitutionResult.logs;
        }
        logger.info('Executing Knowledge Base script', { id: tip.id, finalLength: scriptContentToExecute?.length });
      } else if (input.scriptPath || input.scriptContent) {
        languageToUse = input.language || 'applescript';
        if (input.scriptPath) {
            logger.debug('Executing script from path', { scriptPath: input.scriptPath, language: languageToUse });
        } else if (input.scriptContent) {
            logger.debug('Executing script from content', { language: languageToUse, initialLength: input.scriptContent.length });
        }
      } else {
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, "No script source provided (content, path, or KB ID).");
      }
      
      // Log the actual script to be executed (especially useful for KB scripts after substitution)
      if (scriptContentToExecute) {
        logger.debug('Final script content to be executed:', { language: languageToUse, script: scriptContentToExecute });
      } else if (scriptPathToExecute) {
        // For scriptPath, we don't log content here, just that it's a path-based execution
        logger.debug('Executing script via path (content not logged here):', { scriptPath: scriptPathToExecute, language: languageToUse });
      }

      try {
        const result = await scriptExecutor.execute(
          { content: scriptContentToExecute, path: scriptPathToExecute },
          {
            language: languageToUse,
            timeoutMs: (input.timeoutSeconds || 30) * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput || false,
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], 
          }
        );
        
        if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        
        const outputContent: { type: 'text'; text: string }[] = [];

        if (input.includeSubstitutionLogs && substitutionLogs.length > 0) {
          const logsHeader = "\n--- Substitution Logs ---\n";
          const logsString = substitutionLogs.join('\n');
          result.stdout = `${logsHeader}${logsString}\n\n--- Original STDOUT ---\n${result.stdout}`;
        }
        
        outputContent.push({ type: 'text', text: result.stdout });

        if (input.includeExecutedScriptInOutput) {
          let scriptIdentifier = "Script source not determined (should not happen).";
          if (scriptContentToExecute) {
            scriptIdentifier = `\n--- Executed Script Content ---\n${scriptContentToExecute}`;
          } else if (scriptPathToExecute) {
            scriptIdentifier = `\n--- Executed Script Path ---\n${scriptPathToExecute}`;
          }
          outputContent.push({ type: 'text', text: scriptIdentifier });
        }
        return { content: outputContent };

      } catch (error: unknown) {
        const execError = error as ScriptExecutionError;
        let baseErrorMessage = 'Script execution failed. ';
        
        if (execError.name === "UnsupportedPlatformError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
        }
        if (execError.isTimeout) {
             throw new sdkTypes.McpError(sdkTypes.ErrorCode.RequestTimeout, `Script execution timed out after ${input.timeoutSeconds || 30} seconds.`);
        }

        baseErrorMessage += execError.stderr?.trim() ? `Details: ${execError.stderr.trim()}` : (execError.message || 'No specific error message from script.');
        
        let finalErrorMessage = baseErrorMessage;
        const permissionErrorPattern = /Not authorized|access for assistive devices is disabled|errAEEventNotPermitted|errAEAccessDenied|-1743|-10004/i;
        const likelyPermissionError = execError.stderr && permissionErrorPattern.test(execError.stderr);
        // Sometimes exit code 1 with no stderr can also be a silent permission issue
        const possibleSilentPermissionError = execError.exitCode === 1 && !execError.stderr?.trim(); 

        if (likelyPermissionError || possibleSilentPermissionError) {
            finalErrorMessage = `${baseErrorMessage}\n\nPOSSIBLE PERMISSION ISSUE: Ensure the application running this server (e.g., Terminal, Node) has required permissions in 'System Settings > Privacy & Security > Automation' and 'Accessibility'. See README.md. The target application for the script may also need specific permissions.`;
        }

        // Append the attempted script to the error message
        let scriptIdentifierForError = "Script source not determined (should not happen).";
        if (scriptContentToExecute) {
          scriptIdentifierForError = `\n\n--- Script Attempted (Content) ---\n${scriptContentToExecute}`;
        } else if (scriptPathToExecute) {
          scriptIdentifierForError = `\n\n--- Script Attempted (Path) ---\n${scriptPathToExecute}`;
        }
        finalErrorMessage += scriptIdentifierForError;

        if (input.includeSubstitutionLogs && substitutionLogs.length > 0) {
            finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join('\n')}`;
        }

        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, finalErrorMessage);
      }
    }
  );

  // ADD THE NEW TOOL get_scripting_tips HERE
  server.tool(
    'get_scripting_tips',
    'Discover how to automate any app on your Mac with this comprehensive knowledge base of AppleScript/JXA tips and runnable scripts. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions, effectively teaching you how to control virtually any aspect of your macOS experience.\\n\\n**Primary Use Cases & Parameters:**\\n\\n*   **Discovering Solutions (Use `searchTerm`):**\\n    *   Parameter: `searchTerm` (string, optional).\\n    *   Functionality: Performs a fuzzy search across all tip titles, descriptions, keywords, script content, and IDs. Ideal for natural language queries like "how to..." (e.g., `searchTerm: "how do I get the current Safari URL and title?"`) or keyword-based searches (e.g., `searchTerm: "Finder copy file to new location"`). This is the most common way to find relevant tips.\\n    *   Output: Returns a list of matching tips in Markdown format.\\n\\n*   **Limiting Search Results (Use `limit`):**\\n    *   Parameter: `limit` (integer, optional, default: 10).\\n    *   Functionality: Specifies the maximum number of script tips to return when using `searchTerm` or browsing a specific `category` (without `listCategories: true`). Does not apply if `listCategories` is true. If more tips are found than the limit, a notice will indicate this.\\n    *   Output: The list of tips will be truncated to this number if applicable.\\n\\n*   **Listing All Categories (Use `listCategories`):**\\n    *   Parameter: `listCategories` (boolean, optional, default: false).\\n    *   Functionality: If `true`, this will return a list of all available script categories (e.g., "safari", "finder_operations", "system_interaction") along with their descriptions and the number of tips in each. This overrides other parameters, including `limit`.\\n    *   Output: A Markdown list of categories.\\n\\n*   **Browsing a Specific Category (Use `category`):**\\n    *   Parameter: `category` (string, optional).\\n    *   Functionality: Retrieves all tips belonging to the specified category ID. Useful if you know the general area of automation you\'re interested in. Results can be limited by the `limit` parameter.\\n    *   Output: All tips within that category, formatted in Markdown (potentially limited).\\n\\n*   **Forcing a Knowledge Base Reload (Use `refreshDatabase`):**\\n    *   Parameter: `refreshDatabase` (boolean, optional, default: false).\\n    *   Functionality: If `true`, forces the server to reload the entire knowledge base from disk before processing the request. Primarily useful during development if knowledge base files are being actively modified and you need to ensure the latest versions are reflected without a server restart.\\n\\n**Output Details:**\\nThe tool returns a single Markdown formatted string. Each tip in the output typically includes:\\n- Title: A human-readable title for the tip.\\n- Description: A brief explanation of what the script does.\\n- Language: `applescript` or `javascript`.\\n- Script: The actual code snippet.\\n- Runnable ID: A unique identifier (e.g., `safari_get_front_tab_url`). **This ID is critical as it can be directly used as the `kbScriptId` parameter in the `execute_script` tool for immediate execution.**\\n- Arguments Prompt: If the script is designed to take inputs when run by ID, this field describes what `arguments` or `inputData` are expected by `execute_script`.\\n- Keywords: Relevant search terms.\\n- Notes: Additional context or important considerations.\\n\\n**Workflow Example:**\\n1. User asks: "How do I create a new note in the Notes app with a specific title?"\\n2. Agent calls `get_scripting_tips` with `searchTerm: "create new note in Notes app with title"`.\\n3. Agent reviews the output. If a tip like `notes_create_new_note_with_title` with a `Runnable ID` and an `argumentsPrompt` for `noteTitle` and `noteBody` is found:\\n4. Agent then calls `execute_script` with `kbScriptId: "notes_create_new_note_with_title"` and appropriate `inputData`.',
    GetScriptingTipsInputShape,
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      logger.info('get_scripting_tips tool called', input);
      try {
        const serverInfo = { startTime: SERVER_START_TIME_ISO, mode: EXECUTION_MODE_INFO, version: pkg.version };
        const tipsMarkdown = await getScriptingTipsService(input, serverInfo);
        return { content: [{ type: 'text', text: tipsMarkdown }] } as const;
      } catch (e: unknown) {
        const error = e as Error;
        logger.error('Error in get_scripting_tips tool handler', { message: error.message });
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Failed to retrieve scripting tips: ${error.message}`);
      }
    }
  );

  // ADD THE NEW accessibility_query TOOL HERE
  server.tool(
    'accessibility_query',
    'Query and interact with the macOS accessibility interface to inspect UI elements of applications. This tool provides a powerful way to explore and manipulate the user interface elements of any application using the native macOS accessibility framework.\\n\\nThis tool exposes the complete macOS accessibility API capabilities, allowing detailed inspection of UI elements and their properties. It\'s particularly useful for automating interactions with applications that don\'t have robust AppleScript support or when you need to inspect the UI structure in detail.\\n\\n**Input Parameters:**\\n\\n* `cmd` (enum: \'query\' | \'perform\', required): The operation to perform.\\n  * `query`: Retrieves information about UI elements.\\n  * `perform`: Executes an action on a UI element (like clicking a button).\\n\\n* `locator` (object, required): Specifications to find the target element(s).\\n  * `app` (string, required): The application to target, specified by either bundle ID or display name (e.g., "Safari", "com.apple.Safari").\\n  * `role` (string, required): The accessibility role of the target element (e.g., "AXButton", "AXStaticText").\\n  * `match` (object, required): Key-value pairs of attributes to match. Can be empty ({}) if not needed.\\n  * `pathHint` (array of strings, optional): Path to navigate within the application hierarchy (e.g., ["window[1]", "toolbar[1]"]).\\n\\n* `multi` (boolean, optional): When `true`, returns all matching elements rather than just the first match. Default is `false`.\\n\\n* `attributes` (array of strings, optional): Specific attributes to query for matched elements. If not provided, common attributes will be included. Examples: ["AXRole", "AXTitle", "AXValue"]\\n\\n* `requireAction` (string, optional): Filter elements to only those supporting a specific action (e.g., "AXPress" for clickable elements).\\n\\n* `action` (string, optional, required when cmd="perform"): The accessibility action to perform on the matched element (e.g., "AXPress" to click a button).\\n\\n**Example Queries:**\\n\\n1. Find all text elements in the front Safari window:\\n```json\\n{\\n  "cmd": "query",\\n  "multi": true,\\n  "locator": {\\n    "app": "Safari",\\n    "role": "AXStaticText",\\n    "match": {},\\n    "pathHint": ["window[1]"]\\n  }\\n}\\n```\\n\\n2. Find and click a button with a specific title:\\n```json\\n{\\n  "cmd": "perform",\\n  "locator": {\\n    "app": "System Settings",\\n    "role": "AXButton",\\n    "match": {"AXTitle": "General"}\\n  },\\n  "action": "AXPress"\\n}\\n```\\n\\n3. Get detailed information about the focused UI element:\\n```json\\n{\\n  "cmd": "query",\\n  "locator": {\\n    "app": "Mail",\\n    "role": "AXTextField",\\n    "match": {"AXFocused": "true"}\\n  },\\n  "attributes": ["AXRole", "AXTitle", "AXValue", "AXDescription", "AXHelp", "AXPosition", "AXSize"]\\n}\\n```\\n\\n**Note:** Using this tool requires that the application running this server has the necessary Accessibility permissions in macOS System Settings > Privacy & Security > Accessibility.',
    AXQueryInputShape,
    async (args: unknown) => {
      try {
        const input = AXQueryInputSchema.parse(args);
        logger.info('accessibility_query called with input:', input);
        
        const result = await axQueryExecutor.execute(input);
        
        // For cleaner output, especially for multi-element queries, format the response
        let formattedOutput: string;
        
        if (input.cmd === 'query' && input.multi === true) {
          // For multi-element queries, format the results more readably
          if ('elements' in result) {
            formattedOutput = JSON.stringify(result, null, 2);
          } else {
            formattedOutput = JSON.stringify(result, null, 2);
          }
        } else {
          // For single element queries or perform actions
          formattedOutput = JSON.stringify(result, null, 2);
        }
        
        return { content: [{ type: 'text', text: formattedOutput }] };
      } catch (error: unknown) {
        const err = error as Error;
        logger.error('Error in accessibility_query tool handler', { message: err.message });
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Failed to execute accessibility query: ${err.message}`);
      }
    }
  );

  const transport = new StdioServerTransport();
  try {
    await server.connect(transport);
    logger.info(`macos_automator MCP Server v${pkg.version} connected via STDIO and ready.`);
  } catch (error: unknown) { // Changed from any to unknown
    const connectError = error as Error;
    logger.error('Failed to connect server to transport', { message: connectError.message, stack: connectError.stack });
    process.exit(1);
  }
}

// Graceful shutdown
const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM', 'SIGQUIT'];
for (const signal of signals) {
  process.on(signal, () => {
    logger.info(`Received ${signal}, shutting down server...`);
    // Perform any cleanup if necessary
    process.exit(0);
  });
}

// Global error handlers
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', { message: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', { promise, reason: reason instanceof Error ? reason.message : reason });
  process.exit(1);
});

// Execute main() if this module is the entry point, even when invoked via a symlinked CLI script
try {
  const executedPath = realpathSync(process.argv[1] || '');
  const modulePath = realpathSync(fileURLToPath(import.meta.url));
  if (executedPath === modulePath) {
    await main();
  }
} catch (error) {
  const mainError = error as Error;
  logger.error("Fatal error during server startup:", { message: mainError.message, stack: mainError.stack });
  process.exit(1);
} 