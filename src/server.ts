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
const IS_RUNNING_FROM_SRC = SCRIPT_PATH_EXECUTED.includes('/src/server.ts') || SCRIPT_PATH_EXECUTED.endsWith('src/server.ts');
const EXECUTION_MODE_INFO = IS_RUNNING_FROM_SRC ? 'TypeScript source (e.g., via tsx)' : 'Compiled JavaScript (e.g., dist/server.js)';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

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
*   \`kbScriptId\` (string): **Preferred.** Executes a pre-defined script from the knowledge base by its ID. Use \`get_scripting_tips\` to find IDs and inputs. Supports placeholder substitution via \`inputData\` or \`arguments\`. Ex: \`kbScriptId: "safari_get_front_tab_url"\`.
*   \`scriptContent\` (string): Executes raw AppleScript/JXA code. Good for simple or dynamic scripts. Ex: \`scriptContent: "tell application \\"Finder\\" to empty trash"\`.
*   \`scriptPath\` (string): Executes a script from an absolute POSIX path on the server. Ex: \`/Users/user/myscripts/myscript.applescript\`.

**2. Script Inputs (Optional):**
*   \`inputData\` (JSON object): For \`kbScriptId\`, provides named inputs (e.g., \`--MCP_INPUT:keyName\`). Values (string, number, boolean, simple array/object) are auto-converted. Ex: \`inputData: { "folderName": "New Docs" }\`.
*   \`arguments\` (array of strings): For \`scriptPath\` (passes to \`on run argv\` / \`run(argv)\`). For \`kbScriptId\`, used for positional args (e.g., \`--MCP_ARG_1\`).

**3. Execution Options (Optional):**
*   \`language\` ('applescript' | 'javascript'): Specify for \`scriptContent\`/\`scriptPath\` (default: 'applescript'). Inferred for \`kbScriptId\`.
*   \`timeoutSeconds\` (integer, default: 60): Max script runtime.
*   \`useScriptFriendlyOutput\` (boolean, default: false): Use \`osascript -ss\` for structured output.
*   \`includeExecutedScriptInOutput\` (boolean, default: false): Appends executed script/path to output.
*   \`includeSubstitutionLogs\` (boolean, default: false): For \`kbScriptId\`, includes detailed placeholder substitution logs.`,
    ExecuteScriptInputShape,
    async (args: unknown) => {
      let execution_time_seconds: number | undefined;

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
            timeoutMs: (input.timeoutSeconds || 60) * 1000,
            useScriptFriendlyOutput: input.useScriptFriendlyOutput || false,
            arguments: scriptPathToExecute ? finalArgumentsForScriptFile : [], 
          }
        );
        execution_time_seconds = result.execution_time_seconds; // Capture script execution duration
        
        if (result.stderr) {
           logger.warn('Script execution produced stderr (even on success)', { stderr: result.stderr });
        }
        
        // Check for error pattern in stdout and set isError accordingly
        let isError = false;
        const errorPattern = /^\s*error[:\s-]/i;
        if (errorPattern.test(result.stdout)) {
          isError = true;
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
        return {
          content: outputContent,
          isError,
          timings: { execution_time_seconds }
        };

      } catch (error: unknown) {
        const execError = error as ScriptExecutionError;
        execution_time_seconds = execError.execution_time_seconds; // Capture script duration if available from the error

        let baseErrorMessage = 'Script execution failed. ';
        
        if (execError.name === "UnsupportedPlatformError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidRequest, execError.message);
        }
        if (execError.name === "ScriptFileAccessError") {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, execError.message);
        }
        if (execError.isTimeout) {
             throw new sdkTypes.McpError(sdkTypes.ErrorCode.RequestTimeout, `Script execution timed out after ${input.timeoutSeconds || 60} seconds.`);
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

        // It's important to throw McpError as the tool framework expects it.
        // We can add timing information to the McpError's details or message if desired,
        // but the primary return path for timings is via the successful response structure.
        // For now, just ensure execution_time_seconds is calculated.
        // The sdkTypes.McpError constructor doesn't directly support a structured `details` field for timings.
        // We could augment the error message, but it might make it verbose.
        // Let's log it and rely on the structured timing for successful calls.
        logger.error('execute_script handler error', { execution_time_seconds });

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