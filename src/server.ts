#!/usr/bin/env node
// server.ts - MCP server entrypoint
// NOTE: SDK ESM/CJS hybrid: imports work at runtime, but types are mapped via tsconfig.json "paths". Suppress TS errors for imports.
// TODO: Replace 'unknown' with proper input types if/when SDK types are available.

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import * as sdkTypes from '@modelcontextprotocol/sdk/types.js';
// import { ZodError } from 'zod'; // ZodError is not directly used from here, handled by SDK or refined errors
import { Logger } from './logger.js';
import { ExecuteScriptInputSchema, GetScriptingTipsInputSchema } from './schemas.js';
import { ScriptExecutor } from './ScriptExecutor.js';
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
const IS_RUNNING_FROM_SRC = SCRIPT_PATH_EXECUTED.includes('/src/server.ts') || SCRIPT_PATH_EXECUTED.endsWith('/src/server.ts');
const EXECUTION_MODE_INFO = IS_RUNNING_FROM_SRC ? 'TypeScript source (e.g., via tsx)' : 'Compiled JavaScript (e.g., dist/server.js)';

let hasEmittedFirstCallInfo = false; // Flag for first tool call
const serverInfoMessage = `MacOS Automator MCP v${pkg.version}, started at ${SERVER_START_TIME_ISO}`;

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

// Define raw shapes for tool registration (required by newer SDK versions)
const ExecuteScriptInputShape = {
  script_content: z.string().optional(),
  script_path: z.string().optional(),
  kb_script_id: z.string().optional(),
  language: z.enum(['applescript', 'javascript']).optional(),
  arguments: z.array(z.string()).optional(),
  input_data: z.record(z.any()).optional(),
  timeout_seconds: z.number().optional(),
  use_script_friendly_output: z.boolean().optional(),
  include_executed_script_in_output: z.boolean().optional(),
  include_substitution_logs: z.boolean().optional(),
} as const;

const GetScriptingTipsInputShape = {
  category: z.string().optional(),
  search_term: z.string().optional(),
  list_categories: z.boolean().optional(),
  refresh_database: z.boolean().optional(),
  limit: z.number().int().positive().optional(),
} as const;

async function main() {
  console.log("[Server Startup] Current working directory:", process.cwd());
  // console.log("[Server Startup] Environment:", JSON.stringify(process.env, null, 2)); // Potentially too verbose, log specific vars if needed
  // console.log("[Server Startup] PATH:", process.env.PATH);
  // console.log("[Server Startup] HOME:", process.env.HOME);
  // console.log("[Server Startup] USER:", process.env.USER);

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
    `Automate macOS tasks using AppleScript or JXA (JavaScript for Automation) to control applications like Terminal, Chrome, Safari, Finder, etc.

**1. Script Source (Choose one):**
*   \`kb_script_id\` (string): **Preferred.** Executes a pre-defined script from the knowledge base by its ID. Use \`get_scripting_tips\` to find IDs and inputs. Supports placeholder substitution via \`input_data\` or \`arguments\`. Ex: \`kb_script_id: "safari_get_front_tab_url"\`.
*   \`script_content\` (string): Executes raw AppleScript/JXA code. Good for simple or dynamic scripts. Ex: \`script_content: "tell application \\"Finder\\" to empty trash"\`.
*   \`script_path\` (string): Executes a script from an absolute POSIX path on the server. Ex: \`/Users/user/myscripts/myscript.applescript\`.

**2. Script Inputs (Optional):**
*   \`input_data\` (JSON object): For \`kb_script_id\`, provides named inputs (e.g., \`--MCP_INPUT:keyName\`). Values (string, number, boolean, simple array/object) are auto-converted. Ex: \`input_data: { "folder_name": "New Docs" }\`.
*   \`arguments\` (array of strings): For \`script_path\` (passes to \`on run argv\` / \`run(argv)\`). For \`kb_script_id\`, used for positional args (e.g., \`--MCP_ARG_1\`).

**3. Execution Options (Optional):**
*   \`language\` ('applescript' | 'javascript'): Specify for \`script_content\`/\`script_path\` (default: 'applescript'). Inferred for \`kb_script_id\`.
*   \`timeout_seconds\` (integer, default: 60): Max script runtime.
*   \`use_script_friendly_output\` (boolean, default: false): Use \`osascript -ss\` for structured output.
*   \`include_executed_script_in_output\` (boolean, default: false): Appends executed script/path to output.
*   \`include_substitution_logs\` (boolean, default: false): For \`kb_script_id\`, includes detailed placeholder substitution logs.`,
    ExecuteScriptInputShape,
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let execution_time_seconds: number | undefined;
      let scriptContentToExecute: string | undefined = input.script_content;
      let scriptPathToExecute: string | undefined = input.script_path;
      let languageToUse: 'applescript' | 'javascript';
      let finalArgumentsForScriptFile = input.arguments || [];
      let substitutionLogs: string[] = [];

      logger.debug('execute_script called with input:', input);

      // Construct the main part of the response first
      const mainOutputContent: { type: 'text'; text: string }[] = [];

      if (input.kb_script_id) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find((t: { id: string }) => t.id === input.kb_script_id);

        if (!tip) {
          throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, `Knowledge base script with ID '${input.kb_script_id}' not found.`);
        }
        if (!tip.script) {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Knowledge base script ID '${input.kb_script_id}' has no script content.`);
        }

        languageToUse = tip.language;
        scriptPathToExecute = undefined; 
        finalArgumentsForScriptFile = []; 

        if (tip.script) { // Check if tip.script exists before substitution
            const substitutionResult: SubstitutionResult = substitutePlaceholders({
                scriptContent: tip.script, // Use tip.script directly
                inputData: input.input_data,
                args: input.arguments, // Pass input.arguments which might be undefined
                includeSubstitutionLogs: input.include_substitution_logs || false,
            });

            scriptContentToExecute = substitutionResult.substitutedScript;
            substitutionLogs = substitutionResult.logs;
        }
        logger.info('Executing Knowledge Base script', { id: tip.id, finalLength: scriptContentToExecute?.length });
      } else if (input.script_path || input.script_content) {
        languageToUse = input.language || 'applescript';
        if (input.script_path) {
            logger.debug('Executing script from path', { scriptPath: input.script_path, language: languageToUse });
        } else if (input.script_content) {
            logger.debug('Executing script from content', { language: languageToUse, initialLength: input.script_content.length });
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
            timeoutMs: (input.timeout_seconds || 60) * 1000,
            useScriptFriendlyOutput: input.use_script_friendly_output || false,
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], 
          }
        );
        execution_time_seconds = result.execution_time_seconds;
        
        if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        
        let isError = false;
        const errorPattern = /^\s*error[:\s-]/i;
        if (errorPattern.test(result.stdout)) {
          isError = true;
        }

        if (input.include_substitution_logs && substitutionLogs.length > 0) {
          const logsHeader = "\n--- Substitution Logs ---\n";
          const logsString = substitutionLogs.join('\n');
          // Prepend to main result, not just stdout string if other parts exist
          mainOutputContent.push({ type: 'text', text: `${logsHeader}${logsString}\n\n--- Original STDOUT ---\n${result.stdout}` });
        }

        mainOutputContent.push({ type: 'text', text: result.stdout });

        if (input.include_executed_script_in_output) {
          let scriptIdentifier = "Script source not determined (should not happen).";
          if (scriptContentToExecute) {
            scriptIdentifier = `\n--- Executed Script Content ---\n${scriptContentToExecute}`;
          } else if (scriptPathToExecute) {
            scriptIdentifier = `\n--- Executed Script Path ---\n${scriptPathToExecute}`;
          }
          mainOutputContent.push({ type: 'text', text: scriptIdentifier });
        }

        // Now, construct the final response with potential first-call info
        const finalResponseContent: { type: 'text'; text: string }[] = [];
        if (!hasEmittedFirstCallInfo) {
          finalResponseContent.push({ type: 'text', text: serverInfoMessage });
          finalResponseContent.push({ type: 'text', text: '---' }); // Separator
          hasEmittedFirstCallInfo = true;
        }
        finalResponseContent.push(...mainOutputContent); // Add the actual script output

        return {
          content: finalResponseContent,
          isError,
          timings: { execution_time_seconds }
        };

      } catch (error: unknown) {
        const execError = error as ScriptExecutionError;
        execution_time_seconds = execError.execution_time_seconds;

        let baseErrorMessage = 'Script execution failed. ';
        
        if (execError.name === "UnsupportedPlatformError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
        }
        if (execError.isTimeout) {
             throw new sdkTypes.McpError(sdkTypes.ErrorCode.RequestTimeout, `Script execution timed out after ${input.timeout_seconds || 60} seconds.`);
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

        if (input.include_substitution_logs && substitutionLogs.length > 0) {
            finalErrorMessage += `\n\n--- Substitution Logs ---\n${substitutionLogs.join('\n')}`;
        }

        logger.error('execute_script handler error', { execution_time_seconds });

        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, finalErrorMessage);
      }
    }
  );

  // ADD THE NEW TOOL get_scripting_tips HERE
  server.tool(
    'get_scripting_tips',
    `Discover how to automate any app on your Mac with this comprehensive knowledge base of AppleScript/JXA tips and runnable scripts. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions, effectively teaching you how to control virtually any aspect of your macOS experience.

**Primary Use Cases & Parameters:**

*   **Discovering Solutions (Use \`search_term\`):**
    *   Parameter: \`search_term\` (string, optional).
    *   Functionality: Performs a fuzzy search across all tip titles, descriptions, keywords, script content, and IDs. Ideal for natural language queries like "how to..." (e.g., \`search_term: "how do I get the current Safari URL and title?"\`). This is the most common way to find relevant tips.
    *   Output: Returns a list of matching tips in Markdown format.

*   **Limiting Search Results (Use \`limit\`):**
    *   Parameter: \`limit\` (integer, optional, default: 10).
    *   Functionality: Specifies the maximum number of script tips to return when using \`search_term\` or browsing a specific \`category\` (without \`list_categories: true\`). Does not apply if \`list_categories\` is true. If more tips are found than the limit, a notice will indicate this.
    *   Output: The list of tips will be truncated to this number if applicable.

*   **Listing All Categories (Use \`list_categories\`):**
    *   Parameter: \`list_categories\` (boolean, optional, default: false).
    *   Functionality: If \`true\`, this will return a list of all available script categories (e.g., "safari", "finder_operations", "system_interaction") along with their descriptions and the number of tips in each. This overrides other parameters, including \`limit\`.
    *   Output: A Markdown list of categories.

*   **Browsing a Specific Category (Use \`category\`):**
    *   Parameter: \`category\` (string, optional).
    *   Functionality: Retrieves all tips belonging to the specified category ID. Useful if you know the general area of automation you're interested in. Results can be limited by the \`limit\` parameter.
    *   Output: All tips within that category, formatted in Markdown (potentially limited).

*   **Forcing a Knowledge Base Reload (Use \`refresh_database\`):**
    *   Parameter: \`refresh_database\` (boolean, optional, default: false).
    *   Functionality: If \`true\`, forces the server to reload the entire knowledge base from disk before processing the request. Primarily useful during development if knowledge base files are being actively modified and you need to ensure the latest versions are reflected without a server restart.

**Output Details:**
The tool returns a single Markdown formatted string. Each tip in the output typically includes:
- Title: A human-readable title for the tip.
- Description: A brief explanation of what the script does.
- Language: \`applescript\` or \`javascript\`.
- Script: The actual code snippet.
- Runnable ID: A unique identifier (e.g., \`safari_get_front_tab_url\`). **This ID is critical as it can be directly used as the \`kbScriptId\` parameter in the \`execute_script\` tool for immediate execution.**
- Arguments Prompt: If the script is designed to take inputs when run by ID, this field describes what \`arguments\` or \`inputData\` are expected by \`execute_script\`.
- Keywords: Relevant search terms.
- Notes: Additional context or important considerations.

**Workflow Example:**
1. User asks: "How do I create a new note in the Notes app with a specific title?"
2. Agent calls \`get_scripting_tips\` with \`search_term: "create new note in Notes app with title"\`.
3. Agent reviews the output. If a tip like \`notes_create_new_note_with_title\` with a \`Runnable ID\` and an \`argumentsPrompt\` for \`noteTitle\` and \`noteBody\` is found:
4. Agent then calls \`execute_script\` with \`kb_script_id: "notes_create_new_note_with_title"\` and appropriate \`input_data\`.`,
    GetScriptingTipsInputShape,
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      logger.info('get_scripting_tips tool called', input);
      try {
        const serverInfoForService = { startTime: SERVER_START_TIME_ISO, mode: EXECUTION_MODE_INFO, version: pkg.version };
        const tipsMarkdown = await getScriptingTipsService(input, serverInfoForService);

        const finalResponseContent: { type: 'text'; text: string }[] = [];
        if (!hasEmittedFirstCallInfo) {
          finalResponseContent.push({ type: 'text', text: serverInfoMessage });
          finalResponseContent.push({ type: 'text', text: '---' }); // Separator
          hasEmittedFirstCallInfo = true;
        }
        finalResponseContent.push({ type: 'text', text: tipsMarkdown });

        return { content: finalResponseContent } as const;
      } catch (e: unknown) {
        const error = e as Error;
        logger.error('Error in get_scripting_tips tool handler', { message: error.message });
        throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Failed to retrieve scripting tips: ${error.message}`);
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