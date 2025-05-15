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
import pkg from '../package.json' with { type: 'json' }; // Import package.json
import { getKnowledgeBase, getScriptingTipsService, conditionallyInitializeKnowledgeBase } from './services/knowledgeBaseService.js'; // Import KB functions
import { z } from 'zod';

const SERVER_START_TIME_ISO = new Date().toISOString();
const SCRIPT_PATH_EXECUTED = process.argv[1] || 'unknown_path';
const IS_RUNNING_FROM_SRC = SCRIPT_PATH_EXECUTED.includes('/src/server.ts') || SCRIPT_PATH_EXECUTED.endsWith('src/server.ts');
const EXECUTION_MODE_INFO = IS_RUNNING_FROM_SRC ? 'TypeScript source (e.g., via tsx)' : 'Compiled JavaScript (e.g., dist/server.js)';

const logger = new Logger('macos_automator_server');
const scriptExecutor = new ScriptExecutor();

// Helper functions for KB script argument substitution
function escapeForAppleScriptStringLiteral(value: string): string {
    return `"${value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
}

// Helper to escape special characters in regex patterns
// function escapeRegExp(string: string): string { // This function is no longer used
//     return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
// }

function valueToAppleScriptLiteral(value: unknown): string {
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
    logger.warn('Unsupported type for AppleScript literal conversion, using "missing value"', { value });
    return "missing value"; // AppleScript's equivalent of null/undefined (bare keyword)
}

// Define raw shapes for tool registration (required by newer SDK versions)
const ExecuteScriptInputShape = {
  scriptContent: z.string().optional(),
  scriptPath: z.string().optional(),
  knowledgeBaseScriptId: z.string().optional(),
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
    'Executes AppleScript or JavaScript for Automation (JXA) scripts on macOS. This is the primary tool for performing direct automation actions.\n\n**1. Script Source (Exactly one of these MUST be provided):**\n\n*   `knowledgeBaseScriptId` (string):\n    *   **Highly Preferred Method.** Executes a pre-defined, tested script from the server\'s knowledge base using its unique ID.\n    *   **Discovery:** Use the `get_scripting_tips` tool to find available scripts, their `Runnable ID`s (which become this `knowledgeBaseScriptId`), and any required inputs (see `argumentsPrompt` from `get_scripting_tips`).\n    *   Example: `knowledgeBaseScriptId: "safari_get_front_tab_url"`.\n    *   Placeholder Substitution: Scripts from the knowledge base can contain placeholders like `--MCP_INPUT:keyName` or `--MCP_ARG_N` which will be substituted using the `inputData` or `arguments` parameters respectively.\n\n*   `scriptContent` (string):\n    *   Executes raw AppleScript or JXA code provided directly as a string.\n    *   Useful for simple, one-off commands or dynamically generated scripts.\n    *   Example: `scriptContent: "tell application \\"Finder\\" to empty trash"`.\n\n*   `scriptPath` (string):\n    *   Executes a script from a local file on the server machine.\n    *   The path MUST be an absolute POSIX path to the script file (e.g., `/Users/user/myscripts/myscript.applescript`).\n    *   Useful for complex or proprietary scripts not in the knowledge base.\n\n**2. Providing Inputs to Scripts:**\n\n*   `inputData` (JSON object, optional):\n    *   **Primarily for `knowledgeBaseScriptId` scripts.**\n    *   Used to provide named inputs that replace `--MCP_INPUT:keyName` placeholders within the knowledge base script.\n    *   The keys in the object should match the `keyName` in the placeholders. Values (strings, numbers, booleans, simple arrays/objects) are automatically converted to their AppleScript/JXA literal equivalents.\n    *   Example: `inputData: { "folderName": "New Docs", "targetPath": "~/Desktop" }` for a script with `--MCP_INPUT:folderName` and `--MCP_INPUT:targetPath`.\n\n*   `arguments` (array of strings, optional):\n    *   For `scriptPath`: Passed as an array of string arguments to the script\'s main handler (e.g., `on run argv` in AppleScript, `run(argv)` in JXA).\n    *   For `knowledgeBaseScriptId`: Used if a script is specifically designed for positional string arguments (replaces `--MCP_ARG_1`, `--MCP_ARG_2`, etc.). Check the script\'s `argumentsPrompt` from `get_scripting_tips`. Less common for KB scripts than `inputData`.\n\n**3. Execution Options:**\n\n*   `language` (enum: \'applescript\' | \'javascript\', optional):\n    *   Specifies the scripting language.\n    *   **Crucial for `scriptContent` and `scriptPath`** if not `applescript`. Defaults to \'applescript\' if omitted for these sources.\n    *   Automatically inferred from the metadata if using `knowledgeBaseScriptId`.\n\n*   `timeoutSeconds` (integer, optional, default: 30):\n    *   Sets the maximum time (in seconds) the script is allowed to run before being terminated. Increase for potentially long-running operations.\n\n*   `useScriptFriendlyOutput` (boolean, optional, default: false):\n    *   If `true`, uses `osascript -ss` flag. This can provide more structured output (e.g., proper lists/records) from AppleScript, which might be easier for a program to parse than the default human-readable format.\n\n*   `includeExecutedScriptInOutput` (boolean, optional, default: false):\n    *   If `true`, the full script content (after placeholder substitutions for knowledge base scripts) or the `scriptPath` will be appended to the successful output. Useful for verification and debugging.\n\n*   `includeSubstitutionLogs` (boolean, optional, default: false):\n    *   **Only applies to `knowledgeBaseScriptId` scripts.**\n    *   If `true`, detailed logs of each placeholder substitution step performed on the knowledge base script are included in the output (prepended on success, appended on error). Extremely useful for debugging issues with `inputData`/`arguments` processing and how they are inserted into the script.\n\n**Security Note:** Exercise caution, as this tool executes arbitrary code on the macOS machine. Ensure any user-provided script content or files are from trusted sources. macOS permissions (Automation, Accessibility) must be correctly configured for the server process.\n',
    ExecuteScriptInputShape,
    async (args: unknown) => {
      const input = ExecuteScriptInputSchema.parse(args);
      let scriptContentToExecute: string | undefined = input.scriptContent;
      let scriptPathToExecute: string | undefined = input.scriptPath;
      let languageToUse: 'applescript' | 'javascript';
      let finalArgumentsForScriptFile = input.arguments || [];
      const substitutionLogs: string[] = [];

      logger.debug('execute_script called with input:', input);

      if (input.knowledgeBaseScriptId) {
        const kb = await getKnowledgeBase();
        const tip = kb.tips.find((t: { id: string }) => t.id === input.knowledgeBaseScriptId);

        if (!tip) {
          throw new sdkTypes.McpError(sdkTypes.ErrorCode.InvalidParams, `Knowledge base script with ID '${input.knowledgeBaseScriptId}' not found.`);
        }
        if (!tip.script) {
            throw new sdkTypes.McpError(sdkTypes.ErrorCode.InternalError, `Knowledge base script ID '${input.knowledgeBaseScriptId}' has no script content.`);
        }

        scriptContentToExecute = tip.script;
        languageToUse = tip.language;
        scriptPathToExecute = undefined; 
        finalArgumentsForScriptFile = []; 

        if (scriptContentToExecute) {
            // Log char codes for initial script content for deep debugging of quotes
            const charCodes = Array.from(scriptContentToExecute).map(char => char.charCodeAt(0));
            logger.debug('[SUBSTITUTION_DEEP_DEBUG] Initial char codes for script', { first100CharCodes: charCodes.slice(0,100), last100CharCodes: charCodes.slice(-100) });

            // Define placeholder patterns carefully to match placeholders in script templates.
            // These typically appear as quoted strings in the templates for safety.
            // Example from KB: return myHandler("--MCP_INPUT:name", "--MCP_ARG_1")

            const logSub = (message: string, data: unknown) => {
                const logEntry = `[SUBST] ${message} ${JSON.stringify(data)}`;
                logger.debug(logEntry); // Keep debug logging to console
                if (input.includeSubstitutionLogs) {
                    substitutionLogs.push(logEntry);
                }
            };

            // JS-style ${inputData.key}
            const jsInputDataRegex = /\\$\\{inputData\\.(\\w+)\\}/g;
            logSub('Before jsInputDataRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(jsInputDataRegex, (match, keyName) => {
                const replacementValue = input.inputData && keyName in input.inputData
                    ? valueToAppleScriptLiteral(input.inputData[keyName])
                    : "missing value"; // Bare keyword
                logSub('jsInputDataRegex replacing', { match, keyName, replacementValue });
                return replacementValue;
            });
            logSub('After jsInputDataRegex', { scriptContentLength: scriptContentToExecute.length });

            // JS-style ${arguments[N]}
            const jsArgumentsRegex = /\\$\\{arguments\\[(\\d+)\\]\\}/g;
            logSub('Before jsArgumentsRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(jsArgumentsRegex, (match, indexStr) => {
                const index = Number.parseInt(indexStr, 10);
                const replacementValue = input.arguments && index >= 0 && index < input.arguments.length
                    ? valueToAppleScriptLiteral(input.arguments[index])
                    : "missing value"; // Bare keyword
                logSub('jsArgumentsRegex replacing', { match, indexStr, index, replacementValue });
                return replacementValue;
            });
            logSub('After jsArgumentsRegex', { scriptContentLength: scriptContentToExecute.length });
            
            // Quoted "--MCP_INPUT:keyName" (handles single or double quotes around the placeholder)
            // const quotedMcpInputRegex = /(?:["'])--MCP_INPUT:(\w+)(?:["'])/g; // Original regex
            // const quotedMcpInputRegex = /--MCP_INPUT:(\w+)/g; // Previous step
            const quotedMcpInputRegex = /(["'])--MCP_INPUT:(\w+)\1/g; // Match opening quote, then key, then same opening quote
            logSub('Before quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(quotedMcpInputRegex, (match, openingQuote, keyName) => {
                 const replacementValue = input.inputData && keyName in input.inputData
                    ? valueToAppleScriptLiteral(input.inputData[keyName])
                    : "missing value"; // Bare keyword
                 logSub('quotedMcpInputRegex (match surrounding quotes) replacing', { match, openingQuote, keyName, replacementValue });
                 return replacementValue; // Return just the value, as quotes are consumed by the regex
            });
            logSub('After quotedMcpInputRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });

            // Quoted "--MCP_ARG_N" (handles single or double quotes)
            // Adapting quotedMcpArgRegex similarly
            // const quotedMcpArgRegex = /(?:["'])--MCP_ARG_(\d+)(?:["'])/g; // Original
            const quotedMcpArgRegex = /(["'])--MCP_ARG_(\d+)\1/g;
            logSub('Before quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(quotedMcpArgRegex, (match, openingQuote, argNumStr) => {
                const argIndex = Number.parseInt(argNumStr, 10) - 1;
                const replacementValue = input.arguments && argIndex >= 0 && argIndex < input.arguments.length
                    ? valueToAppleScriptLiteral(input.arguments[argIndex])
                    : "missing value"; // Bare keyword
                logSub('quotedMcpArgRegex (match surrounding quotes) replacing', { match, openingQuote, argNumStr, argIndex, replacementValue });
                return replacementValue;
            });
            logSub('After quotedMcpArgRegex (match surrounding quotes)', { scriptContentLength: scriptContentToExecute.length });

            // Context-aware bare placeholders (not in comments) e.g., in function calls like myFunc(--MCP_INPUT:key)
            const expressionMcpInputRegex = /([(,=]\s*)--MCP_INPUT:(\w+)\b/g;
            logSub('Before expressionMcpInputRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(expressionMcpInputRegex, (match, prefix, keyName) => {
                const replacementValue = input.inputData && keyName in input.inputData
                        ? valueToAppleScriptLiteral(input.inputData[keyName])
                        : "missing value";
                logSub('expressionMcpInputRegex replacing', { match, prefix, keyName, replacementValue });
                return prefix + replacementValue;
            });
            logSub('After expressionMcpInputRegex', { scriptContentLength: scriptContentToExecute.length });

            const expressionMcpArgRegex = /([(,=]\s*)--MCP_ARG_(\d+)\b/g;
            logSub('Before expressionMcpArgRegex', { scriptContentLength: scriptContentToExecute.length });
            scriptContentToExecute = scriptContentToExecute.replace(expressionMcpArgRegex, (match, prefix, argNumStr) => {
                const argIndex = Number.parseInt(argNumStr, 10) - 1;
                const replacementValue = input.arguments && argIndex >= 0 && argIndex < input.arguments.length
                        ? valueToAppleScriptLiteral(input.arguments[argIndex])
                        : "missing value";
                logSub('expressionMcpArgRegex replacing', { match, prefix, argNumStr, argIndex, replacementValue });
                return prefix + replacementValue;
            });
            logSub('After expressionMcpArgRegex', { scriptContentLength: scriptContentToExecute.length });
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
    'Provides comprehensive access to a curated knowledge base of AppleScript/JXA tips and runnable scripts for macOS automation. This tool is essential for discovery and should be the FIRST CHOICE when aiming to automate macOS tasks, especially those involving common applications or system functions, before attempting to write scripts from scratch. It helps identify pre-built, tested solutions.\n\n**Primary Use Cases & Parameters:**\n\n*   **Discovering Solutions (Use `searchTerm`):**\n    *   Parameter: `searchTerm` (string, optional).\n    *   Functionality: Performs a fuzzy search across all tip titles, descriptions, keywords, script content, and IDs. Ideal for natural language queries like "how to..." (e.g., `searchTerm: "how do I get the current Safari URL and title?"`) or keyword-based searches (e.g., `searchTerm: "Finder copy file to new location"`). This is the most common way to find relevant tips.\n    *   Output: Returns a list of matching tips in Markdown format.\n\n*   **Listing All Categories (Use `listCategories`):**\n    *   Parameter: `listCategories` (boolean, optional, default: false).\n    *   Functionality: If `true`, this will return a list of all available script categories (e.g., "safari", "finder_operations", "system_interaction") along with their descriptions and the number of tips in each. This overrides all other parameters.\n    *   Output: A Markdown list of categories.\n\n*   **Browsing a Specific Category (Use `category`):**\n    *   Parameter: `category` (string, optional).\n    *   Functionality: Retrieves all tips belonging to the specified category ID. Useful if you know the general area of automation you\'re interested in.\n    *   Output: All tips within that category, formatted in Markdown.\n\n*   **Forcing a Knowledge Base Reload (Use `refreshDatabase`):**\n    *   Parameter: `refreshDatabase` (boolean, optional, default: false).\n    *   Functionality: If `true`, forces the server to reload the entire knowledge base from disk before processing the request. Primarily useful during development if knowledge base files are being actively modified and you need to ensure the latest versions are reflected without a server restart.\n\n**Output Details:**\nThe tool returns a single Markdown formatted string. Each tip in the output typically includes:\n- Title: A human-readable title for the tip.\n- Description: A brief explanation of what the script does.\n- Language: `applescript` or `javascript`.\n- Script: The actual code snippet.\n- Runnable ID: A unique identifier (e.g., `safari_get_front_tab_url`). **This ID is critical as it can be directly used as the `knowledgeBaseScriptId` parameter in the `execute_script` tool for immediate execution.**\n- Arguments Prompt: If the script is designed to take inputs when run by ID, this field describes what `arguments` or `inputData` are expected by `execute_script`.\n- Keywords: Relevant search terms.\n- Notes: Additional context or important considerations.\n\n**Workflow Example:**\n1. User asks: "How do I create a new note in the Notes app with a specific title?"\n2. Agent calls `get_scripting_tips` with `searchTerm: "create new note in Notes app with title"`.\n3. Agent reviews the output. If a tip like `notes_create_new_note_with_title` with a `Runnable ID` and an `argumentsPrompt` for `noteTitle` and `noteBody` is found:\n4. Agent then calls `execute_script` with `knowledgeBaseScriptId: "notes_create_new_note_with_title"` and appropriate `inputData`.\n',
    GetScriptingTipsInputShape,
    async (args: unknown) => {
      const input = GetScriptingTipsInputSchema.parse(args);
      logger.info('get_scripting_tips tool called', input);
      try {
        const serverInfo = { startTime: SERVER_START_TIME_ISO, mode: EXECUTION_MODE_INFO };
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


if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(error => {
        const mainError = error as Error;
        logger.error("Fatal error during server startup:", { message: mainError.message, stack: mainError.stack });
        process.exit(1);
    });
} 